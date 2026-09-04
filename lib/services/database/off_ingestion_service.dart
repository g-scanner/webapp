// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/models.dart';
import '../analyzer/analyzer.dart';
import '../../core/network/off_api_client.dart';
import 'local_cache_service.dart';
import 'history_db_service.dart';

class OffIngestionService {
  static Future<Product> scanBarcodeClientSide({
    required FirebaseFirestore db,
    required dynamic auth,
    required String barcode,
    required UserSettings settings,
  }) async {
    // 1. CACHE LOCALE: Cerca in locale. Se esiste, restituiscilo immediatamente.
    final localProduct = await LocalCacheService.getLocalProductByBarcode(barcode);
    if (localProduct != null) {
      if (settings.autoSaveHistory) {
        await HistoryDbService.saveHistoryItem(db, auth, localProduct);
      }

      // Check se i dati OFF hanno più di 30 giorni (Stale Cache) -> innesca aggiornamento in background
      checkAndRefreshOffStaleCache(db: db, product: localProduct, settings: settings);
      return localProduct;
    }

    // 2. FIRESTORE (`products/{barcode}`): Cerca su Firestore se manca in locale
    Product? remoteProduct;
    try {
      remoteProduct = await LocalCacheService.getProductByBarcode(db, barcode);
      if (remoteProduct != null) {
        await LocalCacheService.upsertLocalProduct(remoteProduct);
        if (settings.autoSaveHistory) {
          await HistoryDbService.saveHistoryItem(db, auth, remoteProduct);
        }
        checkAndRefreshOffStaleCache(db: db, product: remoteProduct, settings: settings);
        return remoteProduct;
      }
    } catch (e) {
      debugPrint("Firestore product lookup failed: $e");
    }

    // 3. PRODOTTO NUOVO (OFF API): Se manca sia in locale che in Firestore, chiama OFF
    final offProduct = await fetchAndParseOffProduct(barcode, settings);
    if (offProduct != null) {
      // Salva su Firestore per popolare il DB globale
      try {
        await db
            .collection(productsCollection)
            .doc(barcode)
            .set(offProduct.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error saving new OFF product to Firestore: $e");
      }

      // Salva in locale
      await LocalCacheService.upsertLocalProduct(offProduct);

      if (settings.autoSaveHistory) {
        await HistoryDbService.saveHistoryItem(db, auth, offProduct);
      }
      return offProduct;
    }

    // GHOST PRODUCT: Prodotto non trovato né in cache, né su Firestore, né su OFF.
    // Creiamo un oggetto "Fantasma" con mappe VUOTE per nome, brand, ingredienti e allergeni.
    // Nessun testo hardcoded sul DB: l'app userà la localizzazione dinamica json i18n ("product.status.unknownProductName".tr()).
    final nowIso = DateTime.now().toIso8601String();
    final ghostProduct = Product(
      barcode: barcode,
      nameMap: {},        // Mappa VUOTA: nessun dato su DB (UI usa "product.status.unknownProductName".tr())
      brandMap: {},       // Mappa VUOTA: nessun dato su DB (UI usa "product.status.unknownBrand".tr())
      ingredientsMap: {}, // Mappa VUOTA: ingredienti non disponibili
      allergensMap: {},   // Mappa VUOTA: allergeni non disponibili (hasAllergenData = false)
      pendingReportsCount: 0,
      lastUpdated: nowIso,
      fetchedFromOffAt: nowIso, // permette ricalcolo automatico tra 30 giorni
    );

    // Salva su Firestore per popolare il DB globale (rispetta l'architettura)
    try {
      await db
          .collection(productsCollection)
          .doc(barcode)
          .set(ghostProduct.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving ghost product to Firestore: $e");
    }

    // Salva in cache locale
    await LocalCacheService.upsertLocalProduct(ghostProduct);

    // Registra nella cronologia (fondamentale per BUG 1)
    if (settings.autoSaveHistory) {
      await HistoryDbService.saveHistoryItem(db, auth, ghostProduct);
    }

    return ghostProduct;
  }

  static void checkAndRefreshOffStaleCache({
    required FirebaseFirestore db,
    required Product product,
    required UserSettings settings,
  }) async {
    if (product.fetchedFromOffAt == null) return;
    try {
      final fetchedDate = DateTime.tryParse(product.fetchedFromOffAt!);
      if (fetchedDate == null) return;

      final diffDays = DateTime.now().difference(fetchedDate).inDays;
      if (diffDays >= 30) {
        // Innesca ricalcolo asincrono silenzioso in background
        fetchAndParseOffProduct(product.barcode, settings).then((newOffProduct) async {
          if (newOffProduct != null) {
            await db
                .collection(productsCollection)
                .doc(product.barcode)
                .set(newOffProduct.toJson(), SetOptions(merge: true));
            await LocalCacheService.upsertLocalProduct(newOffProduct);
          }
        }).catchError((e) {
          debugPrint("Background OFF stale refresh error: $e");
        });
      }
    } catch (e) {
      debugPrint("Stale check error: $e");
    }
  }

  static Future<Product?> fetchAndParseOffProduct(
    String barcode,
    UserSettings settings,
  ) async {
    try {
      final response = await OffApiClient.getProduct(barcode);
      if (response.statusCode == 200) {
        final offData = json.decode(response.body);
        if (offData != null && offData['status'] == 1) {
          final pData = offData['product'] as Map<String, dynamic>;

          final Map<String, String> nameMap = {};
          final Map<String, String> brandMap = {};
          final Map<String, String> ingredientsMap = {};
          final Map<String, List<String>> allergensMap = {};

          final supportedLangs = ['it', 'en', 'es', 'fr', 'de'];

          // Estrazione Multilingua NOMI
          for (final lang in supportedLangs) {
            final n = getFirstNonEmptyString(pData, [
              'product_name_$lang',
              'product_name',
            ], '');
            if (n.isNotEmpty) nameMap[lang] = n;
          }

          // Estrazione Multilingua BRANDS (solo se presente su OFF)
          final brandStr = getFirstNonEmptyString(pData, [
            'brands',
            'brand_tags',
          ], '');
          if (brandStr.isNotEmpty && brandStr != '-') {
            for (final lang in supportedLangs) {
              brandMap[lang] = brandStr;
            }
          }

          // Estrazione Multilingua INGREDIENTI
          for (final lang in supportedLangs) {
            String ing = getFirstNonEmptyString(pData, [
              'ingredients_text_$lang',
            ], '');
            if (ing.isNotEmpty) {
              ingredientsMap[lang] = cleanIngredientsText(ing);
            }
          }

          // Fallback Lingua Estremo (Punto 4 Specifica)
          // Se su OFF mancano IT, EN, ES, FR, DE, prendi la primissima lingua disponibile
          if (ingredientsMap.isEmpty) {
            String fallbackIng = '';
            for (final key in pData.keys) {
              if (key.startsWith('ingredients_text_') &&
                  key != 'ingredients_text_with_allergens') {
                final val = pData[key];
                if (val is String && val.trim().isNotEmpty) {
                  fallbackIng = cleanIngredientsText(val.trim());
                  break;
                }
              }
            }
            if (fallbackIng.isNotEmpty) {
              ingredientsMap['en'] = fallbackIng; // Salva nella mappa sotto 'en'
            }
          }

          // Se nameMap è vuoto, cerca prima qualunque chiave di nome su OFF
          if (nameMap.isEmpty) {
            String fallbackName = '';
            for (final key in pData.keys) {
              if (key.startsWith('product_name')) {
                final val = pData[key];
                if (val is String && val.trim().isNotEmpty) {
                  fallbackName = val.trim();
                  break;
                }
              }
            }
            if (fallbackName.isNotEmpty) {
              nameMap['en'] = fallbackName;
            }
            // Se su OFF non esiste alcun nome, nameMap rimane vuota {} (UI userà "product.status.unknownProductName".tr())
          }

          // Estrazione Allergeni con rilevamento accurato dei dati mancanti:
          // Distinguiamo se OFF ha effettivamente campi allergeni / ingredienti oppure se i dati non esistono proprio.
          List<String>? rawAllergens;
          if (pData['allergens_tags'] != null && (pData['allergens_tags'] as List).isNotEmpty) {
            rawAllergens = List<String>.from(pData['allergens_tags']);
          } else if (pData['allergens_from_ingredients'] != null &&
              pData['allergens_from_ingredients'].toString().trim().isNotEmpty) {
            rawAllergens = pData['allergens_from_ingredients']
                .toString()
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          } else if (pData['allergens'] != null &&
              pData['allergens'].toString().trim().isNotEmpty) {
            rawAllergens = pData['allergens']
                .toString()
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          } else if (ingredientsMap.isNotEmpty) {
            // Gli ingredienti sono stati forniti su OFF ma non sono stati segnalati allergeni
            // -> Il produttore/OFF dichiara 0 allergeni
            rawAllergens = [];
          } else if (pData['allergens_tags'] is List && (pData['allergens_tags'] as List).isEmpty) {
            // OFF ha confermato esplicitamente un array vuoto di allergeni
            rawAllergens = [];
          }

          // Se rawAllergens è non-null, abbiamo dati certi (popoliamo la mappa per tutte le lingue).
          // Se rawAllergens è null (es. solo nome su OFF, niente ingredienti né allergeni),
          // allergensMap rimane vuota {} (hasAllergenData = false -> "Informazioni Insufficienti").
          if (rawAllergens != null) {
            for (final lang in supportedLangs) {
              allergensMap[lang] = AllergenCanonicalizer.translateAllergens(rawAllergens, lang);
            }

            // Se OFF conteneva una dicitura safe negli allergeni (es. "it:senza-glutine"),
            // la preserviamo negli ingredienti per informare l'analisi di sicurezza
            final safeClaims = rawAllergens.where(AllergenCanonicalizer.isSafeGlutenClaim).toList();
            if (safeClaims.isNotEmpty) {
              for (final lang in supportedLangs) {
                final currentIng = ingredientsMap[lang] ?? '';
                if (!AllergenCanonicalizer.isSafeGlutenClaim(currentIng)) {
                  ingredientsMap[lang] = currentIng.isEmpty
                      ? 'Senza glutine'
                      : '$currentIng (Senza glutine)';
                }
              }
            }
          }

          final imageUrl = pData['image_url'] ??
              pData['image_front_url'] ??
              pData['image_thumb_url'] ??
              "";

          final nowIso = DateTime.now().toIso8601String();

          return Product(
            barcode: barcode,
            nameMap: nameMap,
            brandMap: brandMap,
            ingredientsMap: ingredientsMap,
            allergensMap: allergensMap,
            imageUrl: imageUrl,
            pendingReportsCount: 0,
            lastUpdated: nowIso,
            fetchedFromOffAt: nowIso,
          );
        }
      }
    } catch (e) {
      debugPrint("OFF fetch and parse error: $e");
    }
    return null;
  }

  static String cleanIngredientsText(String text) {
    if (text.trim().isEmpty) return text;
    return text
        .replaceAllMapped(RegExp(r'_([^_]+)_'), (m) => m[1]!)
        .replaceAll('_', '')
        .replaceAllMapped(RegExp(r'\{[a-z]{2}:([^}]+)\}'), (m) => m[1]!)
        .replaceAll(RegExp(r'\{[^}]*\}'), '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll('\$', '')
        .replaceAllMapped(RegExp(r'\(([^()]+)\(([^()]+)\)\)'), (m) {
          return '(${m[1]!.trim()}, ${m[2]!.trim()})';
        })
        .replaceAllMapped(RegExp(r'\(\s*([^()]+)\s*\(\s*([^()]+)\s*\)\s*\)'), (m) {
          return '(${m[1]!.trim()}, ${m[2]!.trim()})';
        })
        .replaceAll(RegExp(r'\(\s+'), '(')
        .replaceAll(RegExp(r'\s+\)'), ')')
        .replaceAll(RegExp(r'\([^a-zA-Z0-9À-ÿ]*\)'), '')
        .replaceAll('))', ')')
        .replaceAllMapped(RegExp(r'\s+([,.;])'), (m) => m[1]!)
        .replaceAll(RegExp(r'  +'), ' ')
        .trim();
  }

  static String getFirstNonEmptyString(
    Map<String, dynamic> data,
    List<String> keys,
    String defaultValue,
  ) {
    for (final key in keys) {
      final val = data[key];
      if (val == null) continue;
      if (val is List && val.isNotEmpty) {
        final firstVal = val[0].toString().trim();
        if (firstVal.isNotEmpty) return firstVal;
      } else if (val is String && val.trim().isNotEmpty) {
        return val.trim();
      } else if (val is! List && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return defaultValue;
  }
}

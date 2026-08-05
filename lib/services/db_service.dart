// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/types.dart';
import 'analyzer_service.dart';
import 'off_api_client.dart';

const String productsCollection = "products";
const String reportsCollection = "reports";

class DbService {
  static final FirebaseFirestore db = FirebaseFirestore.instance;
  static final FirebaseAuth auth = FirebaseAuth.instance;

  static Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final docSnap = await db
          .collection(productsCollection)
          .doc(barcode)
          .get();
      if (docSnap.exists) {
        return Product.fromJson(docSnap.data()!);
      }
      return null;
    } catch (e) {
      print("Error getting product: $e");
      return null;
    }
  }

  static const String _productsKey = 'celiac_products_cache';

  static Future<List<Product>> getLocalProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_productsKey) ?? [];
      return list.map((e) => Product.fromJson(json.decode(e))).toList();
    } catch (e) {
      print("Error loading local products: $e");
      return [];
    }
  }

  static Future<List<Product>> fetchAllProducts() async {
    try {
      final snap = await db.collection(productsCollection).limit(100).get();
      final products = snap.docs
          .map((d) => Product.fromJson(d.data()))
          .toList();
      // Salva in locale per il prossimo avvio
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          _productsKey,
          products.map((p) => json.encode(p.toJson())).toList(),
        );
      } catch (_) {}
      return products;
    } catch (e) {
      print("Error fetching products: $e");
      return [];
    }
  }

  static String _getHistoryKey() {
    final user = auth.currentUser;
    if (user != null && !user.isAnonymous) {
      return 'celiac_history_${user.uid}';
    }
    return 'celiac_history';
  }

  static String _getReportsKey() {
    final user = auth.currentUser;
    if (user != null && !user.isAnonymous) {
      return 'celiac_reports_${user.uid}';
    }
    return 'celiac_reports';
  }

  static Future<List<ProductReport>> fetchUserReports() async {
    try {
      final key = _getReportsKey();
      final prefs = await SharedPreferences.getInstance();
      List<String> reportsStr = prefs.getStringList(key) ?? [];
      return reportsStr
          .map((e) => ProductReport.fromJson(json.decode(e)))
          .toList();
    } catch (e) {
      print("Error fetching local user reports: $e");
      return [];
    }
  }

  static Future<List<ProductReport>> syncReportsWithFirestore() async {
    final user = auth.currentUser;
    if (user == null || user.isAnonymous) {
      return fetchUserReports();
    }
    try {
      final snap = await db
          .collection(reportsCollection)
          .where("userId", isEqualTo: user.uid)
          .get();
      final remoteReports = snap.docs
          .map((d) => ProductReport.fromJson(d.data()))
          .toList();

      // Ordina in memoria per data decrescente
      remoteReports.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      final key = _getReportsKey();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        key,
        remoteReports.map((e) => json.encode(e.toJson())).toList(),
      );
      return remoteReports;
    } catch (e) {
      print("Error syncing user reports: $e");
      return fetchUserReports();
    }
  }

  static String _getFirstNonEmptyString(
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

  static Future<Product> scanBarcodeClientSide(
    String barcode,
    UserSettings settings,
  ) async {
    String offName = "Prodotto Sconosciuto";
    String offBrand = "Produttore Sconosciuto";
    String offIngredients = "";
    List<String> offAllergens = [];
    List<String> offCategories =
        []; // Variabile per le Categorie OFF (Context-Aware)
    String offImage = "";
    int offLastModified = 0;

    Product? productApi;

    try {
      final response = await OffApiClient.getProduct(barcode);
      if (response.statusCode == 200) {
        final offData = json.decode(response.body);
        if (offData != null && offData['status'] == 1) {
          final pData = offData['product'] as Map<String, dynamic>;
          offName = _getFirstNonEmptyString(pData, [
            'product_name_it',
            'product_name',
            'product_name_en',
            'product_name_fr',
            'product_name_de',
            'product_name_es',
            'product_name_pt',
            'product_name_nl',
            'product_name_pl',
            'product_name_ar',
            'product_name_ja',
            'product_name_zh',
            'product_name_ko',
            'product_name_ru',
            'generic_name_it',
            'generic_name',
            'generic_name_en',
            'generic_name_fr',
            'abbreviated_product_name',
          ], offName);
          offBrand = _getFirstNonEmptyString(pData, [
            'brands',
            'brand_tags',
            'brands_imported',
          ], offBrand);
          final prefLang = settings.preferredLanguage;
          offIngredients = _getFirstNonEmptyString(pData, [
            'ingredients_text_$prefLang',
            'ingredients_text_it',
            'ingredients_text_en',
            'ingredients_text_de',
            'ingredients_text_fr',
            'ingredients_text',
            'ingredients_text_es',
            'ingredients_text_pt',
            'ingredients_text_pl',
            'ingredients_text_ar',
            'ingredients_text_nl',
          ], offIngredients);

          // Fallback dinamico su qualsiasi lingua disponibile se ancora vuoto
          if (offIngredients.trim().isEmpty) {
            for (final key in pData.keys) {
              if (key.startsWith('ingredients_text_') &&
                  key != 'ingredients_text_with_allergens') {
                final val = pData[key];
                if (val is String && val.trim().isNotEmpty) {
                  offIngredients = val.trim();
                  break;
                }
              }
            }
          }

          // Ripulisce il testo degli ingredienti con l'helper dedicato
          offIngredients = _cleanIngredientsText(offIngredients);
          offImage =
              pData['image_url'] ??
              pData['image_front_url'] ??
              pData['image_thumb_url'] ??
              "";
          if (pData['last_modified_t'] != null) {
            offLastModified = (pData['last_modified_t'] as int) * 1000;
          }

          // Sorgente primaria: allergens_tags contiene tag canonici tipo "en:gluten", "en:milk"
          // indipendenti dalla lingua del prodotto. translateAllergens rimuove il prefisso e
          // traduce nella lingua giusta seguendo il pattern preferenze.
          if (pData['allergens_tags'] != null) {
            final rawTags = List<String>.from(pData['allergens_tags']);
            if (rawTags.isNotEmpty) {
              offAllergens = rawTags;
            }
          }
          // Fallback: allergens_from_ingredients se i tag strutturati sono vuoti
          if (offAllergens.isEmpty &&
              pData['allergens_from_ingredients'] != null &&
              pData['allergens_from_ingredients'].toString().isNotEmpty) {
            offAllergens = pData['allergens_from_ingredients']
                .toString()
                .split(",")
                .map((a) => a.trim())
                .where((a) => a.isNotEmpty)
                .toList();
          }

          // Estrazione delle categorie (Context-Aware)
          if (pData['categories_tags'] != null) {
            offCategories = List<String>.from(pData['categories_tags']);
          }

          final offTags = OffTags(
            allergensTags: List<String>.from(pData['allergens_tags'] ?? []),
            tracesTags: List<String>.from(pData['traces_tags'] ?? []),
            labelsTags: List<String>.from(pData['labels_tags'] ?? []),
            ingredientsAnalysisTags: List<String>.from(
              pData['ingredients_analysis_tags'] ?? [],
            ),
          );

          // Calcola i dati localizzati solo per la lingua richiesta dall'utente.
          // La lingua già presente nel DB verrà gestita dopo (merge), qui costruiamo
          // solo i valori per la sessione corrente.
          // (prefLang è già definito sopra come settings.preferredLanguage)

          // Risolvi il testo degli ingredienti per la lingua richiesta:
          // 1) Prova il campo specifico per lingua su OFF
          // 2) Se vuoto, cerca la prima lingua disponibile in pData (stesso fallback della UI)
          // 3) Se ancora vuoto, usa offIngredients (che già ha il suo fallback)
          String langIng = _getFirstNonEmptyString(pData, [
            'ingredients_text_$prefLang',
          ], '');
          if (langIng.trim().isEmpty) {
            // Cerca la prima chiave ingredients_text_* disponibile
            for (final key in pData.keys) {
              if (key.startsWith('ingredients_text_') &&
                  key != 'ingredients_text_with_allergens') {
                final val = pData[key];
                if (val is String && val.trim().isNotEmpty) {
                  langIng = val.trim();
                  break;
                }
              }
            }
          }
          if (langIng.trim().isNotEmpty) {
            langIng = _cleanIngredientsText(langIng);
          }
          final String langIngFinal = langIng.isEmpty
              ? offIngredients
              : langIng;

          final langAnalysis = AnalyzerService.analyzeGlutenSafety(
            name: offName,
            brand: offBrand,
            ingredients: langIngFinal,
            allergensList: offAllergens,
            reportCount: 0,
            offTags: offTags,
            categoriesTags: offCategories,
            strictMode: settings.strictMode,
            warnAdditives: settings.warnAdditives,
            alertLactose: settings.alertLactose,
            preferredLanguage: prefLang,
          );

          // Mappe parziali con solo la lingua corrente: verranno fuse con il DB dopo
          final Map<String, String> ingredientsMap = {
            prefLang: langIngFinal.isEmpty ? "Non disponibile" : langIngFinal,
          };
          final Map<String, List<String>> allergensMap = {
            prefLang: langAnalysis.allergens,
          };
          final Map<String, String> reasonsMap = {
            prefLang: langAnalysis.reason,
          };
          final Map<String, List<IngredientAnalyzed>> ingredientsAnalyzedMap = {
            prefLang: langAnalysis.ingredientsAnalyzed,
          };

          // 1° CHIAMATA ANALYZER (Prodotti Nuovi / Aggiornati)
          final analysis = AnalyzerService.analyzeGlutenSafety(
            name: offName,
            brand: offBrand,
            ingredients: offIngredients,
            allergensList: offAllergens,
            reportCount: 0,
            offTags: offTags,
            categoriesTags: offCategories, // Passo le categorie
            strictMode: settings.strictMode,
            warnAdditives: settings.warnAdditives,
            alertLactose:
                settings.alertLactose, // Passo l'impostazione lattosio
            preferredLanguage: settings.preferredLanguage,
          );

          productApi = Product(
            barcode: barcode,
            name: offName,
            brand: offBrand,
            ingredients: offIngredients.isEmpty
                ? "Non disponibile"
                : offIngredients,
            allergens: analysis.allergens,
            status: analysis.status,
            reason: analysis.reason,
            ingredientsAnalyzed: analysis.ingredientsAnalyzed,
            imageUrl: offImage,
            lastUpdated: DateTime.now().toIso8601String(),
            reportCount: 0,
            ingredientsMap: ingredientsMap,
            allergensMap: allergensMap,
            reasonsMap: reasonsMap,
            ingredientsAnalyzedMap: ingredientsAnalyzedMap,
          );
        }
      }
    } catch (err) {
      print("Open Food Facts fetch failed: $err");
    }

    Product? productDb = await getProductByBarcode(barcode);
    Product productToReturn;

    if (productApi != null) {
      // Fondi le mappe localizzate del DB (se esistente) con la nuova lingua calcolata,
      // senza sovrascrivere le chiavi già presenti.
      final String prefLang = settings.preferredLanguage;
      final existingIngMap = productDb?.ingredientsMap ?? {};
      final existingAlgMap = productDb?.allergensMap ?? {};
      final existingRsnMap = productDb?.reasonsMap ?? {};
      final existingIaMap = productDb?.ingredientsAnalyzedMap ?? {};

      // Controlla se la lingua è già registrata nel DB per tutte le mappe localizzate
      final bool alreadyHasLang =
          productDb != null &&
          existingIngMap.containsKey(prefLang) &&
          existingAlgMap.containsKey(prefLang) &&
          existingRsnMap.containsKey(prefLang) &&
          existingIaMap.containsKey(prefLang);

      // Nuovo entry per la lingua corrente (da productApi)
      final newIngEntry = productApi.ingredientsMap?[prefLang];
      final newAlgEntry = productApi.allergensMap?[prefLang];
      final newRsnEntry = productApi.reasonsMap?[prefLang];
      final newIaEntry = productApi.ingredientsAnalyzedMap?[prefLang];

      // Mappe fuse: mantiene le lingue già nel DB, aggiunge quella nuova
      final mergedIngMap = Map<String, String>.from(existingIngMap);
      final mergedAlgMap = Map<String, List<String>>.from(existingAlgMap);
      final mergedRsnMap = Map<String, String>.from(existingRsnMap);
      final mergedIaMap = Map<String, List<IngredientAnalyzed>>.from(
        existingIaMap,
      );

      if (newIngEntry != null) mergedIngMap[prefLang] = newIngEntry;
      if (newAlgEntry != null) mergedAlgMap[prefLang] = newAlgEntry;
      if (newRsnEntry != null) mergedRsnMap[prefLang] = newRsnEntry;
      if (newIaEntry != null) mergedIaMap[prefLang] = newIaEntry;

      // Aggiorna productApi con le mappe fuse
      productApi = Product(
        barcode: productApi.barcode,
        name: productApi.name,
        brand: productApi.brand,
        ingredients: productApi.ingredients,
        allergens: productApi.allergens,
        status: productApi.status,
        reason: productApi.reason,
        ingredientsAnalyzed: productApi.ingredientsAnalyzed,
        imageUrl: productApi.imageUrl,
        lastUpdated: productApi.lastUpdated,
        reportCount: productApi.reportCount,
        ingredientsMap: mergedIngMap,
        allergensMap: mergedAlgMap,
        reasonsMap: mergedRsnMap,
        ingredientsAnalyzedMap: mergedIaMap,
      );

      // Delta da salvare su Firestore: solo le chiavi mappa nuove/aggiornate
      // Usiamo set con merge: true per non toccare gli altri campi del documento
      final Map<String, dynamic> langDelta = {};
      langDelta['ingredients_map.$prefLang'] = mergedIngMap[prefLang];
      langDelta['allergens_map.$prefLang'] = mergedAlgMap[prefLang];
      langDelta['reasons_map.$prefLang'] = mergedRsnMap[prefLang];
      langDelta['ingredients_analyzed_map.$prefLang'] = mergedIaMap[prefLang]
          ?.map((e) => e.toJson())
          .toList();

      if (productDb != null && (productDb.reportCount ?? 0) > 0) {
        int dbReportTime = DateTime.parse(
          productDb.lastUpdated,
        ).millisecondsSinceEpoch;
        if (offLastModified > 0 && offLastModified > dbReportTime) {
          productToReturn = Product(
            barcode: productApi.barcode,
            name: productApi.name,
            brand: productApi.brand,
            ingredients: productApi.ingredients,
            allergens: productApi.allergens,
            status: productApi.status,
            reason: productApi.reason,
            ingredientsAnalyzed: productApi.ingredientsAnalyzed,
            imageUrl: productApi.imageUrl,
            lastUpdated: DateTime.now().toIso8601String(),
            reportCount: 0,
            ingredientsMap: mergedIngMap,
            allergensMap: mergedAlgMap,
            reasonsMap: mergedRsnMap,
            ingredientsAnalyzedMap: mergedIaMap,
          );
          try {
            // Set completo perché il prodotto OFF è stato aggiornato dopo le segnalazioni
            await db
                .collection(productsCollection)
                .doc(barcode)
                .set(productToReturn.toJson());
          } catch (e) {
            print("Error saving updated product to Firestore: $e");
          }
        } else {
          // 2° CHIAMATA ANALYZER (Ricalcolo per prodotto con segnalazioni attive)
          final reanalysis = AnalyzerService.analyzeGlutenSafety(
            name: productApi.name,
            brand: productApi.brand,
            ingredients: productApi.ingredients == "Non disponibile"
                ? ""
                : productApi.ingredients,
            allergensList: productApi.allergens,
            reportCount: productDb.reportCount ?? 0,
            offTags: null,
            categoriesTags: offCategories, // Passo le categorie
            strictMode: settings.strictMode,
            warnAdditives: settings.warnAdditives,
            alertLactose:
                settings.alertLactose, // Passo l'impostazione lattosio
            preferredLanguage: settings.preferredLanguage,
          );
          productToReturn = Product(
            barcode: productApi.barcode,
            name: productApi.name,
            brand: productApi.brand,
            ingredients: productApi.ingredients,
            allergens: reanalysis.allergens,
            status: reanalysis.status,
            reason: productDb.reason,
            ingredientsAnalyzed: reanalysis.ingredientsAnalyzed,
            imageUrl: productApi.imageUrl,
            lastUpdated: productDb.lastUpdated,
            reportCount: productDb.reportCount,
            ingredientsMap: mergedIngMap,
            allergensMap: mergedAlgMap,
            reasonsMap: mergedRsnMap,
            ingredientsAnalyzedMap: mergedIaMap,
          );
          // Merge solo le mappe lingua senza toccare il resto (segnalazioni, status, etc.)
          if (!alreadyHasLang) {
            try {
              await db
                  .collection(productsCollection)
                  .doc(barcode)
                  .update(langDelta);
            } catch (e) {
              print("Error updating lang maps on Firestore: $e");
            }
          }
        }
      } else {
        productToReturn = productApi;
        try {
          if (productDb == null) {
            // Prodotto nuovo: set completo
            await db
                .collection(productsCollection)
                .doc(barcode)
                .set(productToReturn.toJson());
          } else {
            // Prodotto già nel DB senza segnalazioni: merge solo delle mappe lingua
            if (!alreadyHasLang) {
              await db
                  .collection(productsCollection)
                  .doc(barcode)
                  .update(langDelta);
            }
          }
        } catch (e) {
          print("Error saving product to Firestore: $e");
        }
      }
    } else {
      if (productDb != null) {
        productToReturn = productDb;
      } else {
        // 3° CHIAMATA ANALYZER (Fallback se l'API non risponde e non è nel DB)
        final analysisFallback = AnalyzerService.analyzeGlutenSafety(
          name: offName,
          brand: offBrand,
          ingredients: offIngredients,
          allergensList: offAllergens,
          reportCount: 0,
          offTags: null,
          categoriesTags: offCategories, // Passo le categorie
          strictMode: settings.strictMode,
          warnAdditives: settings.warnAdditives,
          alertLactose: settings.alertLactose, // Passo l'impostazione lattosio
          preferredLanguage: settings.preferredLanguage,
        );

        productToReturn = Product(
          barcode: barcode,
          name: offName,
          brand: offBrand,
          ingredients: offIngredients.isEmpty
              ? "Non disponibile"
              : offIngredients,
          allergens: analysisFallback.allergens,
          status: analysisFallback.status,
          reason: analysisFallback.reason,
          ingredientsAnalyzed: analysisFallback.ingredientsAnalyzed,
          imageUrl: offImage,
          lastUpdated: DateTime.now().toIso8601String(),
          reportCount: 0,
        );

        try {
          await db
              .collection(productsCollection)
              .doc(barcode)
              .set(productToReturn.toJson());
        } catch (e) {
          print("Error saving fallback product to Firestore: $e");
        }
      }
    }

    if (settings.autoSaveHistory) {
      await _saveHistoryItem(productToReturn);
    }

    return productToReturn;
  }

  static Future<void> _saveHistoryItem(Product product) async {
    final user = auth.currentUser;
    final now = DateTime.now();
    final key = _getHistoryKey();

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> histStr = prefs.getStringList(key) ?? [];
      List<dynamic> localHist = histStr.map((e) => json.decode(e)).toList();

      bool isDuplicate = false;
      for (var item in localHist) {
        if (item['barcode'] == product.barcode) {
          final scannedAtStr = item['scannedAt'] as String?;
          if (scannedAtStr != null) {
            final scannedAt = DateTime.tryParse(scannedAtStr);
            if (scannedAt != null) {
              final diff = now.difference(scannedAt).inSeconds.abs();
              if (diff <= 10) {
                isDuplicate = true;
                break;
              }
            }
          }
        }
      }

      if (!isDuplicate) {
        final id = user != null && !user.isAnonymous
            ? db.collection("users/${user.uid}/history").doc().id
            : now.millisecondsSinceEpoch.toString();

        final hasLactose = AnalyzerService.checkLactose(
          product.ingredients,
          product.allergens,
        );

        final historyItem = ScanHistoryItem(
          id: id,
          userId: user?.uid,
          barcode: product.barcode,
          productName: product.name,
          brand: product.brand,
          status: product.status,
          scannedAt: now.toIso8601String(),
          hasLactose: hasLactose,
        );

        localHist.insert(0, historyItem.toJson());
        if (localHist.length > 50) localHist.removeLast();

        await prefs.setStringList(
          key,
          localHist.map((e) => json.encode(e)).toList(),
        );

        if (user != null && !user.isAnonymous) {
          await db
              .collection("users/${user.uid}/history")
              .doc(id)
              .set(historyItem.toJson());
        }
      }
    } catch (e) {
      print("Failed saving history: $e");
    }
  }

  static Future<List<ScanHistoryItem>> getHistory() async {
    try {
      final key = _getHistoryKey();
      final prefs = await SharedPreferences.getInstance();
      List<String> histStr = prefs.getStringList(key) ?? [];
      return histStr
          .map((e) => ScanHistoryItem.fromJson(json.decode(e)))
          .toList();
    } catch (e) {
      print("Failed fetching local history: $e");
      return [];
    }
  }

  static Future<List<ScanHistoryItem>> syncHistoryWithFirestore() async {
    final user = auth.currentUser;
    if (user == null || user.isAnonymous) {
      return getHistory();
    }
    try {
      final snap = await db
          .collection("users/${user.uid}/history")
          .orderBy("scannedAt", descending: true)
          .limit(50)
          .get();
      final remoteHistory = snap.docs
          .map((d) => ScanHistoryItem.fromJson(d.data()))
          .toList();

      final key = _getHistoryKey();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        key,
        remoteHistory.map((e) => json.encode(e.toJson())).toList(),
      );
      return remoteHistory;
    } catch (e) {
      print("Failed syncing Firestore history: $e");
      return getHistory();
    }
  }

  static Future<void> wipeHistoryLocal() async {
    final user = auth.currentUser;
    final key = _getHistoryKey();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, []);

      if (user != null && !user.isAnonymous) {
        final q = await db.collection("users/${user.uid}/history").get();
        final batch = db.batch();
        for (var d in q.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      print("Could not wipe history: $e");
    }
  }

  static Future<void> deleteHistoryByBarcodeLocal(String barcode) async {
    final user = auth.currentUser;
    final key = _getHistoryKey();

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> histStr = prefs.getStringList(key) ?? [];
      List<dynamic> localHist = histStr.map((e) => json.decode(e)).toList();
      localHist.removeWhere((item) => item['barcode'] == barcode);
      await prefs.setStringList(
        key,
        localHist.map((e) => json.encode(e)).toList(),
      );

      if (user != null && !user.isAnonymous) {
        final snapshot = await db
            .collection("users/${user.uid}/history")
            .where("barcode", isEqualTo: barcode)
            .get();
        final batch = db.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      print("Could not delete history items by barcode: $e");
    }
  }

  static Future<void> deleteHistoryItemLocal(String id) async {
    final user = auth.currentUser;
    final key = _getHistoryKey();

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> histStr = prefs.getStringList(key) ?? [];
      List<dynamic> localHist = histStr.map((e) => json.decode(e)).toList();
      localHist.removeWhere((item) => item['id'] == id);
      await prefs.setStringList(
        key,
        localHist.map((e) => json.encode(e)).toList(),
      );

      if (user != null && !user.isAnonymous) {
        await db.collection("users/${user.uid}/history").doc(id).delete();
      }
    } catch (e) {
      print("Could not delete history item: $e");
    }
  }

  static bool productDataHasOriginal(Map<String, dynamic> data, String key) {
    return data.containsKey(key) && data[key] != null;
  }

  static Future<Map<String, dynamic>?> _buildProductUpdateOnReport(
    String barcode,
    ProductReport finalReport,
  ) async {
    final prodRef = db.collection(productsCollection).doc(barcode);
    final prodSnap = await prodRef.get();

    if (prodSnap.exists) {
      final p = Product.fromJson(prodSnap.data()!);

      int offLastModified = 0;
      try {
        final offRes = await OffApiClient.getProduct(
          barcode,
          fields: const ['last_modified_t'],
          timeout: const Duration(seconds: 3),
        );
        if (offRes.statusCode == 200) {
          final offData = json.decode(offRes.body);
          if (offData['product'] != null &&
              offData['product']['last_modified_t'] != null) {
            offLastModified =
                (offData['product']['last_modified_t'] as int) * 1000;
          }
        }
      } catch (err) {
        print("Could not check OFF last modification date. $err");
      }

      int reportTime = DateTime.parse(
        finalReport.submittedAt,
      ).millisecondsSinceEpoch;

      final String? origStatus =
          productDataHasOriginal(prodSnap.data()!, 'originalStatus')
          ? prodSnap.data()!['originalStatus']
          : (finalReport.originalStatus?.name ?? p.status.name);
      final String? origReason =
          productDataHasOriginal(prodSnap.data()!, 'originalReason')
          ? prodSnap.data()!['originalReason']
          : p.reason;
      final Map<String, dynamic>? origReasonsMap =
          productDataHasOriginal(prodSnap.data()!, 'originalReasons_map')
          ? prodSnap.data()!['originalReasons_map']
          : p.reasonsMap;

      if (offLastModified > 0 && reportTime > offLastModified) {
        return {
          'status': GlutenSafetyStatus.incerto.name,
          'reason':
              '''ATTENZIONE: La tua segnalazione ("${finalReport.comments}") è più recente dell'ultimo aggiornamento del database Open Food Facts. La ricetta in fabbrica potrebbe essere cambiata. Risulta INCERTO.''',
          'reportCount': (p.reportCount ?? 0) + 1,
          'lastUpdated': DateTime.now().toIso8601String(),
          'originalStatus': origStatus,
          'originalReason': origReason,
          'originalReasons_map': origReasonsMap,
        };
      } else {
        return {
          'status': GlutenSafetyStatus.incerto.name,
          'reason':
              'ATTENZIONE: Segnalata etichetta incongruente. Note: ${finalReport.comments}',
          'reportCount': (p.reportCount ?? 0) + 1,
          'lastUpdated': DateTime.now().toIso8601String(),
          'originalStatus': origStatus,
          'originalReason': origReason,
          'originalReasons_map': origReasonsMap,
        };
      }
    }
    return null;
  }

  static Future<ProductReport> submitProductReportClientSide(
    String barcode,
    String productName,
    String brand,
    Map<String, dynamic> reportData,
    Product? productSnapshot,
  ) async {
    final user = auth.currentUser;
    final isAnonymous = user == null || user.isAnonymous;
    final userId = user?.uid ?? "anonymous";
    final key = _getReportsKey();

    try {
      GlutenSafetyStatus? originalStatus;
      if (reportData['originalStatus'] != null) {
        originalStatus = GlutenSafetyStatus.values.firstWhere(
          (e) => e.name == reportData['originalStatus'],
          orElse: () => GlutenSafetyStatus.sconosciuto,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      List<String> reportsStr = prefs.getStringList(key) ?? [];
      List<dynamic> localReports = reportsStr
          .map((e) => json.decode(e))
          .toList();

      final id = db.collection(reportsCollection).doc().id;

      final finalReport = ProductReport(
        id: id,
        barcode: barcode,
        productName: productName,
        brand: brand,
        type: reportData['type'] ?? "label_unclear",
        comments: reportData['comments'] ?? "Etichetta poco chiara.",
        submittedAt: DateTime.now().toIso8601String(),
        status: "open",
        userId: userId,
        originalStatus: originalStatus,
        productSnapshot: productSnapshot,
      );

      localReports.insert(0, finalReport.toJson());
      await prefs.setStringList(
        key,
        localReports.map((e) => json.encode(e)).toList(),
      );

      final docRef = db.collection(reportsCollection).doc(id);
      final productUpdate = await _buildProductUpdateOnReport(
        barcode,
        finalReport,
      );

      final batch = db.batch();
      batch.set(docRef, finalReport.toJson());

      if (productUpdate != null) {
        final prodRef = db.collection(productsCollection).doc(barcode);
        batch.update(prodRef, productUpdate);
      }

      if (user != null) {
        final userRef = db.collection("users").doc(userId);
        batch.set(userRef, {
          'reportedBarcodes': FieldValue.arrayUnion([barcode]),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      if (isAnonymous) {
        List<String> reportedBarcodes =
            prefs.getStringList('celiac_reported_barcodes') ?? [];
        if (!reportedBarcodes.contains(barcode)) {
          reportedBarcodes.add(barcode);
          await prefs.setStringList(
            'celiac_reported_barcodes',
            reportedBarcodes,
          );
        }
      }

      return finalReport;
    } catch (error) {
      print("Error submit report: $error");
      rethrow;
    }
  }

  static Future<void> voteOnReportByBarcode(String barcode, int newVote) async {
    final userId = auth.currentUser?.uid ?? "anonymous_voter";

    try {
      final querySnapshot = await db
          .collection(reportsCollection)
          .where('barcode', isEqualTo: barcode)
          .where('status', isEqualTo: 'open')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("Nessuna segnalazione trovata per il barcode: $barcode");
        return;
      }

      final reportDoc = querySnapshot.docs.first;
      final reportRef = reportDoc.reference;
      final userVoteRef = reportRef.collection('votes').doc(userId);

      final voteSnap = await userVoteRef.get();
      int oldVote = 0;
      if (voteSnap.exists) {
        oldVote = voteSnap.data()?['val'] ?? 0;
      }

      if (oldVote == newVote) return;

      final scoreDiff = newVote - oldVote;

      final batch = db.batch();
      batch.set(userVoteRef, {'val': newVote});
      batch.update(reportRef, {'score': FieldValue.increment(scoreDiff)});
      await batch.commit();

      print("Voto $newVote salvato con successo per il barcode $barcode!");
    } catch (e) {
      print("Errore durante il salvataggio del voto: $e");
    }
  }

  static Future<Map<String, int>> getReportVoteDataByBarcode(
    String barcode,
  ) async {
    final userId = auth.currentUser?.uid ?? "anonymous_voter";

    try {
      final querySnapshot = await db
          .collection(reportsCollection)
          .where('barcode', isEqualTo: barcode)
          .where('status', isEqualTo: 'open')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {'score': 0, 'userVote': 0};
      }

      final reportDoc = querySnapshot.docs.first;
      int score = reportDoc.data()['score'] ?? 0;
      int userVote = 0;

      final voteSnap = await reportDoc.reference
          .collection('votes')
          .doc(userId)
          .get();
      if (voteSnap.exists) {
        userVote = voteSnap.data()?['val'] ?? 0;
      }

      return {'score': score, 'userVote': userVote};
    } catch (e) {
      print("Errore durante il recupero dei dati del voto: $e");
      return {'score': 0, 'userVote': 0};
    }
  }

  static Future<void> voteOnReport(String reportId, int newVote) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return;

    final reportRef = db.collection(reportsCollection).doc(reportId);
    final userVoteRef = reportRef.collection('votes').doc(userId);

    try {
      final voteSnap = await userVoteRef.get();

      int oldVote = 0;
      if (voteSnap.exists) {
        oldVote = voteSnap.data()?['val'] ?? 0;
      }

      if (oldVote == newVote) return;

      final scoreDiff = newVote - oldVote;

      final batch = db.batch();
      batch.set(userVoteRef, {'val': newVote});
      batch.update(reportRef, {'score': FieldValue.increment(scoreDiff)});
      await batch.commit();
    } catch (e) {
      print("Errore durante il voto: $e");
    }
  }

  static Future<void> deleteReportFromDb(String reportId) async {
    try {
      final reportRef = db.collection(reportsCollection).doc(reportId);
      final reportSnap = await reportRef.get();
      if (!reportSnap.exists) return;

      final barcode = reportSnap.data()?['barcode'] as String?;

      // Leggiamo i dati necessari PRIMA di aprire il batch
      Map<String, dynamic>? productUpdates;
      if (barcode != null) {
        final productRef = db.collection(productsCollection).doc(barcode);
        final productSnap = await productRef.get();
        if (productSnap.exists) {
          final productData = productSnap.data()!;
          final currentCount = (productData['reportCount'] ?? 0) as int;
          final int newCount = (currentCount - 1) < 0 ? 0 : currentCount - 1;

          if (newCount == 0) {
            final String? originalStatus =
                productData['originalStatus'] as String? ??
                reportSnap.data()?['originalStatus'] as String?;
            final String originalReason =
                (productData['originalReason'] as String? ??
                reportSnap.data()?['originalReason'] as String? ??
                '');
            productUpdates = {
              'status': originalStatus ?? GlutenSafetyStatus.sconosciuto.name,
              'reason': originalReason,
              'reportCount': 0,
              'originalStatus': FieldValue.delete(),
              'originalReason': FieldValue.delete(),
            };
          } else {
            productUpdates = {'reportCount': newCount};
          }
        }
      }

      // Leggiamo tutti i voti associati al report per poterli cancellare nel batch
      final votesQuery = await reportRef.collection('votes').get();

      // Tutto in un unico WriteBatch — atomico: tutto o niente
      final batch = db.batch();

      // Cancelliamo prima i singoli voti
      for (var doc in votesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Cancelliamo il report
      batch.delete(reportRef);

      if (barcode != null && productUpdates != null) {
        batch.update(
          db.collection(productsCollection).doc(barcode),
          productUpdates,
        );
      }
      final user = auth.currentUser;
      if (user != null && !user.isAnonymous && barcode != null) {
        batch.update(db.collection("users").doc(user.uid), {
          'reportedBarcodes': FieldValue.arrayRemove([barcode]),
        });
      }
      await batch.commit();
    } catch (error) {
      print("Could not delete report $error");
    }
  }

  static Future<void> deleteLocalReport(String reportId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getReportsKey();
      List<String> reportsStr = prefs.getStringList(key) ?? [];
      List<ProductReport> reports = reportsStr
          .map((e) => ProductReport.fromJson(json.decode(e)))
          .toList();

      final index = reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        final reportToDelete = reports[index];
        reports.removeAt(index);
        await prefs.setStringList(
          key,
          reports.map((e) => json.encode(e.toJson())).toList(),
        );

        if (reportToDelete.barcode.isNotEmpty) {
          List<String> reportedBarcodes =
              prefs.getStringList('celiac_reported_barcodes') ?? [];
          reportedBarcodes.remove(reportToDelete.barcode);
          await prefs.setStringList(
            'celiac_reported_barcodes',
            reportedBarcodes,
          );
        }
      }
    } catch (e) {
      print("Error deleting local report: $e");
    }
  }

  static Future<UserSettings> getLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? settingsStr = prefs.getString('celiac_settings');
    if (settingsStr != null) {
      try {
        return UserSettings.fromJson(json.decode(settingsStr));
      } catch (e) {
        print("Error parsing local settings: $e");
      }
    }
    return UserSettings(
      strictMode: true,
      alertLactose: false,
      warnAdditives: true,
      autoSaveHistory: true,
      preferredLanguage: "it",
      reportedBarcodes: const [],
    );
  }

  static Future<void> saveLocalSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('celiac_settings', json.encode(settings.toJson()));
  }

  static Future<void> saveSettings(UserSettings settings) async {
    final user = auth.currentUser;
    final effectiveSettings = user != null && !user.isAnonymous
        ? UserSettings(
            userId: user.uid,
            strictMode: settings.strictMode,
            alertLactose: settings.alertLactose,
            warnAdditives: settings.warnAdditives,
            autoSaveHistory: settings.autoSaveHistory,
            preferredLanguage: settings.preferredLanguage,
            reportedBarcodes: settings.reportedBarcodes,
          )
        : settings;

    await saveLocalSettings(effectiveSettings);
    if (user != null && !user.isAnonymous) {
      try {
        await db
            .collection("users")
            .doc(user.uid)
            .set(effectiveSettings.toJson(), SetOptions(merge: true));
      } catch (e) {
        print("Failed saving settings to Firestore: $e");
      }
    }
  }

  static Future<UserSettings> syncSettingsWithFirestore(
    UserSettings localSettings,
  ) async {
    final user = auth.currentUser;
    if (user == null || user.isAnonymous) return localSettings;

    try {
      final docSnap = await db.collection("users").doc(user.uid).get();
      final effectiveLocalSettings = UserSettings(
        userId: user.uid,
        strictMode: localSettings.strictMode,
        alertLactose: localSettings.alertLactose,
        warnAdditives: localSettings.warnAdditives,
        autoSaveHistory: localSettings.autoSaveHistory,
        preferredLanguage: localSettings.preferredLanguage,
        reportedBarcodes: localSettings.reportedBarcodes,
      );

      if (docSnap.exists && docSnap.data() != null) {
        final firestoreSettings = UserSettings.fromJson(docSnap.data()!);

        final localBarcodes = effectiveLocalSettings.reportedBarcodes;
        final remoteBarcodes = firestoreSettings.reportedBarcodes;
        final mergedBarcodes = {...localBarcodes, ...remoteBarcodes}.toList();

        final mergedSettings = UserSettings(
          userId: user.uid,
          strictMode: firestoreSettings.strictMode,
          alertLactose: firestoreSettings.alertLactose,
          warnAdditives: firestoreSettings.warnAdditives,
          autoSaveHistory: firestoreSettings.autoSaveHistory,
          preferredLanguage: firestoreSettings.preferredLanguage,
          reportedBarcodes: mergedBarcodes,
        );

        await saveLocalSettings(mergedSettings);

        await db
            .collection("users")
            .doc(user.uid)
            .set(mergedSettings.toJson(), SetOptions(merge: true));

        return mergedSettings;
      } else {
        await db
            .collection("users")
            .doc(user.uid)
            .set(effectiveLocalSettings.toJson(), SetOptions(merge: true));
        await saveLocalSettings(effectiveLocalSettings);
        return effectiveLocalSettings;
      }
    } catch (e) {
      print("Failed syncing settings from Firestore: $e");
    }
    return UserSettings(
      userId: user.uid,
      strictMode: localSettings.strictMode,
      alertLactose: localSettings.alertLactose,
      warnAdditives: localSettings.warnAdditives,
      autoSaveHistory: localSettings.autoSaveHistory,
      preferredLanguage: localSettings.preferredLanguage,
      reportedBarcodes: localSettings.reportedBarcodes,
    );
  }

  static Future<List<ScanHistoryItem>> getLocalUnsyncedHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> histStr = prefs.getStringList('celiac_history') ?? [];
    return histStr
        .map((e) => ScanHistoryItem.fromJson(json.decode(e)))
        .toList();
  }

  static Future<List<ProductReport>> getLocalUnsyncedReports() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> reportsStr = prefs.getStringList('celiac_reports') ?? [];
    return reportsStr
        .map((e) => ProductReport.fromJson(json.decode(e)))
        .toList();
  }

  static Future<void> migrateLocalDataToFirestore(String newUid) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      bool sameHistoryItem(ScanHistoryItem a, ScanHistoryItem b) {
        if (a.barcode != b.barcode) return false;
        if (a.scannedAt == b.scannedAt) return true;

        final aTime = DateTime.tryParse(a.scannedAt);
        final bTime = DateTime.tryParse(b.scannedAt);
        if (aTime == null || bTime == null) return false;
        return aTime.difference(bTime).inSeconds.abs() <= 10;
      }

      // 1. MIGRAZIONE CRONOLOGIA
      List<String> histStr = prefs.getStringList('celiac_history') ?? [];
      if (histStr.isNotEmpty) {
        final localHistory = histStr
            .map((e) => ScanHistoryItem.fromJson(json.decode(e)))
            .toList();

        final firestoreHistorySnap = await db
            .collection("users/$newUid/history")
            .orderBy("scannedAt", descending: true)
            .limit(100)
            .get();
        final firestoreHistory = firestoreHistorySnap.docs
            .map((d) => ScanHistoryItem.fromJson(d.data()))
            .toList();

        final historyBatch = db.batch();
        final historyRefBase = db.collection("users/$newUid/history");
        final pendingHistory = <ScanHistoryItem>[];
        bool hasHistoryToMigrate = false;

        for (var localItem in localHistory) {
          final isDuplicate =
              firestoreHistory.any(
                (existing) => sameHistoryItem(existing, localItem),
              ) ||
              pendingHistory.any(
                (existing) => sameHistoryItem(existing, localItem),
              );

          if (!isDuplicate) {
            final docRef = historyRefBase.doc(
              localItem.id.isNotEmpty ? localItem.id : historyRefBase.doc().id,
            );
            final itemMap = localItem.toJson();
            itemMap['userId'] = newUid;
            historyBatch.set(docRef, itemMap);
            pendingHistory.add(localItem);
            hasHistoryToMigrate = true;
          }
        }

        if (hasHistoryToMigrate) {
          await historyBatch.commit();
        }
      }

      // 2. MIGRAZIONE SEGNALAZIONI (REPORTS)
      List<String> reportsStr = prefs.getStringList('celiac_reports') ?? [];
      if (reportsStr.isNotEmpty) {
        final localReports = reportsStr
            .map((e) => ProductReport.fromJson(json.decode(e)))
            .toList();

        final firestoreReportsSnap = await db
            .collection(reportsCollection)
            .where("userId", isEqualTo: newUid)
            .get();
        final firestoreReports = firestoreReportsSnap.docs
            .map((d) => ProductReport.fromJson(d.data()))
            .toList();

        final reportsBatch = db.batch();
        final migratedReports = <ProductReport>[];
        bool hasReportsToMigrate = false;

        for (var localReport in localReports) {
          bool reportExists = firestoreReports.any(
            (r) => r.barcode == localReport.barcode,
          );

          if (!reportExists) {
            final docRef = db
                .collection(reportsCollection)
                .doc(
                  localReport.id.isNotEmpty
                      ? localReport.id
                      : db.collection(reportsCollection).doc().id,
                );
            final reportMap = localReport.toJson();
            reportMap['userId'] = newUid;

            reportsBatch.set(docRef, reportMap);
            migratedReports.add(localReport);
            hasReportsToMigrate = true;
          }
        }

        if (hasReportsToMigrate) {
          await reportsBatch.commit();
          for (final report in migratedReports) {
            final productUpdate = await _buildProductUpdateOnReport(
              report.barcode,
              report,
            );
            if (productUpdate != null) {
              final prodRef = db
                  .collection(productsCollection)
                  .doc(report.barcode);
              await prodRef.update(productUpdate);
            }
          }
        }
      }

      // 3. SINCRONIZZAZIONE REPORTED BARCODES
      List<String> localReportedBarcodes =
          prefs.getStringList('celiac_reported_barcodes') ?? [];
      if (localReportedBarcodes.isNotEmpty) {
        await db.collection("users").doc(newUid).set({
          'reportedBarcodes': FieldValue.arrayUnion(localReportedBarcodes),
        }, SetOptions(merge: true));
      }

      // 4. PULIZIA COMPLETA SHAREDPREFERENCES LOCALI
      await prefs.remove('celiac_history');
      await prefs.remove('celiac_reports');
      await prefs.remove('celiac_reported_barcodes');
      print("Migrazione completata con successo!");
    } catch (e) {
      print("Errore durante la migrazione: $e");
    }
  }

  static Future<void> wipeAllLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('celiac_history');
      await prefs.remove('celiac_reports');
      await prefs.remove('celiac_reported_barcodes');
      await prefs.remove('celiac_settings');

      final user = auth.currentUser;
      if (user != null) {
        await prefs.remove('celiac_history_${user.uid}');
        await prefs.remove('celiac_reports_${user.uid}');
      }
      print("Tutti i dati locali sono stati eliminati con successo!");
    } catch (e) {
      print("Errore durante il wipe dei dati locali: $e");
    }
  }

  static String _cleanIngredientsText(String text) {
    if (text.trim().isEmpty) return text;
    return text
        // 1. Rimuove markup allergenico OFF: _testo_ -> testo
        .replaceAllMapped(RegExp(r'_([^_]+)_'), (m) => m[1]!)
        .replaceAll('_', '')
        // 2. Rimuove tag localizzazione OFF: {it:testo} -> testo
        .replaceAllMapped(RegExp(r'\{[a-z]{2}:([^}]+)\}'), (m) => m[1]!)
        // 3. Rimuove tag di provenienza o graffe vuote: {} o {it:} -> ''
        .replaceAll(RegExp(r'\{[^}]*\}'), '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll('\$', '')
        // Gestione parentesi tonde doppie: (A (B)) -> (A, B)
        .replaceAllMapped(RegExp(r'\(([^()]+)\(([^()]+)\)\)'), (m) {
          return '(${m[1]!.trim()}, ${m[2]!.trim()})';
        })
        // Gestione parentesi tonde doppie con spazi: ( A ( B ) ) -> (A, B)
        .replaceAllMapped(RegExp(r'\(\s*([^()]+)\s*\(\s*([^()]+)\s*\)\s*\)'), (
          m,
        ) {
          return '(${m[1]!.trim()}, ${m[2]!.trim()})';
        })
        // 4. Trim spazi subito dentro parentesi: ( testo ) -> (testo)
        .replaceAll(RegExp(r'\(\s+'), '(')
        .replaceAll(RegExp(r'\s+\)'), ')')
        // 5. Rimuove parentesi vuote o con sola punteggiatura/trattini: () (-) ( - ) -> ''
        .replaceAll(RegExp(r'\([^a-zA-Z0-9À-ÿ]*\)'), '')
        // 6. Rimuove doppie chiusure residue
        .replaceAll('))', ')')
        // 7. Rimuove spazi prima dei segni di punteggiatura
        .replaceAllMapped(RegExp(r'\s+([,.;])'), (m) => m[1]!)
        // 8. Collassa spazi multipli
        .replaceAll(RegExp(r'  +'), ' ')
        .trim();
  }

  static Future<void> deleteUserHistory(String userId) async {
    try {
      final historyRef = db.collection("users/$userId/history");
      final snap = await historyRef.get();
      final batch = db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print("User cloud history deleted successfully.");
    } catch (e) {
      print("Error deleting user history: $e");
    }
  }

  static Future<void> deleteUserSettings(String userId) async {
    try {
      await db.collection("users").doc(userId).delete();
      print("User cloud settings deleted successfully.");
    } catch (e) {
      print("Error deleting user settings: $e");
    }
  }

  static Future<void> anonymizeUserReports(String userId) async {
    try {
      final snap = await db
          .collection(reportsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final batch = db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'userId': 'deleted_user'});
      }
      await batch.commit();
      print("User reports anonymized successfully.");
    } catch (e) {
      print("Error anonymizing user reports: $e");
    }
  }

  static Future<void> wipeCurrentUserLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = auth.currentUser;
      if (user != null) {
        await prefs.remove('celiac_history_${user.uid}');
        await prefs.remove('celiac_reports_${user.uid}');
      } else {
        await prefs.remove('celiac_history');
        await prefs.remove('celiac_reports');
        await prefs.remove('celiac_reported_barcodes');
      }
      await prefs.remove('celiac_settings');
      print("Dati locali dell'utente eliminati con successo!");
    } catch (e) {
      print("Errore durante il wipe dei dati locali dell'utente: $e");
    }
  }
}

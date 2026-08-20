// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

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
  static FirebaseFirestore db = FirebaseFirestore.instance;
  static FirebaseAuth auth = FirebaseAuth.instance;

  static const String _productsKey = 'celiac_products_cache';
  static const String _lastSyncKey = 'celiac_app_last_sync_time';

  // ─── LOCAL PRODUCT CACHE & DELTA SYNC (PILASTRO 2) ──────────────────────────

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

  static Future<Product?> getLocalProductByBarcode(String barcode) async {
    final list = await getLocalProducts();
    try {
      return list.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveLocalProducts(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _productsKey,
        products.map((p) => json.encode(p.toJson())).toList(),
      );
    } catch (e) {
      print("Error saving local products: $e");
    }
  }

  static Future<void> upsertLocalProduct(Product product) async {
    try {
      final products = await getLocalProducts();
      final index = products.indexWhere((p) => p.barcode == product.barcode);
      if (index != -1) {
        products[index] = product;
      } else {
        products.insert(0, product);
      }
      await saveLocalProducts(products);
    } catch (e) {
      print("Error upserting local product: $e");
    }
  }

  static Future<String?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncKey);
  }

  static Future<void> saveLastSyncTime(String timeIso) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, timeIso);
  }

  /// Delta Sync (Pilostro 2, Punto 3 & 4)
  /// Fa una singola query a Firestore per scaricare SOLO i prodotti modificati dai mod:
  /// `db.collection('products').where('last_updated', '>', app_last_sync_time)`
  static Future<List<Product>> performDeltaSync() async {
    try {
      final lastSync = await getLastSyncTime();
      Query<Map<String, dynamic>> query = db.collection(productsCollection);

      if (lastSync != null && lastSync.isNotEmpty) {
        query = query.where('last_updated', isGreaterThan: lastSync);
      } else {
        // Primo avvio: limita a 100 per non saturare le letture
        query = query.orderBy('last_updated', descending: true).limit(100);
      }

      final snap = await query.get();
      if (snap.docs.isEmpty) {
        return getLocalProducts();
      }

      final updatedProducts = snap.docs
          .map((d) => Product.fromJson(d.data()))
          .toList();

      final localProducts = await getLocalProducts();
      final Map<String, Product> productMap = {
        for (var p in localProducts) p.barcode: p,
      };

      for (var p in updatedProducts) {
        productMap[p.barcode] = p;
      }

      final newList = productMap.values.toList();
      await saveLocalProducts(newList);
      await saveLastSyncTime(DateTime.now().toIso8601String());

      return newList;
    } catch (e) {
      print("Error performing delta sync: $e");
      return getLocalProducts();
    }
  }

  static Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final docSnap = await db.collection(productsCollection).doc(barcode).get();
      if (docSnap.exists && docSnap.data() != null) {
        final prod = Product.fromJson(docSnap.data()!);
        await upsertLocalProduct(prod);
        return prod;
      }
      return null;
    } catch (e) {
      print("Error getting product from Firestore: $e");
      return null;
    }
  }

  // ─── PIPELINE DI SCANSIONE (PILASTRO 2 & 4) ───────────────────────────────

  static Future<Product> scanBarcodeClientSide(
    String barcode,
    UserSettings settings,
  ) async {
    // 1. CACHE LOCALE: Cerca in locale. Se esiste, restituiscilo immediatamente.
    final localProduct = await getLocalProductByBarcode(barcode);
    if (localProduct != null) {
      if (settings.autoSaveHistory) {
        await _saveHistoryItem(localProduct);
      }

      // Check se i dati OFF hanno più di 30 giorni (Stale Cache) -> innesca aggiornamento in background
      _checkAndRefreshOffStaleCache(localProduct, settings);
      return localProduct;
    }

    // 2. FIRESTORE (`products/{barcode}`): Cerca su Firestore se manca in locale
    Product? remoteProduct;
    try {
      remoteProduct = await getProductByBarcode(barcode);
      if (remoteProduct != null) {
        await upsertLocalProduct(remoteProduct);
        if (settings.autoSaveHistory) {
          await _saveHistoryItem(remoteProduct);
        }
        _checkAndRefreshOffStaleCache(remoteProduct, settings);
        return remoteProduct;
      }
    } catch (e) {
      print("Firestore product lookup failed: $e");
    }

    // 3. PRODOTTO NUOVO (OFF API): Se manca sia in locale che in Firestore, chiama OFF
    final offProduct = await _fetchAndParseOffProduct(barcode, settings);
    if (offProduct != null) {
      // Salva su Firestore per popolare il DB globale
      try {
        await db
            .collection(productsCollection)
            .doc(barcode)
            .set(offProduct.toJson(), SetOptions(merge: true));
      } catch (e) {
        print("Error saving new OFF product to Firestore: $e");
      }

      // Salva in locale
      await upsertLocalProduct(offProduct);

      if (settings.autoSaveHistory) {
        await _saveHistoryItem(offProduct);
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
      print("Error saving ghost product to Firestore: $e");
    }

    // Salva in cache locale
    await upsertLocalProduct(ghostProduct);

    // Registra nella cronologia (fondamentale per BUG 1)
    if (settings.autoSaveHistory) {
      await _saveHistoryItem(ghostProduct);
    }

    return ghostProduct;
  }

  static void _checkAndRefreshOffStaleCache(Product product, UserSettings settings) async {
    if (product.fetchedFromOffAt == null) return;
    try {
      final fetchedDate = DateTime.tryParse(product.fetchedFromOffAt!);
      if (fetchedDate == null) return;

      final diffDays = DateTime.now().difference(fetchedDate).inDays;
      if (diffDays >= 30) {
        // Innesca ricalcolo asincrono silenzioso in background
        _fetchAndParseOffProduct(product.barcode, settings).then((newOffProduct) async {
          if (newOffProduct != null) {
            await db
                .collection(productsCollection)
                .doc(product.barcode)
                .set(newOffProduct.toJson(), SetOptions(merge: true));
            await upsertLocalProduct(newOffProduct);
          }
        }).catchError((e) {
          print("Background OFF stale refresh error: $e");
        });
      }
    } catch (e) {
      print("Stale check error: $e");
    }
  }

  static Future<Product?> _fetchAndParseOffProduct(
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
            final n = _getFirstNonEmptyString(pData, [
              'product_name_$lang',
              'product_name',
            ], '');
            if (n.isNotEmpty) nameMap[lang] = n;
          }

          // Estrazione Multilingua BRANDS (solo se presente su OFF)
          final brandStr = _getFirstNonEmptyString(pData, [
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
            String ing = _getFirstNonEmptyString(pData, [
              'ingredients_text_$lang',
            ], '');
            if (ing.isNotEmpty) {
              ingredientsMap[lang] = _cleanIngredientsText(ing);
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
                  fallbackIng = _cleanIngredientsText(val.trim());
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
              allergensMap[lang] = AnalyzerService.translateAllergens(rawAllergens, lang);
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
      print("OFF fetch and parse error: $e");
    }
    return null;
  }

  // ─── CRONOLOGIA SCANSIONI LOCALE E PAGINATA (PILASTRO 3 & 8) ───────────────

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

  static Future<void> _saveHistoryItem(Product product) async {
    final user = auth.currentUser;
    final now = DateTime.now();
    final key = _getHistoryKey();

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> histStr = prefs.getStringList(key) ?? [];
      List<dynamic> localHist = histStr.map((e) => json.decode(e)).toList();

      // Evita duplicati ravvicinati (< 10s) per lo stesso barcode
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

        final historyItem = ScanHistoryItem(
          id: id,
          barcode: product.barcode,
          scannedAt: now.toIso8601String(),
        );

        localHist.insert(0, historyItem.toJson());
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
      print("Failed saving history item: $e");
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

  /// Paginazione Locale della Cronologia (Pilastro 3 & 8)
  static Future<List<ScanHistoryItem>> getHistoryPaged({
    int offset = 0,
    int limit = 20,
  }) async {
    final fullHistory = await getHistory();
    if (offset >= fullHistory.length) return [];
    final end = (offset + limit < fullHistory.length) ? offset + limit : fullHistory.length;
    return fullHistory.sublist(offset, end);
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
          .limit(100)
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

  // ─── GESTIONE ATOMICA DELLE SEGNALAZIONI (PILASTRO 4 & 7 & 9) ──────────────

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

  /// Creazione Segnalazione con Atomicità WriteBatch (Regola d'Oro 9 & Pilastro 4)
  static Future<ProductReport> submitProductReportClientSide(
    String barcode,
    String productName,
    String brand,
    Map<String, dynamic> reportData,
  ) async {
    final user = auth.currentUser;
    final userId = user?.uid ?? "anonymous";
    final key = _getReportsKey();

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> reportsStr = prefs.getStringList(key) ?? [];
      List<dynamic> localReports = reportsStr.map((e) => json.decode(e)).toList();

      final reportId = db.collection(reportsCollection).doc().id;
      final nowIso = DateTime.now().toIso8601String();

      final finalReport = ProductReport(
        id: reportId,
        barcode: barcode,
        productName: productName,
        brand: brand,
        type: reportData['type'] ?? "label_unclear",
        comments: reportData['comments'] ?? "Etichetta poco chiara.",
        submittedAt: nowIso,
        status: "open",
        userId: userId,
      );

      localReports.insert(0, finalReport.toJson());
      await prefs.setStringList(
        key,
        localReports.map((e) => json.encode(e)).toList(),
      );

      // ATOMIC WRITE BATCH
      final batch = db.batch();

      // 1. Doc in `reports`
      final reportRef = db.collection(reportsCollection).doc(reportId);
      batch.set(reportRef, finalReport.toJson());

      // 2. Increment `pending_reports_count` su `products` e imposta `last_updated`
      final prodRef = db.collection(productsCollection).doc(barcode);
      batch.set(prodRef, {
        'pending_reports_count': FieldValue.increment(1),
        'last_updated': nowIso,
      }, SetOptions(merge: true));

      // 3. Aggiungi barcode alla lista `reportedBarcodes` dell'utente
      if (user != null && !user.isAnonymous) {
        final userRef = db.collection("users").doc(userId);
        batch.set(userRef, {
          'reportedBarcodes': FieldValue.arrayUnion([barcode]),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      // Salva barcode nei segnalati personali locali
      List<String> reportedBarcodes = prefs.getStringList('celiac_reported_barcodes') ?? [];
      if (!reportedBarcodes.contains(barcode)) {
        reportedBarcodes.add(barcode);
        await prefs.setStringList('celiac_reported_barcodes', reportedBarcodes);
      }

      return finalReport;
    } catch (error) {
      print("Error submit report: $error");
      rethrow;
    }
  }

  /// Cancellazione Efemera del Report (Pilastro 7 & Regola d'Oro 9)
  static Future<void> deleteReportFromDb(String reportId) async {
    try {
      final reportRef = db.collection(reportsCollection).doc(reportId);
      final reportSnap = await reportRef.get();
      if (!reportSnap.exists) return;

      final barcode = reportSnap.data()?['barcode'] as String?;
      final nowIso = DateTime.now().toIso8601String();

      // Leggi voti del report prima del batch
      final votesQuery = await reportRef.collection('votes').get();

      // ATOMIC WRITE BATCH
      final batch = db.batch();

      // 1. Cancella voti associati
      for (var doc in votesQuery.docs) {
        batch.delete(doc.reference);
      }

      // 2. Cancella DEFINITIVAMENTE il report (Approccio Efemero)
      batch.delete(reportRef);

      // 3. Decrementa `pending_reports_count` ed aggiorna `last_updated`
      if (barcode != null) {
        final prodRef = db.collection(productsCollection).doc(barcode);
        batch.set(prodRef, {
          'pending_reports_count': FieldValue.increment(-1),
          'last_updated': nowIso,
        }, SetOptions(merge: true));
      }

      // 4. Rimuovi barcode da `reportedBarcodes` dell'utente
      final user = auth.currentUser;
      if (user != null && !user.isAnonymous && barcode != null) {
        batch.set(db.collection("users").doc(user.uid), {
          'reportedBarcodes': FieldValue.arrayRemove([barcode]),
        }, SetOptions(merge: true));
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

  static Future<void> voteOnReportByBarcode(String barcode, int newVote) async {
    final userId = auth.currentUser?.uid ?? "anonymous_voter";

    try {
      final querySnapshot = await db
          .collection(reportsCollection)
          .where('barcode', isEqualTo: barcode)
          .where('status', isEqualTo: 'open')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return;

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
    } catch (e) {
      print("Errore durante il salvataggio del voto: $e");
    }
  }

  static Future<Map<String, int>> getReportVoteDataByBarcode(String barcode) async {
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
      print("Errore durante il recupero del voto: $e");
      return {'score': 0, 'userVote': 0};
    }
  }

  // ─── IMPOSTAZIONI UTENTE LOCALI E CLOUD ─────────────────────────────────────

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

    final defaultSettings = UserSettings(
      strictMode: true,
      alertLactose: false,
      warnAdditives: true,
      autoSaveHistory: true,
      preferredLanguage: UserSettings.defaultSystemLanguage,
      preferredTheme: 'system',
      reportedBarcodes: prefs.getStringList('celiac_reported_barcodes') ?? const [],
    );
    await saveLocalSettings(defaultSettings);
    return defaultSettings;
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
            preferredTheme: settings.preferredTheme,
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

  static Future<UserSettings> syncSettingsWithFirestore(UserSettings localSettings) async {
    final user = auth.currentUser;
    if (user == null || user.isAnonymous) return localSettings;

    try {
      final docSnap = await db.collection("users").doc(user.uid).get();
      if (docSnap.exists && docSnap.data() != null) {
        final firestoreSettings = UserSettings.fromJson(docSnap.data()!);

        final localBarcodes = localSettings.reportedBarcodes;
        final remoteBarcodes = firestoreSettings.reportedBarcodes;
        final mergedBarcodes = {...localBarcodes, ...remoteBarcodes}.toList();

        final mergedSettings = UserSettings(
          userId: user.uid,
          strictMode: firestoreSettings.strictMode,
          alertLactose: firestoreSettings.alertLactose,
          warnAdditives: firestoreSettings.warnAdditives,
          autoSaveHistory: firestoreSettings.autoSaveHistory,
          preferredLanguage: firestoreSettings.preferredLanguage,
          preferredTheme: firestoreSettings.preferredTheme,
          reportedBarcodes: mergedBarcodes,
        );

        await saveLocalSettings(mergedSettings);
        return mergedSettings;
      }
    } catch (e) {
      print("Failed syncing settings: $e");
    }
    return localSettings;
  }

  // ─── MIGRAZIONE E WIPE ─────────────────────────────────────────────────────

  static Future<List<ScanHistoryItem>> getLocalUnsyncedHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> histStr = prefs.getStringList('celiac_history') ?? [];
    return histStr.map((e) => ScanHistoryItem.fromJson(json.decode(e))).toList();
  }

  static Future<List<ProductReport>> getLocalUnsyncedReports() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> reportsStr = prefs.getStringList('celiac_reports') ?? [];
    return reportsStr.map((e) => ProductReport.fromJson(json.decode(e))).toList();
  }

  static Future<void> migrateLocalDataToFirestore(String newUid) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. MIGRAZIONE CRONOLOGIA
      List<String> histStr = prefs.getStringList('celiac_history') ?? [];
      if (histStr.isNotEmpty) {
        final localHistory = histStr
            .map((e) => ScanHistoryItem.fromJson(json.decode(e)))
            .toList();

        final historyBatch = db.batch();
        final historyRefBase = db.collection("users/$newUid/history");

        for (var item in localHistory) {
          final docRef = historyRefBase.doc(
            item.id.isNotEmpty ? item.id : historyRefBase.doc().id,
          );
          historyBatch.set(docRef, item.toJson());
        }
        await historyBatch.commit();
      }

      // 2. MIGRAZIONE SEGNALAZIONI
      List<String> reportsStr = prefs.getStringList('celiac_reports') ?? [];
      if (reportsStr.isNotEmpty) {
        final localReports = reportsStr
            .map((e) => ProductReport.fromJson(json.decode(e)))
            .toList();

        final reportsBatch = db.batch();
        for (var report in localReports) {
          final docRef = db
              .collection(reportsCollection)
              .doc(report.id.isNotEmpty ? report.id : db.collection(reportsCollection).doc().id);
          final rMap = report.toJson();
          rMap['userId'] = newUid;
          reportsBatch.set(docRef, rMap);
        }
        await reportsBatch.commit();
      }

      // 3. REPORTED BARCODES
      List<String> localReportedBarcodes =
          prefs.getStringList('celiac_reported_barcodes') ?? [];
      if (localReportedBarcodes.isNotEmpty) {
        await db.collection("users").doc(newUid).set({
          'reportedBarcodes': FieldValue.arrayUnion(localReportedBarcodes),
        }, SetOptions(merge: true));
      }

      // 4. PULIZIA SHAREDPREFERENCES
      await prefs.remove('celiac_history');
      await prefs.remove('celiac_reports');
      await prefs.remove('celiac_reported_barcodes');
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
      await prefs.remove(_productsKey);
      await prefs.remove(_lastSyncKey);

      final user = auth.currentUser;
      if (user != null) {
        await prefs.remove('celiac_history_${user.uid}');
        await prefs.remove('celiac_reports_${user.uid}');
      }
    } catch (e) {
      print("Errore durante il wipe dei dati locali: $e");
    }
  }

  static Future<void> wipeCurrentUserLocalData() async {
    await wipeAllLocalData();
  }

  static String _cleanIngredientsText(String text) {
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

  static Future<bool> hasAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('gscanner_terms_accepted') ?? false;
  }

  static Future<void> saveTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gscanner_terms_accepted', true);
  }

  // ─── ACCOUNT DELETION HELPERS ────────────────────────────────────────────────

  /// Elimina le impostazioni utente da Firestore.
  static Future<void> deleteUserSettings(String uid) async {
    try {
      await db.collection('users').doc(uid).delete();
    } catch (e) {
      print('deleteUserSettings error: $e');
    }
  }

  /// Elimina tutta la cronologia scansioni dell'utente da Firestore.
  static Future<void> deleteUserHistory(String uid) async {
    try {
      final snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('history')
          .get();
      final batch = db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('deleteUserHistory error: $e');
    }
  }

  /// Anonimizza tutte le segnalazioni dell'utente (rimuove userId e segna come anonymized).
  static Future<void> anonymizeUserReports(String uid) async {
    try {
      final snapshot = await db
          .collection(reportsCollection)
          .where('user_id', isEqualTo: uid)
          .get();
      if (snapshot.docs.isEmpty) return;
      final batch = db.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'user_id': 'deleted',
          'anonymized': true,
        });
      }
      await batch.commit();
    } catch (e) {
      print('anonymizeUserReports error: $e');
    }
  }
}

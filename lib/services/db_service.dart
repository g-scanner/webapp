import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/types.dart';
import 'analyzer_service.dart';

const String productsCollection = "products";
const String reportsCollection = "reports";

class DbService {
  static final FirebaseFirestore db = FirebaseFirestore.instance;
  static final FirebaseAuth auth = FirebaseAuth.instance;

  static Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final docSnap = await db.collection(productsCollection).doc(barcode).get();
      if (docSnap.exists) {
        return Product.fromJson(docSnap.data()!);
      }
      return null;
    } catch (e) {
      print("Error getting product: $e");
      return null;
    }
  }

  static Future<List<Product>> fetchAllProducts() async {
    try {
      final snap = await db.collection(productsCollection).limit(100).get();
      return snap.docs.map((d) => Product.fromJson(d.data())).toList();
    } catch (e) {
      print("Error fetching products: $e");
      return [];
    }
  }

  // Fetch solo le segnalazioni dell'utente corrente
  static Future<List<ProductReport>> fetchUserReports() async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return [];
    try {
      final snap = await db
          .collection(reportsCollection)
          .where("userId", isEqualTo: userId)
          .orderBy("submittedAt", descending: true)
          .limit(50)
          .get();
      return snap.docs.map((d) => ProductReport.fromJson(d.data())).toList();
    } catch (e) {
      print("Error fetching user reports: $e");
      return [];
    }
  }

  static Future<Product> scanBarcodeClientSide(String barcode, UserSettings settings) async {
    String offName = "Prodotto Sconosciuto";
    String offBrand = "N/A";
    String offIngredients = "";
    List<String> offAllergens = [];
    String offImage = "";
    int offLastModified = 0;

    Product? productApi;

    try {
      final response = await http.get(Uri.parse('https://world.openfoodfacts.org/api/v2/product/$barcode.json'));
      if (response.statusCode == 200) {
        final offData = json.decode(response.body);
        if (offData != null && offData['status'] == 1) {
          final pData = offData['product'];
          offName = pData['product_name_it'] ?? pData['product_name'] ?? offName;
          offBrand = pData['brands'] ?? (pData['brand_tags']?.isNotEmpty == true ? pData['brand_tags'][0] : null) ?? offBrand;
          offIngredients = pData['ingredients_text_it'] ?? pData['ingredients_text'] ?? offIngredients;
          offImage = pData['image_url'] ?? pData['image_front_url'] ?? pData['image_thumb_url'] ?? "";
          if (pData['last_modified_t'] != null) {
            offLastModified = (pData['last_modified_t'] as int) * 1000;
          }

          if (pData['allergens_from_ingredients'] != null && pData['allergens_from_ingredients'].toString().isNotEmpty) {
            offAllergens = pData['allergens_from_ingredients'].toString().split(",").map((a) => a.trim().replaceAll("en:", "")).toList();
          }

          final offTags = OffTags(
            allergensTags: List<String>.from(pData['allergens_tags'] ?? []),
            tracesTags: List<String>.from(pData['traces_tags'] ?? []),
            labelsTags: List<String>.from(pData['labels_tags'] ?? []),
            ingredientsAnalysisTags: List<String>.from(pData['ingredients_analysis_tags'] ?? []),
          );

          final analysis = AnalyzerService.analyzeGlutenSafety(
            name: offName,
            brand: offBrand,
            ingredients: offIngredients,
            allergensList: offAllergens,
            reportCount: 0, // prodotto fresco da API
            offTags: offTags,
            strictMode: settings.strictMode,
            warnAdditives: settings.warnAdditives,
          );

          productApi = Product(
            barcode: barcode,
            name: offName,
            brand: offBrand,
            ingredients: offIngredients.isEmpty ? "Non disponibile" : offIngredients,
            allergens: analysis.allergens,
            status: analysis.status,
            reason: analysis.reason,
            ingredientsAnalyzed: analysis.ingredientsAnalyzed,
            imageUrl: offImage,
            lastUpdated: DateTime.now().toIso8601String(),
            reportCount: 0,
          );
        }
      }
    } catch (err) {
      print("Open Food Facts fetch failed: $err");
    }

    Product? productDb = await getProductByBarcode(barcode);
    Product productToReturn;

    if (productApi != null) {
      if (productDb != null && (productDb.reportCount ?? 0) > 0) {
        int dbReportTime = DateTime.parse(productDb.lastUpdated).millisecondsSinceEpoch;
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
          );
          try {
            await db.collection(productsCollection).doc(barcode).set(productToReturn.toJson());
          } catch(e){}
        } else {
          // Prodotto ha segnalazioni attive: ricalcola con reportCount reale
          // così l'analyzer applica la logica gialla per segnalazione
          final reanalysis = AnalyzerService.analyzeGlutenSafety(
            name: productApi.name,
            brand: productApi.brand,
            ingredients: productApi.ingredients,
            allergensList: productApi.allergens,
            reportCount: productDb.reportCount ?? 0,
            offTags: null, // offTags già incorporati nella prima analisi
            strictMode: settings.strictMode,
            warnAdditives: settings.warnAdditives,
          );
          productToReturn = Product(
            barcode: productApi.barcode,
            name: productApi.name,
            brand: productApi.brand,
            ingredients: productApi.ingredients,
            allergens: reanalysis.allergens,
            status: reanalysis.status,
            reason: productDb.reason, // usa il reason dell'ultima segnalazione
            ingredientsAnalyzed: reanalysis.ingredientsAnalyzed,
            imageUrl: productApi.imageUrl,
            lastUpdated: productDb.lastUpdated,
            reportCount: productDb.reportCount,
          );
        }
      } else {
        productToReturn = productApi;
        try {
          await db.collection(productsCollection).doc(barcode).set(productToReturn.toJson());
        } catch(e){}
      }
    } else {
      if (productDb != null) {
        productToReturn = productDb;
      } else {
        final analysisFallback = AnalyzerService.analyzeGlutenSafety(
          name: offName,
          brand: offBrand,
          ingredients: offIngredients,
          allergensList: offAllergens,
          reportCount: 0,
          offTags: null,
          strictMode: settings.strictMode,
          warnAdditives: settings.warnAdditives,
        );

        productToReturn = Product(
          barcode: barcode,
          name: offName,
          brand: offBrand,
          ingredients: offIngredients.isEmpty ? "Non disponibile" : offIngredients,
          allergens: analysisFallback.allergens,
          status: analysisFallback.status,
          reason: analysisFallback.reason,
          ingredientsAnalyzed: analysisFallback.ingredientsAnalyzed,
          imageUrl: offImage,
          lastUpdated: DateTime.now().toIso8601String(),
          reportCount: 0,
        );

        try {
          await db.collection(productsCollection).doc(barcode).set(productToReturn.toJson());
        } catch(e){}
      }
    }

    if (settings.autoSaveHistory) {
      await _saveHistoryItem(productToReturn);
    }

    return productToReturn;
  }

  /// Salva un elemento nella cronologia (Firestore se loggato, SharedPreferences altrimenti)
  static Future<void> _saveHistoryItem(Product product) async {
    final userId = auth.currentUser?.uid;
    if (userId != null) {
      try {
        // Controlla duplicati su Firestore
        final q = await db
            .collection("users/$userId/history")
            .orderBy("scannedAt", descending: true)
            .limit(1)
            .get();
        bool isDuplicate = q.docs.isNotEmpty && q.docs.first.data()['barcode'] == product.barcode;
        if (!isDuplicate) {
          final historyRef = db.collection("users/$userId/history").doc();
          final historyItem = ScanHistoryItem(
            id: historyRef.id,
            userId: userId,
            barcode: product.barcode,
            productName: product.name,
            brand: product.brand,
            status: product.status,
            scannedAt: DateTime.now().toIso8601String(),
          );
          await historyRef.set(historyItem.toJson());
        }
      } catch (error) {
        print("Failed saving history to Firestore: $error");
      }
    } else {
      // Fallback locale
      try {
        final prefs = await SharedPreferences.getInstance();
        List<String> histStr = prefs.getStringList('celiac_history') ?? [];
        List<dynamic> localHist = histStr.map((e) => json.decode(e)).toList();
        if (localHist.isEmpty || localHist.first['barcode'] != product.barcode) {
          final id = DateTime.now().millisecondsSinceEpoch.toString();
          localHist.insert(0, {
            'id': id,
            'barcode': product.barcode,
            'productName': product.name,
            'brand': product.brand,
            'status': product.status.name,
            'scannedAt': DateTime.now().toIso8601String(),
          });
          if (localHist.length > 50) localHist.removeLast();
          await prefs.setStringList('celiac_history', localHist.map((e) => json.encode(e)).toList());
        }
      } catch (e) {
        print("Failed saving history locally: $e");
      }
    }
  }

  /// Recupera la cronologia: da Firestore se loggato, da SharedPreferences altrimenti
  static Future<List<ScanHistoryItem>> getHistory() async {
    final userId = auth.currentUser?.uid;
    if (userId != null) {
      try {
        final snap = await db
            .collection("users/$userId/history")
            .orderBy("scannedAt", descending: true)
            .limit(50)
            .get();
        return snap.docs.map((d) => ScanHistoryItem.fromJson(d.data())).toList();
      } catch (e) {
        print("Failed fetching Firestore history: $e");
      }
    }
    // Fallback locale
    final prefs = await SharedPreferences.getInstance();
    List<String> histStr = prefs.getStringList('celiac_history') ?? [];
    return histStr.map((e) => ScanHistoryItem.fromJson(json.decode(e))).toList();
  }

  static Future<ProductReport> submitProductReportClientSide(String barcode, String productName, String brand, Map<String, dynamic> reportData) async {
    final userId = auth.currentUser?.uid ?? "anonymous";

    try {
      final docRef = db.collection(reportsCollection).doc();
      final finalReport = ProductReport(
        id: docRef.id,
        barcode: barcode,
        productName: productName,
        brand: brand,
        type: reportData['type'] ?? "label_unclear",
        comments: reportData['comments'] ?? "Etichetta poco chiara.",
        submittedAt: DateTime.now().toIso8601String(),
        status: "open",
        userId: userId,
      );
      await docRef.set(finalReport.toJson());

      final prodRef = db.collection(productsCollection).doc(barcode);
      final prodSnap = await prodRef.get();
      if (prodSnap.exists) {
        final p = Product.fromJson(prodSnap.data()!);

        int offLastModified = 0;
        try {
          final offRes = await http.get(Uri.parse('https://world.openfoodfacts.org/api/v2/product/$barcode.json?fields=last_modified_t'));
          if (offRes.statusCode == 200) {
            final offData = json.decode(offRes.body);
            if (offData['product'] != null && offData['product']['last_modified_t'] != null) {
              offLastModified = (offData['product']['last_modified_t'] as int) * 1000;
            }
          }
        } catch (err) {
          print("Could not check OFF last modification date. $err");
        }

        int reportTime = DateTime.parse(finalReport.submittedAt).millisecondsSinceEpoch;

        if (offLastModified > 0 && reportTime > offLastModified) {
          await prodRef.update({
            'status': GlutenSafetyStatus.incerto.name,
            'reason': '''ATTENZIONE: La tua segnalazione ("${finalReport.comments}") è più recente dell'ultimo aggiornamento del database Open Food Facts. La ricetta in fabbrica potrebbe essere cambiata. Risulta INCERTO.''',
            'reportCount': (p.reportCount ?? 0) + 1,
            'lastUpdated': DateTime.now().toIso8601String(),
          });
        } else {
          await prodRef.update({
            'status': GlutenSafetyStatus.incerto.name,
            'reason': 'ATTENZIONE: Segnalata etichetta incongruente. Note: ${finalReport.comments}',
            'reportCount': (p.reportCount ?? 0) + 1,
            'lastUpdated': DateTime.now().toIso8601String(),
          });
        }
      }
      return finalReport;
    } catch (error) {
      print("Error submit report: $error");
      rethrow;
    }
  }

  static Future<void> deleteReportFromDb(String reportId) async {
    try {
      final reportRef = db.collection(reportsCollection).doc(reportId);
      final reportSnap = await reportRef.get();
      if (reportSnap.exists) {
        final barcode = reportSnap.data()?['barcode'];
        await reportRef.delete();

        if (barcode != null) {
          final productRef = db.collection(productsCollection).doc(barcode);
          final productSnap = await productRef.get();
          if (productSnap.exists) {
            final currentCount = productSnap.data()?['reportCount'] ?? 0;
            await productRef.update({
              'reportCount': (currentCount - 1) < 0 ? 0 : currentCount - 1
            });
          }
        }
      }
    } catch (error) {
      print("Could not delete report $error");
    }
  }

  static Future<void> wipeHistoryLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('celiac_history', []);
    final userId = auth.currentUser?.uid;
    if (userId != null) {
      try {
        final q = await db.collection("users/$userId/history").get();
        for (var d in q.docs) {
          await d.reference.delete();
        }
      } catch (e) {
        print("Could not wipe server history $e");
      }
    }
  }

  static Future<void> deleteHistoryByBarcodeLocal(String barcode) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> histStr = prefs.getStringList('celiac_history') ?? [];
    List<dynamic> localHist = histStr.map((e) => json.decode(e)).toList();
    localHist.removeWhere((item) => item['barcode'] == barcode);
    await prefs.setStringList('celiac_history', localHist.map((e) => json.encode(e)).toList());

    final userId = auth.currentUser?.uid;
    if (userId != null) {
      try {
        final snapshot = await db.collection("users/$userId/history").where("barcode", isEqualTo: barcode).get();
        final batch = db.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (e) {
        print("Could not delete server history items by barcode $e");
      }
    }
  }

  static Future<void> deleteHistoryItemLocal(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> histStr = prefs.getStringList('celiac_history') ?? [];
    List<dynamic> localHist = histStr.map((e) => json.decode(e)).toList();
    localHist.removeWhere((item) => item['id'] == id);
    await prefs.setStringList('celiac_history', localHist.map((e) => json.encode(e)).toList());

    final userId = auth.currentUser?.uid;
    if (userId != null) {
      try {
        await db.collection("users/$userId/history").doc(id).delete();
      } catch (e) {
        print("Could not delete server history item $e");
      }
    }
  }

  static Future<UserSettings> getLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? settingsStr = prefs.getString('celiac_settings');
    if (settingsStr != null) {
      return UserSettings.fromJson(json.decode(settingsStr));
    }
    return UserSettings(
      strictMode: false,
      alertLactose: false,
      warnAdditives: true,
      autoSaveHistory: true,
      preferredLanguage: "it",
    );
  }

  static Future<void> saveLocalSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('celiac_settings', json.encode(settings.toJson()));
  }
}

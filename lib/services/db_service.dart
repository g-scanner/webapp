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

  static Future<Product> scanBarcodeClientSide(
    String barcode,
    UserSettings settings,
  ) async {
    String offName = "Prodotto Sconosciuto";
    String offBrand = "Produttore Sconosciuto";
    String offIngredients = "";
    List<String> offAllergens = [];
    String offImage = "";
    int offLastModified = 0;

    Product? productApi;

    try {
      final response = await http.get(
        Uri.parse(
          'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
        ),
      );
      if (response.statusCode == 200) {
        final offData = json.decode(response.body);
        if (offData != null && offData['status'] == 1) {
          final pData = offData['product'];
          offName =
              pData['product_name_it'] ?? pData['product_name'] ?? offName;
          offBrand =
              pData['brands'] ??
              (pData['brand_tags']?.isNotEmpty == true
                  ? pData['brand_tags'][0]
                  : null) ??
              offBrand;
          offIngredients =
              pData['ingredients_text_it'] ??
              pData['ingredients_text'] ??
              offIngredients;
          offImage =
              pData['image_url'] ??
              pData['image_front_url'] ??
              pData['image_thumb_url'] ??
              "";
          if (pData['last_modified_t'] != null) {
            offLastModified = (pData['last_modified_t'] as int) * 1000;
          }

          if (pData['allergens_from_ingredients'] != null &&
              pData['allergens_from_ingredients'].toString().isNotEmpty) {
            offAllergens = pData['allergens_from_ingredients']
                .toString()
                .split(",")
                .map((a) => a.trim().replaceAll("en:", ""))
                .toList();
          }

          final offTags = OffTags(
            allergensTags: List<String>.from(pData['allergens_tags'] ?? []),
            tracesTags: List<String>.from(pData['traces_tags'] ?? []),
            labelsTags: List<String>.from(pData['labels_tags'] ?? []),
            ingredientsAnalysisTags: List<String>.from(
              pData['ingredients_analysis_tags'] ?? [],
            ),
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
          );
          try {
            await db
                .collection(productsCollection)
                .doc(barcode)
                .set(productToReturn.toJson());
          } catch (e) {}
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
          await db
              .collection(productsCollection)
              .doc(barcode)
              .set(productToReturn.toJson());
        } catch (e) {}
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
        } catch (e) {}
      }
    }

    if (settings.autoSaveHistory) {
      await _saveHistoryItem(productToReturn);
    }

    return productToReturn;
  }

  /// Salva un elemento nella cronologia (Firestore se loggato, SharedPreferences altrimenti)
  /// Salva un elemento nella cronologia
  static Future<void> _saveHistoryItem(Product product) async {
    final user = auth.currentUser;

    // Controlliamo che l'utente esista e NON sia anonimo
    if (user != null && !user.isAnonymous) {
      final userId = user.uid;
      try {
        final q = await db
            .collection("users/$userId/history")
            .orderBy("scannedAt", descending: true)
            .limit(1)
            .get();
        bool isDuplicate =
            q.docs.isNotEmpty &&
            q.docs.first.data()['barcode'] == product.barcode;

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
      // UTENTE ANONIMO: Salva solo nel telefono
      try {
        final prefs = await SharedPreferences.getInstance();
        List<String> histStr = prefs.getStringList('celiac_history') ?? [];
        List<dynamic> localHist = histStr.map((e) => json.decode(e)).toList();

        // Evita duplicati rimuovendo il vecchio se esiste
        localHist.removeWhere((item) => item['barcode'] == product.barcode);

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

        await prefs.setStringList(
          'celiac_history',
          localHist.map((e) => json.encode(e)).toList(),
        );
      } catch (e) {
        print("Failed saving history locally: $e");
      }
    }
  }

  /// Recupera la cronologia
  static Future<List<ScanHistoryItem>> getHistory() async {
    final user = auth.currentUser;

    // Se loggato con credenziali reali
    if (user != null && !user.isAnonymous) {
      try {
        final snap = await db
            .collection("users/${user.uid}/history")
            .orderBy("scannedAt", descending: true)
            .limit(50)
            .get();
        return snap.docs
            .map((d) => ScanHistoryItem.fromJson(d.data()))
            .toList();
      } catch (e) {
        print("Failed fetching Firestore history: $e");
        return [];
      }
    }

    // UTENTE ANONIMO: Prendi i dati dalla memoria del telefono
    final prefs = await SharedPreferences.getInstance();
    List<String> histStr = prefs.getStringList('celiac_history') ?? [];
    return histStr
        .map((e) => ScanHistoryItem.fromJson(json.decode(e)))
        .toList();
  }

  static Future<void> wipeHistoryLocal() async {
    final user = auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        final q = await db.collection("users/${user.uid}/history").get();
        for (var d in q.docs) {
          await d.reference.delete();
        }
      } catch (e) {
        print("Could not wipe server history $e");
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('celiac_history', []);
    }
  }

  static Future<void> deleteHistoryByBarcodeLocal(String barcode) async {
    final user = auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        final snapshot = await db
            .collection("users/${user.uid}/history")
            .where("barcode", isEqualTo: barcode)
            .get();
        final batch = db.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (e) {
        print("Could not delete server history items by barcode $e");
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      List<String> histStr = prefs.getStringList('celiac_history') ?? [];
      List<dynamic> localHist = histStr.map((e) => json.decode(e)).toList();
      localHist.removeWhere((item) => item['barcode'] == barcode);
      await prefs.setStringList(
        'celiac_history',
        localHist.map((e) => json.encode(e)).toList(),
      );
    }
  }

  static Future<void> deleteHistoryItemLocal(String id) async {
    final user = auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        await db.collection("users/${user.uid}/history").doc(id).delete();
      } catch (e) {
        print("Could not delete server history item $e");
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      List<String> histStr = prefs.getStringList('celiac_history') ?? [];
      List<dynamic> localHist = histStr.map((e) => json.decode(e)).toList();
      localHist.removeWhere((item) => item['id'] == id);
      await prefs.setStringList(
        'celiac_history',
        localHist.map((e) => json.encode(e)).toList(),
      );
    }
  }

  static Future<ProductReport> submitProductReportClientSide(
    String barcode,
    String productName,
    String brand,
    Map<String, dynamic> reportData,
  ) async {
    final userId = auth.currentUser?.uid ?? "anonymous";

    try {
      // 1. Estraiamo lo stato originale passato dalla UI
      GlutenSafetyStatus? originalStatus;
      if (reportData['originalStatus'] != null) {
        originalStatus = GlutenSafetyStatus.values.firstWhere(
          (e) => e.name == reportData['originalStatus'],
          orElse: () => GlutenSafetyStatus.sconosciuto,
        );
      }

      // 2. Creiamo il report INCLUDENDO l'originalStatus
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
        originalStatus: originalStatus, // <--- SALVATO QUI!
      );

      await docRef.set(finalReport.toJson());

      // 3. Ora procediamo al resto (aggiornare il prodotto a INCERTO)
      final prodRef = db.collection(productsCollection).doc(barcode);
      final prodSnap = await prodRef.get();

      if (prodSnap.exists) {
        final p = Product.fromJson(prodSnap.data()!);

        int offLastModified = 0;
        try {
          final offRes = await http.get(
            Uri.parse(
              'https://world.openfoodfacts.org/api/v2/product/$barcode.json?fields=last_modified_t',
            ),
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

        if (offLastModified > 0 && reportTime > offLastModified) {
          await prodRef.update({
            'status': GlutenSafetyStatus.incerto.name,
            'reason':
                '''ATTENZIONE: La tua segnalazione ("${finalReport.comments}") è più recente dell'ultimo aggiornamento del database Open Food Facts. La ricetta in fabbrica potrebbe essere cambiata. Risulta INCERTO.''',
            'reportCount': (p.reportCount ?? 0) + 1,
            'lastUpdated': DateTime.now().toIso8601String(),
            'originalStatus': originalStatus?.name,
          });
        } else {
          await prodRef.update({
            'status': GlutenSafetyStatus.incerto.name,
            'reason':
                'ATTENZIONE: Segnalata etichetta incongruente. Note: ${finalReport.comments}',
            'reportCount': (p.reportCount ?? 0) + 1,
            'lastUpdated': DateTime.now().toIso8601String(),
            'originalStatus': originalStatus?.name,
          });
        }
      }
      return finalReport;
    } catch (error) {
      print("Error submit report: $error");
      rethrow;
    }
  }

  static Future<void> voteOnReportByBarcode(String barcode, int newVote) async {
    // FIX: Aggiunto il fallback nel caso in cui Firebase non sia riuscito a fare il login anonimo,
    // esattamente come hai fatto per l'invio della segnalazione!
    final userId = auth.currentUser?.uid ?? "anonymous_voter";

    try {
      // 1. Cerca la segnalazione "aperta" associata a questo barcode
      final querySnapshot = await db
          .collection(reportsCollection)
          .where('barcode', isEqualTo: barcode)
          .where(
            'status',
            isEqualTo: 'open',
          ) // Cerca solo le segnalazioni attive
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("Nessuna segnalazione trovata per il barcode: $barcode");
        return;
      }

      // 2. Prendi l'ID reale del report
      final reportDoc = querySnapshot.docs.first;
      final reportRef = reportDoc.reference;

      // 3. Creiamo il riferimento per il voto dello specifico utente
      final userVoteRef = reportRef.collection('votes').doc(userId);

      // 4. Eseguiamo la transazione per aggiornare i voti in modo sicuro
      await db.runTransaction((transaction) async {
        final voteSnap = await transaction.get(userVoteRef);

        int oldVote = 0;
        if (voteSnap.exists) {
          oldVote = voteSnap.data()?['val'] ?? 0;
        }

        // Se è lo stesso voto, non facciamo nulla
        if (oldVote == newVote) return;

        // Calcola la differenza da applicare al totale
        final scoreDiff = newVote - oldVote;

        // Salva/aggiorna il voto del singolo utente
        transaction.set(userVoteRef, {'val': newVote});

        // Aggiorna il punteggio globale della segnalazione
        transaction.update(reportRef, {
          'score': FieldValue.increment(scoreDiff),
        });
      });

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
      // 1. Cerca la segnalazione aperta
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
      // 2. Controlla se questo specifico utente ha già votato in passato
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

  // Aggiungi questo in DbService.dart
  static Future<void> voteOnReport(String reportId, int newVote) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return; // L'utente deve essere loggato per votare

    final reportRef = db.collection(reportsCollection).doc(reportId);
    // Usiamo una sottocollezione "votes" dentro al report per tracciare i voti degli utenti
    final userVoteRef = reportRef.collection('votes').doc(userId);

    try {
      await db.runTransaction((transaction) async {
        final voteSnap = await transaction.get(userVoteRef);

        int oldVote = 0;
        if (voteSnap.exists) {
          oldVote = voteSnap.data()?['val'] ?? 0;
        }

        // Se l'utente clicca lo stesso voto che aveva già dato, ignoriamo o resettiamo
        if (oldVote == newVote) return;

        // Calcola la differenza (es: se prima era -1 e ora mette +1, la differenza è +2)
        final scoreDiff = newVote - oldVote;

        // Salva il voto del singolo utente
        transaction.set(userVoteRef, {'val': newVote});

        // Aggiorna il totale del report in modo sicuro
        transaction.update(reportRef, {
          'score': FieldValue.increment(scoreDiff),
        });
      });
    } catch (e) {
      print("Errore durante il voto: $e");
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
              'reportCount': (currentCount - 1) < 0 ? 0 : currentCount - 1,
            });
          }
        }
      }
    } catch (error) {
      print("Could not delete report $error");
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

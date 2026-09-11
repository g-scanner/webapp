// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';
import 'daos/product_report_dao.dart';
import 'local_cache_service.dart' show productsCollection;

const String reportsCollection = "reports";

/// Servizio per la gestione delle segnalazioni e della cronologia segnalazioni.
/// I dati locali sono memorizzati in SQLite (sqflite) per evitare saturazione RAM.
class ReportsDbService {
  static const ProductReportDao _reportDao = ProductReportDao();

  /// Identificatore logico dell'utente per il partizionamento dei report.
  static String getUserId(FirebaseAuth auth) {
    final user = auth.currentUser;
    if (user != null && !user.isAnonymous) {
      return user.uid;
    }
    return 'anonymous';
  }

  /// Mantiene compatibilità di interfaccia per eventuali test o chiamate storiche.
  static String getReportsKey(FirebaseAuth auth) {
    final user = auth.currentUser;
    if (user != null && !user.isAnonymous) {
      return 'celiac_reports_${user.uid}';
    }
    return 'celiac_reports';
  }

  /// Recupera le segnalazioni locali dell'utente (cronologia segnalazioni).
  static Future<List<ProductReport>> fetchUserReports(FirebaseAuth auth) async {
    try {
      final userId = getUserId(auth);
      final fromDb = await _reportDao.getUserReports(userId);
      if (fromDb.isNotEmpty) return fromDb;

      final key = getReportsKey(auth);
      final prefs = await SharedPreferences.getInstance();
      final reportsStr = prefs.getStringList(key) ?? [];
      final List<ProductReport> result = [];
      for (final e in reportsStr) {
        try {
          final decoded = json.decode(e);
          if (decoded is Map<String, dynamic>) {
            result.add(ProductReport.fromJson(decoded));
          }
        } catch (_) {}
      }
      return result;
    } catch (e) {
      debugPrint("Error fetching local user reports from SQLite: $e");
      return [];
    }
  }

  /// Sincronizza le segnalazioni con Firestore e aggiorna la cache locale SQLite.
  static Future<List<ProductReport>> syncReportsWithFirestore(
    FirebaseFirestore db,
    FirebaseAuth auth,
  ) async {
    final user = auth.currentUser;
    if (user == null || user.isAnonymous) {
      return fetchUserReports(auth);
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

      await _reportDao.setReports(user.uid, remoteReports);
      return remoteReports;
    } catch (e) {
      debugPrint("Error syncing user reports: $e");
      return fetchUserReports(auth);
    }
  }

  /// Creazione Segnalazione con Atomicità WriteBatch (Regola d'Oro 9 & Pilastro 4)
  static Future<ProductReport> submitProductReportClientSide(
    FirebaseFirestore db,
    FirebaseAuth auth,
    String barcode,
    String productName,
    String brand,
    Map<String, dynamic> reportData,
  ) async {
    final user = auth.currentUser;
    final userId = getUserId(auth);

    try {
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

      // Persistenza locale SQLite immediata
      await _reportDao.insertReport(finalReport);

      // ATOMIC WRITE BATCH SU FIRESTORE
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

      return finalReport;
    } catch (error) {
      debugPrint("Error submit report: $error");
      rethrow;
    }
  }

  /// Cancellazione Efemera del Report (Pilastro 7 & Regola d'Oro 9)
  static Future<void> deleteReportFromDb(
    FirebaseFirestore db,
    FirebaseAuth auth,
    String reportId,
  ) async {
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
      debugPrint("Could not delete report $error");
    }
  }

  /// Elimina una segnalazione dal database locale SQLite.
  static Future<void> deleteLocalReport(
    FirebaseAuth auth,
    String reportId,
  ) async {
    try {
      final userId = getUserId(auth);
      await _reportDao.deleteReport(userId, reportId);

      // Supporta pulizia prefs per test che iniettano in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final key = getReportsKey(auth);
      final reportsStr = prefs.getStringList(key) ?? [];
      if (reportsStr.isNotEmpty) {
        final reports = reportsStr
            .map((e) => ProductReport.fromJson(json.decode(e) as Map<String, dynamic>))
            .toList();
        final index = reports.indexWhere((r) => r.id == reportId);
        if (index != -1) {
          final toDel = reports.removeAt(index);
          await prefs.setStringList(
            key,
            reports.map((e) => json.encode(e.toJson())).toList(),
          );
          final barList = prefs.getStringList('celiac_reported_barcodes') ?? [];
          barList.remove(toDel.barcode);
          await prefs.setStringList('celiac_reported_barcodes', barList);
        }
      }
    } catch (e) {
      debugPrint("Error deleting local report from SQLite: $e");
    }
  }

  static Future<void> voteOnReportByBarcode(
    FirebaseFirestore db,
    FirebaseAuth auth,
    String barcode,
    int newVote,
  ) async {
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
      debugPrint("Errore durante il salvataggio del voto: $e");
    }
  }

  static Future<Map<String, int>> getReportVoteDataByBarcode(
    FirebaseFirestore db,
    FirebaseAuth auth,
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
      debugPrint("Errore durante il recupero del voto: $e");
      return {'score': 0, 'userVote': 0};
    }
  }
}

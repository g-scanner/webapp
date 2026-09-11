// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';
import 'daos/product_dao.dart';
import 'daos/scan_history_dao.dart';
import 'daos/product_report_dao.dart';
import 'daos/sync_metadata_dao.dart';
import 'local_cache_service.dart';
import 'reports_db_service.dart' show reportsCollection;

/// Servizio responsabile della migrazione dei dati anonimi post-login
/// e della cancellazione/pulizia di tutti i dati locali.
class AccountDataService {
  static const ScanHistoryDao _historyDao = ScanHistoryDao();
  static const ProductReportDao _reportDao = ProductReportDao();
  static const ProductDao _productDao = ProductDao();
  static const SyncMetadataDao _syncMetadataDao = SyncMetadataDao();

  /// Recupera la cronologia creata in modalità anonima (non sincronizzata).
  static Future<List<ScanHistoryItem>> getLocalUnsyncedHistory() async {
    try {
      final list = await _historyDao.getHistory('anonymous');
      if (list.isNotEmpty) return list;

      // Fallback per test o sessioni legacy
      final prefs = await SharedPreferences.getInstance();
      final histStr = prefs.getStringList('celiac_history') ?? [];
      return histStr
          .map((e) => ScanHistoryItem.fromJson(json.decode(e) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Error fetching unsynced history: $e");
      return [];
    }
  }

  /// Recupera le segnalazioni create in modalità anonima.
  static Future<List<ProductReport>> getLocalUnsyncedReports() async {
    try {
      final list = await _reportDao.getUserReports('anonymous');
      if (list.isNotEmpty) return list;

      // Fallback per test o sessioni legacy
      final prefs = await SharedPreferences.getInstance();
      final reportsStr = prefs.getStringList('celiac_reports') ?? [];
      return reportsStr
          .map((e) => ProductReport.fromJson(json.decode(e) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Error fetching unsynced reports: $e");
      return [];
    }
  }

  /// Migra la cronologia e le segnalazioni locali anonime su Firestore al momento dell'autenticazione.
  static Future<void> migrateLocalDataToFirestore(
    FirebaseFirestore db,
    String newUid,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. MIGRAZIONE CRONOLOGIA
      var localHistory = await _historyDao.getHistory('anonymous');
      if (localHistory.isEmpty) {
        final histStr = prefs.getStringList('celiac_history') ?? [];
        localHistory = histStr
            .map((e) => ScanHistoryItem.fromJson(json.decode(e) as Map<String, dynamic>))
            .toList();
      }
      if (localHistory.isNotEmpty) {
        final historyBatch = db.batch();
        final historyRefBase = db.collection("users/$newUid/history");

        for (final item in localHistory) {
          final docRef = historyRefBase.doc(
            item.id.isNotEmpty ? item.id : historyRefBase.doc().id,
          );
          historyBatch.set(docRef, item.toJson());
        }
        await historyBatch.commit();
        await _historyDao.reassignAnonymousHistory(newUid);
      }

      // 2. MIGRAZIONE SEGNALAZIONI
      var localReports = await _reportDao.getUserReports('anonymous');
      if (localReports.isEmpty) {
        final reportsStr = prefs.getStringList('celiac_reports') ?? [];
        localReports = reportsStr
            .map((e) => ProductReport.fromJson(json.decode(e) as Map<String, dynamic>))
            .toList();
      }
      if (localReports.isNotEmpty) {
        final reportsBatch = db.batch();
        for (final report in localReports) {
          final docRef = db.collection(reportsCollection).doc(
            report.id.isNotEmpty ? report.id : db.collection(reportsCollection).doc().id,
          );
          final rMap = report.toJson();
          rMap['userId'] = newUid;
          reportsBatch.set(docRef, rMap);
        }
        await reportsBatch.commit();
        await _reportDao.reassignAnonymousReports(newUid);
      }

      // 3. REPORTED BARCODES
      var reportedBarcodes = await _reportDao.getReportedBarcodes(newUid);
      if (reportedBarcodes.isEmpty) {
        reportedBarcodes = prefs.getStringList('celiac_reported_barcodes') ?? [];
      }
      if (reportedBarcodes.isNotEmpty) {
        await db.collection("users").doc(newUid).set({
          'reportedBarcodes': FieldValue.arrayUnion(reportedBarcodes),
        }, SetOptions(merge: true));
      }

      // 4. Pulizia chiavi residue SharedPreferences se presenti
      await prefs.remove('celiac_history');
      await prefs.remove('celiac_reports');
      await prefs.remove('celiac_reported_barcodes');
    } catch (e) {
      debugPrint("Errore durante la migrazione: $e");
    }
  }

  /// Svuota completamente tutti i dati locali (SQLite per entità, SharedPreferences per settings).
  static Future<void> wipeAllLocalData(FirebaseAuth auth) async {
    try {
      // 1. Svuota tabelle SQLite
      await _productDao.deleteAllProducts();
      await _historyDao.wipeHistory('anonymous');
      await _reportDao.wipeReports('anonymous');
      await _syncMetadataDao.clearAll();

      final user = auth.currentUser;
      if (user != null) {
        await _historyDao.wipeHistory(user.uid);
        await _reportDao.wipeReports(user.uid);
      }

      // 2. Svuota SharedPreferences (settings e chiavi residue)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('celiac_settings');
      await prefs.remove(LocalCacheService.productsKey);
      await prefs.remove(LocalCacheService.lastSyncKey);
      await prefs.remove('celiac_history');
      await prefs.remove('celiac_reports');
      await prefs.remove('celiac_reported_barcodes');
      if (user != null) {
        await prefs.remove('celiac_history_${user.uid}');
        await prefs.remove('celiac_reports_${user.uid}');
      }
    } catch (e) {
      debugPrint("Errore durante il wipe dei dati locali: $e");
    }
  }

  static Future<void> wipeCurrentUserLocalData(FirebaseAuth auth) async {
    await wipeAllLocalData(auth);
  }

  // ─── ACCOUNT DELETION HELPERS ────────────────────────────────────────────────

  /// Elimina le impostazioni utente da Firestore.
  static Future<void> deleteUserSettings(FirebaseFirestore db, String uid) async {
    try {
      await db.collection('users').doc(uid).delete();
    } catch (e) {
      debugPrint('deleteUserSettings error: $e');
    }
  }

  /// Elimina tutta la cronologia scansioni dell'utente da Firestore.
  static Future<void> deleteUserHistory(FirebaseFirestore db, String uid) async {
    try {
      final snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('history')
          .get();
      const int chunkSize = 450;
      for (int i = 0; i < snapshot.docs.length; i += chunkSize) {
        final chunk = snapshot.docs.sublist(
          i,
          (i + chunkSize < snapshot.docs.length) ? i + chunkSize : snapshot.docs.length,
        );
        final batch = db.batch();
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('deleteUserHistory error: $e');
    }
  }

  /// Anonimizza tutte le segnalazioni dell'utente (rimuove userId e segna come anonymized).
  static Future<void> anonymizeUserReports(FirebaseFirestore db, String uid) async {
    try {
      final snapshot = await db
          .collection(reportsCollection)
          .where('userId', isEqualTo: uid)
          .get();
      if (snapshot.docs.isEmpty) return;
      const int chunkSize = 450;
      for (int i = 0; i < snapshot.docs.length; i += chunkSize) {
        final chunk = snapshot.docs.sublist(
          i,
          (i + chunkSize < snapshot.docs.length) ? i + chunkSize : snapshot.docs.length,
        );
        final batch = db.batch();
        for (final doc in chunk) {
          batch.update(doc.reference, {
            'userId': 'deleted',
            'anonymized': true,
          });
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('anonymizeUserReports error: $e');
    }
  }
}

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
import 'settings_db_service.dart';

/// Servizio responsabile della migrazione dei dati anonimi post-login
/// e della cancellazione/pulizia di tutti i dati locali.
class AccountDataService {
  static const ScanHistoryDao _historyDao = ScanHistoryDao();
  static const ProductReportDao _reportDao = ProductReportDao();
  static const ProductDao _productDao = ProductDao();
  static const SyncMetadataDao _syncMetadataDao = SyncMetadataDao();

  /// Chiave SharedPreferences per tracciare l'UID dell'ultimo utente anonimo.
  static const String lastAnonymousUidKey = 'last_anonymous_uid';

  /// Verifica se l'utente anonimo corrente è diverso dall'ultimo tracciato.
  /// Se sì, significa che è un NUOVO anonimo → i dati del precedente vanno cancellati.
  static Future<bool> isNewAnonymousSession(String currentAnonUid) async {
    final prefs = await SharedPreferences.getInstance();
    final lastUid = prefs.getString(lastAnonymousUidKey);
    return lastUid != null && lastUid != currentAnonUid;
  }

  /// Salva l'UID dell'utente anonimo corrente per rilevare transizioni future.
  static Future<void> trackAnonymousSession(String anonUid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastAnonymousUidKey, anonUid);
  }

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

  /// Verifica la presenza di impostazioni salvate/personalizzate in modalità anonima.
  static Future<bool> hasAnonymousSettings() =>
      SettingsDbService.hasAnonymousSettings();

  /// Verifica se esistono dati orfani o appartenenti a un utente anonimo
  /// (scansioni, segnalazioni, impostazioni).
  static Future<bool> hasAnonymousData() async {
    try {
      final history = await getLocalUnsyncedHistory();
      if (history.isNotEmpty) return true;

      final reports = await getLocalUnsyncedReports();
      if (reports.isNotEmpty) return true;

      final anonSettings = await hasAnonymousSettings();
      if (anonSettings) return true;

      return false;
    } catch (e) {
      debugPrint("Error checking anonymous data: $e");
      return false;
    }
  }

  /// Migra la cronologia, le segnalazioni e le impostazioni locali anonime su Firestore al momento dell'autenticazione.
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
        try {
          final historyBatch = db.batch();
          final historyRefBase = db.collection("users/$newUid/history");

          for (final item in localHistory) {
            final docRef = historyRefBase.doc(
              item.id.isNotEmpty ? item.id : historyRefBase.doc().id,
            );
            historyBatch.set(docRef, item.toJson());
          }
          await historyBatch.commit();
        } catch (e) {
          debugPrint("Failed committing history batch to Firestore: $e");
        }
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
        try {
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
        } catch (e) {
          debugPrint("Failed committing reports batch to Firestore: $e");
        }
        await _reportDao.reassignAnonymousReports(newUid);
      }

      // 3. REPORTED BARCODES
      var reportedBarcodes = await _reportDao.getReportedBarcodes(newUid);
      if (reportedBarcodes.isEmpty) {
        reportedBarcodes = prefs.getStringList('celiac_reported_barcodes') ?? [];
      }
      if (reportedBarcodes.isNotEmpty) {
        try {
          await db.collection("users").doc(newUid).set({
            'reportedBarcodes': FieldValue.arrayUnion(reportedBarcodes),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint("Failed merging reported barcodes to Firestore: $e");
        }
      }

      // 4. MIGRAZIONE IMPOSTAZIONI
      final localSettings = await SettingsDbService.getLocalSettings();
      final updatedSettings = UserSettings(
        userId: newUid,
        strictMode: localSettings.strictMode,
        alertLactose: localSettings.alertLactose,
        warnAdditives: localSettings.warnAdditives,
        autoSaveHistory: localSettings.autoSaveHistory,
        preferredLanguage: localSettings.preferredLanguage,
        preferredTheme: localSettings.preferredTheme,
        reportedBarcodes: localSettings.reportedBarcodes,
      );
      await SettingsDbService.saveLocalSettings(updatedSettings);
      try {
        await db.collection("users").doc(newUid).set(
          updatedSettings.toJson(),
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint("Failed saving migrated settings to Firestore: $e");
      }

      // 5. Pulizia chiavi residue SharedPreferences e tabelle SQLite anonime
      await prefs.remove('celiac_history');
      await prefs.remove('celiac_reports');
      await prefs.remove('celiac_reported_barcodes');
      await prefs.remove(SettingsDbService.hasAnonymousSettingsKey);
      await prefs.remove(lastAnonymousUidKey);
      await _historyDao.wipeHistory('anonymous');
      await _reportDao.wipeReports('anonymous');
    } catch (e) {
      debugPrint("Errore durante la migrazione: $e");
    }
  }

  /// Svuota unicamente i dati appartenenti all'utente anonimo (scartati alla schermata sincro).
  static Future<void> wipeAnonymousData() async {
    try {
      await _historyDao.wipeHistory('anonymous');
      await _reportDao.wipeReports('anonymous');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('celiac_history');
      await prefs.remove('celiac_reports');
      await prefs.remove('celiac_reported_barcodes');
      await prefs.remove(SettingsDbService.hasAnonymousSettingsKey);
      await prefs.remove(lastAnonymousUidKey);

      final currentSettings = await SettingsDbService.getLocalSettings();
      if (currentSettings.userId == 'anonymous' || currentSettings.userId == null) {
        await prefs.remove(SettingsDbService.settingsKey);
      }
    } catch (e) {
      debugPrint("Errore durante il wipe dei dati anonimi: $e");
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
      await prefs.remove(SettingsDbService.settingsKey);
      await prefs.remove(SettingsDbService.hasAnonymousSettingsKey);
      await prefs.remove(lastAnonymousUidKey);
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

  /// Svuota i dati locali dell'utente (utilizzato anche in cancellazione account).
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

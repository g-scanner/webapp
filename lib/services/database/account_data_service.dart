// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';
import 'daos/scan_history_dao.dart';
import 'daos/product_report_dao.dart';
import 'history_db_service.dart';
import 'reports_db_service.dart';
import 'settings_db_service.dart';
import 'offline_db_sync_service.dart';

/// Servizio responsabile della migrazione dei dati anonimi post-login
/// e della cancellazione/pulizia di tutti i dati locali.
class AccountDataService {
  static const ScanHistoryDao _historyDao = ScanHistoryDao();
  static const ProductReportDao _reportDao = ProductReportDao();

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
  static Future<List<ScanHistoryItem>> getLocalUnsyncedHistory([
    String? anonUid,
  ]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final targetUid = anonUid ?? prefs.getString(lastAnonymousUidKey);
      if (targetUid != null && targetUid.isNotEmpty) {
        return await _historyDao.getHistory(targetUid);
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching unsynced history: $e");
      return [];
    }
  }

  /// Recupera le segnalazioni create in modalità anonima.
  static Future<List<ProductReport>> getLocalUnsyncedReports([
    String? anonUid,
  ]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final targetUid = anonUid ?? prefs.getString(lastAnonymousUidKey);
      if (targetUid != null && targetUid.isNotEmpty) {
        return await _reportDao.getUserReports(targetUid);
      }
      return [];
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

  /// Recupera il riepilogo dei dati anonimi non ancora sincronizzati (se presenti).
  static Future<AnonymousDataSummary?> getPendingAnonymousSyncData([
    String? anonUid,
  ]) async {
    try {
      final history = await getLocalUnsyncedHistory(anonUid);
      final reports = await getLocalUnsyncedReports(anonUid);
      final hasSettings = await hasAnonymousSettings();
      if (history.isNotEmpty || reports.isNotEmpty || hasSettings) {
        return AnonymousDataSummary(
          history: history,
          reports: reports,
          hasSettings: hasSettings,
        );
      }
      return null;
    } catch (e) {
      debugPrint("Error checking pending anonymous sync data: $e");
      return null;
    }
  }

  /// Migra e riassegna le segnalazioni e i relativi barcode segnalati,
  /// aggiornando la proprietà del report su Firestore e riallineando la persistenza SQLite.
  static Future<void> _migrateReports(
    FirebaseFirestore db,
    String fromUid,
    String toUid,
  ) async {
    final localReports = await _reportDao.getUserReports(fromUid);
    if (localReports.isNotEmpty) {
      // 1. Riassegna SUBITO in SQLite per garantire disponibilità locale
      await _reportDao.reassignReports(fromUid, toUid);

      // 2. Traccia gli ID come pendenti per il nuovo utente
      final newReportIds = localReports.map((e) => e.id).toList();
      for (final id in newReportIds) {
        await ReportsDbService.markReportPending(toUid, id);
      }

      try {
        final reportsBatch = db.batch();
        for (final report in localReports) {
          final docRef = db
              .collection(reportsCollection)
              .doc(
                report.id.isNotEmpty
                    ? report.id
                    : db.collection(reportsCollection).doc().id,
              );
          final rMap = report.toJson();
          rMap['userId'] = toUid;
          reportsBatch.set(docRef, rMap, SetOptions(merge: true));
        }
        await reportsBatch.commit().timeout(const Duration(seconds: 3));
        await ReportsDbService.markReportsSynced(toUid, newReportIds);
      } catch (e) {
        debugPrint("Failed committing reports batch to Firestore: $e");
      }
    }

    final reportedBarcodes = await _reportDao.getReportedBarcodes(toUid);
    if (reportedBarcodes.isNotEmpty) {
      try {
        await db.collection("users").doc(toUid).set({
          'reportedBarcodes': FieldValue.arrayUnion(reportedBarcodes),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint("Failed merging reported barcodes to Firestore: $e");
      }
    }
  }

  /// Migra la cronologia, le segnalazioni e le impostazioni locali anonime su Firestore al momento dell'autenticazione.
  /// Rispetta la scelta granulare dell'utente per ciascuna categoria.
  static Future<void> migrateLocalDataToFirestore(
    FirebaseFirestore db,
    String newUid, {
    bool syncHistory = true,
    bool syncReports = true,
    bool syncSettings = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAnonUid = prefs.getString(lastAnonymousUidKey);
      if (lastAnonUid == null || lastAnonUid.isEmpty) return;

      // 1. MIGRAZIONE CRONOLOGIA
      if (syncHistory) {
        final localHistory = await _historyDao.getHistory(lastAnonUid);
        if (localHistory.isNotEmpty) {
          // 1. Riassegna SUBITO in SQLite per garantire disponibilità locale
          await _historyDao.reassignHistory(lastAnonUid, newUid);

          // 2. Traccia gli ID come pendenti per il nuovo utente
          final newHistoryIds = localHistory.map((e) => e.id).toList();
          for (final id in newHistoryIds) {
            await HistoryDbService.markHistoryPending(newUid, id);
          }

          try {
            final historyBatch = db.batch();
            final historyRefBase = db.collection("users/$newUid/history");

            for (final item in localHistory) {
              final docRef = historyRefBase.doc(
                item.id.isNotEmpty ? item.id : historyRefBase.doc().id,
              );
              historyBatch.set(docRef, item.toJson());
            }
            await historyBatch.commit().timeout(const Duration(seconds: 3));
            await HistoryDbService.markHistorySynced(newUid, newHistoryIds);
          } catch (e) {
            debugPrint("Failed committing history batch to Firestore: $e");
          }
        }
      }

      // 2. MIGRAZIONE SEGNALAZIONI (LOCALE + FIRESTORE)
      if (syncReports) {
        await _migrateReports(db, lastAnonUid, newUid);
      }

      // 3. MIGRAZIONE IMPOSTAZIONI
      if (syncSettings) {
        final localSettings = await SettingsDbService.getLocalSettings();
        if (localSettings.userId == lastAnonUid) {
          final updatedSettings = localSettings.copyWith(
            userId: newUid,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
          await SettingsDbService.saveLocalSettings(updatedSettings);
          try {
            final jsonData = updatedSettings.toJson();
            if (!updatedSettings.offlineDbCloudSync) {
              jsonData['offlineDbTier'] = FieldValue.delete();
              jsonData['offlineDbLastSyncedAt'] = FieldValue.delete();
              jsonData['offlineDbAutoSync'] = FieldValue.delete();
              jsonData['offlineDbWifiOnly'] = FieldValue.delete();
            }
            await db
                .collection("users")
                .doc(newUid)
                .set(jsonData, SetOptions(merge: true))
                .timeout(const Duration(seconds: 3));
          } catch (e) {
            debugPrint("Failed saving migrated settings to Firestore: $e");
          }
        }
      } else {
        // Se non vuole migrare le impostazioni anonime, rimuove le impostazioni locali
        final currentSettings = await SettingsDbService.getLocalSettings();
        if (currentSettings.userId == lastAnonUid) {
          await prefs.remove(SettingsDbService.settingsKey);
        }
      }

      // 4. Pulizia chiavi e dati dell'utente anonimo
      await prefs.remove(SettingsDbService.hasAnonymousSettingsKey);
      await prefs.remove(lastAnonymousUidKey);
      await _historyDao.wipeHistory(lastAnonUid);
      await _reportDao.wipeReports(lastAnonUid);
    } catch (e) {
      debugPrint("Errore durante la migrazione: $e");
    }
  }

  /// Migra la cronologia e le impostazioni (in locale) e le segnalazioni (in locale e su Firestore)
  /// da una sessione anonima precedente alla nuova sessione anonima corrente.
  static Future<void> migrateAnonymousDataToNewAnonymous(
    FirebaseFirestore db,
    String newAnonUid, {
    bool syncHistory = true,
    bool syncReports = true,
    bool syncSettings = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAnonUid = prefs.getString(lastAnonymousUidKey);
      if (lastAnonUid == null || lastAnonUid.isEmpty) return;

      // 1. MIGRAZIONE CRONOLOGIA (LOCALE IN SQLITE)
      if (syncHistory) {
        await _historyDao.reassignHistory(lastAnonUid, newAnonUid);
      }

      // 2. MIGRAZIONE SEGNALAZIONI (LOCALE IN SQLITE + AGGIORNAMENTO FIRESTORE)
      if (syncReports) {
        await _migrateReports(db, lastAnonUid, newAnonUid);
      }

      // 3. MIGRAZIONE IMPOSTAZIONI (LOCALE IN SHAREDPREFERENCES)
      if (syncSettings) {
        final localSettings = await SettingsDbService.getLocalSettings();
        if (localSettings.userId == lastAnonUid) {
          final updatedSettings = localSettings.copyWith(
            userId: newAnonUid,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
          await SettingsDbService.saveLocalSettings(updatedSettings);
        }
      } else {
        final currentSettings = await SettingsDbService.getLocalSettings();
        if (currentSettings.userId == lastAnonUid) {
          await prefs.remove(SettingsDbService.settingsKey);
        }
      }

      // 4. Pulizia chiavi e dati del vecchio utente anonimo
      await prefs.remove(SettingsDbService.hasAnonymousSettingsKey);
      await _historyDao.wipeHistory(lastAnonUid);
      await _reportDao.wipeReports(lastAnonUid);
      await prefs.setString(lastAnonymousUidKey, newAnonUid);
    } catch (e) {
      debugPrint("Errore durante la migrazione anonimo -> anonimo: $e");
    }
  }

  /// Svuota unicamente i dati appartenenti all'utente anonimo (scartati alla schermata sincro).
  static Future<void> wipeAnonymousData([String? anonUid]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUid = anonUid ?? prefs.getString(lastAnonymousUidKey);
      if (lastUid != null && lastUid.isNotEmpty) {
        await _historyDao.wipeHistory(lastUid);
        await _reportDao.wipeReports(lastUid);
        final currentSettings = await SettingsDbService.getLocalSettings();
        if (currentSettings.userId == lastUid) {
          await prefs.remove(SettingsDbService.settingsKey);
        }
        await prefs.remove(HistoryDbService.getPendingHistoryKey(lastUid));
        await prefs.remove(ReportsDbService.getPendingReportsKey(lastUid));
      }

      await prefs.remove(SettingsDbService.hasAnonymousSettingsKey);
      await prefs.remove(lastAnonymousUidKey);
    } catch (e) {
      debugPrint("Errore durante il wipe dei dati anonimi: $e");
    }
  }

  /// Svuota i dati personali dell'utente (cronologia, segnalazioni, impostazioni)
  /// preservando la cache locale dei prodotti e dei metadati (riutilizzabili dai successivi utenti).
  /// Per gli utenti anonimi, preserva i dati al logout per consentire la sincronizzazione nella sessione successiva.
  static Future<void> wipeCurrentUserLocalData(
    FirebaseAuth auth, {
    String? explicitUserId,
  }) async {
    try {
      OfflineDbSyncService.cancelSync();

      final user = auth.currentUser;
      final targetUid = explicitUserId ?? user?.uid;
      final prefs = await SharedPreferences.getInstance();

      // Se l'utente è anonimo e stiamo eseguendo un normale logout (explicitUserId == null),
      // NON cancelliamo i suoi dati personali per permettere alla schermata di sync
      // di proporli alla sessione successiva (anonima o registrata).
      if (user != null && user.isAnonymous && explicitUserId == null) {
        return;
      }

      if (targetUid != null && targetUid.isNotEmpty && !(user?.isAnonymous ?? false)) {
        await _historyDao.wipeHistory(targetUid);
        await _reportDao.wipeReports(targetUid);
        await prefs.remove('celiac_history_$targetUid');
        await prefs.remove('celiac_reports_$targetUid');
        await prefs.remove(SettingsDbService.settingsKey);
        await prefs.remove(HistoryDbService.getPendingHistoryKey(targetUid));
        await prefs.remove(ReportsDbService.getPendingReportsKey(targetUid));
        await prefs.remove(ReportsDbService.getPendingVotesKey(targetUid));
        await prefs.remove(ReportsDbService.getLocalVotesKey(targetUid));
      }

      // Svuota chiavi generiche
      await prefs.remove('celiac_history');
      await prefs.remove('celiac_reports');
    } catch (e) {
      debugPrint("Errore durante il wipe dei dati utente: $e");
    }
  }

  // ─── ACCOUNT DELETION HELPERS ────────────────────────────────────────────────

  /// Elimina le impostazioni utente da Firestore.
  static Future<void> deleteUserSettings(
    FirebaseFirestore db,
    String uid,
  ) async {
    try {
      await db.collection('users').doc(uid).delete();
    } catch (e) {
      debugPrint('deleteUserSettings error: $e');
    }
  }

  /// Elimina tutta la cronologia scansioni dell'utente da Firestore.
  static Future<void> deleteUserHistory(
    FirebaseFirestore db,
    String uid,
  ) async {
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
          (i + chunkSize < snapshot.docs.length)
              ? i + chunkSize
              : snapshot.docs.length,
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
  static Future<void> anonymizeUserReports(
    FirebaseFirestore db,
    String uid,
  ) async {
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
          (i + chunkSize < snapshot.docs.length)
              ? i + chunkSize
              : snapshot.docs.length,
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

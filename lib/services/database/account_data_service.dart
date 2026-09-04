// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';
import 'local_cache_service.dart';
import 'reports_db_service.dart' show reportsCollection;

class AccountDataService {
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

  static Future<void> migrateLocalDataToFirestore(
    FirebaseFirestore db,
    String newUid,
  ) async {
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
      debugPrint("Errore durante la migrazione: $e");
    }
  }

  static Future<void> wipeAllLocalData(FirebaseAuth auth) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('celiac_history');
      await prefs.remove('celiac_reports');
      await prefs.remove('celiac_reported_barcodes');
      await prefs.remove('celiac_settings');
      await prefs.remove(LocalCacheService.productsKey);
      await prefs.remove(LocalCacheService.lastSyncKey);

      final user = auth.currentUser;
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
      // Chunked delete: Firestore WriteBatch max 500 ops — use 450 for safety margin
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
      // Chunked update: Firestore WriteBatch max 500 ops — use 450 for safety margin
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

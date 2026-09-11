// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';
import 'daos/scan_history_dao.dart';

/// Servizio per la gestione della cronologia delle scansioni.
/// Utilizza SQLite (sqflite) per paginazione nativa e zero caricamenti massivi in RAM.
class HistoryDbService {
  static const ScanHistoryDao _historyDao = ScanHistoryDao();

  /// Identificatore logico dell'utente per il partizionamento della cronologia.
  static String getUserId(FirebaseAuth auth) {
    final user = auth.currentUser;
    if (user != null && !user.isAnonymous) {
      return user.uid;
    }
    return 'anonymous';
  }

  /// Mantiene compatibilità di interfaccia per eventuali test o chiamate storiche.
  static String getHistoryKey(FirebaseAuth auth) {
    final user = auth.currentUser;
    if (user != null && !user.isAnonymous) {
      return 'celiac_history_${user.uid}';
    }
    return 'celiac_history';
  }

  /// Salva una nuova voce di cronologia nel database locale SQLite e, se autenticato, su Firestore.
  static Future<void> saveHistoryItem(
    FirebaseFirestore db,
    FirebaseAuth auth,
    Product product,
  ) async {
    final user = auth.currentUser;
    final userId = getUserId(auth);
    final now = DateTime.now();

    try {
      // Evita duplicati ravvicinati (< 10s) per lo stesso barcode direttamente via SQL
      final isDuplicate = await _historyDao.hasRecentScan(userId, product.barcode);
      if (isDuplicate) return;

      final id = user != null && !user.isAnonymous
          ? db.collection("users/${user.uid}/history").doc().id
          : now.millisecondsSinceEpoch.toString();

      final historyItem = ScanHistoryItem(
        id: id,
        barcode: product.barcode,
        scannedAt: now.toIso8601String(),
      );

      await _historyDao.insertHistoryItem(userId, historyItem);

      if (user != null && !user.isAnonymous) {
        await db
            .collection("users/${user.uid}/history")
            .doc(id)
            .set(historyItem.toJson());
      }
    } catch (e) {
      debugPrint("Failed saving history item to SQLite: $e");
    }
  }

  /// Recupera tutta la cronologia dell'utente corrente.
  static Future<List<ScanHistoryItem>> getHistory(FirebaseAuth auth) async {
    try {
      final userId = getUserId(auth);
      final fromDb = await _historyDao.getHistory(userId);
      if (fromDb.isNotEmpty) return fromDb;

      final key = getHistoryKey(auth);
      final prefs = await SharedPreferences.getInstance();
      final histStr = prefs.getStringList(key) ?? [];
      final List<ScanHistoryItem> result = [];
      for (final e in histStr) {
        try {
          final decoded = json.decode(e);
          if (decoded is Map<String, dynamic>) {
            result.add(ScanHistoryItem.fromJson(decoded));
          }
        } catch (_) {}
      }
      return result;
    } catch (e) {
      debugPrint("Failed fetching local history from SQLite: $e");
      return [];
    }
  }

  /// Paginazione Locale della Cronologia (Pilastro 3 & 8)
  /// Esegue una query SQL nativa `LIMIT / OFFSET` senza caricare tutta la lista in memoria.
  static Future<List<ScanHistoryItem>> getHistoryPaged(
    FirebaseAuth auth, {
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final userId = getUserId(auth);
      final fromDb = await _historyDao.getHistoryPaged(
        userId,
        offset: offset,
        limit: limit,
      );
      if (fromDb.isNotEmpty) return fromDb;

      final fullHistory = await getHistory(auth);
      if (offset >= fullHistory.length) return [];
      final end = (offset + limit < fullHistory.length) ? offset + limit : fullHistory.length;
      return fullHistory.sublist(offset, end);
    } catch (e) {
      debugPrint("Failed fetching paged history from SQLite: $e");
      return [];
    }
  }

  /// Sincronizza la cronologia locale con Firestore per utenti autenticati.
  static Future<List<ScanHistoryItem>> syncHistoryWithFirestore(
    FirebaseFirestore db,
    FirebaseAuth auth,
  ) async {
    final user = auth.currentUser;
    if (user == null || user.isAnonymous) {
      return getHistory(auth);
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

      await _historyDao.setHistory(user.uid, remoteHistory);
      return remoteHistory;
    } catch (e) {
      debugPrint("Failed syncing Firestore history: $e");
      return getHistory(auth);
    }
  }

  /// Svuota completamente la cronologia sia da SQLite sia da Firestore.
  static Future<void> wipeHistoryLocal(
    FirebaseFirestore db,
    FirebaseAuth auth,
  ) async {
    final user = auth.currentUser;
    final userId = getUserId(auth);
    final key = getHistoryKey(auth);

    try {
      await _historyDao.wipeHistory(userId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      await prefs.setStringList(key, []);

      if (user != null && !user.isAnonymous) {
        final q = await db.collection("users/${user.uid}/history").get();
        // Chunked delete: Firestore WriteBatch max 500 ops — use 450 for safety margin
        const int chunkSize = 450;
        for (int i = 0; i < q.docs.length; i += chunkSize) {
          final chunk = q.docs.sublist(
            i,
            (i + chunkSize < q.docs.length) ? i + chunkSize : q.docs.length,
          );
          final batch = db.batch();
          for (var d in chunk) {
            batch.delete(d.reference);
          }
          await batch.commit();
        }
      }
    } catch (e) {
      debugPrint("Could not wipe history: $e");
    }
  }

  /// Elimina dalla cronologia locale e da Firestore le voci per un determinato barcode.
  static Future<void> deleteHistoryByBarcodeLocal(
    FirebaseFirestore db,
    FirebaseAuth auth,
    String barcode,
  ) async {
    final user = auth.currentUser;
    final userId = getUserId(auth);
    final key = getHistoryKey(auth);

    try {
      await _historyDao.deleteHistoryByBarcode(userId, barcode);

      final prefs = await SharedPreferences.getInstance();
      final histStr = prefs.getStringList(key) ?? [];
      if (histStr.isNotEmpty) {
        final localHist = histStr
            .map((e) => json.decode(e) as Map<String, dynamic>)
            .where((item) => item['barcode'] != barcode)
            .map((e) => json.encode(e))
            .toList();
        await prefs.setStringList(key, localHist);
      }

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
      debugPrint("Could not delete history items by barcode: $e");
    }
  }

  /// Elimina una singola voce di cronologia per ID.
  static Future<void> deleteHistoryItemLocal(
    FirebaseFirestore db,
    FirebaseAuth auth,
    String id,
  ) async {
    final user = auth.currentUser;
    final userId = getUserId(auth);
    final key = getHistoryKey(auth);

    try {
      await _historyDao.deleteHistoryItem(userId, id);

      final prefs = await SharedPreferences.getInstance();
      final histStr = prefs.getStringList(key) ?? [];
      if (histStr.isNotEmpty) {
        final localHist = histStr
            .map((e) => json.decode(e) as Map<String, dynamic>)
            .where((item) => item['id'] != id)
            .map((e) => json.encode(e))
            .toList();
        await prefs.setStringList(key, localHist);
      }

      if (user != null && !user.isAnonymous) {
        await db.collection("users/${user.uid}/history").doc(id).delete();
      }
    } catch (e) {
      debugPrint("Could not delete history item: $e");
    }
  }
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';

class HistoryDbService {
  static String getHistoryKey(FirebaseAuth auth) {
    final user = auth.currentUser;
    if (user != null && !user.isAnonymous) {
      return 'celiac_history_${user.uid}';
    }
    return 'celiac_history';
  }

  static Future<void> saveHistoryItem(
    FirebaseFirestore db,
    FirebaseAuth auth,
    Product product,
  ) async {
    final user = auth.currentUser;
    final now = DateTime.now();
    final key = getHistoryKey(auth);

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
      debugPrint("Failed saving history item: $e");
    }
  }

  static Future<List<ScanHistoryItem>> getHistory(FirebaseAuth auth) async {
    try {
      final key = getHistoryKey(auth);
      final prefs = await SharedPreferences.getInstance();
      List<String> histStr = prefs.getStringList(key) ?? [];
      final List<ScanHistoryItem> result = [];
      for (final e in histStr) {
        try {
          final decoded = json.decode(e);
          if (decoded is Map<String, dynamic>) {
            result.add(ScanHistoryItem.fromJson(decoded));
          }
        } catch (err) {
          debugPrint("Failed decoding single history item: $err");
        }
      }
      return result;
    } catch (e) {
      debugPrint("Failed fetching local history: $e");
      return [];
    }
  }

  /// Paginazione Locale della Cronologia (Pilastro 3 & 8)
  static Future<List<ScanHistoryItem>> getHistoryPaged(
    FirebaseAuth auth, {
    int offset = 0,
    int limit = 20,
  }) async {
    final fullHistory = await getHistory(auth);
    if (offset >= fullHistory.length) return [];
    final end = (offset + limit < fullHistory.length) ? offset + limit : fullHistory.length;
    return fullHistory.sublist(offset, end);
  }

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

      final key = getHistoryKey(auth);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        key,
        remoteHistory.map((e) => json.encode(e.toJson())).toList(),
      );
      return remoteHistory;
    } catch (e) {
      debugPrint("Failed syncing Firestore history: $e");
      return getHistory(auth);
    }
  }

  static Future<void> wipeHistoryLocal(
    FirebaseFirestore db,
    FirebaseAuth auth,
  ) async {
    final user = auth.currentUser;
    final key = getHistoryKey(auth);

    try {
      final prefs = await SharedPreferences.getInstance();
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

  static Future<void> deleteHistoryByBarcodeLocal(
    FirebaseFirestore db,
    FirebaseAuth auth,
    String barcode,
  ) async {
    final user = auth.currentUser;
    final key = getHistoryKey(auth);

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
      debugPrint("Could not delete history items by barcode: $e");
    }
  }

  static Future<void> deleteHistoryItemLocal(
    FirebaseFirestore db,
    FirebaseAuth auth,
    String id,
  ) async {
    final user = auth.currentUser;
    final key = getHistoryKey(auth);

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
      debugPrint("Could not delete history item: $e");
    }
  }
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';
import 'daos/scan_history_dao.dart';
import 'background_sync_manager.dart';

/// Servizio per la gestione della cronologia delle scansioni.
/// Utilizza SQLite (sqflite) per paginazione nativa e zero caricamenti massivi in RAM.
class HistoryDbService {
  static const ScanHistoryDao _historyDao = ScanHistoryDao();

  /// Identificatore logico dell'utente per il partizionamento della cronologia.
  static String getUserId(FirebaseAuth auth) {
    final user = auth.currentUser;
    if (user != null) {
      return user.uid;
    }
    return 'anonymous';
  }

  /// Mantiene compatibilità di interfaccia per eventuali test o chiamate storiche.
  static String getHistoryKey(FirebaseAuth auth) {
    final user = auth.currentUser;
    if (user != null) {
      return 'celiac_history_${user.uid}';
    }
    return 'celiac_history';
  }

  static const String pendingHistoryPrefix = 'pending_history_ids_';

  /// Restituisce la chiave SharedPreferences per gli ID di cronologia in attesa di sync.
  static String getPendingHistoryKey(String uid) => '$pendingHistoryPrefix$uid';

  /// Recupera gli ID delle voci di cronologia salvate localmente e non ancora sincronizzate su Firestore.
  static Future<List<String>> getPendingHistoryIds(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(getPendingHistoryKey(uid)) ?? [];
  }

  /// Contrassegna una voce di cronologia come pendente (creata offline o non ancora sincronizzata).
  static Future<void> markHistoryPending(String uid, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = getPendingHistoryKey(uid);
    final current = prefs.getStringList(key) ?? [];
    if (!current.contains(id)) {
      await prefs.setStringList(key, [...current, id]);
    }
    await BackgroundSyncManager.schedulePendingDataSyncIfNeeded();
  }

  /// Rimuove gli ID specificati dalla lista dei pendenti (sincronizzati con successo o eliminati).
  static Future<void> markHistorySynced(String uid, List<String> ids) async {
    if (ids.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = getPendingHistoryKey(uid);
    final current = prefs.getStringList(key) ?? [];
    final idSet = ids.toSet();
    final updated = current.where((id) => !idSet.contains(id)).toList();
    await prefs.setStringList(key, updated);
    await BackgroundSyncManager.schedulePendingDataSyncIfNeeded();
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

      final id = user != null
          ? db.collection("users/${user.uid}/history").doc().id
          : now.millisecondsSinceEpoch.toString();

      final historyItem = ScanHistoryItem(
        id: id,
        barcode: product.barcode,
        scannedAt: now.toIso8601String(),
      );

      await _historyDao.insertHistoryItem(userId, historyItem);

      if (user != null && !user.isAnonymous) {
        await markHistoryPending(user.uid, id);
        try {
          db
              .collection("users/${user.uid}/history")
              .doc(id)
              .set(historyItem.toJson())
              .then((_) async {
            await markHistorySynced(user.uid, [id]);
          }).catchError((e) {
            debugPrint("Failed saving history item to Firestore: $e");
          });
        } catch (e) {
          debugPrint("Failed initiating history save to Firestore: $e");
        }
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

  /// Restituisce il conteggio degli elementi nella cronologia dell'utente corrente.
  static Future<int> getHistoryCount(FirebaseAuth auth) async {
    try {
      final userId = getUserId(auth);
      return await _historyDao.getHistoryCount(userId);
    } catch (e) {
      debugPrint("Failed getting history count from SQLite: $e");
      return 0;
    }
  }

  /// Restituisce la stima dei byte occupati dalla cronologia dell'utente corrente.
  static Future<int> getHistorySizeBytes(FirebaseAuth auth) async {
    try {
      final userId = getUserId(auth);
      return await _historyDao.getHistorySizeBytes(userId);
    } catch (e) {
      debugPrint("Failed getting history size from SQLite: $e");
      return 0;
    }
  }

  /// Sincronizza la cronologia locale con Firestore per utenti autenticati.
  /// Esegue un merge bidirezionale Push-then-Pull: carica le scansioni locali effettuate offline
  /// e scarica le ultime scansioni remote, filtrando i tombstone ed evitando resurrezioni.
  static Future<List<ScanHistoryItem>> syncHistoryWithFirestore(
    FirebaseFirestore db,
    FirebaseAuth auth,
  ) async {
    final user = auth.currentUser;
    if (user == null || user.isAnonymous) {
      return getHistory(auth);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isWipePending = prefs.getBool('history_wipe_pending') ?? false;
      if (isWipePending) {
        _deleteFirestoreHistory(db, user.uid).then((_) async {
          final p = await SharedPreferences.getInstance();
          await p.remove('history_wipe_pending');
        }).catchError((e) {
          debugPrint("Failed wiping Firestore history on reconnect: $e");
        });
        await _historyDao.wipeHistory(user.uid);
        await prefs.remove(getPendingHistoryKey(user.uid));
        return [];
      }

      final deletedBarcodes =
          prefs.getStringList('deleted_barcodes_sync_filter')?.toSet() ?? {};
      final deletedIds =
          prefs.getStringList('deleted_history_ids_sync_filter')?.toSet() ?? {};

      final snap = await db
          .collection("users/${user.uid}/history")
          .orderBy("scannedAt", descending: true)
          .limit(100)
          .get()
          .timeout(const Duration(seconds: 4));

      final List<ScanHistoryItem> remoteHistory = [];
      final Set<String> remoteDocIds = {};
      for (final doc in snap.docs) {
        final item = ScanHistoryItem.fromJson(doc.data());
        if (deletedBarcodes.contains(item.barcode) || deletedIds.contains(item.id)) {
          // Elimina definitivamente la voce fantasma da Firestore
          doc.reference.delete().catchError((_) => null);
        } else {
          remoteHistory.add(item);
          remoteDocIds.add(item.id);
        }
      }

      // ── Gestione elementi locali salvati offline (Pending Sync) ──
      final pendingIds = (await getPendingHistoryIds(user.uid)).toSet();
      final alreadySynced = pendingIds.intersection(remoteDocIds);
      if (alreadySynced.isNotEmpty) {
        await markHistorySynced(user.uid, alreadySynced.toList());
        pendingIds.removeAll(alreadySynced);
      }

      if (pendingIds.isNotEmpty) {
        final localHistory = await _historyDao.getHistory(user.uid);
        final itemsToUpload = localHistory
            .where((item) =>
                pendingIds.contains(item.id) &&
                !deletedBarcodes.contains(item.barcode) &&
                !deletedIds.contains(item.id))
            .toList();

        if (itemsToUpload.isNotEmpty) {
          try {
            final batch = db.batch();
            final historyRefBase = db.collection("users/${user.uid}/history");
            for (final item in itemsToUpload) {
              final docRef = historyRefBase.doc(item.id);
              batch.set(docRef, item.toJson());
            }
            await batch.commit().timeout(const Duration(seconds: 4));
            final uploadedIds = itemsToUpload.map((e) => e.id).toList();
            await markHistorySynced(user.uid, uploadedIds);
            for (final item in itemsToUpload) {
              remoteHistory.add(item);
            }
          } catch (e) {
            debugPrint("Failed uploading pending local history to Firestore: $e");
            for (final item in itemsToUpload) {
              remoteHistory.add(item);
            }
          }
        }
      }

      remoteHistory.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));

      await _historyDao.setHistory(user.uid, remoteHistory);
      return remoteHistory;
    } catch (e) {
      debugPrint("Failed syncing Firestore history: $e");
      return getHistory(auth);
    }
  }

  /// Elimina tutti i documenti della cronologia su Firestore a blocchi (batch).
  static Future<void> _deleteFirestoreHistory(
    FirebaseFirestore db,
    String uid,
  ) async {
    final q = await db
        .collection("users/$uid/history")
        .get()
        .timeout(const Duration(seconds: 4));
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
      await batch.commit().timeout(const Duration(seconds: 4));
    }
  }

  /// Svuota completamente la cronologia sia da SQLite sia da Firestore in modo ottimistico.
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
      await prefs.remove('deleted_barcodes_sync_filter');
      await prefs.remove('deleted_history_ids_sync_filter');
      await prefs.remove(getPendingHistoryKey(userId));

      if (user != null && !user.isAnonymous) {
        await prefs.setBool('history_wipe_pending', true);
        _deleteFirestoreHistory(db, user.uid).then((_) async {
          final p = await SharedPreferences.getInstance();
          await p.remove('history_wipe_pending');
        }).catchError((e) {
          debugPrint("Firestore wipe warning: $e");
        });
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
      if (user != null && !user.isAnonymous) {
        final items = await _historyDao.getHistoryByBarcode(userId, barcode);
        await markHistorySynced(user.uid, items.map((e) => e.id).toList());
      }

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

      // Registra nel filtro dei barcode cancellati per evitare resurrezione su sync
      final deletedFilter =
          prefs.getStringList('deleted_barcodes_sync_filter') ?? [];
      if (!deletedFilter.contains(barcode)) {
        deletedFilter.add(barcode);
        if (deletedFilter.length > 100) deletedFilter.removeAt(0);
        await prefs.setStringList(
          'deleted_barcodes_sync_filter',
          deletedFilter,
        );
        await BackgroundSyncManager.schedulePendingDataSyncIfNeeded();
      }

      if (user != null && !user.isAnonymous) {
        db
            .collection("users/${user.uid}/history")
            .where("barcode", isEqualTo: barcode)
            .get()
            .then((snapshot) {
          final batch = db.batch();
          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          return batch.commit();
        }).catchError((e) {
          debugPrint("Firestore delete history warning: $e");
        });
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
      if (user != null && !user.isAnonymous) {
        await markHistorySynced(user.uid, [id]);
      }

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

      // Registra nel filtro degli ID cancellati per evitare resurrezione su sync
      final deletedFilter =
          prefs.getStringList('deleted_history_ids_sync_filter') ?? [];
      if (!deletedFilter.contains(id)) {
        deletedFilter.add(id);
        if (deletedFilter.length > 100) deletedFilter.removeAt(0);
        await prefs.setStringList(
          'deleted_history_ids_sync_filter',
          deletedFilter,
        );
        await BackgroundSyncManager.schedulePendingDataSyncIfNeeded();
      }

      if (user != null && !user.isAnonymous) {
        db
            .collection("users/${user.uid}/history")
            .doc(id)
            .delete()
            .catchError((e) {
          debugPrint("Firestore delete history item warning: $e");
        });
      }
    } catch (e) {
      debugPrint("Could not delete history item: $e");
    }
  }
}

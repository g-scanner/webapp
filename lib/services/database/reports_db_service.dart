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
    if (user != null) {
      return user.uid;
    }
    return 'anonymous';
  }

  /// Mantiene compatibilità di interfaccia per eventuali test o chiamate storiche.
  static String getReportsKey(FirebaseAuth auth) {
    final user = auth.currentUser;
    if (user != null) {
      return 'celiac_reports_${user.uid}';
    }
    return 'celiac_reports';
  }

  static const String pendingReportsPrefix = 'pending_reports_ids_';

  /// Restituisce la chiave SharedPreferences per gli ID delle segnalazioni in attesa di sync.
  static String getPendingReportsKey(String uid) => '$pendingReportsPrefix$uid';

  /// Recupera gli ID delle segnalazioni salvate localmente e non ancora sincronizzate su Firestore.
  static Future<List<String>> getPendingReportsIds(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(getPendingReportsKey(uid)) ?? [];
  }

  /// Contrassegna una segnalazione come pendente (creata offline o non ancora sincronizzata).
  static Future<void> markReportPending(String uid, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = getPendingReportsKey(uid);
    final current = prefs.getStringList(key) ?? [];
    if (!current.contains(id)) {
      await prefs.setStringList(key, [...current, id]);
    }
  }

  /// Rimuove gli ID specificati dalla lista delle segnalazioni pendenti.
  static Future<void> markReportsSynced(String uid, List<String> ids) async {
    if (ids.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = getPendingReportsKey(uid);
    final current = prefs.getStringList(key) ?? [];
    final idSet = ids.toSet();
    final updated = current.where((id) => !idSet.contains(id)).toList();
    await prefs.setStringList(key, updated);
  }

  static const String pendingVotesPrefix = 'pending_report_votes_';
  static const String localVotesPrefix = 'local_report_votes_';

  /// Restituisce la chiave SharedPreferences per i voti delle segnalazioni in attesa di sync.
  static String getPendingVotesKey(String uid) => '$pendingVotesPrefix$uid';

  /// Restituisce la chiave SharedPreferences per la cache locale dei voti dell'utente.
  static String getLocalVotesKey(String uid) => '$localVotesPrefix$uid';

  /// Recupera i voti in attesa di sincronizzazione salvati localmente.
  static Future<Map<String, int>> getPendingVotes(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(getPendingVotesKey(uid));
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
    } catch (_) {}
    return {};
  }

  /// Contrassegna un voto su una segnalazione come pendente (salvato offline).
  static Future<void> markVotePending(String uid, String barcode, int vote) async {
    final prefs = await SharedPreferences.getInstance();
    final votes = await getPendingVotes(uid);
    votes[barcode] = vote;
    await prefs.setString(getPendingVotesKey(uid), json.encode(votes));
  }

  /// Rimuove un voto dalla lista dei voti pendenti una volta sincronizzato.
  static Future<void> markVoteSynced(String uid, String barcode) async {
    final prefs = await SharedPreferences.getInstance();
    final votes = await getPendingVotes(uid);
    if (votes.containsKey(barcode)) {
      votes.remove(barcode);
      if (votes.isEmpty) {
        await prefs.remove(getPendingVotesKey(uid));
      } else {
        await prefs.setString(getPendingVotesKey(uid), json.encode(votes));
      }
    }
  }

  /// Recupera la cache locale dei voti dell'utente.
  static Future<Map<String, int>> getLocalVotes(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(getLocalVotesKey(uid));
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
    } catch (_) {}
    return {};
  }

  /// Salva il voto nella cache locale.
  static Future<void> saveLocalVote(String uid, String barcode, int vote) async {
    final prefs = await SharedPreferences.getInstance();
    final votes = await getLocalVotes(uid);
    votes[barcode] = vote;
    await prefs.setString(getLocalVotesKey(uid), json.encode(votes));
  }

  /// Sincronizza i voti pendenti con Firestore.
  static Future<void> syncPendingVotesWithFirestore(
    FirebaseFirestore db,
    FirebaseAuth auth,
  ) async {
    final user = auth.currentUser;
    final userId = user?.uid ?? 'anonymous_voter';

    final pendingVotes = await getPendingVotes(userId);
    if (pendingVotes.isEmpty) return;

    for (final entry in pendingVotes.entries) {
      final barcode = entry.key;
      final newVote = entry.value;

      try {
        final querySnapshot = await db
            .collection(reportsCollection)
            .where('barcode', isEqualTo: barcode)
            .where('status', isEqualTo: 'open')
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 4));

        if (querySnapshot.docs.isNotEmpty) {
          final reportDoc = querySnapshot.docs.first;
          final reportRef = reportDoc.reference;
          final userVoteRef = reportRef.collection('votes').doc(userId);

          final voteSnap = await userVoteRef.get().timeout(const Duration(seconds: 4));
          int oldVote = 0;
          if (voteSnap.exists) {
            oldVote = voteSnap.data()?['val'] ?? 0;
          }

          if (oldVote != newVote) {
            final scoreDiff = newVote - oldVote;
            final batch = db.batch();
            batch.set(userVoteRef, {'val': newVote});
            batch.update(reportRef, {'score': FieldValue.increment(scoreDiff)});
            await batch.commit().timeout(const Duration(seconds: 4));
          }
        }
        await markVoteSynced(userId, barcode);
      } catch (e) {
        debugPrint('Failed to sync pending vote for barcode $barcode: $e');
      }
    }
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
  /// Esegue un merge bidirezionale Push-then-Pull: carica le segnalazioni locali create offline
  /// e scarica quelle remote, filtrando i tombstone ed evitando resurrezioni.
  static Future<List<ProductReport>> syncReportsWithFirestore(
    FirebaseFirestore db,
    FirebaseAuth auth,
  ) async {
    final user = auth.currentUser;
    if (user == null || user.isAnonymous) {
      return fetchUserReports(auth);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final deletedFilter =
          prefs.getStringList('deleted_reports_sync_filter')?.toSet() ?? {};

      final snap = await db
          .collection(reportsCollection)
          .where("userId", isEqualTo: user.uid)
          .get()
          .timeout(const Duration(seconds: 4));

      final List<ProductReport> remoteReports = [];
      final Set<String> remoteDocIds = {};
      for (final d in snap.docs) {
        final report = ProductReport.fromJson(d.data());
        if (deletedFilter.contains(report.id)) {
          // Elimina definitivamente la segnalazione fantasma da Firestore
          d.reference.delete().catchError((_) => null);
        } else {
          remoteReports.add(report);
          remoteDocIds.add(report.id);
        }
      }

      // ── Gestione segnalazioni locali salvate offline (Pending Sync) ──
      final pendingIds = (await getPendingReportsIds(user.uid)).toSet();
      final alreadySynced = pendingIds.intersection(remoteDocIds);
      if (alreadySynced.isNotEmpty) {
        await markReportsSynced(user.uid, alreadySynced.toList());
        pendingIds.removeAll(alreadySynced);
      }

      if (pendingIds.isNotEmpty) {
        final localReports = await _reportDao.getUserReports(user.uid);
        final reportsToUpload = localReports
            .where((r) => pendingIds.contains(r.id) && !deletedFilter.contains(r.id))
            .toList();

        if (reportsToUpload.isNotEmpty) {
          try {
            final batch = db.batch();
            for (final rep in reportsToUpload) {
              final docRef = db.collection(reportsCollection).doc(rep.id);
              batch.set(docRef, rep.toJson(), SetOptions(merge: true));

              final prodRef = db.collection(productsCollection).doc(rep.barcode);
              batch.set(prodRef, {
                'pending_reports_count': FieldValue.increment(1),
                'last_updated': rep.submittedAt,
              }, SetOptions(merge: true));
            }

            final userRef = db.collection("users").doc(user.uid);
            batch.set(userRef, {
              'reportedBarcodes': FieldValue.arrayUnion(
                reportsToUpload.map((r) => r.barcode).toList(),
              ),
            }, SetOptions(merge: true));

            await batch.commit().timeout(const Duration(seconds: 4));
            final uploadedIds = reportsToUpload.map((r) => r.id).toList();
            await markReportsSynced(user.uid, uploadedIds);
            for (final rep in reportsToUpload) {
              remoteReports.add(rep);
            }
          } catch (e) {
            debugPrint("Failed uploading pending local reports to Firestore: $e");
            for (final rep in reportsToUpload) {
              remoteReports.add(rep);
            }
          }
        }
      }

      await syncPendingVotesWithFirestore(db, auth);

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

    String? reportId;
    try {
      reportId = db.collection(reportsCollection).doc().id;
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
      await markReportPending(userId, reportId);

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
      if (user != null) {
        final userRef = db.collection("users").doc(userId);
        batch.set(userRef, {
          'reportedBarcodes': FieldValue.arrayUnion([barcode]),
        }, SetOptions(merge: true));
      }

      try {
        await batch.commit().timeout(const Duration(seconds: 4));
        await markReportsSynced(userId, [reportId]);
      } catch (commitError) {
        debugPrint("Firestore batch commit failed/timed out, queued locally: $commitError");
      }

      return finalReport;
    } catch (error) {
      debugPrint("Error submit report: $error");
      if (reportId != null) {
        try {
          await _reportDao.deleteReport(userId, reportId);
          await markReportsSynced(userId, [reportId]);
        } catch (_) {}
      }
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
      final reportSnap = await reportRef.get().timeout(const Duration(seconds: 3));
      if (!reportSnap.exists) return;

      final barcode = reportSnap.data()?['barcode'] as String?;
      final nowIso = DateTime.now().toIso8601String();

      // Leggi voti del report prima del batch
      final votesQuery = await reportRef
          .collection('votes')
          .get()
          .timeout(const Duration(seconds: 3));

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
      if (user != null && barcode != null) {
        batch.set(db.collection("users").doc(user.uid), {
          'reportedBarcodes': FieldValue.arrayRemove([barcode]),
        }, SetOptions(merge: true));
      }

      await batch.commit().timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint("Could not delete report from Firestore: $error");
    }
  }

  /// Elimina una segnalazione dal database locale SQLite e registra il tombstone.
  static Future<void> deleteLocalReport(
    FirebaseAuth auth,
    String reportId,
  ) async {
    try {
      final userId = getUserId(auth);
      await _reportDao.deleteReport(userId, reportId);
      await markReportsSynced(userId, [reportId]);

      final prefs = await SharedPreferences.getInstance();

      // Registra tombstone per evitare che risorga durante la sincronizzazione Firestore
      final deletedFilter =
          prefs.getStringList('deleted_reports_sync_filter') ?? [];
      if (!deletedFilter.contains(reportId)) {
        deletedFilter.add(reportId);
        if (deletedFilter.length > 100) deletedFilter.removeAt(0);
        await prefs.setStringList('deleted_reports_sync_filter', deletedFilter);
      }

      // Supporta pulizia prefs per test che iniettano in SharedPreferences
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

    // Persistenza locale immediata (cache e coda pending per supporto offline)
    await saveLocalVote(userId, barcode, newVote);
    await markVotePending(userId, barcode, newVote);

    try {
      final querySnapshot = await db
          .collection(reportsCollection)
          .where('barcode', isEqualTo: barcode)
          .where('status', isEqualTo: 'open')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 4));

      if (querySnapshot.docs.isEmpty) return;

      final reportDoc = querySnapshot.docs.first;
      final reportRef = reportDoc.reference;
      final userVoteRef = reportRef.collection('votes').doc(userId);

      final voteSnap = await userVoteRef.get().timeout(const Duration(seconds: 4));
      int oldVote = 0;
      if (voteSnap.exists) {
        oldVote = voteSnap.data()?['val'] ?? 0;
      }

      if (oldVote != newVote) {
        final scoreDiff = newVote - oldVote;

        final batch = db.batch();
        batch.set(userVoteRef, {'val': newVote});
        batch.update(reportRef, {'score': FieldValue.increment(scoreDiff)});
        await batch.commit().timeout(const Duration(seconds: 4));
      }

      // Sincronizzato con successo
      await markVoteSynced(userId, barcode);
    } catch (e) {
      debugPrint("Firestore vote commit failed/timed out, queued locally: $e");
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
          .get()
          .timeout(const Duration(seconds: 3));

      if (querySnapshot.docs.isEmpty) {
        final pendingVotes = await getPendingVotes(userId);
        final localVotes = await getLocalVotes(userId);
        final userVote = pendingVotes[barcode] ?? localVotes[barcode] ?? 0;
        return {'score': 0, 'userVote': userVote};
      }

      final reportDoc = querySnapshot.docs.first;
      int score = reportDoc.data()['score'] ?? 0;
      int userVote = 0;

      final voteSnap = await reportDoc.reference
          .collection('votes')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 3));
      if (voteSnap.exists) {
        userVote = voteSnap.data()?['val'] ?? 0;
      }

      // Se esiste un voto pendente locale, sovrascrivi e adatta lo score
      final pendingVotes = await getPendingVotes(userId);
      if (pendingVotes.containsKey(barcode)) {
        final pendingVote = pendingVotes[barcode]!;
        score += (pendingVote - userVote);
        userVote = pendingVote;
      }

      return {'score': score, 'userVote': userVote};
    } catch (e) {
      debugPrint("Errore durante il recupero del voto: $e");
      final pendingVotes = await getPendingVotes(userId);
      final localVotes = await getLocalVotes(userId);
      final userVote = pendingVotes[barcode] ?? localVotes[barcode] ?? 0;
      return {'score': 0, 'userVote': userVote};
    }
  }
}

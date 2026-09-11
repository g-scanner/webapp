// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../../../models/models.dart';
import '../app_database.dart';

/// Data Access Object per la cronologia scansioni.
/// Supporta paginazione nativa con LIMIT/OFFSET ed evita il caricamento
/// dell'intera cronologia in memoria RAM.
class ScanHistoryDao {
  const ScanHistoryDao();

  Future<Database> get _db async => AppDatabase.instance.database;

  static const String tableName = 'scan_history';

  ScanHistoryItem _fromMap(Map<String, dynamic> map) {
    final rawJson = map['data_json'] as String;
    return ScanHistoryItem.fromJson(
      json.decode(rawJson) as Map<String, dynamic>,
    );
  }

  /// Recupera l'intera cronologia dell'utente ordinata per scansione più recente.
  Future<List<ScanHistoryItem>> getHistory(String userId) async {
    final db = await _db;
    final rows = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'scanned_at DESC',
    );
    return rows.map(_fromMap).toList();
  }

  /// Paginazione efficiente a livello di database (zero spreco di RAM).
  Future<List<ScanHistoryItem>> getHistoryPaged(
    String userId, {
    int offset = 0,
    int limit = 20,
  }) async {
    final db = await _db;
    final rows = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'scanned_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(_fromMap).toList();
  }

  /// Verifica se esiste una scansione dello stesso barcode entro una finestra temporale (es. 10 secondi).
  Future<bool> hasRecentScan(
    String userId,
    String barcode, {
    Duration window = const Duration(seconds: 10),
  }) async {
    final db = await _db;
    final cutoff = DateTime.now().subtract(window).toIso8601String();
    final rows = await db.query(
      tableName,
      columns: ['id'],
      where: 'user_id = ? AND barcode = ? AND scanned_at >= ?',
      whereArgs: [userId, barcode, cutoff],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Inserisce una nuova voce nella cronologia.
  Future<void> insertHistoryItem(String userId, ScanHistoryItem item) async {
    final db = await _db;
    await db.insert(
      tableName,
      {
        'id': item.id,
        'user_id': userId,
        'barcode': item.barcode,
        'scanned_at': item.scannedAt,
        'data_json': json.encode(item.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Sovrascrive atomicamente la cronologia dell'utente (ad es. dopo sync remoto da Firestore).
  Future<void> setHistory(String userId, List<ScanHistoryItem> items) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        tableName,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      final batch = txn.batch();
      for (final item in items) {
        batch.insert(
          tableName,
          {
            'id': item.id,
            'user_id': userId,
            'barcode': item.barcode,
            'scanned_at': item.scannedAt,
            'data_json': json.encode(item.toJson()),
          },
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Elimina una singola voce per ID.
  Future<int> deleteHistoryItem(String userId, String id) async {
    final db = await _db;
    return await db.delete(
      tableName,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }

  /// Elimina tutte le voci per un determinato barcode.
  Future<int> deleteHistoryByBarcode(String userId, String barcode) async {
    final db = await _db;
    return await db.delete(
      tableName,
      where: 'user_id = ? AND barcode = ?',
      whereArgs: [userId, barcode],
    );
  }

  /// Svuota completamente la cronologia dell'utente specificato.
  Future<int> wipeHistory(String userId) async {
    final db = await _db;
    return await db.delete(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Riassegna la cronologia dell'utente anonimo al nuovo UID al momento del login.
  Future<int> reassignAnonymousHistory(String newUid) async {
    final db = await _db;
    return await db.update(
      tableName,
      {'user_id': newUid},
      where: 'user_id = ?',
      whereArgs: ['anonymous'],
    );
  }
}

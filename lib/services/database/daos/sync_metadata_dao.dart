// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:sqflite/sqflite.dart';
import '../app_database.dart';

/// Data Access Object per metadati chiave-valore operativi (es. timestamp di sync).
class SyncMetadataDao {
  const SyncMetadataDao();

  Future<Database> get _db async => AppDatabase.instance.database;

  static const String tableName = 'sync_metadata';

  /// Legge un valore di metadato dato la chiave.
  Future<String?> getMetadata(String key) async {
    final db = await _db;
    final rows = await db.query(
      tableName,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  /// Salva o aggiorna un valore di metadato.
  Future<void> setMetadata(String key, String value) async {
    final db = await _db;
    await db.insert(
      tableName,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Rimuove una chiave di metadato.
  Future<int> removeMetadata(String key) async {
    final db = await _db;
    return await db.delete(
      tableName,
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  /// Cancella tutti i metadati di sincronizzazione.
  Future<int> clearAll() async {
    final db = await _db;
    return await db.delete(tableName);
  }
}

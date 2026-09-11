// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../../../models/models.dart';
import '../app_database.dart';

/// Data Access Object per la cache locale e offline dei prodotti.
/// Esegue query indicizzate native senza allocare inutilmente strutture in RAM.
class ProductDao {
  const ProductDao();

  Future<Database> get _db async => AppDatabase.instance.database;

  static const String tableName = 'products';

  /// Mappa un'entità [Product] in una riga SQLite indicizzata.
  Map<String, dynamic> _toMap(Product product) {
    return {
      'barcode': product.barcode,
      'name': product.nameMap['it'] ??
          (product.nameMap.isNotEmpty ? product.nameMap.values.first : ''),
      'brand': product.brandMap['it'] ??
          (product.brandMap.isNotEmpty ? product.brandMap.values.first : ''),
      'danger_level': null,
      'last_updated': product.lastUpdated,
      'fetched_from_off_at': product.fetchedFromOffAt,
      'content_hash': null,
      'data_json': json.encode(product.toJson()),
    };
  }

  /// Converte una riga SQLite nel modello tipizzato [Product].
  Product _fromMap(Map<String, dynamic> map) {
    final rawJson = map['data_json'] as String;
    return Product.fromJson(json.decode(rawJson) as Map<String, dynamic>);
  }

  /// Recupera tutti i prodotti salvati nel database.
  Future<List<Product>> getAllProducts() async {
    final db = await _db;
    final rows = await db.query(tableName, orderBy: 'cached_at DESC');
    return rows.map(_fromMap).toList();
  }

  /// Recupera un prodotto puntuale dato il barcode (O(1) tramite indice PRIMARY KEY).
  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await _db;
    final rows = await db.query(
      tableName,
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  /// Inserisce o aggiorna un prodotto nella cache locale.
  Future<void> upsertProduct(Product product) async {
    final db = await _db;
    final map = _toMap(product);
    map['cached_at'] = DateTime.now().microsecondsSinceEpoch;
    await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Inserisce o aggiorna massivamente un elenco di prodotti in una singola transazione Batch.
  Future<void> upsertProducts(List<Product> products) async {
    if (products.isEmpty) return;
    final db = await _db;
    final batch = db.batch();
    final base = DateTime.now().microsecondsSinceEpoch;
    for (int i = 0; i < products.length; i++) {
      final map = _toMap(products[i]);
      map['cached_at'] = base + (products.length - i);
      batch.insert(
        tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Elimina un singolo prodotto dato il barcode.
  Future<int> deleteProduct(String barcode) async {
    final db = await _db;
    return await db.delete(
      tableName,
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
  }

  /// Svuota completamente la cache locale dei prodotti.
  Future<int> deleteAllProducts() async {
    final db = await _db;
    return await db.delete(tableName);
  }

  /// Restituisce il conteggio totale dei prodotti in cache.
  Future<int> getProductsCount() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
    );
    return count ?? 0;
  }

  /// Elimina record con data `fetched_from_off_at` precedente a [cutoff].
  Future<int> deleteOlderThan(DateTime cutoff) async {
    final db = await _db;
    final cutoffIso = cutoff.toIso8601String();
    return await db.delete(
      tableName,
      where: 'fetched_from_off_at IS NOT NULL AND fetched_from_off_at < ?',
      whereArgs: [cutoffIso],
    );
  }
}

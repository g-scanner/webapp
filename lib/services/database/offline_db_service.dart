// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/models.dart';

/// Servizio responsabile dell'interrogazione e gestione del Database SQLite offline locale.
class OfflineDbService {
  static Database? _database;
  static String? _cachedDbPath;

  /// Restituisce il percorso standard del file SQLite sul disco.
  static Future<String> getDatabasePath() async {
    if (_cachedDbPath != null) return _cachedDbPath!;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return p.join(Directory.systemTemp.path, 'offline_products_test.db');
    }
    final appDir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory(p.join(appDir.path, 'offline_db'));
    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }
    _cachedDbPath = p.join(offlineDir.path, 'offline_products.db');
    return _cachedDbPath!;
  }

  /// Consente di sovrascrivere il percorso (utile per test o directory temporanee).
  @visibleForTesting
  static void setMockDatabasePath(String? path) {
    _cachedDbPath = path;
    _database = null;
  }

  /// Consente di iniettare un'istanza [Database] aperta per i test unitari.
  @visibleForTesting
  static void setMockDatabase(Database? db) {
    _database = db;
  }

  @visibleForTesting
  static bool? mockIsDatabaseInstalled;

  /// Verifica se il file di database SQLite esiste su disco ed è accessibile.
  static Future<bool> isDatabaseInstalled() async {
    if (mockIsDatabaseInstalled != null) return mockIsDatabaseInstalled!;
    if (Platform.environment.containsKey('FLUTTER_TEST') &&
        _cachedDbPath == null &&
        _database == null) {
      return false;
    }
    try {
      final path = await getDatabasePath();
      final file = File(path);
      if (!await file.exists()) return false;
      final length = await file.length();
      return length > 1024; // Minimo header SQLite
    } catch (e) {
      debugPrint("OfflineDbService.isDatabaseInstalled error: $e");
      return false;
    }
  }

  /// Restituisce la dimensione in byte del database locale su disco.
  static Future<int> getDatabaseSizeBytes() async {
    try {
      final path = await getDatabasePath();
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Inizializza o restituisce la connessione attiva al database SQLite locale in sola lettura.
  static Future<Database?> getDatabase() async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    final isInstalled = await isDatabaseInstalled();
    if (!isInstalled) return null;

    final path = await getDatabasePath();
    try {
      _database = await openDatabase(
        path,
        readOnly:
            false, // Per consentire anche operazioni di ATTACH transazionali
      );
      return _database;
    } catch (e) {
      debugPrint("OfflineDbService.getDatabase error: $e");
      return null;
    }
  }

  /// Cerca un prodotto per barcode all'interno del DB locale indicizzato.
  static Future<Product?> searchProduct(String barcode) async {
    try {
      final db = await getDatabase();
      if (db == null) return null;

      final results = await db.query(
        'products',
        where: 'code = ?',
        whereArgs: [barcode.trim()],
        limit: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      final row = results.first;
      return _mapRowToProduct(row);
    } catch (e) {
      debugPrint("OfflineDbService.searchProduct error: $e");
      return null;
    }
  }

  /// Mappa una riga SQLite del catalogo nel modello unificato [Product].
  static Product _mapRowToProduct(Map<String, dynamic> row) {
    final barcode = row['code']?.toString() ?? '';
    final productName = row['product_name']?.toString() ?? '';
    final brand = row['brands']?.toString() ?? '';
    final ingredientsText = row['ingredients_text']?.toString() ?? '';
    final allergensTags = row['allergens_tags']?.toString() ?? '';
    final labelsTags = row['labels_tags']?.toString() ?? '';
    final tracesTags = row['traces_tags']?.toString() ?? '';

    // Creazione liste allergeni e tracce
    final allergensList = <String>[];
    if (allergensTags.isNotEmpty) {
      allergensList.addAll(
        allergensTags
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
      );
    }
    if (tracesTags.isNotEmpty) {
      allergensList.addAll(
        tracesTags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
      );
    }

    // Integrazione claim da labels
    if (labelsTags.isNotEmpty) {
      allergensList.addAll(
        labelsTags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
      );
    }

    return Product(
      barcode: barcode,
      nameMap: {'it': productName, 'en': productName},
      brandMap: {'it': brand, 'en': brand},
      ingredientsMap: {'it': ingredientsText, 'en': ingredientsText},
      allergensMap: {'it': allergensList, 'en': allergensList},
      imageUrl: null,
      pendingReportsCount: 0,
      lastUpdated: DateTime.now().toIso8601String(),
      fetchedFromOffAt: DateTime.now().toIso8601String(),
      isFromOfflineDb: true,
      isOfflineNotFound: false,
      needsVerification: true,
    );
  }

  /// Crea un prodotto fittizio per rappresentare un record non censito nella copia offline.
  static Product createOfflineNotFoundProduct(String barcode) {
    return Product(
      barcode: barcode,
      nameMap: const {},
      brandMap: const {},
      ingredientsMap: const {},
      allergensMap: const {},
      imageUrl: null,
      pendingReportsCount: 0,
      lastUpdated: DateTime.now().toIso8601String(),
      fetchedFromOffAt: DateTime.now().toIso8601String(),
      isFromOfflineDb: true,
      isOfflineNotFound: true,
      needsVerification: true,
    );
  }

  /// Chiude la connessione ed elimina fisicamente il database dal dispositivo.
  static Future<void> deleteDatabaseFile() async {
    try {
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }
      final path = await getDatabasePath();
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("OfflineDbService.deleteDatabaseFile error: $e");
    }
  }

  /// Chiude la connessione SQLite attiva.
  static Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}

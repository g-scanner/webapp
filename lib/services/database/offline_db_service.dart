// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:io' show Platform, Directory, File;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';
import '../../core/network/connectivity_helper.dart';

/// Servizio responsabile dell'interrogazione e gestione del Database SQLite offline locale.
class OfflineDbService {
  static Database? _database;
  static String? _cachedDbPath;

  /// Restituisce il percorso standard del file SQLite sul disco o il nome virtuale IndexedDB su Web.
  static Future<String> getDatabasePath() async {
    if (_cachedDbPath != null) return _cachedDbPath!;
    if (kIsWeb) {
      _cachedDbPath = 'offline_products.db';
      return _cachedDbPath!;
    }
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return p.join(Directory.systemTemp.path, 'offline_products_test.db');
    }
    final appDir = await getApplicationSupportDirectory();
    final offlineDir = Directory(p.join(appDir.path, 'offline_db'));
    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }
    final targetPath = p.join(offlineDir.path, 'offline_products.db');

    _cachedDbPath = targetPath;
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

  static const String installedTierKey = 'locally_installed_offline_db_tier';

  @visibleForTesting
  static OfflineDbTier? mockInstalledTier;

  /// Restituisce il tier del database offline fisicamente presente su questo dispositivo.
  static Future<OfflineDbTier?> getInstalledTier() async {
    if (mockInstalledTier != null) return mockInstalledTier;
    try {
      final prefs = await SharedPreferences.getInstance();
      final tierStr = prefs.getString(installedTierKey);
      if (tierStr == null) return null;
      return OfflineDbTier.values.firstWhere(
        (t) => t.key == tierStr,
        orElse: () => OfflineDbTier.none,
      );
    } catch (_) {
      return null;
    }
  }

  /// Salva il tier del database offline installato localmente sul dispositivo.
  static Future<void> setInstalledTier(OfflineDbTier tier) async {
    mockInstalledTier = tier;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (tier == OfflineDbTier.none) {
        await prefs.remove(installedTierKey);
      } else {
        await prefs.setString(installedTierKey, tier.key);
      }
    } catch (_) {}
  }

  @visibleForTesting
  static bool? mockIsDatabaseInstalled;

  /// Verifica se il file di database SQLite esiste su disco o in IndexedDB ed è accessibile.
  static Future<bool> isDatabaseInstalled() async {
    if (mockIsDatabaseInstalled != null) return mockIsDatabaseInstalled!;
    if (!kIsWeb &&
        Platform.environment.containsKey('FLUTTER_TEST') &&
        _cachedDbPath == null &&
        _database == null) {
      return false;
    }
    try {
      final path = await getDatabasePath();
      if (kIsWeb) {
        final exists = await databaseFactory.databaseExists(path);
        if (!exists) return false;
        final bytes = await databaseFactory.readDatabaseBytes(path);
        return bytes.length > 1024;
      }
      final file = File(path);
      if (!file.existsSync()) return false;
      final length = file.lengthSync();
      return length > 1024; // Minimo header SQLite
    } catch (e) {
      debugPrint("OfflineDbService.isDatabaseInstalled error: $e");
      return false;
    }
  }

  /// Restituisce la dimensione in byte del database locale su disco o in IndexedDB.
  static Future<int> getDatabaseSizeBytes() async {
    try {
      final path = await getDatabasePath();
      if (kIsWeb) {
        final exists = await databaseFactory.databaseExists(path);
        if (!exists) return 0;
        final bytes = await databaseFactory.readDatabaseBytes(path);
        return bytes.length;
      }
      final file = File(path);
      if (file.existsSync()) {
        return file.lengthSync();
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
    if (kIsWeb) {
      // Previene lo svuotamento automatico di Safari dopo 7 giorni di inattività
      ConnectivityHelper.requestStoragePersistence();
    }
    try {
      _database = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(readOnly: false),
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
      if (mockIsDatabaseInstalled != null) {
        mockIsDatabaseInstalled = false;
      }
      mockInstalledTier = null;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(installedTierKey);
      } catch (_) {}
      final path = await getDatabasePath();
      if (kIsWeb) {
        if (await databaseFactory.databaseExists(path)) {
          await databaseFactory.deleteDatabase(path);
        }
      } else {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
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

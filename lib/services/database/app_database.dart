// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Coordinatore centrale del database SQLite locale (sqflite).
/// Gestisce ciclo di vita, versioning dello schema, indici per query ad alte prestazioni
/// e compatibilità cross-platform (mobile nativo e FFI per desktop/test).
class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  static const String databaseName = 'gscanner.db';
  static const int databaseVersion = 1;

  Database? _db;

  /// Restituisce l'istanza del Database aperta. Se chiusa o non ancora inizializzata, la crea.
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) {
      return _db!;
    }
    _db = await _initDatabase();
    return _db!;
  }

  /// Hook per test unitari e widget: consente di iniettare un database in memoria
  /// o un'istanza mock/customizzata.
  @visibleForTesting
  Future<Database> initForTesting({
    Database? overrideDb,
    bool inMemory = false,
  }) async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }

    _ensureFfiInitialized();

    if (overrideDb != null) {
      _db = overrideDb;
      return _db!;
    }

    final dbFactory = databaseFactoryFfi;
    final path = inMemory ? inMemoryDatabasePath : 'test_gscanner.db';
    if (!inMemory) {
      await dbFactory.deleteDatabase(path);
    }

    _db = await dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: databaseVersion,
        onCreate: _onCreate,
      ),
    );
    return _db!;
  }

  /// Chiude la connessione al database se aperta.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  /// Inizializzazione della connessione effettiva su disco o in-memory per i test.
  Future<Database> _initDatabase() async {
    _ensureFfiInitialized();

    final String path;
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      path = inMemoryDatabasePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = p.join(dbPath, databaseName);
    }

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  /// Inizializza FFI su ambienti desktop (Windows, Linux, macOS) o test headless.
  static void _ensureFfiInitialized() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      // Nei test con testWidgets l'uso di background isolates può bloccare
      // l'event loop di Flutter test. databaseFactoryFfiNoIsolate evita il deadlock.
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        databaseFactory = databaseFactoryFfiNoIsolate;
      } else {
        databaseFactory = databaseFactoryFfi;
      }
    }
  }

  /// Creazione di tabelle e indici per la versione 1.
  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. Tabella PRODOTTI (Cache locale & offline DB)
    batch.execute('''
      CREATE TABLE products (
        barcode TEXT PRIMARY KEY,
        name TEXT,
        brand TEXT,
        danger_level TEXT,
        last_updated TEXT,
        fetched_from_off_at TEXT,
        content_hash TEXT,
        cached_at INTEGER,
        data_json TEXT NOT NULL
      )
    ''');

    batch.execute(
      'CREATE INDEX idx_products_last_updated ON products(last_updated)',
    );
    batch.execute(
      'CREATE INDEX idx_products_fetched_at ON products(fetched_from_off_at)',
    );

    // 2. Tabella CRONOLOGIA SCANSIONI
    batch.execute('''
      CREATE TABLE scan_history (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        barcode TEXT NOT NULL,
        scanned_at TEXT NOT NULL,
        data_json TEXT NOT NULL
      )
    ''');

    batch.execute(
      'CREATE INDEX idx_history_user_scanned ON scan_history(user_id, scanned_at DESC)',
    );
    batch.execute(
      'CREATE INDEX idx_history_barcode ON scan_history(barcode)',
    );

    // 3. Tabella SEGNALAZIONI PRODOTTO & CRONOLOGIA SEGNALAZIONI
    batch.execute('''
      CREATE TABLE product_reports (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        barcode TEXT NOT NULL,
        product_name TEXT,
        brand TEXT,
        type TEXT,
        status TEXT,
        submitted_at TEXT NOT NULL,
        data_json TEXT NOT NULL
      )
    ''');

    batch.execute(
      'CREATE INDEX idx_reports_user_submitted ON product_reports(user_id, submitted_at DESC)',
    );
    batch.execute(
      'CREATE INDEX idx_reports_barcode ON product_reports(barcode)',
    );

    // 4. Tabella BARCODE SEGNALATI DALL'UTENTE
    batch.execute('''
      CREATE TABLE reported_barcodes (
        barcode TEXT NOT NULL,
        user_id TEXT NOT NULL,
        reported_at TEXT NOT NULL,
        PRIMARY KEY (barcode, user_id)
      )
    ''');

    // 5. Tabella METADATI DI SINCRONIZZAZIONE
    batch.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await batch.commit(noResult: true);
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Gestione future migrazioni di schema
  }

  /// Cancella direttamente da SQLite i prodotti più vecchi di un cutoff temporale.
  /// Esegue una query SQL nativa senza caricare i dati in memoria RAM.
  Future<int> deleteProductsOlderThan(DateTime cutoff) async {
    final db = await database;
    final cutoffIso = cutoff.toIso8601String();
    return await db.delete(
      'products',
      where: 'fetched_from_off_at IS NOT NULL AND fetched_from_off_at < ?',
      whereArgs: [cutoffIso],
    );
  }
}

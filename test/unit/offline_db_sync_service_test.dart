// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Unit Tests: OfflineDbSyncService

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

import 'package:gscanner/models/models.dart';
import 'package:gscanner/services/database/offline_db_sync_service.dart';
import 'package:gscanner/services/database/offline_db_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late String dbPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gscanner_sync_test_');
    dbPath = p.join(tempDir.path, 'offline_products.db');
    OfflineDbService.setMockDatabasePath(dbPath);
  });

  tearDown(() async {
    await OfflineDbService.close();
    OfflineDbService.setMockDatabasePath(null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('OfflineDbSyncService 3-State Decision Engine Tests', () {
    const publishedAt = 1773320000;
    const delta7dSince = publishedAt - (7 * 86400); // 1772715200
    const delta30dSince = publishedAt - (30 * 86400); // 1770728000

    test('cold start (DB not installed) selects fullDownload', () {
      final action = OfflineDbSyncService.determineSyncAction(
        isDbInstalled: false,
        lastSyncedAt: null,
        delta7dSince: delta7dSince,
        delta30dSince: delta30dSince,
      );
      expect(action, equals(OfflineSyncAction.fullDownload));
    });

    test(
      'cold start (DB installed but lastSyncedAt null) selects fullDownload',
      () {
        final action = OfflineDbSyncService.determineSyncAction(
          isDbInstalled: true,
          lastSyncedAt: null,
          delta7dSince: delta7dSince,
          delta30dSince: delta30dSince,
        );
        expect(action, equals(OfflineSyncAction.fullDownload));
      },
    );

    test('State 1 (Fast Delta): synced 3 days ago selects fastDelta7d', () {
      final threeDaysAgo = publishedAt - (3 * 86400);
      final action = OfflineDbSyncService.determineSyncAction(
        isDbInstalled: true,
        lastSyncedAt: threeDaysAgo,
        delta7dSince: delta7dSince,
        delta30dSince: delta30dSince,
      );
      expect(action, equals(OfflineSyncAction.fastDelta7d));
    });

    test(
      'State 2 (Extended Delta): synced 15 days ago selects extendedDelta30d',
      () {
        final fifteenDaysAgo = publishedAt - (15 * 86400);
        final action = OfflineDbSyncService.determineSyncAction(
          isDbInstalled: true,
          lastSyncedAt: fifteenDaysAgo,
          delta7dSince: delta7dSince,
          delta30dSince: delta30dSince,
        );
        expect(action, equals(OfflineSyncAction.extendedDelta30d));
      },
    );

    test(
      'State 3 (Full Re-alignment): synced 40 days ago selects fullDownload',
      () {
        final fortyDaysAgo = publishedAt - (40 * 86400);
        final action = OfflineDbSyncService.determineSyncAction(
          isDbInstalled: true,
          lastSyncedAt: fortyDaysAgo,
          delta7dSince: delta7dSince,
          delta30dSince: delta30dSince,
        );
        expect(action, equals(OfflineSyncAction.fullDownload));
      },
    );
  });

  group('OfflineDbSyncService Atomic SQLite ATTACH Merge Tests', () {
    test(
      'applyPatchDatabase correctly updates existing products and inserts new ones',
      () async {
        // 1. Inizializza DB principale con Prodotto A
        final mainDb = await openDatabase(
          dbPath,
          version: 1,
          onCreate: (db, v) async {
            await db.execute('''
          CREATE TABLE products (
            code TEXT PRIMARY KEY,
            product_name TEXT,
            brands TEXT,
            ingredients_text TEXT,
            allergens_tags TEXT,
            labels_tags TEXT,
            traces_tags TEXT,
            last_modified_t INTEGER
          );
        ''');
          },
        );

        await mainDb.insert('products', {
          'code': '111',
          'product_name': 'Nome Vecchio A',
          'brands': 'Marca A',
          'ingredients_text': 'Ingredienti vecchi',
          'allergens_tags': '',
          'labels_tags': '',
          'traces_tags': '',
          'last_modified_t': 100,
        });
        await mainDb.close();

        // 2. Crea patch DB con Prodotto A modificato e Prodotto B nuovo
        final patchPath = p.join(tempDir.path, 'patch_temp.db');
        final patchDb = await openDatabase(
          patchPath,
          version: 1,
          onCreate: (db, v) async {
            await db.execute('''
          CREATE TABLE products (
            code TEXT PRIMARY KEY,
            product_name TEXT,
            brands TEXT,
            ingredients_text TEXT,
            allergens_tags TEXT,
            labels_tags TEXT,
            traces_tags TEXT,
            last_modified_t INTEGER
          );
        ''');
          },
        );

        await patchDb.insert('products', {
          'code': '111',
          'product_name': 'Nome Nuovo A',
          'brands': 'Marca A',
          'ingredients_text': 'Ingredienti aggiornati',
          'allergens_tags': 'en:gluten',
          'labels_tags': '',
          'traces_tags': '',
          'last_modified_t': 200,
        });

        await patchDb.insert('products', {
          'code': '222',
          'product_name': 'Prodotto B',
          'brands': 'Marca B',
          'ingredients_text': 'Ingredienti B',
          'allergens_tags': '',
          'labels_tags': 'en:gluten-free',
          'traces_tags': '',
          'last_modified_t': 200,
        });
        await patchDb.close();

        // 3. Esegui fusione atomica via ATTACH
        await OfflineDbSyncService.applyPatchDatabase(
          targetDbPath: dbPath,
          patchFile: File(patchPath),
        );

        // 4. Verifica che Prodotto A sia aggiornato e Prodotto B sia inserito
        final checkDb = await openDatabase(dbPath);
        final results = await checkDb.query('products', orderBy: 'code ASC');
        await checkDb.close();

        expect(results.length, equals(2));
        expect(results[0]['code'], equals('111'));
        expect(results[0]['product_name'], equals('Nome Nuovo A'));
        expect(
          results[0]['ingredients_text'],
          equals('Ingredienti aggiornati'),
        );
        expect(results[1]['code'], equals('222'));
        expect(results[1]['product_name'], equals('Prodotto B'));

        // Il file patch deve essere stato eliminato automaticamente dopo il merge
        expect(await File(patchPath).exists(), isFalse);
      },
    );
  });

  group('OfflineDbSyncService Web & Gzip Extraction Tests', () {
    test('decompressGzipBytes decompresses valid gzipped payload accurately', () {
      final originalString = 'SQLite format 3\u0000Some database bytes for testing';
      final compressedBytes = gzip.encode(utf8.encode(originalString));

      final decompressedBytes = OfflineDbSyncService.decompressGzipBytes(compressedBytes);
      final resultString = utf8.decode(decompressedBytes);

      expect(resultString, equals(originalString));
    });

    test('syncDatabase returns idle for tier none', () async {
      final events = await OfflineDbSyncService.syncDatabase(
        tier: OfflineDbTier.none,
        currentLastSyncedAt: null,
      ).toList();

      expect(events.length, equals(1));
      expect(events.first.step, equals(OfflineSyncStep.idle));
    });
  });
}

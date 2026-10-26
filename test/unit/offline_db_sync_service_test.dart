// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Unit Tests: OfflineDbSyncService

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:gscanner/models/models.dart';
import 'package:gscanner/core/network/connectivity_helper.dart';
import 'package:gscanner/services/database/offline_db_sync_service.dart';
import 'package:gscanner/services/database/offline_db_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late String dbPath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    OfflineDbSyncService.resetState();
    OfflineDbService.mockIsDatabaseInstalled = null;
    OfflineDbService.mockInstalledTier = null;
    tempDir = await Directory.systemTemp.createTemp('gscanner_sync_test_');
    dbPath = p.join(tempDir.path, 'offline_products.db');
    OfflineDbService.setMockDatabasePath(dbPath);
  });

  tearDown(() async {
    OfflineDbSyncService.resetState();
    OfflineDbService.mockIsDatabaseInstalled = null;
    OfflineDbService.mockInstalledTier = null;
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

    test('State 0 (Up To Date): lastSyncedAt >= publishedAt selects upToDate', () {
      final action = OfflineDbSyncService.determineSyncAction(
        isDbInstalled: true,
        lastSyncedAt: publishedAt,
        delta7dSince: delta7dSince,
        delta30dSince: delta30dSince,
        publishedAt: publishedAt,
      );
      expect(action, equals(OfflineSyncAction.upToDate));
    });
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

    test('applyPatchDatabaseWeb batch-upserts records correctly into main DB', () async {
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

      // 2. Crea patch DB su file temporaneo per generare i bytes del delta
      final tempPatchFile = p.join(tempDir.path, 'patch_web_source.db');
      final patchDb = await openDatabase(
        tempPatchFile,
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
        'product_name': 'Nome Aggiornato Web A',
        'brands': 'Marca A',
        'ingredients_text': 'Ingredienti Web',
        'allergens_tags': 'en:gluten',
        'labels_tags': '',
        'traces_tags': '',
        'last_modified_t': 200,
      });
      await patchDb.insert('products', {
        'code': '333',
        'product_name': 'Prodotto C Web',
        'brands': 'Marca C',
        'ingredients_text': 'Ingredienti C',
        'allergens_tags': '',
        'labels_tags': 'en:gluten-free',
        'traces_tags': '',
        'last_modified_t': 200,
      });
      await patchDb.close();

      final patchBytes = await File(tempPatchFile).readAsBytes();

      // 3. Esegui applyPatchDatabaseWeb
      await OfflineDbSyncService.applyPatchDatabaseWeb(
        targetDbPath: dbPath,
        patchBytes: patchBytes,
      );

      // 4. Verifica che il DB principale contenga i dati aggiornati
      final checkDb = await openDatabase(dbPath);
      final results = await checkDb.query('products', orderBy: 'code ASC');
      await checkDb.close();

      expect(results.length, equals(2));
      expect(results[0]['code'], equals('111'));
      expect(results[0]['product_name'], equals('Nome Aggiornato Web A'));
      expect(results[1]['code'], equals('333'));
      expect(results[1]['product_name'], equals('Prodotto C Web'));
    });
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

  group('OfflineDbSyncService autoDownloadIfNeeded Tests', () {
    test('does nothing if offlineDbTier is none', () async {
      var called = false;
      final settings = UserSettings(
        strictMode: true,
        alertLactose: false,
        warnAdditives: true,
        autoSaveHistory: true,
        preferredLanguage: 'it',
        offlineDbTier: OfflineDbTier.none,
      );

      await OfflineDbSyncService.autoDownloadIfNeeded(
        settings: settings,
        onSettingsChange: (_) async => called = true,
      );

      expect(called, isFalse);
      expect(OfflineDbSyncService.isSyncing, isFalse);
    });

    test('does nothing if offlineDbAutoSync is false and not forceCheck', () async {
      var called = false;
      final settings = UserSettings(
        strictMode: true,
        alertLactose: false,
        warnAdditives: true,
        autoSaveHistory: true,
        preferredLanguage: 'it',
        offlineDbTier: OfflineDbTier.glutenFree,
        offlineDbAutoSync: false,
      );

      await OfflineDbSyncService.autoDownloadIfNeeded(
        settings: settings,
        onSettingsChange: (_) async => called = true,
      );

      expect(called, isFalse);
      expect(OfflineDbSyncService.isSyncing, isFalse);
    });

    test('skips autoDownload if offlineDbWifiOnly is true and connection is mobile', () async {
      ConnectivityHelper.mockIsWifi = false;
      var called = false;
      final settings = UserSettings(
        strictMode: true,
        alertLactose: false,
        warnAdditives: true,
        autoSaveHistory: true,
        preferredLanguage: 'it',
        offlineDbTier: OfflineDbTier.glutenFree,
        offlineDbAutoSync: true,
        offlineDbWifiOnly: true,
      );

      await OfflineDbSyncService.autoDownloadIfNeeded(
        settings: settings,
        onSettingsChange: (_) async => called = true,
      );

      expect(called, isFalse);
      expect(OfflineDbSyncService.isSyncing, isFalse);
      ConnectivityHelper.mockIsWifi = null;
    });

    test('skips autoDownload on web if offlineDbWifiOnly is true and not forceCheck', () async {
      OfflineDbSyncService.isWebOverride = true;
      var called = false;
      final settings = UserSettings(
        strictMode: true,
        alertLactose: false,
        warnAdditives: true,
        autoSaveHistory: true,
        preferredLanguage: 'it',
        offlineDbTier: OfflineDbTier.glutenFree,
        offlineDbAutoSync: true,
        offlineDbWifiOnly: true,
      );

      await OfflineDbSyncService.autoDownloadIfNeeded(
        settings: settings,
        onSettingsChange: (_) async => called = true,
      );

      expect(called, isFalse);
      expect(OfflineDbSyncService.isSyncing, isFalse);
      OfflineDbSyncService.isWebOverride = null;
    });

    test('isWeeklyUpdateAvailable evaluates conditions correctly', () async {
      // 1. Tier none -> false
      final sNone = UserSettings(
        strictMode: true,
        alertLactose: false,
        warnAdditives: true,
        autoSaveHistory: true,
        preferredLanguage: 'it',
        offlineDbTier: OfflineDbTier.none,
      );
      expect(await OfflineDbSyncService.isWeeklyUpdateAvailable(sNone), isFalse);

      // 2. AutoSync false -> false
      final sNoAuto = UserSettings(
        strictMode: true,
        alertLactose: false,
        warnAdditives: true,
        autoSaveHistory: true,
        preferredLanguage: 'it',
        offlineDbTier: OfflineDbTier.glutenFree,
        offlineDbAutoSync: false,
      );
      expect(await OfflineDbSyncService.isWeeklyUpdateAvailable(sNoAuto), isFalse);

      // 3. Not installed -> false
      final sInstalled = UserSettings(
        strictMode: true,
        alertLactose: false,
        warnAdditives: true,
        autoSaveHistory: true,
        preferredLanguage: 'it',
        offlineDbTier: OfflineDbTier.glutenFree,
        offlineDbAutoSync: true,
        offlineDbLastSyncedAt: 1000,
      );
      expect(await OfflineDbSyncService.isWeeklyUpdateAvailable(sInstalled), isFalse);

      // Install dummy DB
      final file = File(dbPath);
      await file.writeAsBytes(List.filled(2048, 1));
      OfflineDbService.setMockDatabasePath(dbPath);

      // 4. lastSync >= releaseEpoch -> false (already updated this week)
      const releaseEpoch = 2000;
      final sUpdated = sInstalled.copyWith(offlineDbLastSyncedAt: 2005);
      expect(
        await OfflineDbSyncService.isWeeklyUpdateAvailable(
          sUpdated,
          mockReleaseEpoch: releaseEpoch,
        ),
        isFalse,
      );

      // 5. lastSync < releaseEpoch -> true (update available!)
      final sOutdated = sInstalled.copyWith(offlineDbLastSyncedAt: 1500);
      expect(
        await OfflineDbSyncService.isWeeklyUpdateAvailable(
          sOutdated,
          mockReleaseEpoch: releaseEpoch,
        ),
        isTrue,
      );
    });

    test('does nothing if database is already installed and matches tier', () async {
      // create a dummy sqlite file so isDatabaseInstalled is true
      final file = File(dbPath);
      await file.writeAsBytes(List.filled(2048, 1));
      OfflineDbService.setMockDatabasePath(dbPath);
      await OfflineDbService.setInstalledTier(OfflineDbTier.glutenFree);

      var called = false;
      final settings = UserSettings(
        strictMode: true,
        alertLactose: false,
        warnAdditives: true,
        autoSaveHistory: true,
        preferredLanguage: 'it',
        offlineDbTier: OfflineDbTier.glutenFree,
      );

      await OfflineDbSyncService.autoDownloadIfNeeded(
        settings: settings,
        onSettingsChange: (_) async => called = true,
      );

      expect(called, isFalse);
      expect(OfflineDbSyncService.isSyncing, isFalse);
    });

    test('deletes DB if settings tier is none and DB is installed', () async {
      final file = File(dbPath);
      await file.writeAsBytes(List.filled(2048, 1));
      OfflineDbService.setMockDatabasePath(dbPath);
      await OfflineDbService.setInstalledTier(OfflineDbTier.glutenFree);
      expect(await OfflineDbService.isDatabaseInstalled(), isTrue);

      var called = false;
      final settings = UserSettings(
        strictMode: true,
        alertLactose: false,
        warnAdditives: true,
        autoSaveHistory: true,
        preferredLanguage: 'it',
        offlineDbTier: OfflineDbTier.none,
      );

      await OfflineDbSyncService.autoDownloadIfNeeded(
        settings: settings,
        onSettingsChange: (_) async => called = true,
      );

      expect(called, isFalse);
      expect(await OfflineDbService.isDatabaseInstalled(), isFalse);
      expect(await OfflineDbService.getInstalledTier(), isNull);
    });

    test('deletes old DB on tier mismatch and downloads new tier', () async {
      final file = File(dbPath);
      await file.writeAsBytes(List.filled(2048, 1));
      OfflineDbService.setMockDatabasePath(dbPath);
      await OfflineDbService.setInstalledTier(OfflineDbTier.glutenFree);
      expect(await OfflineDbService.isDatabaseInstalled(), isTrue);

      final manifestJson = json.encode({
        'version': 2,
        'published_at': 1773320000,
        'packages': {
          'euro_core': {
            'full': {'file': 'euro_core_full.db.gz'},
          },
        },
      });

      final dummyDbBytes = List.filled(2048, 42);
      final gzippedDbBytes = gzip.encode(dummyDbBytes);

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('version.json')) {
          return http.Response(manifestJson, 200);
        }
        if (request.url.path.endsWith('euro_core_full.db.gz')) {
          return http.Response.bytes(gzippedDbBytes, 200);
        }
        return http.Response('Not found', 404);
      });

      UserSettings? updatedSettings;
      final settings = UserSettings(
        strictMode: true,
        alertLactose: false,
        warnAdditives: true,
        autoSaveHistory: true,
        preferredLanguage: 'it',
        offlineDbTier: OfflineDbTier.euroCore,
        offlineDbLastSyncedAt: null,
      );

      await OfflineDbSyncService.autoDownloadIfNeeded(
        settings: settings,
        client: mockClient,
        onSettingsChange: (updated) async {
          updatedSettings = updated;
        },
      );

      var attempts = 0;
      while (updatedSettings == null && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
      }

      expect(updatedSettings, isNotNull);
      expect(updatedSettings!.offlineDbTier, equals(OfflineDbTier.euroCore));
      expect(await File(dbPath).exists(), isTrue);
      expect(await OfflineDbService.getInstalledTier(), equals(OfflineDbTier.euroCore));
    });

    test('triggers auto-download and calls onSettingsChange when DB is not installed', () async {
      final manifestJson = json.encode({
        'version': 2,
        'published_at': 1773320000,
        'packages': {
          'gluten_free': {
            'full': {'file': 'gluten_free_full.db.gz'},
          },
        },
      });

      final dummyDbBytes = List.filled(2048, 42);
      final gzippedDbBytes = gzip.encode(dummyDbBytes);

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('version.json')) {
          return http.Response(manifestJson, 200);
        }
        if (request.url.path.endsWith('gluten_free_full.db.gz')) {
          return http.Response.bytes(gzippedDbBytes, 200);
        }
        return http.Response('Not found', 404);
      });

      UserSettings? updatedSettings;
      final settings = UserSettings(
        strictMode: true,
        alertLactose: false,
        warnAdditives: true,
        autoSaveHistory: true,
        preferredLanguage: 'it',
        offlineDbTier: OfflineDbTier.glutenFree,
        offlineDbLastSyncedAt: null,
      );

      await OfflineDbSyncService.autoDownloadIfNeeded(
        settings: settings,
        client: mockClient,
        onSettingsChange: (updated) async {
          updatedSettings = updated;
        },
      );

      var attempts = 0;
      while (updatedSettings == null && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
      }

      expect(updatedSettings, isNotNull);
      expect(updatedSettings!.offlineDbTier, equals(OfflineDbTier.glutenFree));
      expect(updatedSettings!.offlineDbLastSyncedAt, isNotNull);
      expect(await File(dbPath).exists(), isTrue);
    });
  });

  group('OfflineDbSyncService Redundant Download Prevention Tests', () {
    test('syncDatabase skips download if database is already installed and up to date with published version', () async {
      final dbPath = p.join(tempDir.path, 'offline_products.db');
      await File(dbPath).writeAsBytes(List.filled(2048, 42));
      OfflineDbService.setMockDatabasePath(dbPath);

      const publishedAt = 1773320000;
      final manifestJson = json.encode({
        'version': 2,
        'published_at': publishedAt,
        'packages': {
          'gluten_free': {
            'full': {'file': 'gluten_free_full.db.gz'},
          },
        },
      });

      var downloadAttempted = false;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('version.json')) {
          return http.Response(manifestJson, 200);
        }
        if (request.url.path.endsWith('.db.gz')) {
          downloadAttempted = true;
          return http.Response('Unexpected download', 500);
        }
        return http.Response('Not found', 404);
      });

      final progressList = await OfflineDbSyncService.syncDatabase(
        tier: OfflineDbTier.glutenFree,
        currentLastSyncedAt: publishedAt + 100,
        client: mockClient,
      ).toList();

      expect(downloadAttempted, isFalse);
      expect(progressList.last.step, equals(OfflineSyncStep.completed));
    });

    test('deleteDatabaseFile closes connection, resets mock and deletes physical file', () async {
      final dbPath = p.join(tempDir.path, 'offline_to_delete.db');
      await File(dbPath).writeAsBytes(List.filled(2048, 42));
      OfflineDbService.setMockDatabasePath(dbPath);
      OfflineDbService.mockIsDatabaseInstalled = true;

      expect(await OfflineDbService.isDatabaseInstalled(), isTrue);
      expect(File(dbPath).existsSync(), isTrue);

      await OfflineDbService.deleteDatabaseFile();

      expect(OfflineDbService.mockIsDatabaseInstalled, isFalse);
      expect(File(dbPath).existsSync(), isFalse);
    });

    test('syncDatabase yields error sha256_mismatch when checksum does not match manifest', () async {
      final manifestJson = json.encode({
        'version': 2,
        'published_at': 1773320000,
        'packages': {
          'gluten_free': {
            'full': {
              'file': 'gluten_free_full.db.gz',
              'sha256': 'expected_real_hash_that_wont_match',
            },
          },
        },
      });

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('version.json')) {
          return http.Response(manifestJson, 200);
        }
        if (request.url.path.endsWith('.db.gz')) {
          return http.Response.bytes(List.filled(100, 42), 200);
        }
        return http.Response('Not found', 404);
      });

      final progressList = await OfflineDbSyncService.syncDatabase(
        tier: OfflineDbTier.glutenFree,
        currentLastSyncedAt: null,
        client: mockClient,
      ).toList();

      expect(progressList.any((p) => p.step == OfflineSyncStep.error && p.errorMessage == 'sha256_mismatch'), isTrue);
    });
  });
}

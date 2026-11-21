// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — Unit Tests: OfflineDbService

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

import 'package:glutiend/services/database/offline_db_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late String dbPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('glutiend_offline_test_');
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

  group('OfflineDbService Unit Tests', () {
    test(
      'isDatabaseInstalled returns false when db file does not exist',
      () async {
        final isInstalled = await OfflineDbService.isDatabaseInstalled();
        expect(isInstalled, isFalse);
      },
    );

    test(
      'isDatabaseInstalled and getDatabaseSizeBytes work correctly when db exists',
      () async {
        // Create empty db with schema
        final db = await openDatabase(
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
        await db.close();

        expect(await OfflineDbService.isDatabaseInstalled(), isTrue);
        expect(await OfflineDbService.getDatabaseSizeBytes(), greaterThan(0));
      },
    );

    test(
      'searchProduct returns Product with isFromOfflineDb: true when found',
      () async {
        final db = await openDatabase(
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

        await db.insert('products', {
          'code': '8001234567890',
          'product_name': 'Pasta Senza Glutine',
          'brands': 'Barilla',
          'ingredients_text': 'Farina di mais, farina di riso',
          'allergens_tags': 'en:none',
          'labels_tags': 'en:gluten-free',
          'traces_tags': '',
          'last_modified_t': 1773000000,
        });
        await db.close();

        final product = await OfflineDbService.searchProduct('8001234567890');
        expect(product, isNotNull);
        expect(product!.barcode, equals('8001234567890'));
        expect(product.getName('it'), equals('Pasta Senza Glutine'));
        expect(product.getBrand('it'), equals('Barilla'));
        expect(product.isFromOfflineDb, isTrue);
        expect(product.isOfflineNotFound, isFalse);
        expect(product.labelsTags, contains('en:gluten-free'));
        expect(product.toOffTags().labelsTags, contains('en:gluten-free'));
      },
    );

    test(
      'searchProduct returns null when product does not exist in DB',
      () async {
        final db = await openDatabase(
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
        await db.close();

        final product = await OfflineDbService.searchProduct('9999999999999');
        expect(product, isNull);
      },
    );

    test(
      'createOfflineNotFoundProduct returns volatile product with isOfflineNotFound: true',
      () {
        final notFoundProduct = OfflineDbService.createOfflineNotFoundProduct(
          '8000000000000',
        );
        expect(notFoundProduct.barcode, equals('8000000000000'));
        expect(notFoundProduct.isFromOfflineDb, isTrue);
        expect(notFoundProduct.isOfflineNotFound, isTrue);
        expect(notFoundProduct.nameMap, isEmpty);
        expect(notFoundProduct.ingredientsMap, isEmpty);
      },
    );

    test('deleteDatabaseFile removes the physical file cleanly', () async {
      final db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, v) async {
          await db.execute('CREATE TABLE dummy (id INTEGER PRIMARY KEY);');
        },
      );
      await db.close();

      expect(await File(dbPath).exists(), isTrue);
      await OfflineDbService.deleteDatabaseFile();
      expect(await File(dbPath).exists(), isFalse);
    });

    test('searchProduct maps labels, traces, and categories without polluting allergens', () async {
      final db = await openDatabase(
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
              categories_tags TEXT,
              last_modified_t INTEGER
            );
          ''');
        },
      );

      await db.insert('products', {
        'code': '0071146012455',
        'product_name': 'HARVEST SNAPS ORIGINAL BAKED VEGGIE SNACKS',
        'brands': 'Calbee',
        'ingredients_text': 'Green peas, Vegetable oil, Rice, Salt, Calcium carbonate, Rosemary. May contain: Milk, Mustard.',
        'allergens_tags': '',
        'labels_tags': 'en:no-gluten,en:gfco-gluten-free',
        'traces_tags': 'en:milk,en:mustard',
        'categories_tags': 'en:snacks,en:salty-snacks',
        'last_modified_t': 1773000000,
      });
      await db.close();

      final product = await OfflineDbService.searchProduct('0071146012455');
      expect(product, isNotNull);
      expect(product!.labelsTags, containsAll(['en:no-gluten', 'en:gfco-gluten-free']));
      expect(product.tracesTags, containsAll(['en:milk', 'en:mustard']));
      expect(product.categoriesTags, containsAll(['en:snacks', 'en:salty-snacks']));
      // Allergeni puliti: non devono contenere le labels
      expect(product.getAllergens('it'), isNot(contains('en:no-gluten')));
      expect(product.getAllergens('it'), isNot(contains('en:gfco-gluten-free')));
    });
  });
}

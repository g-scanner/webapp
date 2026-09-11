// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Dedicated Unit Tests: AppDatabase & DAOs

import 'package:flutter_test/flutter_test.dart';
import 'package:gscanner/models/models.dart';
import 'package:gscanner/services/database/app_database.dart';
import 'package:gscanner/services/database/daos/product_dao.dart';
import 'package:gscanner/services/database/daos/scan_history_dao.dart';
import 'package:gscanner/services/database/daos/product_report_dao.dart';
import 'package:gscanner/services/database/daos/sync_metadata_dao.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const productDao = ProductDao();
  const historyDao = ScanHistoryDao();
  const reportDao = ProductReportDao();
  const metadataDao = SyncMetadataDao();

  setUp(() async {
    // Inizializza un database SQLite completamente isolato in memoria per ogni test
    await AppDatabase.instance.initForTesting(inMemory: true);
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  Product createSampleProduct({
    String barcode = '8001234567890',
    String name = 'Pasta Senza Glutine',
    String lastUpdated = '2026-08-01T12:00:00Z',
    String? fetchedFromOffAt,
  }) {
    return Product(
      barcode: barcode,
      nameMap: {'it': name},
      brandMap: {'it': 'Brand Bio'},
      ingredientsMap: {'it': 'Farina di riso, farina di mais'},
      allergensMap: {'it': <String>[]},
      lastUpdated: lastUpdated,
      fetchedFromOffAt: fetchedFromOffAt,
      pendingReportsCount: 0,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1 – AppDatabase Lifecycle & Schema
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 1 – AppDatabase Lifecycle & Schema', () {
    test('database opens and creates all expected tables', () async {
      final db = await AppDatabase.instance.database;
      expect(db.isOpen, isTrue);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final tableNames = tables.map((t) => t['name'] as String).toList();

      expect(tableNames, contains('products'));
      expect(tableNames, contains('scan_history'));
      expect(tableNames, contains('product_reports'));
      expect(tableNames, contains('reported_barcodes'));
      expect(tableNames, contains('sync_metadata'));
    });

    test('deleteProductsOlderThan prunes stale products via SQL without memory load', () async {
      final now = DateTime.now();
      final fresh = createSampleProduct(
        barcode: 'fresh_1',
        fetchedFromOffAt: now.subtract(const Duration(days: 5)).toIso8601String(),
      );
      final stale = createSampleProduct(
        barcode: 'stale_1',
        fetchedFromOffAt: now.subtract(const Duration(days: 45)).toIso8601String(),
      );

      await productDao.upsertProducts([fresh, stale]);
      expect(await productDao.getProductsCount(), 2);

      // Cutoff a 30 giorni
      final cutoff = now.subtract(const Duration(days: 30));
      final deletedCount = await AppDatabase.instance.deleteProductsOlderThan(cutoff);

      expect(deletedCount, 1);
      expect(await productDao.getProductsCount(), 1);
      expect(await productDao.getProductByBarcode('fresh_1'), isNotNull);
      expect(await productDao.getProductByBarcode('stale_1'), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2 – ProductDao CRUD & Queries
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 2 – ProductDao CRUD & Queries', () {
    test('getAllProducts returns empty initially', () async {
      final all = await productDao.getAllProducts();
      expect(all, isEmpty);
    });

    test('upsertProduct inserts and getProductByBarcode retrieves product', () async {
      final p = createSampleProduct(barcode: '12345', name: 'Pizza Margherita');
      await productDao.upsertProduct(p);

      final retrieved = await productDao.getProductByBarcode('12345');
      expect(retrieved, isNotNull);
      expect(retrieved!.barcode, '12345');
      expect(retrieved.nameMap['it'], 'Pizza Margherita');
      expect(retrieved.brandMap['it'], 'Brand Bio');
    });

    test('upsertProduct updates existing product on conflict replace', () async {
      final p1 = createSampleProduct(barcode: '111', name: 'Nome Vecchio');
      await productDao.upsertProduct(p1);

      final p2 = createSampleProduct(barcode: '111', name: 'Nome Nuovo');
      await productDao.upsertProduct(p2);

      final list = await productDao.getAllProducts();
      expect(list.length, 1);
      expect(list.first.nameMap['it'], 'Nome Nuovo');
    });

    test('upsertProducts batch inserts multiple products', () async {
      final p1 = createSampleProduct(barcode: 'p1', name: 'Biscotti');
      final p2 = createSampleProduct(barcode: 'p2', name: 'Crackers');
      final p3 = createSampleProduct(barcode: 'p3', name: 'Grissini');

      await productDao.upsertProducts([p1, p2, p3]);
      expect(await productDao.getProductsCount(), 3);

      final all = await productDao.getAllProducts();
      expect(all.length, 3);
    });

    test('deleteProduct removes specific item and deleteAllProducts empties table', () async {
      final p1 = createSampleProduct(barcode: 'p1');
      final p2 = createSampleProduct(barcode: 'p2');
      await productDao.upsertProducts([p1, p2]);

      await productDao.deleteProduct('p1');
      expect(await productDao.getProductByBarcode('p1'), isNull);
      expect(await productDao.getProductByBarcode('p2'), isNotNull);

      await productDao.deleteAllProducts();
      expect(await productDao.getProductsCount(), 0);
    });

    test('deleteOlderThan removes items older than cutoff', () async {
      final now = DateTime.now();
      final pOld = createSampleProduct(
        barcode: 'old',
        fetchedFromOffAt: now.subtract(const Duration(days: 60)).toIso8601String(),
      );
      final pNew = createSampleProduct(
        barcode: 'new',
        fetchedFromOffAt: now.subtract(const Duration(days: 2)).toIso8601String(),
      );
      await productDao.upsertProducts([pOld, pNew]);

      final deleted = await productDao.deleteOlderThan(now.subtract(const Duration(days: 30)));
      expect(deleted, 1);
      expect(await productDao.getProductByBarcode('old'), isNull);
      expect(await productDao.getProductByBarcode('new'), isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3 – ScanHistoryDao
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 3 – ScanHistoryDao', () {
    test('insertHistoryItem and getHistory return items ordered by scannedAt DESC', () async {
      final item1 = ScanHistoryItem(
        id: 'h1',
        barcode: '111',
        scannedAt: '2026-08-01T10:00:00Z',
      );
      final item2 = ScanHistoryItem(
        id: 'h2',
        barcode: '222',
        scannedAt: '2026-08-01T11:00:00Z',
      );

      await historyDao.insertHistoryItem('user_1', item1);
      await historyDao.insertHistoryItem('user_1', item2);

      final hist = await historyDao.getHistory('user_1');
      expect(hist.length, 2);
      expect(hist.first.id, 'h2'); // il più recente per primo
      expect(hist.last.id, 'h1');
    });

    test('getHistoryPaged performs native SQL pagination with limit and offset', () async {
      for (int i = 0; i < 10; i++) {
        final paddedIndex = i.toString().padLeft(2, '0');
        await historyDao.insertHistoryItem(
          'user_page',
          ScanHistoryItem(
            id: 'item_$i',
            barcode: 'barcode_$i',
            scannedAt: '2026-08-01T10:$paddedIndex:00Z',
          ),
        );
      }

      // Pagina 1: 4 elementi
      final page1 = await historyDao.getHistoryPaged('user_page', offset: 0, limit: 4);
      expect(page1.length, 4);
      expect(page1.first.id, 'item_9');

      // Pagina 2: 4 elementi
      final page2 = await historyDao.getHistoryPaged('user_page', offset: 4, limit: 4);
      expect(page2.length, 4);
      expect(page2.first.id, 'item_5');

      // Pagina 3: restanti 2 elementi
      final page3 = await historyDao.getHistoryPaged('user_page', offset: 8, limit: 4);
      expect(page3.length, 2);
      expect(page3.last.id, 'item_0');
    });

    test('hasRecentScan returns true within window and false outside', () async {
      final now = DateTime.now();
      await historyDao.insertHistoryItem(
        'user_recent',
        ScanHistoryItem(
          id: 'rec_1',
          barcode: 'recent_bar',
          scannedAt: now.subtract(const Duration(seconds: 4)).toIso8601String(),
        ),
      );

      final hasRecent = await historyDao.hasRecentScan('user_recent', 'recent_bar');
      expect(hasRecent, isTrue);

      final hasOtherBarcode = await historyDao.hasRecentScan('user_recent', 'other_bar');
      expect(hasOtherBarcode, isFalse);
    });

    test('deleteHistoryItem, deleteHistoryByBarcode and wipeHistory work correctly', () async {
      await historyDao.insertHistoryItem(
        'u1',
        ScanHistoryItem(id: '1', barcode: 'A', scannedAt: '2026-08-01T10:00:00Z'),
      );
      await historyDao.insertHistoryItem(
        'u1',
        ScanHistoryItem(id: '2', barcode: 'A', scannedAt: '2026-08-01T11:00:00Z'),
      );
      await historyDao.insertHistoryItem(
        'u1',
        ScanHistoryItem(id: '3', barcode: 'B', scannedAt: '2026-08-01T12:00:00Z'),
      );

      // Elimina per ID
      await historyDao.deleteHistoryItem('u1', '3');
      expect(await historyDao.getHistory('u1'), hasLength(2));

      // Elimina per barcode
      await historyDao.deleteHistoryByBarcode('u1', 'A');
      expect(await historyDao.getHistory('u1'), isEmpty);

      // Wipe
      await historyDao.insertHistoryItem(
        'u1',
        ScanHistoryItem(id: '4', barcode: 'C', scannedAt: '2026-08-01T13:00:00Z'),
      );
      await historyDao.wipeHistory('u1');
      expect(await historyDao.getHistory('u1'), isEmpty);
    });

    test('reassignAnonymousHistory reassigns records to new UID on login', () async {
      await historyDao.insertHistoryItem(
        'anonymous',
        ScanHistoryItem(id: 'anon_1', barcode: 'A', scannedAt: '2026-08-01T10:00:00Z'),
      );

      expect(await historyDao.getHistory('anonymous'), hasLength(1));
      expect(await historyDao.getHistory('logged_user'), isEmpty);

      final updated = await historyDao.reassignAnonymousHistory('logged_user');
      expect(updated, 1);

      expect(await historyDao.getHistory('anonymous'), isEmpty);
      expect(await historyDao.getHistory('logged_user'), hasLength(1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4 – ProductReportDao & Reported Barcodes
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 4 – ProductReportDao & Reported Barcodes', () {
    test('insertReport saves report and tracks reported barcode', () async {
      final report = ProductReport(
        id: 'rep_1',
        barcode: 'BAR_1',
        productName: 'Biscotti',
        brand: 'BioBrand',
        type: 'gluten_detected',
        comments: 'Contiene glutine!',
        submittedAt: '2026-08-01T12:00:00Z',
        status: 'open',
        userId: 'user_rep',
      );

      await reportDao.insertReport(report);

      final reports = await reportDao.getUserReports('user_rep');
      expect(reports.length, 1);
      expect(reports.first.id, 'rep_1');

      final isReported = await reportDao.isBarcodeReported('user_rep', 'BAR_1');
      expect(isReported, isTrue);

      final isOtherReported = await reportDao.isBarcodeReported('user_rep', 'BAR_2');
      expect(isOtherReported, isFalse);
    });

    test('deleteReport deletes report and cleans up reported barcode if no other reports exist', () async {
      final report = ProductReport(
        id: 'rep_single',
        barcode: 'BAR_DEL',
        productName: 'Pane',
        brand: 'B',
        type: 't',
        comments: 'c',
        submittedAt: '2026-08-01T12:00:00Z',
        status: 'open',
        userId: 'u_del',
      );

      await reportDao.insertReport(report);
      expect(await reportDao.isBarcodeReported('u_del', 'BAR_DEL'), isTrue);

      await reportDao.deleteReport('u_del', 'rep_single');
      expect(await reportDao.getUserReports('u_del'), isEmpty);
      expect(await reportDao.isBarcodeReported('u_del', 'BAR_DEL'), isFalse);
    });

    test('reassignAnonymousReports transfers anonymous reports and barcodes to new UID', () async {
      final report = ProductReport(
        id: 'rep_anon',
        barcode: 'BAR_ANON',
        productName: 'Snack',
        brand: 'B',
        type: 't',
        comments: 'c',
        submittedAt: '2026-08-01T12:00:00Z',
        status: 'open',
        userId: 'anonymous',
      );

      await reportDao.insertReport(report);

      await reportDao.reassignAnonymousReports('auth_user_123');

      expect(await reportDao.getUserReports('anonymous'), isEmpty);
      final transferred = await reportDao.getUserReports('auth_user_123');
      expect(transferred, hasLength(1));
      expect(await reportDao.isBarcodeReported('auth_user_123', 'BAR_ANON'), isTrue);
    });

    test('wipeReports completely cleans user reports and reported barcodes', () async {
      final report = ProductReport(
        id: 'rep_wipe',
        barcode: 'BAR_WIPE',
        productName: 'Cereali',
        brand: 'B',
        type: 't',
        comments: 'c',
        submittedAt: '2026-08-01T12:00:00Z',
        status: 'open',
        userId: 'u_wipe',
      );

      await reportDao.insertReport(report);
      await reportDao.wipeReports('u_wipe');

      expect(await reportDao.getUserReports('u_wipe'), isEmpty);
      expect(await reportDao.isBarcodeReported('u_wipe', 'BAR_WIPE'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5 – SyncMetadataDao
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 5 – SyncMetadataDao', () {
    test('getMetadata returns null for missing key', () async {
      final val = await metadataDao.getMetadata('non_existent_key');
      expect(val, isNull);
    });

    test('setMetadata and getMetadata store and retrieve values', () async {
      await metadataDao.setMetadata('last_sync', '2026-09-11T12:00:00Z');
      final val = await metadataDao.getMetadata('last_sync');
      expect(val, '2026-09-11T12:00:00Z');
    });

    test('removeMetadata and clearAll delete metadata entries', () async {
      await metadataDao.setMetadata('k1', 'v1');
      await metadataDao.setMetadata('k2', 'v2');

      await metadataDao.removeMetadata('k1');
      expect(await metadataDao.getMetadata('k1'), isNull);
      expect(await metadataDao.getMetadata('k2'), 'v2');

      await metadataDao.clearAll();
      expect(await metadataDao.getMetadata('k2'), isNull);
    });
  });
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Pure Unit Tests: DbService

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show SetOptions;
import 'package:http/http.dart' as http;

import 'package:gscanner/models/models.dart';
import 'package:gscanner/services/db_service.dart';
import 'package:gscanner/services/analyzer_service.dart';
import '../mocks/shared_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseFirestore mockDb;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockCollectionReference mockProductsCol;
  late MockCollectionReference mockReportsCol;
  late MockCollectionReference mockUsersCol;
  late MockDocumentReference mockDocRef;
  late MockDocumentSnapshot mockDocSnap;
  late MockWriteBatch mockBatch;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    setupMocktailFallbacks();
    registerFallbackValue(SetOptions(merge: true));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockDb = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockProductsCol = MockCollectionReference();
    mockReportsCol = MockCollectionReference();
    mockUsersCol = MockCollectionReference();
    mockDocRef = MockDocumentReference();
    mockDocSnap = MockDocumentSnapshot();
    mockBatch = MockWriteBatch();
    mockHttpClient = MockHttpClient();

    DbService.db = mockDb;
    DbService.auth = mockAuth;

    // Default mock behavior
    when(() => mockAuth.currentUser).thenReturn(null);
    when(
      () => mockDb.collection(productsCollection),
    ).thenReturn(mockProductsCol);
    when(() => mockDb.collection(reportsCollection)).thenReturn(mockReportsCol);
    when(() => mockDb.collection('users')).thenReturn(mockUsersCol);
    when(() => mockDb.batch()).thenReturn(mockBatch);
    when(() => mockBatch.commit()).thenAnswer((_) async {});
    when(() => mockDocRef.id).thenReturn('mock_id_123');
    when(() => mockDocRef.set(any(), any())).thenAnswer((_) async {});
    when(() => mockDocRef.set(any())).thenAnswer((_) async {});
    when(() => mockDocRef.delete()).thenAnswer((_) async {});
  });

  Product createSampleProduct({
    String barcode = '8001234567890',
    String name = 'Pasta Senza Glutine',
    String lastUpdated = '2026-08-01T12:00:00Z',
  }) {
    return Product(
      barcode: barcode,
      nameMap: {'it': name},
      brandMap: {'it': 'Brand Bio'},
      ingredientsMap: {'it': 'Farina di riso, farina di mais'},
      allergensMap: {'it': <String>[]},
      lastUpdated: lastUpdated,
      pendingReportsCount: 0,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1 – Local Product Cache
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 1 – Local Product Cache', () {
    test('getLocalProducts returns empty list on initial launch', () async {
      final products = await DbService.getLocalProducts();
      expect(products, isEmpty);
    });

    test(
      'saveLocalProducts and getLocalProducts persists and retrieves products',
      () async {
        final p1 = createSampleProduct(barcode: '111', name: 'Biscotti');
        final p2 = createSampleProduct(barcode: '222', name: 'Crackers');

        await DbService.saveLocalProducts([p1, p2]);
        final loaded = await DbService.getLocalProducts();

        expect(loaded.length, 2);
        expect(loaded[0].barcode, '111');
        expect(loaded[1].barcode, '222');
      },
    );

    test(
      'getLocalProductByBarcode returns product if found or null if absent',
      () async {
        final p = createSampleProduct(barcode: '12345');
        await DbService.saveLocalProducts([p]);

        final found = await DbService.getLocalProductByBarcode('12345');
        expect(found?.nameMap['it'], 'Pasta Senza Glutine');

        final notFound = await DbService.getLocalProductByBarcode('99999');
        expect(notFound, isNull);
      },
    );

    test(
      'upsertLocalProduct updates existing item or prepends new item',
      () async {
        final p1 = createSampleProduct(barcode: '111', name: 'Old Name');
        await DbService.saveLocalProducts([p1]);

        // Update existing
        final p1Updated = createSampleProduct(barcode: '111', name: 'New Name');
        await DbService.upsertLocalProduct(p1Updated);

        var list = await DbService.getLocalProducts();
        expect(list.length, 1);
        expect(list.first.nameMap['it'], 'New Name');

        // Insert new
        final p2 = createSampleProduct(barcode: '222', name: 'Snack');
        await DbService.upsertLocalProduct(p2);

        list = await DbService.getLocalProducts();
        expect(list.length, 2);
        expect(list.first.barcode, '222'); // Prepended
      },
    );

    test('getLastSyncTime and saveLastSyncTime persists timestamp', () async {
      expect(await DbService.getLastSyncTime(), isNull);

      const timestamp = '2026-08-20T10:00:00Z';
      await DbService.saveLastSyncTime(timestamp);

      expect(await DbService.getLastSyncTime(), timestamp);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2 – Firestore Delta Sync & Product Lookup
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 2 – Firestore Delta Sync & Product Lookup', () {
    test(
      'performDeltaSync on first launch queries orderBy last_updated limit 100',
      () async {
        final mockQuery = MockQuery();
        final mockSnap = MockQuerySnapshot();
        final mockDoc = MockQueryDocumentSnapshot();

        final p = createSampleProduct(barcode: '100', name: 'Farina');
        when(() => mockDoc.data()).thenReturn(p.toJson());
        when(() => mockSnap.docs).thenReturn([mockDoc]);

        when(
          () => mockProductsCol.orderBy('last_updated', descending: true),
        ).thenReturn(mockQuery);
        when(() => mockQuery.limit(100)).thenReturn(mockQuery);
        when(() => mockQuery.get()).thenAnswer((_) async => mockSnap);

        final result = await DbService.performDeltaSync();

        expect(result.length, 1);
        expect(result.first.barcode, '100');
        expect(await DbService.getLastSyncTime(), isNotNull);
      },
    );

    test(
      'performDeltaSync incremental queries where last_updated is greater than lastSync',
      () async {
        await DbService.saveLastSyncTime('2026-08-01T00:00:00Z');
        await DbService.saveLocalProducts([
          createSampleProduct(barcode: '100', name: 'Existing'),
        ]);

        final mockQuery = MockQuery();
        final mockSnap = MockQuerySnapshot();
        final mockDoc = MockQueryDocumentSnapshot();

        final updatedProd = createSampleProduct(
          barcode: '200',
          name: 'New Remote',
        );
        when(() => mockDoc.data()).thenReturn(updatedProd.toJson());
        when(() => mockSnap.docs).thenReturn([mockDoc]);

        when(
          () => mockProductsCol.where(
            'last_updated',
            isGreaterThan: '2026-08-01T00:00:00Z',
          ),
        ).thenReturn(mockQuery);
        when(() => mockQuery.get()).thenAnswer((_) async => mockSnap);

        final result = await DbService.performDeltaSync();

        expect(result.length, 2);
        expect(result.any((p) => p.barcode == '100'), isTrue);
        expect(result.any((p) => p.barcode == '200'), isTrue);
      },
    );

    test(
      'getProductByBarcode fetches from Firestore, caches locally, and returns product',
      () async {
        final p = createSampleProduct(barcode: '777');
        when(() => mockProductsCol.doc('777')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.exists).thenReturn(true);
        when(() => mockDocSnap.data()).thenReturn(p.toJson());

        final res = await DbService.getProductByBarcode('777');

        expect(res, isNotNull);
        expect(res?.barcode, '777');

        // Verify cached in local storage
        final local = await DbService.getLocalProductByBarcode('777');
        expect(local, isNotNull);
      },
    );

    test('getProductByBarcode returns null when doc does not exist', () async {
      when(() => mockProductsCol.doc('404')).thenReturn(mockDocRef);
      when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
      when(() => mockDocSnap.exists).thenReturn(false);

      final res = await DbService.getProductByBarcode('404');
      expect(res, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3 – Scanning Pipeline (scanBarcodeClientSide)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 3 – Scanning Pipeline (scanBarcodeClientSide)', () {
    final settings = UserSettings(
      strictMode: true,
      alertLactose: false,
      warnAdditives: true,
      autoSaveHistory: true,
      preferredLanguage: 'it',
      preferredTheme: 'system',
    );

    test('returns immediately from local cache if present', () async {
      final p = createSampleProduct(barcode: 'local_1');
      await DbService.saveLocalProducts([p]);

      final result = await DbService.scanBarcodeClientSide('local_1', settings);

      expect(result.barcode, 'local_1');
      final history = await DbService.getHistory();
      expect(history.first.barcode, 'local_1');
    });

    test(
      'fetches from Firestore if absent locally and populates cache',
      () async {
        final p = createSampleProduct(barcode: 'remote_1');
        when(() => mockProductsCol.doc('remote_1')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.exists).thenReturn(true);
        when(() => mockDocSnap.data()).thenReturn(p.toJson());

        final result = await DbService.scanBarcodeClientSide(
          'remote_1',
          settings,
        );

        expect(result.barcode, 'remote_1');
        expect(await DbService.getLocalProductByBarcode('remote_1'), isNotNull);
      },
    );

    test('creates and caches Ghost Product when missing everywhere', () async {
      // 1. Missing in local
      // 2. Missing in Firestore
      when(() => mockProductsCol.doc('ghost_1')).thenReturn(mockDocRef);
      when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
      when(() => mockDocSnap.exists).thenReturn(false);
      when(() => mockDocRef.set(any(), any())).thenAnswer((_) async {});

      // 3. Missing in OFF (mock 404 response via http.runWithClient)
      final result = await http.runWithClient(
        () async {
          return DbService.scanBarcodeClientSide('ghost_1', settings);
        },
        () {
          when(
            () => mockHttpClient.get(any(), headers: any(named: 'headers')),
          ).thenAnswer((_) async => http.Response('{"status":0}', 404));
          return mockHttpClient;
        },
      );

      expect(result.barcode, 'ghost_1');
      expect(result.nameMap, isEmpty);
      expect(result.brandMap, isEmpty);
      expect(result.ingredientsMap, isEmpty);
      expect(await DbService.getLocalProductByBarcode('ghost_1'), isNotNull);
    });

    // ── BUCO 1: Parsing Open Food Facts & _cleanIngredientsText Regex ────────
    test(
      'fetches from Open Food Facts when missing locally and parses dirty ingredients with regex',
      () async {
        when(() => mockProductsCol.doc('off_prod_1')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.exists).thenReturn(false);
        when(() => mockDocRef.set(any(), any())).thenAnswer((_) async {});

        final rawOffJson = {
          "status": 1,
          "product": {
            "_id": "off_prod_1",
            "product_name_it": "Biscotti Rustici",
            "product_name": "Rustic Cookies",
            "brands": "Bio Brand",
            "ingredients_text_it":
                "_Farina di riso_ 50%, {it:zucchero di canna}, (olio di semi (aroma naturale)), sale \$, {unknown}",
            "allergens_tags": ["en:milk"],
            "image_front_url": "https://img.off.org/1.jpg",
          },
        };

        final result = await http.runWithClient(
          () async {
            return DbService.scanBarcodeClientSide('off_prod_1', settings);
          },
          () {
            when(
              () => mockHttpClient.get(any(), headers: any(named: 'headers')),
            ).thenAnswer(
              (_) async => http.Response(
                json.encode(rawOffJson),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              ),
            );
            return mockHttpClient;
          },
        );

        expect(result.barcode, 'off_prod_1');
        expect(result.nameMap['it'], 'Biscotti Rustici');
        expect(result.brandMap['it'], 'Bio Brand');
        expect(result.imageUrl, 'https://img.off.org/1.jpg');

        // Verify regex cleaned the ingredients string
        final cleanedIng = result.ingredientsMap['it']!;
        expect(cleanedIng, contains('Farina di riso 50%'));
        expect(cleanedIng, contains('zucchero di canna'));
        expect(cleanedIng, contains('(olio di semi, aroma naturale)'));
        expect(cleanedIng.contains('_'), isFalse);
        expect(cleanedIng.contains('{'), isFalse);
        expect(cleanedIng.contains('}'), isFalse);
        expect(cleanedIng.contains('\$'), isFalse);

        // Verify allergens mapped and translated
        expect(result.allergensMap['it'], contains('Latte'));

        // Saved in Firestore and in local cache
        verify(() => mockDocRef.set(any(), any())).called(1);
        expect(
          await DbService.getLocalProductByBarcode('off_prod_1'),
          isNotNull,
        );
      },
    );

    test(
      'OFF parsing fallback to generic languages and allergens_from_ingredients',
      () async {
        when(() => mockProductsCol.doc('off_prod_2')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.exists).thenReturn(false);
        when(() => mockDocRef.set(any(), any())).thenAnswer((_) async {});

        final rawOffJson = {
          "status": 1,
          "product": {
            "_id": "off_prod_2",
            "product_name_pl": "Ciastka", // Non standard language
            "brand_tags": ["TestBrand"],
            "ingredients_text_pl":
                "Maka ryzowa, cukier", // Non standard language
            "allergens_from_ingredients": "en:soybeans, en:eggs",
          },
        };

        final result = await http.runWithClient(
          () async {
            return DbService.scanBarcodeClientSide('off_prod_2', settings);
          },
          () {
            when(
              () => mockHttpClient.get(any(), headers: any(named: 'headers')),
            ).thenAnswer(
              (_) async => http.Response(
                json.encode(rawOffJson),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              ),
            );
            return mockHttpClient;
          },
        );

        expect(result.nameMap['en'], 'Ciastka'); // Fallback to en map slot
        expect(result.ingredientsMap['en'], 'Maka ryzowa, cukier');
        expect(result.allergensMap['it'], containsAll(['Soia', 'Uova']));
      },
    );

    test(
      'OFF product with "Senza Glutine" in allergens uploads sanitized product to Firestore and marks ingredients with safe claim',
      () async {
        when(() => mockProductsCol.doc('off_safe_1')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.exists).thenReturn(false);
        when(() => mockDocRef.set(any(), any())).thenAnswer((_) async {});

        final rawOffJson = {
          "status": 1,
          "product": {
            "_id": "off_safe_1",
            "product_name_it": "Biscotti di Mais",
            "ingredients_text_it": "Farina di mais, zucchero, sale",
            "allergens_tags": ["it:senza-glutine", "en:milk"],
          },
        };

        final result = await http.runWithClient(
          () async {
            return DbService.scanBarcodeClientSide('off_safe_1', settings);
          },
          () {
            when(
              () => mockHttpClient.get(any(), headers: any(named: 'headers')),
            ).thenAnswer(
              (_) async => http.Response(
                json.encode(rawOffJson),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              ),
            );
            return mockHttpClient;
          },
        );

        // Verifica che sia stato salvato su Firestore
        verify(() => mockDocRef.set(any(), any())).called(1);

        // Gli allergeni non devono contenere "Senza Glutine", solo "Latte"
        expect(result.allergensMap['it'], ['Latte']);
        expect(result.allergensMap['it']!.contains('Senza Glutine'), isFalse);
        expect(result.allergensMap['it']!.contains('it:senza-glutine'), isFalse);

        // La claim è stata inclusa negli ingredienti per garantire la valutazione sicura
        expect(result.ingredientsMap['it'], contains('Senza glutine'));

        // Valutazione tramite analyzer service risulta Adatto (Verde)
        final analysis = AnalyzerService.analyzeGlutenSafety(
          name: result.nameMap['it']!,
          brand: '',
          ingredients: result.ingredientsMap['it']!,
          allergensList: result.allergensMap['it']!,
          reportCount: 0,
          categoriesTags: [],
        );
        expect(analysis.status, GlutenSafetyStatus.adatto);
      },
    );

    // ── BUCO 3: Aggiornamento silenzioso Cache Stale (> 30 giorni) ───────────
    test(
      'triggers silent background OFF refresh when local product fetchedFromOffAt >= 30 days',
      () async {
        final oldDate = DateTime.now()
            .subtract(const Duration(days: 40))
            .toIso8601String();
        final staleProduct = Product(
          barcode: 'stale_prod_1',
          nameMap: {'it': 'Vecchio Nome'},
          brandMap: {'it': 'Brand'},
          ingredientsMap: {'it': 'Riso'},
          allergensMap: {'it': []},
          lastUpdated: oldDate,
          fetchedFromOffAt: oldDate,
          pendingReportsCount: 0,
        );
        await DbService.saveLocalProducts([staleProduct]);

        when(() => mockProductsCol.doc('stale_prod_1')).thenReturn(mockDocRef);
        when(() => mockDocRef.set(any(), any())).thenAnswer((_) async {});

        final freshOffJson = {
          "status": 1,
          "product": {
            "_id": "stale_prod_1",
            "product_name_it": "Nome Aggiornato",
            "ingredients_text_it": "Riso 100%",
          },
        };

        await http.runWithClient(
          () async {
            // Scansione restituisce immediatamente il prodotto locale
            final result = await DbService.scanBarcodeClientSide(
              'stale_prod_1',
              settings,
            );
            expect(result.nameMap['it'], 'Vecchio Nome');

            // Attendiamo brevemente che il microtask background completi
            await Future.delayed(const Duration(milliseconds: 50));
          },
          () {
            when(
              () => mockHttpClient.get(any(), headers: any(named: 'headers')),
            ).thenAnswer(
              (_) async => http.Response(
                json.encode(freshOffJson),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              ),
            );
            return mockHttpClient;
          },
        );

        // Il background refresh ha aggiornato Firestore e la cache locale
        verify(() => mockDocRef.set(any(), any())).called(1);
        final updatedLocal = await DbService.getLocalProductByBarcode(
          'stale_prod_1',
        );
        expect(updatedLocal?.nameMap['it'], 'Nome Aggiornato');
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4 – History Management
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 4 – History Management', () {
    // ── BUCO 2: Anti-Spam Cronologia (< 10 secondi) ──────────────────────────
    test(
      'suppresses duplicate scan history entries within 10 seconds for same barcode',
      () async {
        final settings = UserSettings(
          strictMode: true,
          alertLactose: false,
          warnAdditives: true,
          autoSaveHistory: true,
          preferredLanguage: 'it',
          preferredTheme: 'system',
        );

        final p = createSampleProduct(barcode: 'SPAM_TEST_1');
        await DbService.saveLocalProducts([p]);

        // Prima scansione
        await DbService.scanBarcodeClientSide('SPAM_TEST_1', settings);
        var history = await DbService.getHistory();
        expect(history.length, 1);

        // Seconda scansione immediata dello stesso barcode -> deve essere ignorata dall'anti-spam (< 10s)
        await DbService.scanBarcodeClientSide('SPAM_TEST_1', settings);
        history = await DbService.getHistory();
        expect(history.length, 1); // Conteggio invariato!

        // Scansione di un ALTRO barcode -> viene aggiunto
        final p2 = createSampleProduct(barcode: 'ANOTHER_BARCODE');
        await DbService.saveLocalProducts([p2]);
        await DbService.scanBarcodeClientSide('ANOTHER_BARCODE', settings);
        history = await DbService.getHistory();
        expect(history.length, 2);
      },
    );

    test('getHistoryPaged handles offset and limit properly', () async {
      final items = List.generate(
        15,
        (i) => ScanHistoryItem(
          id: 'id_$i',
          barcode: 'code_$i',
          scannedAt: DateTime.now().toIso8601String(),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'celiac_history',
        items.map((e) => json.encode(e.toJson())).toList(),
      );

      final page1 = await DbService.getHistoryPaged(offset: 0, limit: 10);
      expect(page1.length, 10);
      expect(page1.first.barcode, 'code_0');

      final page2 = await DbService.getHistoryPaged(offset: 10, limit: 10);
      expect(page2.length, 5);
      expect(page2.first.barcode, 'code_10');

      final pageEmpty = await DbService.getHistoryPaged(offset: 20, limit: 10);
      expect(pageEmpty, isEmpty);
    });

    test(
      'deleteHistoryByBarcodeLocal removes all occurrences of barcode',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final items = [
          ScanHistoryItem(
            id: '1',
            barcode: 'TARGET',
            scannedAt: '2026-01-01T00:00:00Z',
          ),
          ScanHistoryItem(
            id: '2',
            barcode: 'OTHER',
            scannedAt: '2026-01-02T00:00:00Z',
          ),
          ScanHistoryItem(
            id: '3',
            barcode: 'TARGET',
            scannedAt: '2026-01-03T00:00:00Z',
          ),
        ];
        await prefs.setStringList(
          'celiac_history',
          items.map((e) => json.encode(e.toJson())).toList(),
        );

        await DbService.deleteHistoryByBarcodeLocal('TARGET');

        final remaining = await DbService.getHistory();
        expect(remaining.length, 1);
        expect(remaining.first.barcode, 'OTHER');
      },
    );

    test('deleteHistoryItemLocal removes specific item by id', () async {
      final prefs = await SharedPreferences.getInstance();
      final items = [
        ScanHistoryItem(
          id: 'item_1',
          barcode: '111',
          scannedAt: '2026-01-01T00:00:00Z',
        ),
        ScanHistoryItem(
          id: 'item_2',
          barcode: '222',
          scannedAt: '2026-01-02T00:00:00Z',
        ),
      ];
      await prefs.setStringList(
        'celiac_history',
        items.map((e) => json.encode(e.toJson())).toList(),
      );

      await DbService.deleteHistoryItemLocal('item_1');

      final remaining = await DbService.getHistory();
      expect(remaining.length, 1);
      expect(remaining.first.id, 'item_2');
    });

    test(
      'wipeHistoryLocal clears all items and batch deletes Firestore docs when logged in',
      () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.isAnonymous).thenReturn(false);
        when(() => mockUser.uid).thenReturn('user_123');

        final mockUserHistoryCol = MockCollectionReference();
        final mockHistSnap = MockQuerySnapshot();
        final mockHistDoc = MockQueryDocumentSnapshot();

        when(
          () => mockDb.collection('users/user_123/history'),
        ).thenReturn(mockUserHistoryCol);
        when(
          () => mockUserHistoryCol.get(),
        ).thenAnswer((_) async => mockHistSnap);
        when(() => mockHistSnap.docs).thenReturn([mockHistDoc]);
        when(() => mockHistDoc.reference).thenReturn(mockDocRef);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('celiac_history_user_123', ['{}']);

        await DbService.wipeHistoryLocal();

        expect(await DbService.getHistory(), isEmpty);
        verify(() => mockBatch.delete(mockDocRef)).called(1);
        verify(() => mockBatch.commit()).called(1);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5 – Product Reports & Voting
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 5 – Product Reports & Voting', () {
    test(
      'submitProductReportClientSide performs atomic batch write and persists local report',
      () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.isAnonymous).thenReturn(false);
        when(() => mockUser.uid).thenReturn('reporter_1');

        when(() => mockReportsCol.doc(any())).thenReturn(mockDocRef);
        when(() => mockReportsCol.doc()).thenReturn(mockDocRef);
        when(() => mockProductsCol.doc('800111')).thenReturn(mockDocRef);
        when(() => mockUsersCol.doc('reporter_1')).thenReturn(mockDocRef);

        final report = await DbService.submitProductReportClientSide(
          '800111',
          'Biscotti',
          'Brand',
          {'type': 'gluten_detected', 'comments': 'Contiene frumento!'},
        );

        expect(report.barcode, '800111');
        expect(report.type, 'gluten_detected');

        final localReports = await DbService.fetchUserReports();
        expect(localReports.length, 1);
        expect(localReports.first.barcode, '800111');

        verify(() => mockBatch.commit()).called(1);
      },
    );

    test(
      'deleteLocalReport removes report and removes barcode from reported list',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final report = ProductReport(
          id: 'rep_1',
          barcode: 'BARCODE_9',
          productName: 'P',
          brand: 'B',
          type: 't',
          comments: 'c',
          submittedAt: '2026-08-01T00:00:00Z',
          status: 'open',
        );
        await prefs.setStringList('celiac_reports', [
          json.encode(report.toJson()),
        ]);
        await prefs.setStringList('celiac_reported_barcodes', [
          'BARCODE_9',
          'BARCODE_OTHER',
        ]);

        await DbService.deleteLocalReport('rep_1');

        final remainingReports = await DbService.fetchUserReports();
        expect(remainingReports, isEmpty);

        final reportedBarcodes =
            prefs.getStringList('celiac_reported_barcodes') ?? [];
        expect(reportedBarcodes, ['BARCODE_OTHER']);
      },
    );

    test(
      'deleteReportFromDb performs atomic batch delete of report, votes, decrements pending count, and removes from user',
      () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.isAnonymous).thenReturn(false);
        when(() => mockUser.uid).thenReturn('user_del_rep');

        final mockReportDocRef = MockDocumentReference();
        final mockReportSnap = MockDocumentSnapshot();
        final mockVotesCol = MockCollectionReference();
        final mockVotesSnap = MockQuerySnapshot();
        final mockVoteDoc = MockQueryDocumentSnapshot();
        final mockVoteDocRef = MockDocumentReference();

        when(
          () => mockReportsCol.doc('rep_del_123'),
        ).thenReturn(mockReportDocRef);
        when(
          () => mockReportDocRef.get(),
        ).thenAnswer((_) async => mockReportSnap);
        when(() => mockReportSnap.exists).thenReturn(true);
        when(
          () => mockReportSnap.data(),
        ).thenReturn({'barcode': '800BARCODE_DEL'});

        when(
          () => mockReportDocRef.collection('votes'),
        ).thenReturn(mockVotesCol);
        when(() => mockVotesCol.get()).thenAnswer((_) async => mockVotesSnap);
        when(() => mockVotesSnap.docs).thenReturn([mockVoteDoc]);
        when(() => mockVoteDoc.reference).thenReturn(mockVoteDocRef);

        when(
          () => mockProductsCol.doc('800BARCODE_DEL'),
        ).thenReturn(mockDocRef);
        when(() => mockUsersCol.doc('user_del_rep')).thenReturn(mockDocRef);

        await DbService.deleteReportFromDb('rep_del_123');

        // 1. Vote doc deleted
        verify(() => mockBatch.delete(mockVoteDocRef)).called(1);
        // 2. Report doc deleted
        verify(() => mockBatch.delete(mockReportDocRef)).called(1);
        // 3. Product decremented and user reportedBarcodes updated
        verify(
          () => mockBatch.set<Map<String, dynamic>>(any(), any(), any()),
        ).called(2);
        // 4. Batch committed
        verify(() => mockBatch.commit()).called(1);
      },
    );

    test(
      'deleteReportFromDb returns early when report does not exist',
      () async {
        final mockReportDocRef = MockDocumentReference();
        final mockReportSnap = MockDocumentSnapshot();

        when(
          () => mockReportsCol.doc('rep_missing'),
        ).thenReturn(mockReportDocRef);
        when(
          () => mockReportDocRef.get(),
        ).thenAnswer((_) async => mockReportSnap);
        when(() => mockReportSnap.exists).thenReturn(false);

        await DbService.deleteReportFromDb('rep_missing');

        verifyNever(() => mockBatch.commit());
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 6 – User Settings
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 6 – User Settings', () {
    test(
      'getLocalSettings returns default settings when no saved config exists',
      () async {
        final settings = await DbService.getLocalSettings();

        expect(settings.strictMode, isTrue);
        expect(settings.alertLactose, isFalse);
        expect(settings.warnAdditives, isTrue);
        expect(settings.autoSaveHistory, isTrue);
      },
    );

    test(
      'saveSettings writes locally and syncs to Firestore if user is authenticated',
      () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.isAnonymous).thenReturn(false);
        when(() => mockUser.uid).thenReturn('user_pref');

        when(() => mockUsersCol.doc('user_pref')).thenReturn(mockDocRef);

        final customSettings = UserSettings(
          strictMode: false,
          alertLactose: true,
          warnAdditives: false,
          autoSaveHistory: true,
          preferredLanguage: 'en',
          preferredTheme: 'dark',
        );

        await DbService.saveSettings(customSettings);

        final loaded = await DbService.getLocalSettings();
        expect(loaded.strictMode, isFalse);
        expect(loaded.alertLactose, isTrue);
        expect(loaded.preferredTheme, 'dark');

        verify(() => mockDocRef.set(any(), any())).called(1);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 7 – Anonymous Data Migration & Wipe
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 7 – Anonymous Data Migration & Wipe', () {
    test(
      'migrateLocalDataToFirestore migrates history, reports, and reported barcodes',
      () async {
        final prefs = await SharedPreferences.getInstance();

        final fakeHistory = [
          ScanHistoryItem(
            id: 'h1',
            barcode: '111',
            scannedAt: '2026-08-01T00:00:00Z',
          ),
        ];
        final fakeReports = [
          ProductReport(
            id: 'r1',
            barcode: '222',
            productName: 'P',
            brand: 'B',
            type: 't',
            comments: 'c',
            submittedAt: '2026-08-01T00:00:00Z',
            status: 'open',
          ),
        ];

        await prefs.setStringList('celiac_history', [
          json.encode(fakeHistory.first.toJson()),
        ]);
        await prefs.setStringList('celiac_reports', [
          json.encode(fakeReports.first.toJson()),
        ]);
        await prefs.setStringList('celiac_reported_barcodes', ['222']);

        final mockUserHistoryCol = MockCollectionReference();
        when(
          () => mockDb.collection('users/new_user_123/history'),
        ).thenReturn(mockUserHistoryCol);
        when(() => mockUserHistoryCol.doc(any())).thenReturn(mockDocRef);
        when(() => mockReportsCol.doc(any())).thenReturn(mockDocRef);
        when(() => mockUsersCol.doc('new_user_123')).thenReturn(mockDocRef);

        await DbService.migrateLocalDataToFirestore('new_user_123');

        // Anonymous keys wiped
        expect(prefs.getStringList('celiac_history'), isNull);
        expect(prefs.getStringList('celiac_reports'), isNull);
        expect(prefs.getStringList('celiac_reported_barcodes'), isNull);

        // Verify batch commits
        verify(
          () => mockBatch.commit(),
        ).called(2); // 1 for history, 1 for reports
      },
    );

    test('wipeAllLocalData removes all SharedPreferences keys', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('celiac_history', ['{}']);
      await prefs.setStringList('celiac_reports', ['{}']);
      await prefs.setString('celiac_settings', '{}');

      await DbService.wipeAllLocalData();

      expect(prefs.getStringList('celiac_history'), isNull);
      expect(prefs.getStringList('celiac_reports'), isNull);
      expect(prefs.getString('celiac_settings'), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 8 – Terms & Account Deletion Helpers
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 8 – Terms & Account Deletion Helpers', () {
    test(
      'hasAcceptedTerms and saveTermsAccepted manages terms agreement state',
      () async {
        expect(await DbService.hasAcceptedTerms(), isFalse);

        await DbService.saveTermsAccepted();

        expect(await DbService.hasAcceptedTerms(), isTrue);
      },
    );

    test('deleteUserSettings deletes user doc in users collection', () async {
      when(() => mockUsersCol.doc('del_user')).thenReturn(mockDocRef);

      await DbService.deleteUserSettings('del_user');

      verify(() => mockDocRef.delete()).called(1);
    });

    test(
      'deleteUserHistory deletes all docs in user history subcollection',
      () async {
        final mockUserHistoryCol = MockCollectionReference();
        final mockSnap = MockQuerySnapshot();
        final mockDoc = MockQueryDocumentSnapshot();

        when(() => mockUsersCol.doc('user_hist_del')).thenReturn(mockDocRef);
        when(
          () => mockDocRef.collection('history'),
        ).thenReturn(mockUserHistoryCol);
        when(() => mockUserHistoryCol.get()).thenAnswer((_) async => mockSnap);
        when(() => mockSnap.docs).thenReturn([mockDoc]);
        when(() => mockDoc.reference).thenReturn(mockDocRef);

        await DbService.deleteUserHistory('user_hist_del');

        verify(() => mockBatch.delete(mockDocRef)).called(1);
        verify(() => mockBatch.commit()).called(1);
      },
    );

    test(
      'anonymizeUserReports updates reports to userId: deleted and anonymized: true',
      () async {
        final mockQuery = MockQuery();
        final mockSnap = MockQuerySnapshot();
        final mockDoc = MockQueryDocumentSnapshot();

        when(
          () => mockReportsCol.where('userId', isEqualTo: 'user_to_delete'),
        ).thenReturn(mockQuery);
        when(() => mockQuery.get()).thenAnswer((_) async => mockSnap);
        when(() => mockSnap.docs).thenReturn([mockDoc]);
        when(() => mockDoc.reference).thenReturn(mockDocRef);

        await DbService.anonymizeUserReports('user_to_delete');

        verify(
          () => mockBatch.update(mockDocRef, {
            'userId': 'deleted',
            'anonymized': true,
          }),
        ).called(1);
        verify(() => mockBatch.commit()).called(1);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 9 – Voting, Report Sync & Cloud Sync Edge Cases
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 9 – Voting, Report Sync & Cloud Sync Edge Cases', () {
    test(
      'syncHistoryWithFirestore fetches remote history for authenticated user',
      () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.isAnonymous).thenReturn(false);
        when(() => mockUser.uid).thenReturn('sync_user_1');

        final mockUserHistoryCol = MockCollectionReference();
        final mockQuery = MockQuery();
        final mockSnap = MockQuerySnapshot();
        final mockDoc = MockQueryDocumentSnapshot();

        final remoteItem = ScanHistoryItem(
          id: 'rem_1',
          barcode: '888',
          scannedAt: '2026-08-01T00:00:00Z',
        );
        when(() => mockDoc.data()).thenReturn(remoteItem.toJson());
        when(() => mockSnap.docs).thenReturn([mockDoc]);

        when(
          () => mockDb.collection('users/sync_user_1/history'),
        ).thenReturn(mockUserHistoryCol);
        when(
          () => mockUserHistoryCol.orderBy('scannedAt', descending: true),
        ).thenReturn(mockQuery);
        when(() => mockQuery.limit(100)).thenReturn(mockQuery);
        when(() => mockQuery.get()).thenAnswer((_) async => mockSnap);

        final result = await DbService.syncHistoryWithFirestore();

        expect(result.length, 1);
        expect(result.first.barcode, '888');
      },
    );

    test(
      'syncReportsWithFirestore fetches remote reports for authenticated user and sorts descending',
      () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.isAnonymous).thenReturn(false);
        when(() => mockUser.uid).thenReturn('sync_reporter');

        final mockQuery = MockQuery();
        final mockSnap = MockQuerySnapshot();
        final mockDoc1 = MockQueryDocumentSnapshot();
        final mockDoc2 = MockQueryDocumentSnapshot();

        final repOlder = ProductReport(
          id: 'r_old',
          barcode: '111',
          productName: 'P1',
          brand: 'B1',
          type: 't',
          comments: 'c',
          submittedAt: '2026-01-01T00:00:00Z',
          status: 'open',
        );
        final repNewer = ProductReport(
          id: 'r_new',
          barcode: '222',
          productName: 'P2',
          brand: 'B2',
          type: 't',
          comments: 'c',
          submittedAt: '2026-08-01T00:00:00Z',
          status: 'open',
        );

        when(() => mockDoc1.data()).thenReturn(repOlder.toJson());
        when(() => mockDoc2.data()).thenReturn(repNewer.toJson());
        when(() => mockSnap.docs).thenReturn([mockDoc1, mockDoc2]);

        when(
          () => mockReportsCol.where('userId', isEqualTo: 'sync_reporter'),
        ).thenReturn(mockQuery);
        when(() => mockQuery.get()).thenAnswer((_) async => mockSnap);

        final result = await DbService.syncReportsWithFirestore();

        expect(result.length, 2);
        expect(result.first.id, 'r_new'); // Sorted descending
        expect(result.last.id, 'r_old');
      },
    );

    test(
      'voteOnReportByBarcode creates vote and updates report score via batch',
      () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn('voter_1');

        final mockQuery = MockQuery();
        final mockSnap = MockQuerySnapshot();
        final mockReportDoc = MockQueryDocumentSnapshot();
        final mockVotesCol = MockCollectionReference();
        final mockVoteDocRef = MockDocumentReference();
        final mockVoteSnap = MockDocumentSnapshot();

        when(
          () => mockReportsCol.where('barcode', isEqualTo: '800VOTE'),
        ).thenReturn(mockQuery);
        when(
          () => mockQuery.where('status', isEqualTo: 'open'),
        ).thenReturn(mockQuery);
        when(() => mockQuery.limit(1)).thenReturn(mockQuery);
        when(() => mockQuery.get()).thenAnswer((_) async => mockSnap);

        when(() => mockSnap.docs).thenReturn([mockReportDoc]);
        when(() => mockReportDoc.reference).thenReturn(mockDocRef);
        when(() => mockDocRef.collection('votes')).thenReturn(mockVotesCol);
        when(() => mockVotesCol.doc('voter_1')).thenReturn(mockVoteDocRef);
        when(() => mockVoteDocRef.get()).thenAnswer((_) async => mockVoteSnap);
        when(() => mockVoteSnap.exists).thenReturn(false);

        await DbService.voteOnReportByBarcode('800VOTE', 1);

        verify(() => mockBatch.set(mockVoteDocRef, {'val': 1})).called(1);
        verify(() => mockBatch.commit()).called(1);
      },
    );

    test(
      'getReportVoteDataByBarcode retrieves report score and user vote',
      () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn('voter_1');

        final mockQuery = MockQuery();
        final mockSnap = MockQuerySnapshot();
        final mockReportDoc = MockQueryDocumentSnapshot();
        final mockVotesCol = MockCollectionReference();
        final mockVoteDocRef = MockDocumentReference();
        final mockVoteSnap = MockDocumentSnapshot();

        when(
          () => mockReportsCol.where('barcode', isEqualTo: '800VOTE'),
        ).thenReturn(mockQuery);
        when(
          () => mockQuery.where('status', isEqualTo: 'open'),
        ).thenReturn(mockQuery);
        when(() => mockQuery.limit(1)).thenReturn(mockQuery);
        when(() => mockQuery.get()).thenAnswer((_) async => mockSnap);

        when(() => mockSnap.docs).thenReturn([mockReportDoc]);
        when(() => mockReportDoc.data()).thenReturn({'score': 5});
        when(() => mockReportDoc.reference).thenReturn(mockDocRef);
        when(() => mockDocRef.collection('votes')).thenReturn(mockVotesCol);
        when(() => mockVotesCol.doc('voter_1')).thenReturn(mockVoteDocRef);
        when(() => mockVoteDocRef.get()).thenAnswer((_) async => mockVoteSnap);
        when(() => mockVoteSnap.exists).thenReturn(true);
        when(() => mockVoteSnap.data()).thenReturn({'val': 1});

        final voteData = await DbService.getReportVoteDataByBarcode('800VOTE');

        expect(voteData['score'], 5);
        expect(voteData['userVote'], 1);
      },
    );

    test(
      'syncSettingsWithFirestore merges remote and local reported barcodes',
      () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.isAnonymous).thenReturn(false);
        when(() => mockUser.uid).thenReturn('sync_set_user');

        when(() => mockUsersCol.doc('sync_set_user')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.exists).thenReturn(true);

        final remoteSettings = UserSettings(
          userId: 'sync_set_user',
          strictMode: false,
          alertLactose: true,
          warnAdditives: false,
          autoSaveHistory: true,
          preferredLanguage: 'en',
          preferredTheme: 'dark',
          reportedBarcodes: ['REMOTE_1', 'SHARED_BARCODE'],
        );
        when(() => mockDocSnap.data()).thenReturn(remoteSettings.toJson());

        final localSettings = UserSettings(
          strictMode: true,
          alertLactose: false,
          warnAdditives: true,
          autoSaveHistory: true,
          preferredLanguage: 'it',
          preferredTheme: 'light',
          reportedBarcodes: ['LOCAL_1', 'SHARED_BARCODE'],
        );

        final merged = await DbService.syncSettingsWithFirestore(localSettings);

        expect(merged.strictMode, isFalse); // Remote setting taken
        expect(
          merged.reportedBarcodes,
          containsAll(['LOCAL_1', 'REMOTE_1', 'SHARED_BARCODE']),
        );
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 10 – Anonymous Early Returns, Error Handling & Unsynced Wrappers
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 10 – Anonymous Early Returns, Error Handling & Unsynced Wrappers', () {
    test(
      'scanBarcodeClientSide with autoSaveHistory: false does not record history',
      () async {
        final noHistorySettings = UserSettings(
          strictMode: true,
          alertLactose: false,
          warnAdditives: true,
          autoSaveHistory: false, // Disattivato!
          preferredLanguage: 'it',
          preferredTheme: 'system',
        );

        final p = createSampleProduct(barcode: 'NO_HIST_PROD');
        await DbService.saveLocalProducts([p]);

        await DbService.scanBarcodeClientSide(
          'NO_HIST_PROD',
          noHistorySettings,
        );

        final history = await DbService.getHistory();
        expect(history, isEmpty);
      },
    );

    test(
      'getLocalUnsyncedHistory and getLocalUnsyncedReports read anonymous storage keys',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final fakeHistory = [
          ScanHistoryItem(
            id: 'u_h1',
            barcode: '888',
            scannedAt: '2026-08-01T00:00:00Z',
          ),
        ];
        final fakeReports = [
          ProductReport(
            id: 'u_r1',
            barcode: '999',
            productName: 'P',
            brand: 'B',
            type: 't',
            comments: 'c',
            submittedAt: '2026-08-01T00:00:00Z',
            status: 'open',
          ),
        ];

        await prefs.setStringList('celiac_history', [
          json.encode(fakeHistory.first.toJson()),
        ]);
        await prefs.setStringList('celiac_reports', [
          json.encode(fakeReports.first.toJson()),
        ]);

        final unsyncedHist = await DbService.getLocalUnsyncedHistory();
        final unsyncedRep = await DbService.getLocalUnsyncedReports();

        expect(unsyncedHist.length, 1);
        expect(unsyncedHist.first.barcode, '888');
        expect(unsyncedRep.length, 1);
        expect(unsyncedRep.first.barcode, '999');
      },
    );

    test(
      'anonymous users (isAnonymous == true or user == null) return local data immediately without Firestore calls',
      () async {
        // 1. User is anonymous
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.isAnonymous).thenReturn(true);

        final localSettings = UserSettings(
          strictMode: true,
          alertLactose: false,
          warnAdditives: true,
          autoSaveHistory: true,
          preferredLanguage: 'it',
          preferredTheme: 'system',
        );

        // syncSettingsWithFirestore returns localSettings immediately
        final settingsResult = await DbService.syncSettingsWithFirestore(
          localSettings,
        );
        expect(settingsResult, localSettings);

        // syncReportsWithFirestore returns local reports immediately
        final reportsResult = await DbService.syncReportsWithFirestore();
        expect(reportsResult, isEmpty);

        // syncHistoryWithFirestore returns local history immediately
        final historyResult = await DbService.syncHistoryWithFirestore();
        expect(historyResult, isEmpty);

        verifyNever(() => mockUsersCol.doc(any()));
        verifyNever(
          () => mockReportsCol.where(
            'userId',
            isEqualTo: any(named: 'isEqualTo'),
          ),
        );
      },
    );

    test(
      'wipeCurrentUserLocalData delegates cleanly to wipeAllLocalData',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('celiac_history', ['{}']);
        await prefs.setString('celiac_settings', '{}');

        await DbService.wipeCurrentUserLocalData();

        expect(prefs.getStringList('celiac_history'), isNull);
        expect(prefs.getString('celiac_settings'), isNull);
      },
    );

    test(
      'handles Firestore exceptions in deltaSync, getProductByBarcode, and sync methods without crashing',
      () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.isAnonymous).thenReturn(false);
        when(() => mockUser.uid).thenReturn('err_user');

        // 1. getProductByBarcode exception -> returns null
        when(
          () => mockProductsCol.doc('ERR_DOC'),
        ).thenThrow(Exception('Firestore offline'));
        final prodRes = await DbService.getProductByBarcode('ERR_DOC');
        expect(prodRes, isNull);

        // 2. performDeltaSync exception -> returns local products
        when(
          () => mockProductsCol.orderBy('last_updated', descending: true),
        ).thenThrow(Exception('Network timeout'));
        final deltaRes = await DbService.performDeltaSync();
        expect(deltaRes, isEmpty);

        // 3. syncHistoryWithFirestore exception -> returns local history
        when(
          () => mockDb.collection('users/err_user/history'),
        ).thenThrow(Exception('Quota exceeded'));
        final histRes = await DbService.syncHistoryWithFirestore();
        expect(histRes, isEmpty);

        // 4. syncReportsWithFirestore exception -> returns local reports
        when(
          () => mockReportsCol.where('userId', isEqualTo: 'err_user'),
        ).thenThrow(Exception('Permission denied'));
        final repRes = await DbService.syncReportsWithFirestore();
        expect(repRes, isEmpty);

        // 5. syncSettingsWithFirestore exception -> returns local settings
        when(
          () => mockUsersCol.doc('err_user'),
        ).thenThrow(Exception('Server error'));
        final dummySettings = UserSettings(
          strictMode: true,
          alertLactose: false,
          warnAdditives: true,
          autoSaveHistory: true,
          preferredLanguage: 'it',
          preferredTheme: 'system',
        );
        final setRes = await DbService.syncSettingsWithFirestore(dummySettings);
        expect(setRes, dummySettings);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 11 – Firestore Batch Chunking (>450 docs)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 11 – Firestore Batch Chunking (>450 docs)', () {
    /// Builds a list of [count] MockQueryDocumentSnapshot all pointing to mockDocRef.
    List<MockQueryDocumentSnapshot> makeDocs(
      int count,
      MockDocumentReference ref,
    ) {
      return List.generate(count, (_) {
        final d = MockQueryDocumentSnapshot();
        when(() => d.reference).thenReturn(ref);
        return d;
      });
    }

    test(
      'wipeHistoryLocal splits 900 history docs into 2 separate batch commits',
      () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.isAnonymous).thenReturn(false);
        when(() => mockUser.uid).thenReturn('big_user');

        final mockHistCol = MockCollectionReference();
        final mockHistSnap = MockQuerySnapshot();
        final docs = makeDocs(900, mockDocRef);

        when(
          () => mockDb.collection('users/big_user/history'),
        ).thenReturn(mockHistCol);
        when(() => mockHistCol.get()).thenAnswer((_) async => mockHistSnap);
        when(() => mockHistSnap.docs).thenReturn(docs);

        await DbService.wipeHistoryLocal();

        // 900 docs / 450 chunk = 2 batch commits
        verify(() => mockBatch.commit()).called(2);
        // Each of the 900 docs gets exactly one delete op
        verify(() => mockBatch.delete(mockDocRef)).called(900);
      },
    );

    test(
      'deleteUserHistory splits 901 history docs into 3 separate batch commits',
      () async {
        final mockHistCol = MockCollectionReference();
        final mockSnap = MockQuerySnapshot();
        final docs = makeDocs(901, mockDocRef);

        when(() => mockUsersCol.doc('big_hist_user')).thenReturn(mockDocRef);
        when(() => mockDocRef.collection('history')).thenReturn(mockHistCol);
        when(() => mockHistCol.get()).thenAnswer((_) async => mockSnap);
        when(() => mockSnap.docs).thenReturn(docs);

        await DbService.deleteUserHistory('big_hist_user');

        // 901 docs: chunk1=450, chunk2=450, chunk3=1 → 3 commits
        verify(() => mockBatch.commit()).called(3);
        verify(() => mockBatch.delete(mockDocRef)).called(901);
      },
    );

    test(
      'anonymizeUserReports splits 500 reports into 2 separate batch commits',
      () async {
        final mockQuery = MockQuery();
        final mockSnap = MockQuerySnapshot();
        final docs = makeDocs(500, mockDocRef);

        when(
          () => mockReportsCol.where('userId', isEqualTo: 'big_reporter'),
        ).thenReturn(mockQuery);
        when(() => mockQuery.get()).thenAnswer((_) async => mockSnap);
        when(() => mockSnap.docs).thenReturn(docs);

        await DbService.anonymizeUserReports('big_reporter');

        // 500 docs: chunk1=450, chunk2=50 → 2 commits
        verify(() => mockBatch.commit()).called(2);
        verify(
          () => mockBatch.update(mockDocRef, {
            'userId': 'deleted',
            'anonymized': true,
          }),
        ).called(500);
      },
    );
  });
}

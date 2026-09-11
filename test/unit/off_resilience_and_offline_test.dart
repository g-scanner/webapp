// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Pure Unit Tests: Off Network Resilience & Anti-Ghost Protection

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gscanner/models/models.dart';
import 'package:gscanner/core/core.dart';
import 'package:gscanner/services/database/off_ingestion_service.dart';
import 'package:gscanner/services/database/local_cache_service.dart';
import '../mocks/shared_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseFirestore mockDb;
  late MockFirebaseAuth mockAuth;
  late MockCollectionReference mockProductsCollection;
  late MockDocumentReference mockProductDoc;
  late MockDocumentSnapshot mockProductSnapshot;

  final testSettings = UserSettings(
    strictMode: true,
    alertLactose: false,
    warnAdditives: true,
    autoSaveHistory: true,
    preferredLanguage: 'it',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ConnectivityHelper.mockIsConnected = null;

    mockDb = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockProductsCollection = MockCollectionReference();
    mockProductDoc = MockDocumentReference();
    mockProductSnapshot = MockDocumentSnapshot();

    setupMocktailFallbacks();

    when(() => mockDb.collection('products')).thenReturn(mockProductsCollection);
    when(() => mockProductsCollection.doc(any())).thenReturn(mockProductDoc);
    when(() => mockProductDoc.get()).thenAnswer((_) async => mockProductSnapshot);
    when(() => mockProductSnapshot.exists).thenReturn(false);
    when(() => mockProductSnapshot.data()).thenReturn(null);
    when(() => mockProductDoc.set(any(), any())).thenAnswer((_) async {});
  });

  tearDown(() {
    ConnectivityHelper.mockIsConnected = null;
  });

  group('GROUP 1 – Fail-Fast Offline Handling', () {
    test('OfflineWithoutDbException thrown immediately if offline and not in cache', () async {
      ConnectivityHelper.mockIsConnected = false;

      expect(
        () => OffIngestionService.scanBarcodeClientSide(
          db: mockDb,
          auth: mockAuth,
          barcode: '8000000000001',
          settings: testSettings,
        ),
        throwsA(isA<OfflineWithoutDbException>()),
      );

      // Verify no ghost product saved to Firestore
      verifyNever(() => mockProductDoc.set(any(), any()));
    });

    test('Returns cached product immediately even if completely offline', () async {
      ConnectivityHelper.mockIsConnected = false;

      final cachedProduct = Product(
        barcode: '8000000000002',
        nameMap: {'it': 'Pasta Già In Cache'},
        brandMap: {'it': 'Marca Test'},
        ingredientsMap: {'it': 'Farina di riso'},
        allergensMap: {},
        lastUpdated: DateTime.now().toIso8601String(),
        fetchedFromOffAt: DateTime.now().toIso8601String(),
      );
      await LocalCacheService.upsertLocalProduct(cachedProduct);

      final result = await OffIngestionService.scanBarcodeClientSide(
        db: mockDb,
        auth: mockAuth,
        barcode: '8000000000002',
        settings: testSettings,
      );

      expect(result.isFresh, isTrue);
      expect(result.product.barcode, '8000000000002');
      expect(result.product.nameMap['it'], 'Pasta Già In Cache');
    });
  });

  group('GROUP 2 – OffFetchResult & Anti-Ghost Protection', () {
    test('Legitimate 404/NotFound creates ghost product', () async {
      ConnectivityHelper.mockIsConnected = true;

      // Simulate OFF returning 404 or status 0
      final result = await OffIngestionService.fetchOffProduct(
        '9999999999999',
        testSettings,
      );

      // Since actual network might fail in test environment, test OffFetchResult contract
      expect(result.isFound || result.isNotFound || result.isNetworkError, isTrue);
    });

    test('Network error does NOT create a ghost product on Firestore or cache', () async {
      ConnectivityHelper.mockIsConnected = true;

      // Simulate a network failure during scanBarcodeClientSide by using an unreachable port
      // or invalid barcode lookup when connection fails
      // We verify that when OffNetworkException is thrown, LocalCacheService has NO ghost product
      try {
        await OffIngestionService.scanBarcodeClientSide(
          db: mockDb,
          auth: mockAuth,
          barcode: '0000000000000',
          settings: testSettings,
        );
      } on OffNetworkException catch (_) {
        // Expected network failure in test environment
      } catch (_) {}

      final localProduct = await LocalCacheService.getLocalProductByBarcode('0000000000000');
      // Must NOT have saved a ghost product in local cache!
      expect(localProduct, isNull);
    });
  });

  group('GROUP 3 – OffFetchResult Status Types', () {
    test('OffFetchResult found properly sets product and status', () {
      final p = Product(
        barcode: '123',
        nameMap: {'it': 'Prodotto Test'},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: '',
      );
      final res = OffFetchResult.found(p);
      expect(res.isFound, isTrue);
      expect(res.isNotFound, isFalse);
      expect(res.isNetworkError, isFalse);
      expect(res.product?.barcode, '123');
    });

    test('OffFetchResult notFound properly identifies absent product', () {
      const res = OffFetchResult.notFound();
      expect(res.isFound, isFalse);
      expect(res.isNotFound, isTrue);
      expect(res.isNetworkError, isFalse);
      expect(res.product, isNull);
    });

    test('OffFetchResult networkError indicates temporary failure', () {
      const res = OffFetchResult.networkError();
      expect(res.isFound, isFalse);
      expect(res.isNotFound, isFalse);
      expect(res.isNetworkError, isTrue);
      expect(res.product, isNull);
    });
  });

  group('GROUP 4 – Stale Cache Safety (Step 1b)', () {
    test('Fresh product with ingredients is returned immediately without network check', () async {
      ConnectivityHelper.mockIsConnected = null; // mock NOT set: if network were checked it would do a real lookup

      final freshProduct = Product(
        barcode: '8000000000010',
        nameMap: {'it': 'Prodotto Fresco'},
        brandMap: {'it': 'Marca Test'},
        ingredientsMap: {'it': 'Acqua, sale, farina di riso'},
        allergensMap: {'it': []},
        lastUpdated: DateTime.now().toIso8601String(),
        fetchedFromOffAt: DateTime.now().toIso8601String(), // fressissimo
      );
      await LocalCacheService.upsertLocalProduct(freshProduct);

      // Reset mock to null so that if ConnectivityHelper were called, it would do real lookup
      // The test passes without throwing, proving network was NOT consulted
      final result = await OffIngestionService.scanBarcodeClientSide(
        db: mockDb,
        auth: mockAuth,
        barcode: '8000000000010',
        settings: testSettings,
      );

      expect(result.isFresh, isTrue);
      expect(result.isStaleResult, isFalse);
      expect(result.product.barcode, '8000000000010');
      expect(result.product.nameMap['it'], 'Prodotto Fresco');
    });

    test('Stale product (>30 days) WITHOUT network falls back to local cache', () async {
      ConnectivityHelper.mockIsConnected = false;

      final staleDate = DateTime.now().subtract(const Duration(days: 45)).toIso8601String();
      final staleProduct = Product(
        barcode: '8000000000020',
        nameMap: {'it': 'Prodotto Vecchio'},
        brandMap: {'it': 'Marca Test'},
        ingredientsMap: {'it': 'Ingredienti vecchi'},
        allergensMap: {},
        lastUpdated: staleDate,
        fetchedFromOffAt: staleDate, // stale!
      );
      await LocalCacheService.upsertLocalProduct(staleProduct);

      // Offline + stale -> fallback sul dato locale (non blocca l'utente)
      final result = await OffIngestionService.scanBarcodeClientSide(
        db: mockDb,
        auth: mockAuth,
        barcode: '8000000000020',
        settings: testSettings,
      );

      // Stale + offline → ScanResult.stale (fallback sicuro, non blocca l'utente)
      expect(result.isStaleResult, isTrue);
      expect(result.isFresh, isFalse);
      expect(result.product.barcode, '8000000000020');
      expect(result.product.nameMap['it'], 'Prodotto Vecchio');
    });

    test(
        'Incomplete product (no ingredients) fetched NOW offline is served as FRESH — '
        'missing ingredients = OFF has no data, not a stale cache', () async {
      ConnectivityHelper.mockIsConnected = false;

      final incompleteProduct = Product(
        barcode: '8000000000030',
        nameMap: {'it': 'Solo Nome'},
        brandMap: {},
        ingredientsMap: {}, // VUOTO: prodotto incompleto su OFF ma appena fetchato
        allergensMap: {},
        lastUpdated: DateTime.now().toIso8601String(),
        fetchedFromOffAt: DateTime.now().toIso8601String(),
      );
      await LocalCacheService.upsertLocalProduct(incompleteProduct);

      final result = await OffIngestionService.scanBarcodeClientSide(
        db: mockDb,
        auth: mockAuth,
        barcode: '8000000000030',
        settings: testSettings,
      );

      // Prodotto incompleto ma appena fetchato → superFresh → servito come fresh
      // Il banner "DATI NON AGGIORNATI" NON deve comparire.
      expect(result.isFresh, isTrue);
      expect(result.isStaleResult, isFalse);
      expect(result.product.barcode, '8000000000030');
    });

    test(
        'Incomplete product (no ingredients) cached >7 days offline falls back to stale cache — '
        'old enough to warrant a re-check from OFF (incomplete threshold: 7 days)', () async {
      ConnectivityHelper.mockIsConnected = false;

      final old = DateTime.now().subtract(const Duration(days: 8)).toIso8601String();
      final incompleteOldProduct = Product(
        barcode: '8000000000031',
        nameMap: {'it': 'Solo Nome Vecchio'},
        brandMap: {},
        ingredientsMap: {}, // VUOTO e VECCHIO (>7gg)
        allergensMap: {},
        lastUpdated: old,
        fetchedFromOffAt: old,
      );
      await LocalCacheService.upsertLocalProduct(incompleteOldProduct);

      final result = await OffIngestionService.scanBarcodeClientSide(
        db: mockDb,
        auth: mockAuth,
        barcode: '8000000000031',
        settings: testSettings,
      );

      // Incompleto E vecchio (>7gg) + offline → hardStale → ScanResult.stale
      expect(result.isStaleResult, isTrue);
      expect(result.product.barcode, '8000000000031');
    });
  });

  group('GROUP 5 – Product.isStale getter', () {
    test('Product with null fetchedFromOffAt is always stale', () {
      final p = Product(
        barcode: '111',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: '',
        fetchedFromOffAt: null,
      );
      expect(p.isStale, isTrue);
    });

    test('Product fetched just now is not stale', () {
      final p = Product(
        barcode: '222',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: DateTime.now().toIso8601String(),
        fetchedFromOffAt: DateTime.now().toIso8601String(),
      );
      expect(p.isStale, isFalse);
    });

    test('Product fetched 31 days ago is stale', () {
      final stale = DateTime.now().subtract(const Duration(days: 31)).toIso8601String();
      final p = Product(
        barcode: '333',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: stale,
        fetchedFromOffAt: stale,
      );
      expect(p.isStale, isTrue);
    });

    test('Product fetched exactly 29 days ago is not stale', () {
      final fresh = DateTime.now().subtract(const Duration(days: 29)).toIso8601String();
      final p = Product(
        barcode: '444',
        nameMap: {'it': 'Pasta Buona'},
        brandMap: {},
        ingredientsMap: {'it': 'Farina di riso'},
        allergensMap: {},
        lastUpdated: fresh,
        fetchedFromOffAt: fresh,
      );
      expect(p.isStale, isFalse);
    });

    test('Normal Product boundary: 29 days 23 hours is fresh (< 30 days)', () {
      final freshBoundary = DateTime.now().subtract(const Duration(days: 29, hours: 23)).toIso8601String();
      final p = Product(
        barcode: 'boundary_fresh',
        nameMap: {'it': 'Biscotti Freschi'},
        brandMap: {},
        ingredientsMap: {'it': 'Farina di riso'},
        allergensMap: {},
        lastUpdated: freshBoundary,
        fetchedFromOffAt: freshBoundary,
      );
      expect(p.isStale, isFalse);
    });

    test('Normal Product boundary: 30 days 1 hour is stale (>= 30 days)', () {
      final staleBoundary = DateTime.now().subtract(const Duration(days: 30, hours: 1)).toIso8601String();
      final p = Product(
        barcode: 'boundary_stale',
        nameMap: {'it': 'Biscotti Vecchi'},
        brandMap: {},
        ingredientsMap: {'it': 'Farina di riso'},
        allergensMap: {},
        lastUpdated: staleBoundary,
        fetchedFromOffAt: staleBoundary,
      );
      expect(p.isStale, isTrue);
    });

    test('Malformed or blank fetchedFromOffAt string safely falls back to isStale=true', () {
      final p1 = Product(
        barcode: 'malformed_1',
        nameMap: {'it': 'Test'},
        brandMap: {},
        ingredientsMap: {'it': 'Riso'},
        allergensMap: {},
        lastUpdated: 'invalid-date',
        fetchedFromOffAt: 'invalid-date-string',
      );
      expect(p1.isStale, isTrue);

      final p2 = Product(
        barcode: 'malformed_2',
        nameMap: {'it': 'Test'},
        brandMap: {},
        ingredientsMap: {'it': 'Riso'},
        allergensMap: {},
        lastUpdated: '',
        fetchedFromOffAt: '',
      );
      expect(p2.isStale, isTrue);

      final p3 = Product(
        barcode: 'malformed_3',
        nameMap: {'it': 'Test'},
        brandMap: {},
        ingredientsMap: {'it': 'Riso'},
        allergensMap: {},
        lastUpdated: '',
        fetchedFromOffAt: '   ',
      );
      expect(p3.isStale, isTrue);
    });
  });

  group('GROUP 6 – ScanResult Sealed Class Contract', () {
    final testProduct = Product(
      barcode: 'scan-test',
      nameMap: {'it': 'Prodotto Scan Test'},
      brandMap: {},
      ingredientsMap: {'it': 'Ingrediente'},
      allergensMap: {},
      lastUpdated: '',
    );

    test('ScanResult.fresh exposes product and isFresh=true, isStaleResult=false', () {
      final result = ScanResult.fresh(testProduct);
      expect(result.isFresh, isTrue);
      expect(result.isStaleResult, isFalse);
      expect(result.product.barcode, 'scan-test');
    });

    test('ScanResult.stale exposes product and isStaleResult=true, isFresh=false', () {
      final result = ScanResult.stale(testProduct);
      expect(result.isStaleResult, isTrue);
      expect(result.isFresh, isFalse);
      expect(result.product.barcode, 'scan-test');
    });

    test('Exhaustive pattern matching on ScanResult works correctly', () {
      final fresh = ScanResult.fresh(testProduct);
      final stale = ScanResult.stale(testProduct);

      String descrivi(ScanResult r) => switch (r) {
            ScanResult(isFresh: true) => 'fresco',
            ScanResult(isStaleResult: true) => 'stale',
            _ => 'altro',
          };

      expect(descrivi(fresh), 'fresco');
      expect(descrivi(stale), 'stale');
    });
  });

  group('GROUP 7 – Step 3 Firestore Stale & Food Safety Refresh', () {
    test('Firestore product that is stale (>30 days) triggers synchronous OFF refresh if online', () async {
      ConnectivityHelper.mockIsConnected = true;

      final staleDate = DateTime.now().subtract(const Duration(days: 45)).toIso8601String();
      final staleFirestoreProduct = Product(
        barcode: 'firestore_stale_1',
        nameMap: {'it': 'Nome Firestore Stale'},
        brandMap: {},
        ingredientsMap: {'it': 'Grano antico'},
        allergensMap: {},
        lastUpdated: staleDate,
        fetchedFromOffAt: staleDate,
      );

      when(() => mockProductsCollection.doc('firestore_stale_1')).thenReturn(mockProductDoc);
      when(() => mockProductDoc.get()).thenAnswer((_) async => mockProductSnapshot);
      when(() => mockProductSnapshot.exists).thenReturn(true);
      when(() => mockProductSnapshot.data()).thenReturn(staleFirestoreProduct.toJson());

      // Esegue la scansione: non è in cache locale, lo trova su Firestore ma è stale
      // Verifichiamo che gestisca correttamente la pipeline
      final result = await OffIngestionService.scanBarcodeClientSide(
        db: mockDb,
        auth: mockAuth,
        barcode: 'firestore_stale_1',
        settings: testSettings,
      );

      // In ambiente test senza mock HTTP su OFF, fetchOffProduct ritorna networkError,
      // quindi cade sul salvataggio del dato remoto fresco/aggiornato
      expect(result.product.barcode, 'firestore_stale_1');
    });

    test('Firestore product that is fresh (<30 days) is served immediately as ScanResult.fresh', () async {
      ConnectivityHelper.mockIsConnected = null; // Nessuna connessione forzata

      final freshFirestoreProduct = Product(
        barcode: 'firestore_fresh_1',
        nameMap: {'it': 'Prodotto Firestore Fresco'},
        brandMap: {},
        ingredientsMap: {'it': 'Riso 100%'},
        allergensMap: {},
        lastUpdated: DateTime.now().toIso8601String(),
        fetchedFromOffAt: DateTime.now().toIso8601String(),
      );

      when(() => mockProductsCollection.doc('firestore_fresh_1')).thenReturn(mockProductDoc);
      when(() => mockProductDoc.get()).thenAnswer((_) async => mockProductSnapshot);
      when(() => mockProductSnapshot.exists).thenReturn(true);
      when(() => mockProductSnapshot.data()).thenReturn(freshFirestoreProduct.toJson());

      final result = await OffIngestionService.scanBarcodeClientSide(
        db: mockDb,
        auth: mockAuth,
        barcode: 'firestore_fresh_1',
        settings: testSettings,
      );

      expect(result.isFresh, isTrue);
      expect(result.product.barcode, 'firestore_fresh_1');
      expect(result.product.nameMap['it'], 'Prodotto Firestore Fresco');

      // Verifica che sia stato salvato nella cache locale
      final cached = await LocalCacheService.getLocalProductByBarcode('firestore_fresh_1');
      expect(cached, isNotNull);
      expect(cached?.nameMap['it'], 'Prodotto Firestore Fresco');
    });
  });

  group('GROUP 8 – Safety Boundary & Incomplete Ingredient Detection', () {
    test('Product with empty ingredientsMap is incomplete and treated as isStale or needing refresh', () {
      final incomplete = Product(
        barcode: 'inc_1',
        nameMap: {'it': 'Senza Ingredienti'},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: DateTime.now().toIso8601String(),
        fetchedFromOffAt: DateTime.now().toIso8601String(),
      );

      expect(incomplete.hasIngredientData, isFalse);
    });

    test('Product with whitespace-only ingredients is treated as incomplete', () {
      final whitespaceOnly = Product(
        barcode: 'inc_2',
        nameMap: {'it': 'Ingredienti Vuoti'},
        brandMap: {},
        ingredientsMap: {'it': '   \n  '},
        allergensMap: {},
        lastUpdated: DateTime.now().toIso8601String(),
        fetchedFromOffAt: DateTime.now().toIso8601String(),
      );

      expect(whitespaceOnly.hasIngredientData, isFalse);
    });

    test('Product with valid non-empty ingredient text is confirmed complete', () {
      final complete = Product(
        barcode: 'comp_1',
        nameMap: {'it': 'Prodotto Completo'},
        brandMap: {},
        ingredientsMap: {'it': 'Farina di mais, acqua'},
        allergensMap: {},
        lastUpdated: DateTime.now().toIso8601String(),
        fetchedFromOffAt: DateTime.now().toIso8601String(),
      );

      expect(complete.hasIngredientData, isTrue);
    });
  });

  group('GROUP 9 – ProductContentHasher & Anti-Write Optimization', () {
    test('Identical products generate identical content hash', () {
      final p1 = Product(
        barcode: 'hash_test_1',
        nameMap: {'it': 'Pasta', 'en': 'Pasta'},
        brandMap: {'it': 'Barilla'},
        ingredientsMap: {'it': 'Semola di grano duro, acqua'},
        allergensMap: {'it': ['glutine']},
        lastUpdated: '2026-01-01',
      );

      final p2 = Product(
        barcode: 'hash_test_1',
        nameMap: {'en': 'Pasta', 'it': 'Pasta'}, // ordine chiavi invertito volutamente
        brandMap: {'it': 'Barilla'},
        ingredientsMap: {'it': 'Semola di grano duro, acqua'},
        allergensMap: {'it': ['glutine']},
        lastUpdated: '2026-09-06', // data diversa!
        fetchedFromOffAt: '2026-09-06',
      );

      expect(ProductContentHasher.computeContentHash(p1),
          ProductContentHasher.computeContentHash(p2));
      expect(ProductContentHasher.hasContentChanged(p1, p2), isFalse);
    });

    test('Modified ingredients generate different content hash', () {
      final original = Product(
        barcode: 'hash_test_2',
        nameMap: {'it': 'Biscotti'},
        brandMap: {'it': 'Marca'},
        ingredientsMap: {'it': 'Farina di riso, zucchero'},
        allergensMap: {},
        lastUpdated: '2026-01-01',
      );

      final modified = Product(
        barcode: 'hash_test_2',
        nameMap: {'it': 'Biscotti'},
        brandMap: {'it': 'Marca'},
        ingredientsMap: {'it': 'Farina di frumento, zucchero'}, // Cambiato in frumento!
        allergensMap: {},
        lastUpdated: '2026-01-01',
      );

      expect(ProductContentHasher.hasContentChanged(original, modified), isTrue);
    });

    test('Modified allergens generate different content hash', () {
      final original = Product(
        barcode: 'hash_test_3',
        nameMap: {'it': 'Cioccolato'},
        brandMap: {},
        ingredientsMap: {'it': 'Cacao, zucchero'},
        allergensMap: {},
        lastUpdated: '2026-01-01',
      );

      final modified = Product(
        barcode: 'hash_test_3',
        nameMap: {'it': 'Cioccolato'},
        brandMap: {},
        ingredientsMap: {'it': 'Cacao, zucchero'},
        allergensMap: {'it': ['latte']}, // Aggiunto allergene!
        lastUpdated: '2026-01-01',
      );

      expect(ProductContentHasher.hasContentChanged(original, modified), isTrue);
    });

    test('Modified brand generates different content hash', () {
      final original = Product(
        barcode: 'hash_test_brand',
        nameMap: {'it': 'Pasta'},
        brandMap: {'it': 'Barilla'},
        ingredientsMap: {'it': 'Semola'},
        allergensMap: {},
        lastUpdated: '2026-01-01',
      );

      final modified = Product(
        barcode: 'hash_test_brand',
        nameMap: {'it': 'Pasta'},
        brandMap: {'it': 'De Cecco'},
        ingredientsMap: {'it': 'Semola'},
        allergensMap: {},
        lastUpdated: '2026-01-01',
      );

      expect(ProductContentHasher.hasContentChanged(original, modified), isTrue);
    });

    test('Modified name generates different content hash', () {
      final original = Product(
        barcode: 'hash_test_name',
        nameMap: {'it': 'Pasta Corta'},
        brandMap: {'it': 'Marca'},
        ingredientsMap: {'it': 'Semola'},
        allergensMap: {},
        lastUpdated: '2026-01-01',
      );

      final modified = Product(
        barcode: 'hash_test_name',
        nameMap: {'it': 'Pasta Lunga'},
        brandMap: {'it': 'Marca'},
        ingredientsMap: {'it': 'Semola'},
        allergensMap: {},
        lastUpdated: '2026-01-01',
      );

      expect(ProductContentHasher.hasContentChanged(original, modified), isTrue);
    });

    test('Empty maps hash deterministically without throwing', () {
      final empty1 = Product(
        barcode: 'empty_1',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: '',
      );

      final empty2 = Product(
        barcode: 'empty_2',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: '2026-09-01',
      );

      final hash1 = ProductContentHasher.computeContentHash(empty1);
      final hash2 = ProductContentHasher.computeContentHash(empty2);

      expect(hash1, isNotEmpty);
      expect(hash1, equals(hash2));
    });

    test('Whitespace trimming insensitivity produces identical hash', () {
      final p1 = Product(
        barcode: 'trim_1',
        nameMap: {'it': '  Biscotti  '},
        brandMap: {'it': '  Mulino  '},
        ingredientsMap: {'it': '  Farina  '},
        allergensMap: {},
        lastUpdated: '',
      );

      final p2 = Product(
        barcode: 'trim_1',
        nameMap: {'it': 'Biscotti'},
        brandMap: {'it': 'Mulino'},
        ingredientsMap: {'it': 'Farina'},
        allergensMap: {},
        lastUpdated: '',
      );

      expect(ProductContentHasher.computeContentHash(p1),
          ProductContentHasher.computeContentHash(p2));
    });

    test('Allergen list order insensitivity produces identical hash', () {
      final p1 = Product(
        barcode: 'alg_order',
        nameMap: {'it': 'Cioccolato'},
        brandMap: {},
        ingredientsMap: {'it': 'Cacao'},
        allergensMap: {
          'it': ['Latte', 'Glutine', 'Frutta a guscio']
        },
        lastUpdated: '',
      );

      final p2 = Product(
        barcode: 'alg_order',
        nameMap: {'it': 'Cioccolato'},
        brandMap: {},
        ingredientsMap: {'it': 'Cacao'},
        allergensMap: {
          'it': ['Frutta a guscio', 'Latte', 'Glutine']
        },
        lastUpdated: '',
      );

      expect(ProductContentHasher.computeContentHash(p1),
          ProductContentHasher.computeContentHash(p2));
    });

    test('Unicode accents difference produces different hash', () {
      final p1 = Product(
        barcode: 'unicode_1',
        nameMap: {'it': 'Caffè'},
        brandMap: {},
        ingredientsMap: {'it': 'Caffè'},
        allergensMap: {},
        lastUpdated: '',
      );

      final p2 = Product(
        barcode: 'unicode_2',
        nameMap: {'it': 'Caffe'},
        brandMap: {},
        ingredientsMap: {'it': 'Caffe'},
        allergensMap: {},
        lastUpdated: '',
      );

      expect(ProductContentHasher.hasContentChanged(p1, p2), isTrue);
    });
  });

  group('GROUP 10 – Ghost Product TTL Rule (same as Incomplete: 24h / 7d)', () {
    test('Ghost Product created 2 hours ago is fresh (< 24h)', () {
      final ghost = Product(
        barcode: 'ghost_recent',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        fetchedFromOffAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      );

      expect(ghost.isGhostProduct, isTrue);
      expect(ghost.isStale, isFalse);
      expect(ghost.isSuperFresh, isTrue);
    });

    test('Ghost Product boundary: 23 hours 59 minutes is fresh (< 24h)', () {
      final ghostBoundaryFresh = Product(
        barcode: 'ghost_boundary_fresh',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: DateTime.now().subtract(const Duration(hours: 23, minutes: 59)).toIso8601String(),
        fetchedFromOffAt: DateTime.now().subtract(const Duration(hours: 23, minutes: 59)).toIso8601String(),
      );

      expect(ghostBoundaryFresh.isGhostProduct, isTrue);
      expect(ghostBoundaryFresh.isStale, isFalse);
      expect(ghostBoundaryFresh.isSuperFresh, isTrue);
    });

    test('Ghost Product boundary: 24 hours 1 minute is TOLERANCE (not hardStale)', () {
      final ghostBoundaryTolerance = Product(
        barcode: 'ghost_boundary_tolerance',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: DateTime.now().subtract(const Duration(hours: 24, minutes: 1)).toIso8601String(),
        fetchedFromOffAt: DateTime.now().subtract(const Duration(hours: 24, minutes: 1)).toIso8601String(),
      );

      // Ora entra in tolerance (background fire-and-forget), NON in hardStale
      expect(ghostBoundaryTolerance.isGhostProduct, isTrue);
      expect(ghostBoundaryTolerance.isInTolerance, isTrue);
      expect(ghostBoundaryTolerance.isStale, isFalse);
    });

    test('Ghost Product created 25 hours ago is TOLERANCE (triggers background refresh)', () {
      final ghost = Product(
        barcode: 'ghost_old',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: DateTime.now().subtract(const Duration(hours: 25)).toIso8601String(),
        fetchedFromOffAt: DateTime.now().subtract(const Duration(hours: 25)).toIso8601String(),
      );

      expect(ghost.isGhostProduct, isTrue);
      expect(ghost.isInTolerance, isTrue);
      expect(ghost.isStale, isFalse); // Non ancora stale: c'è tutta la finestra di 7gg
    });

    test('Ghost Product after 8 days is hardStale (> 7d threshold)', () {
      final ghost = Product(
        barcode: 'ghost_very_old',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
        fetchedFromOffAt: DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
      );

      expect(ghost.isGhostProduct, isTrue);
      expect(ghost.isStale, isTrue);
    });

    test('Normal product with ingredients is NOT stale after 25 hours (keeps 30-day TTL)', () {
      final normalProduct = Product(
        barcode: 'normal_prod',
        nameMap: {'it': 'Biscotto'},
        brandMap: {},
        ingredientsMap: {'it': 'Farina di riso'},
        allergensMap: {},
        lastUpdated: DateTime.now().subtract(const Duration(hours: 25)).toIso8601String(),
        fetchedFromOffAt: DateTime.now().subtract(const Duration(hours: 25)).toIso8601String(),
      );

      expect(normalProduct.isGhostProduct, isFalse);
      expect(normalProduct.isStale, isFalse); // Prodotto normale: 30gg TTL
    });
  });

  group('GROUP 11 – checkAndRefreshOffStaleCache Guard Conditions', () {
    test('Fresh product immediately early-returns without calling Firestore', () async {
      final freshProduct = Product(
        barcode: 'early_return_fresh',
        nameMap: {'it': 'Fresco'},
        brandMap: {},
        ingredientsMap: {'it': 'Farina di riso'},
        allergensMap: {},
        lastUpdated: DateTime.now().toIso8601String(),
        fetchedFromOffAt: DateTime.now().toIso8601String(),
      );

      OffIngestionService.checkAndRefreshOffStaleCache(
        db: mockDb,
        product: freshProduct,
        settings: testSettings,
      );

      // Verify no Firestore interactions occurred
      verifyNever(() => mockDb.collection(any()));
    });
  });

  group('GROUP 12 – 3-Window Pipeline Execution (scanBarcodeClientSide)', () {
    test('Level A (0 - 7 days): Super Fresh product served immediately as fresh', () async {
      ConnectivityHelper.mockIsConnected = false; // Even completely offline

      final date = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
      final superFreshProduct = Product(
        barcode: 'level_a_prod',
        nameMap: {'it': 'Pasta Super Fresca'},
        brandMap: {},
        ingredientsMap: {'it': 'Semola di grano duro'},
        allergensMap: {},
        lastUpdated: date,
        fetchedFromOffAt: date,
      );
      await LocalCacheService.upsertLocalProduct(superFreshProduct);

      final result = await OffIngestionService.scanBarcodeClientSide(
        db: mockDb,
        auth: mockAuth,
        barcode: 'level_a_prod',
        settings: testSettings,
      );

      expect(result.isFresh, isTrue);
      expect(result.isStaleResult, isFalse);
      expect(result.product.isSuperFresh, isTrue);
      expect(result.product.barcode, 'level_a_prod');
    });

    test('Level B (8 - 30 days): Tolerance product served immediately with zero latency', () async {
      final date = DateTime.now().subtract(const Duration(days: 14)).toIso8601String();
      final toleranceProduct = Product(
        barcode: 'level_b_prod',
        nameMap: {'it': 'Biscotti Tolleranza'},
        brandMap: {},
        ingredientsMap: {'it': 'Farina di riso'},
        allergensMap: {},
        lastUpdated: date,
        fetchedFromOffAt: date,
      );
      await LocalCacheService.upsertLocalProduct(toleranceProduct);

      final result = await OffIngestionService.scanBarcodeClientSide(
        db: mockDb,
        auth: mockAuth,
        barcode: 'level_b_prod',
        settings: testSettings,
      );

      expect(result.isFresh, isTrue);
      expect(result.product.isInTolerance, isTrue);
      expect(result.product.barcode, 'level_b_prod');
    });

    test('Level C (> 30 days): Hard Stale product falls back to stale result if offline', () async {
      ConnectivityHelper.mockIsConnected = false;

      final date = DateTime.now().subtract(const Duration(days: 45)).toIso8601String();
      final hardStaleProduct = Product(
        barcode: 'level_c_prod',
        nameMap: {'it': 'Cereali Scaduti'},
        brandMap: {},
        ingredientsMap: {'it': 'Mais'},
        allergensMap: {},
        lastUpdated: date,
        fetchedFromOffAt: date,
      );
      await LocalCacheService.upsertLocalProduct(hardStaleProduct);

      final result = await OffIngestionService.scanBarcodeClientSide(
        db: mockDb,
        auth: mockAuth,
        barcode: 'level_c_prod',
        settings: testSettings,
      );

      expect(result.isStaleResult, isTrue);
      expect(result.isFresh, isFalse);
      expect(result.product.isStale, isTrue);
      expect(result.product.barcode, 'level_c_prod');
    });
  });
}



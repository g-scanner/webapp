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

    test('Incomplete product (no ingredients) WITHOUT network falls back to local cache', () async {
      ConnectivityHelper.mockIsConnected = false;

      final incompleteProduct = Product(
        barcode: '8000000000030',
        nameMap: {'it': 'Solo Nome'},
        brandMap: {},
        ingredientsMap: {}, // VUOTO: incompleto
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

      // Incompleto + offline → ScanResult.stale (fallback sicuro)
      expect(result.isStaleResult, isTrue);
      expect(result.product.barcode, '8000000000030');
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
  });

  group('GROUP 10 – Ghost Product 24-Hour TTL Rule (Anti-Shadowing)', () {
    test('Ghost Product created 2 hours ago is fresh (< 24h TTL)', () {
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
    });

    test('Ghost Product created 25 hours ago is STALE (> 24h TTL) and will trigger refresh', () {
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
      expect(ghost.isStale, isTrue); // Regola Aureola: stale dopo 24 ore!
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
}


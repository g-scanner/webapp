// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget & Integration Tests: Offline History Flow

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gscanner/models/models.dart';
import 'package:gscanner/features/history/history_list.dart';
import 'package:gscanner/features/product_detail/product_detail_card.dart';
import 'package:gscanner/core/network/connectivity_helper.dart';
import '../mocks/shared_mocks.dart';

class _MockStatusAssetLoader extends AssetLoader {
  const _MockStatusAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return {
      'history': {
        'item': {
          'status': {
            'safe': 'Sicuro - non contiene glutine',
            'unsafe': 'Vietato - contiene glutine',
            'uncertain': 'Incerto - potrebbe contenere glutine',
            'unknown': 'Sconosciuto - informazioni insufficienti',
          },
          'lactose': 'Lattosio',
          'offlineScan': 'Scansione offline',
        },
      },
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UserSettings testSettings() => UserSettings(
    strictMode: false,
    alertLactose: false,
    warnAdditives: false,
    autoSaveHistory: true,
    preferredLanguage: 'it',
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  tearDown(() {
    ConnectivityHelper.mockIsConnected = null;
  });

  group('Product Model Serialization Tests', () {
    test('serializes and deserializes offline and needsVerification flags', () {
      final product = Product(
        barcode: '1234567890123',
        nameMap: {'it': 'Pasta Senza Glutine'},
        brandMap: {'it': 'Marca Test'},
        ingredientsMap: {'it': 'Farina di mais, farina di riso'},
        allergensMap: {},
        lastUpdated: '2026-10-16T12:00:00Z',
        isFromOfflineDb: true,
        isOfflineNotFound: false,
        needsVerification: true,
      );

      final json = product.toJson();
      expect(json['is_from_offline_db'], isTrue);
      expect(json['is_offline_not_found'], isFalse);
      expect(json['needs_verification'], isTrue);

      final deserialized = Product.fromJson(json);
      expect(deserialized.isFromOfflineDb, isTrue);
      expect(deserialized.isOfflineNotFound, isFalse);
      expect(deserialized.needsVerification, isTrue);
    });

    test('serializes and deserializes offlineNotFound flag', () {
      final notFound = Product(
        barcode: '9999999999999',
        nameMap: const {},
        brandMap: const {},
        ingredientsMap: const {},
        allergensMap: const {},
        lastUpdated: '2026-10-16T12:00:00Z',
        isFromOfflineDb: true,
        isOfflineNotFound: true,
        needsVerification: true,
      );

      final json = notFound.toJson();
      expect(json['is_offline_not_found'], isTrue);
      expect(json['needs_verification'], isTrue);

      final deserialized = Product.fromJson(json);
      expect(deserialized.isOfflineNotFound, isTrue);
      expect(deserialized.needsVerification, isTrue);
    });
  });

  group('History Rendering for Offline Products', () {
    testWidgets(
      'renders unknownBrand and sconosciuto for offlineNotFound product',
      (tester) async {
        final notFound = Product(
          barcode: '9999999999999',
          nameMap: const {},
          brandMap: const {},
          ingredientsMap: const {},
          allergensMap: const {},
          lastUpdated: '2026-10-16T12:00:00Z',
          isFromOfflineDb: true,
          isOfflineNotFound: true,
          needsVerification: true,
        );

        final history = [
          ScanHistoryItem(
            id: 'h1',
            barcode: '9999999999999',
            scannedAt: '2026-10-16T12:00:00Z',
          ),
        ];

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: HistoryList(
                history: history,
                liveProducts: [notFound],
                pendingBarcodes: const {},
                onSelectItem: (_) {},
                onClearHistory: () async {},
                onDeleteHistoryItem: (_) async {},
                onRefresh: () async {},
                userSettings: testSettings(),
                isSynced: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('history.item.fallbackName'),
          findsOneWidget,
        );
        expect(find.text('product.status.unknownBrand'), findsOneWidget);
        expect(find.text('history.item.status.unknown'), findsOneWidget);
        expect(find.text('history.item.offlineScan'), findsOneWidget);
      },
    );

    testWidgets(
      'renders real name and offline evaluated status and offlineScan pill for offlineDb product',
      (tester) async {
        final offlineProduct = Product(
          barcode: '1234567890123',
          nameMap: {'it': 'Biscotti Mais'},
          brandMap: {'it': 'BioBrand'},
          ingredientsMap: {'it': 'Farina di mais, zucchero, uova'},
          allergensMap: {
            'it': ['uova'],
          },
          lastUpdated: '2026-10-16T12:00:00Z',
          isFromOfflineDb: true,
          isOfflineNotFound: false,
          needsVerification: true,
        );

        final history = [
          ScanHistoryItem(
            id: 'h2',
            barcode: '1234567890123',
            scannedAt: '2026-10-16T12:00:00Z',
          ),
        ];

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: HistoryList(
                history: history,
                liveProducts: [offlineProduct],
                pendingBarcodes: const {},
                onSelectItem: (_) {},
                onClearHistory: () async {},
                onDeleteHistoryItem: (_) async {},
                onRefresh: () async {},
                userSettings: testSettings(),
                isSynced: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Biscotti Mais'), findsOneWidget);
        expect(find.text('BioBrand'), findsOneWidget);
        expect(find.text('history.item.status.uncertain'), findsOneWidget);
        expect(find.text('history.item.offlineScan'), findsOneWidget);
      },
    );

    testWidgets(
      'does NOT render offlineScan pill for verified online product',
      (tester) async {
        final onlineProduct = Product(
          barcode: '1234567890123',
          nameMap: {'it': 'Biscotti Mais'},
          brandMap: {'it': 'BioBrand'},
          ingredientsMap: {'it': 'Farina di mais, zucchero, uova'},
          allergensMap: {
            'it': ['uova'],
          },
          lastUpdated: '2026-10-16T12:00:00Z',
          isFromOfflineDb: false,
          isOfflineNotFound: false,
          needsVerification: false,
        );

        final history = [
          ScanHistoryItem(
            id: 'h2',
            barcode: '1234567890123',
            scannedAt: '2026-10-16T12:00:00Z',
          ),
        ];

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: HistoryList(
                history: history,
                liveProducts: [onlineProduct],
                pendingBarcodes: const {},
                onSelectItem: (_) {},
                onClearHistory: () async {},
                onDeleteHistoryItem: (_) async {},
                onRefresh: () async {},
                userSettings: testSettings(),
                isSynced: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Biscotti Mais'), findsOneWidget);
        expect(find.text('history.item.offlineScan'), findsNothing);
      },
    );

    testWidgets(
      'truncates status tag text after hyphen when other pills (offline or lactose) are present',
      (tester) async {
        final item = ScanHistoryItem(
          id: 'h_trunc',
          barcode: '123456',
          scannedAt: '2026-10-16T12:00:00Z',
        );

        Widget createCustomTestApp(Widget child) {
          return EasyLocalization(
            supportedLocales: const [Locale('it')],
            path: 'assets/locales',
            assetLoader: const _MockStatusAssetLoader(),
            fallbackLocale: const Locale('it'),
            startLocale: const Locale('it'),
            useOnlyLangCode: true,
            child: Builder(
              builder: (context) {
                return MaterialApp(
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  locale: context.locale,
                  home: Scaffold(body: child),
                );
              },
            ),
          );
        }

        // Caso 1: Solo valutazione glutine (senza altre pillole) -> testo completo
        await tester.pumpWidget(
          createCustomTestApp(
            HistoryItemTile(
              item: item,
              data: AnalyzedItemData(
                productName: 'Biscotti',
                brand: 'Marca',
                status: GlutenSafetyStatus.incerto,
                hasLactose: false,
                isOffline: false,
              ),
              onSelectItem: (_) {},
              onLongPress: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Incerto - potrebbe contenere glutine'), findsOneWidget);

        // Caso 2: Con pillola offline -> testo compatto troncato dopo il trattino ("Incerto")
        await tester.pumpWidget(
          createCustomTestApp(
            HistoryItemTile(
              item: item,
              data: AnalyzedItemData(
                productName: 'Biscotti',
                brand: 'Marca',
                status: GlutenSafetyStatus.incerto,
                hasLactose: false,
                isOffline: true,
              ),
              onSelectItem: (_) {},
              onLongPress: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Incerto'), findsOneWidget);
        expect(find.text('Incerto - potrebbe contenere glutine'), findsNothing);
        expect(find.text('Scansione offline'), findsOneWidget);

        // Caso 3: Con pillola lattosio -> testo compatto troncato ("Vietato")
        await tester.pumpWidget(
          createCustomTestApp(
            HistoryItemTile(
              item: item,
              data: AnalyzedItemData(
                productName: 'Biscotti',
                brand: 'Marca',
                status: GlutenSafetyStatus.nonAdatto,
                hasLactose: true,
                isOffline: false,
              ),
              alertLactose: true,
              onSelectItem: (_) {},
              onLongPress: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Vietato'), findsOneWidget);
        expect(find.text('Vietato - contiene glutine'), findsNothing);
        expect(find.text('Lattosio'), findsOneWidget);
      },
    );
  });

  group('ProductDetailCard Offline Banners & Auto-Refresh Tests', () {
    testWidgets(
      'shows OfflineDatabaseWarningCard when opened from history with isFromOfflineDb: true',
      (tester) async {
        final offlineProduct = Product(
          barcode: '1234567890123',
          nameMap: {'it': 'Biscotti Mais'},
          brandMap: {'it': 'BioBrand'},
          ingredientsMap: {'it': 'Farina di mais'},
          allergensMap: {},
          lastUpdated: '2026-10-16T12:00:00Z',
          isFromOfflineDb: true,
          isOfflineNotFound: false,
          needsVerification: true,
        );

        await tester.pumpWidget(
          createTestApp(
            child: ProductDetailCard(
              product: offlineProduct,
              onBack: () {},
              onReportSubmit: (_, _) async {},
              onProductUpdate: (_) async {},
              userSettings: testSettings(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OfflineDatabaseWarningCard), findsOneWidget);
      },
    );

    testWidgets(
      'shows OfflineNotFoundWarningCard when product isOfflineNotFound: true',
      (tester) async {
        final notFoundProduct = Product(
          barcode: '9999999999999',
          nameMap: const {},
          brandMap: const {},
          ingredientsMap: const {},
          allergensMap: const {},
          lastUpdated: '2026-10-16T12:00:00Z',
          isFromOfflineDb: true,
          isOfflineNotFound: true,
          needsVerification: true,
        );

        await tester.pumpWidget(
          createTestApp(
            child: ProductDetailCard(
              product: notFoundProduct,
              onBack: () {},
              onReportSubmit: (_, _) async {},
              onProductUpdate: (_) async {},
              userSettings: testSettings(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OfflineNotFoundWarningCard), findsOneWidget);
      },
    );

    testWidgets(
      'triggers onRefreshOnline when connectivity is restored for unverified offline product',
      (tester) async {
        ConnectivityHelper.mockIsConnected = false;

        final offlineProduct = Product(
          barcode: '1234567890123',
          nameMap: {'it': 'Biscotti Mais'},
          brandMap: {'it': 'BioBrand'},
          ingredientsMap: {'it': 'Farina di mais'},
          allergensMap: {},
          lastUpdated: '2026-10-16T12:00:00Z',
          isFromOfflineDb: true,
          isOfflineNotFound: false,
          needsVerification: true,
        );

        bool refreshCalled = false;
        String? refreshedBarcode;

        await tester.pumpWidget(
          createTestApp(
            child: ProductDetailCard(
              product: offlineProduct,
              onBack: () {},
              onReportSubmit: (_, _) async {},
              onProductUpdate: (_) async {},
              userSettings: testSettings(),
              onRefreshOnline: (barcode) async {
                refreshCalled = true;
                refreshedBarcode = barcode;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(refreshCalled, isFalse);

        // Connessione ripristinata
        ConnectivityHelper.mockIsConnected = true;

        // Avanza il timer di retry (3 secondi)
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        expect(refreshCalled, isTrue);
        expect(refreshedBarcode, equals('1234567890123'));
      },
    );

    testWidgets(
      'offlineScan pill disappears from history when product gets verified',
      (tester) async {
        final offlineProduct = Product(
          barcode: '1234567890123',
          nameMap: {'it': 'Biscotti Mais'},
          brandMap: {'it': 'BioBrand'},
          ingredientsMap: {'it': 'Farina di mais'},
          allergensMap: {},
          lastUpdated: '2026-10-16T12:00:00Z',
          isFromOfflineDb: true,
          isOfflineNotFound: false,
          needsVerification: true,
        );

        final history = [
          ScanHistoryItem(
            id: 'h1',
            barcode: '1234567890123',
            scannedAt: '2026-10-16T12:00:00Z',
          ),
        ];

        final productsNotifier = ValueNotifier<List<Product>>([offlineProduct]);

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: ValueListenableBuilder<List<Product>>(
                valueListenable: productsNotifier,
                builder: (context, prods, _) => HistoryList(
                  history: history,
                  liveProducts: prods,
                  pendingBarcodes: const {},
                  onSelectItem: (_) {},
                  onClearHistory: () async {},
                  onDeleteHistoryItem: (_) async {},
                  onRefresh: () async {},
                  userSettings: testSettings(),
                  isSynced: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('history.item.offlineScan'), findsOneWidget);

        // Simuliamo la verifica avvenuta online (in-place update da background check)
        final verifiedProduct = Product(
          barcode: '1234567890123',
          nameMap: {'it': 'Biscotti Mais Verificati'},
          brandMap: {'it': 'BioBrand'},
          ingredientsMap: {'it': 'Farina di mais'},
          allergensMap: {},
          lastUpdated: '2026-10-16T12:30:00Z',
          isFromOfflineDb: false,
          isOfflineNotFound: false,
          needsVerification: false,
        );

        productsNotifier.value = [verifiedProduct];
        await tester.pumpAndSettle();

        expect(find.text('history.item.offlineScan'), findsNothing);
        expect(find.text('Biscotti Mais Verificati'), findsOneWidget);
      },
    );
  });
}

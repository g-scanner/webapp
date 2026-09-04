// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget & Business Logic Tests: HistoryList

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gscanner/models/models.dart';
import 'package:gscanner/widgets/history_list.dart';
import '../mocks/shared_mocks.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock Callbacks Class
// ─────────────────────────────────────────────────────────────────────────────

class MockHistoryCallbacks extends Mock {
  void onSelectItem(String barcode);
  Future<void> onClearHistory();
  Future<void> onDeleteHistoryItem(String id);
  Future<void> onRefresh();
}

// ─────────────────────────────────────────────────────────────────────────────
// Test Helpers & Builders
// ─────────────────────────────────────────────────────────────────────────────

Product _createProduct({
  required String barcode,
  String nameIt = 'Prodotto Senza Glutine',
  String nameEn = 'Gluten Free Product',
  String brandIt = 'Marca Buona',
  String ingredientsIt = 'Farina di riso, fecola di patate.',
  List<String> allergensIt = const [],
  int pendingReportsCount = 0,
}) {
  return Product(
    barcode: barcode,
    nameMap: {'it': nameIt, 'en': nameEn},
    brandMap: {'it': brandIt, 'en': brandIt},
    ingredientsMap: {'it': ingredientsIt, 'en': ingredientsIt},
    allergensMap: {'it': allergensIt, 'en': allergensIt},
    lastUpdated: '2026-08-10T12:00:00Z',
    pendingReportsCount: pendingReportsCount,
  );
}

ScanHistoryItem _createHistoryItem({
  required String id,
  required String barcode,
  String scannedAt = '2026-08-10T14:30:00Z',
}) {
  return ScanHistoryItem(
    id: id,
    barcode: barcode,
    scannedAt: scannedAt,
  );
}

UserSettings _createSettings({
  bool strictMode = false,
  bool alertLactose = false,
  bool warnAdditives = false,
  String preferredLanguage = 'it',
  List<String> reportedBarcodes = const [],
}) {
  return UserSettings(
    userId: 'user_test',
    strictMode: strictMode,
    alertLactose: alertLactose,
    warnAdditives: warnAdditives,
    autoSaveHistory: true,
    preferredLanguage: preferredLanguage,
    preferredTheme: 'system',
    reportedBarcodes: reportedBarcodes,
  );
}

Future<void> _pumpHistoryList(
  WidgetTester tester, {
  required MockHistoryCallbacks callbacks,
  required List<ScanHistoryItem> history,
  required List<Product> liveProducts,
  UserSettings? userSettings,
  bool isSynced = true,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final settings = userSettings ?? _createSettings();

  await tester.pumpWidget(
    createTestApp(
      child: Scaffold(
        body: HistoryList(
          history: history,
          liveProducts: liveProducts,
          onSelectItem: (barcode) => callbacks.onSelectItem(barcode),
          onClearHistory: () => callbacks.onClearHistory(),
          onDeleteHistoryItem: (id) => callbacks.onDeleteHistoryItem(id),
          onRefresh: () => callbacks.onRefresh(),
          userSettings: settings,
          isSynced: isSynced,
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHistoryCallbacks mockCallbacks;

  setUpAll(() async {
    setupMocktailFallbacks();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    mockCallbacks = MockHistoryCallbacks();
    when(() => mockCallbacks.onSelectItem(any())).thenReturn(null);
    when(() => mockCallbacks.onClearHistory()).thenAnswer((_) async {});
    when(() => mockCallbacks.onDeleteHistoryItem(any())).thenAnswer((_) async {});
    when(() => mockCallbacks.onRefresh()).thenAnswer((_) async {});
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1: Header & Page Titles
  // ═══════════════════════════════════════════════════════════════════════════
  group('Header & Page Titles', () {
    testWidgets('renders page title and subtitle', (tester) async {
      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: [],
        liveProducts: [],
        isSynced: true,
      );

      expect(find.text('history.title'), findsOneWidget);
      expect(find.text('history.empty.subtitle'), findsWidgets);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2: Bento Grid / Statistics Boxes
  // ═══════════════════════════════════════════════════════════════════════════
  group('Bento Grid / Statistics Boxes', () {
    testWidgets('calculates and displays correct safe, uncertain, unsafe counts',
        (tester) async {
      final prodSafe = _createProduct(
        barcode: '111',
        nameIt: 'Riso Basmati',
        ingredientsIt: 'Riso 100%',
      );
      final prodUnsafe = _createProduct(
        barcode: '222',
        nameIt: 'Biscotti al Frumento',
        ingredientsIt: 'Farina di grano tenero, zucchero.',
      );
      final prodUncertain = _createProduct(
        barcode: '333',
        nameIt: 'Prodotto con Report',
        ingredientsIt: 'Farina di riso',
        pendingReportsCount: 1,
      );

      final history = [
        _createHistoryItem(id: 'h1', barcode: '111'),
        _createHistoryItem(id: 'h2', barcode: '222'),
        _createHistoryItem(id: 'h3', barcode: '333'),
      ];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prodSafe, prodUnsafe, prodUncertain],
        isSynced: true,
      );

      expect(find.text('1'), findsNWidgets(3));
      expect(find.text('history.filters.safe'), findsWidgets);
      expect(find.text('history.filters.uncertain'), findsWidgets);
      expect(find.text('history.filters.unsafe'), findsWidgets);
    });

    testWidgets('Bento grid is hidden when history is empty and synced',
        (tester) async {
      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: [],
        liveProducts: [],
        isSynced: true,
      );

      expect(find.byIcon(Icons.warning_rounded), findsNothing);
    });

    testWidgets('Bento grid shows skeleton when history is empty and NOT synced',
        (tester) async {
      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: [],
        liveProducts: [],
        isSynced: false,
      );

      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
      expect(find.text('0'), findsNWidgets(3));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3: Empty State & Skeleton Loading
  // ═══════════════════════════════════════════════════════════════════════════
  group('Empty State & Skeleton Loading', () {
    testWidgets('shows empty state when history is empty and synced',
        (tester) async {
      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: [],
        liveProducts: [],
        isSynced: true,
      );

      expect(find.text('history.empty.title'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('shows skeleton list when history is empty and NOT synced',
        (tester) async {
      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: [],
        liveProducts: [],
        isSynced: false,
      );

      expect(find.text('history.empty.title'), findsNothing);
    });

    testWidgets('shows empty state when search filter returns 0 matches',
        (tester) async {
      final prod = _createProduct(barcode: '111', nameIt: 'Pasta');
      final history = [_createHistoryItem(id: 'h1', barcode: '111')];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod],
        isSynced: true,
      );

      expect(find.text('Pasta'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Pizza');
      await tester.pump();

      expect(find.text('Pasta'), findsNothing);
      expect(find.text('history.search.noResultsTitle'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4: History Item Card Rendering & Pure-Data Analyzer
  // ═══════════════════════════════════════════════════════════════════════════
  group('History Item Card Rendering', () {
    testWidgets('renders safe product with safe status tag', (tester) async {
      final prod = _createProduct(
        barcode: '111',
        nameIt: 'Riso Scotti',
        brandIt: 'Scotti',
        ingredientsIt: 'Riso 100%',
      );
      final history = [_createHistoryItem(id: 'h1', barcode: '111')];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod],
      );

      expect(find.text('Riso Scotti'), findsOneWidget);
      expect(find.text('Scotti'), findsOneWidget);
      expect(find.text('history.status.safe'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('renders unsafe product with unsafe status tag',
        (tester) async {
      final prod = _createProduct(
        barcode: '222',
        nameIt: 'Biscotti Frumento',
        brandIt: 'Mulino',
        ingredientsIt: 'Farina di frumento',
      );
      final history = [_createHistoryItem(id: 'h2', barcode: '222')];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod],
      );

      expect(find.text('Biscotti Frumento'), findsOneWidget);
      expect(find.text('history.status.unsafe'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });

    testWidgets('renders uncertain product with uncertain status tag',
        (tester) async {
      final prod = _createProduct(
        barcode: '333',
        nameIt: 'Barretta Avena',
        ingredientsIt: 'Avena, zucchero',
      );
      final history = [_createHistoryItem(id: 'h3', barcode: '333')];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod],
      );

      expect(find.text('Barretta Avena'), findsOneWidget);
      expect(find.text('history.status.uncertain'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('renders fallback info when product is not in liveProducts',
        (tester) async {
      final history = [_createHistoryItem(id: 'h9', barcode: '999')];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [],
      );

      expect(find.textContaining('history.loading.productFallbackName'),
          findsOneWidget);
      expect(find.text('history.loading.brandLoading'), findsOneWidget);
      expect(find.text('history.status.unknown'), findsOneWidget);
    });

    testWidgets('renders unknownBrand key when product brand is empty',
        (tester) async {
      final prod = _createProduct(
        barcode: '111',
        nameIt: 'Farina Riso',
        brandIt: '',
      );
      final history = [_createHistoryItem(id: 'h1', barcode: '111')];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod],
      );

      expect(find.text('product.status.unknownBrand'), findsOneWidget);
    });

    testWidgets('renders lactose tag when alertLactose is enabled and item has lactose',
        (tester) async {
      final prod = _createProduct(
        barcode: '111',
        nameIt: 'Yogurt',
        ingredientsIt: 'Latte intero, fermenti lattici.',
        allergensIt: ['latte'],
      );
      final history = [_createHistoryItem(id: 'h1', barcode: '111')];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod],
        userSettings: _createSettings(alertLactose: true),
      );

      expect(find.text('history.lactose'), findsOneWidget);
      expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
    });

    testWidgets('hides lactose tag when alertLactose is disabled',
        (tester) async {
      final prod = _createProduct(
        barcode: '111',
        nameIt: 'Yogurt',
        ingredientsIt: 'Latte intero',
        allergensIt: ['latte'],
      );
      final history = [_createHistoryItem(id: 'h1', barcode: '111')];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod],
        userSettings: _createSettings(alertLactose: false),
      );

      expect(find.text('history.lactose'), findsNothing);
    });

    testWidgets('forces status to uncertain if product has pending reports count > 0',
        (tester) async {
      final prod = _createProduct(
        barcode: '111',
        nameIt: 'Pasta Riso',
        ingredientsIt: 'Farina di riso 100%',
        pendingReportsCount: 2,
      );
      final history = [_createHistoryItem(id: 'h1', barcode: '111')];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod],
      );

      expect(find.text('history.status.uncertain'), findsOneWidget);
    });

    testWidgets('forces status to uncertain if user has reported the barcode',
        (tester) async {
      final prod = _createProduct(
        barcode: '111',
        nameIt: 'Pasta Riso',
        ingredientsIt: 'Farina di riso 100%',
      );
      final history = [_createHistoryItem(id: 'h1', barcode: '111')];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod],
        userSettings: _createSettings(reportedBarcodes: ['111']),
      );

      expect(find.text('history.status.uncertain'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5: Item Selection & Long-Press Deletion
  // ═══════════════════════════════════════════════════════════════════════════
  group('Item Selection & Long-Press Deletion', () {
    testWidgets('tapping an item card calls onSelectItem with barcode',
        (tester) async {
      final prod = _createProduct(barcode: '8001234567890', nameIt: 'Pasta');
      final history = [_createHistoryItem(id: 'h1', barcode: '8001234567890')];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod],
      );

      await tester.tap(find.text('Pasta'));
      await tester.pump();

      verify(() => mockCallbacks.onSelectItem('8001234567890')).called(1);
    });

    testWidgets('long press opens delete confirmation dialog', (tester) async {
      final prod = _createProduct(barcode: '111', nameIt: 'Pasta');
      final history = [_createHistoryItem(id: 'h1', barcode: '111')];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod],
      );

      await tester.longPress(find.text('Pasta'));
      await tester.pumpAndSettle();

      expect(find.text('history.actions.clearAllConfirmTitle'), findsOneWidget);
      expect(find.text('history.actions.clearAllConfirmBody'), findsOneWidget);
      expect(find.text('common.actions.cancel'), findsOneWidget);
      expect(find.text('common.actions.delete'), findsOneWidget);
    });

    testWidgets('cancelling dialog does NOT call onDeleteHistoryItem',
        (tester) async {
      final prod = _createProduct(barcode: '111', nameIt: 'Pasta');
      final history = [_createHistoryItem(id: 'h1', barcode: '111')];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod],
      );

      await tester.longPress(find.text('Pasta'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.actions.cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockCallbacks.onDeleteHistoryItem(any()));
    });

    testWidgets('confirming dialog calls onDeleteHistoryItem with correct item id',
        (tester) async {
      final prod = _createProduct(barcode: '111', nameIt: 'Pasta');
      final history = [_createHistoryItem(id: 'hist_item_abc', barcode: '111')];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod],
      );

      await tester.longPress(find.text('Pasta'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.actions.delete'));
      await tester.pumpAndSettle();

      verify(() => mockCallbacks.onDeleteHistoryItem('hist_item_abc')).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 6: Search Functionality
  // ═══════════════════════════════════════════════════════════════════════════
  group('Search Functionality', () {
    testWidgets('filters history items by product name (case-insensitive)',
        (tester) async {
      final prod1 = _createProduct(barcode: '111', nameIt: 'Pasta Integrale');
      final prod2 = _createProduct(barcode: '222', nameIt: 'Riso Venere');
      final history = [
        _createHistoryItem(id: 'h1', barcode: '111'),
        _createHistoryItem(id: 'h2', barcode: '222'),
      ];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod1, prod2],
      );

      expect(find.text('Pasta Integrale'), findsOneWidget);
      expect(find.text('Riso Venere'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'riso');
      await tester.pump();

      expect(find.text('Pasta Integrale'), findsNothing);
      expect(find.text('Riso Venere'), findsOneWidget);
    });

    testWidgets('filters history items by brand (case-insensitive)',
        (tester) async {
      final prod1 = _createProduct(
        barcode: '111',
        nameIt: 'Biscotti',
        brandIt: 'Barilla',
      );
      final prod2 = _createProduct(
        barcode: '222',
        nameIt: 'Crackers',
        brandIt: 'Galbusera',
      );
      final history = [
        _createHistoryItem(id: 'h1', barcode: '111'),
        _createHistoryItem(id: 'h2', barcode: '222'),
      ];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod1, prod2],
      );

      await tester.enterText(find.byType(TextField), 'galbu');
      await tester.pump();

      expect(find.text('Biscotti'), findsNothing);
      expect(find.text('Crackers'), findsOneWidget);
    });

    testWidgets('filters history items by barcode string match',
        (tester) async {
      final prod1 = _createProduct(barcode: '800111222', nameIt: 'Pasta');
      final prod2 = _createProduct(barcode: '800333444', nameIt: 'Riso');
      final history = [
        _createHistoryItem(id: 'h1', barcode: '800111222'),
        _createHistoryItem(id: 'h2', barcode: '800333444'),
      ];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod1, prod2],
      );

      await tester.enterText(find.byType(TextField), '333444');
      await tester.pump();

      expect(find.text('Pasta'), findsNothing);
      expect(find.text('Riso'), findsOneWidget);
    });

    testWidgets('clear search button appears when focused with text and resets query',
        (tester) async {
      final prod = _createProduct(barcode: '111', nameIt: 'Pasta');
      final history = [_createHistoryItem(id: 'h1', barcode: '111')];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod],
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Some query');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('clearIcon')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('clearIcon')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pasta'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 7: Gluten Safety Status Filter Dropdown
  // ═══════════════════════════════════════════════════════════════════════════
  group('Gluten Safety Status Filter Dropdown', () {
    testWidgets('filtering by safe status shows only safe products',
        (tester) async {
      final prodSafe = _createProduct(
        barcode: '111',
        nameIt: 'Riso Scotti',
        ingredientsIt: 'Riso 100%',
      );
      final prodUnsafe = _createProduct(
        barcode: '222',
        nameIt: 'Pane Frumento',
        ingredientsIt: 'Farina di grano',
      );
      final history = [
        _createHistoryItem(id: 'h1', barcode: '111'),
        _createHistoryItem(id: 'h2', barcode: '222'),
      ];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prodSafe, prodUnsafe],
      );

      expect(find.text('Riso Scotti'), findsOneWidget);
      expect(find.text('Pane Frumento'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<GlutenSafetyStatus?>));
      await tester.pumpAndSettle();

      final safeMenuItem = find.descendant(
        of: find.byType(DropdownMenuItem<GlutenSafetyStatus?>),
        matching: find.text('history.filters.safe'),
      );
      await tester.tap(safeMenuItem.last);
      await tester.pumpAndSettle();

      expect(find.text('Riso Scotti'), findsOneWidget);
      expect(find.text('Pane Frumento'), findsNothing);
    });

    testWidgets('filtering by unsafe status shows only unsafe products',
        (tester) async {
      final prodSafe = _createProduct(
        barcode: '111',
        nameIt: 'Riso Scotti',
        ingredientsIt: 'Riso 100%',
      );
      final prodUnsafe = _createProduct(
        barcode: '222',
        nameIt: 'Pane Frumento',
        ingredientsIt: 'Farina di grano',
      );
      final history = [
        _createHistoryItem(id: 'h1', barcode: '111'),
        _createHistoryItem(id: 'h2', barcode: '222'),
      ];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prodSafe, prodUnsafe],
      );

      await tester.tap(find.byType(DropdownButtonFormField<GlutenSafetyStatus?>));
      await tester.pumpAndSettle();

      final unsafeMenuItem = find.descendant(
        of: find.byType(DropdownMenuItem<GlutenSafetyStatus?>),
        matching: find.text('history.filters.unsafe'),
      );
      await tester.tap(unsafeMenuItem.last);
      await tester.pumpAndSettle();

      expect(find.text('Riso Scotti'), findsNothing);
      expect(find.text('Pane Frumento'), findsOneWidget);
    });

    testWidgets('combining search query and safety filter intersects both',
        (tester) async {
      final prod1 = _createProduct(
        barcode: '111',
        nameIt: 'Pasta Senza Glutine',
        ingredientsIt: 'Riso',
      );
      final prod2 = _createProduct(
        barcode: '222',
        nameIt: 'Pasta Normale',
        ingredientsIt: 'Frumento',
      );
      final prod3 = _createProduct(
        barcode: '333',
        nameIt: 'Riso Basmati',
        ingredientsIt: 'Riso',
      );

      final history = [
        _createHistoryItem(id: 'h1', barcode: '111'),
        _createHistoryItem(id: 'h2', barcode: '222'),
        _createHistoryItem(id: 'h3', barcode: '333'),
      ];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod1, prod2, prod3],
      );

      await tester.enterText(find.byType(TextField), 'Pasta');
      await tester.pump();

      expect(find.text('Pasta Senza Glutine'), findsOneWidget);
      expect(find.text('Pasta Normale'), findsOneWidget);
      expect(find.text('Riso Basmati'), findsNothing);

      await tester.tap(find.byType(DropdownButtonFormField<GlutenSafetyStatus?>));
      await tester.pumpAndSettle();

      final safeMenuItem = find.descendant(
        of: find.byType(DropdownMenuItem<GlutenSafetyStatus?>),
        matching: find.text('history.filters.safe'),
      );
      await tester.tap(safeMenuItem.last);
      await tester.pumpAndSettle();

      expect(find.text('Pasta Senza Glutine'), findsOneWidget);
      expect(find.text('Pasta Normale'), findsNothing);
      expect(find.text('Riso Basmati'), findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 8: Pull to Refresh & Pagination
  // ═══════════════════════════════════════════════════════════════════════════
  group('Pull to Refresh & Pagination', () {
    testWidgets('pull to refresh triggers onRefresh callback', (tester) async {
      final prod = _createProduct(barcode: '111', nameIt: 'Pasta');
      final history = [_createHistoryItem(id: 'h1', barcode: '111')];

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: [prod],
      );

      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      verify(() => mockCallbacks.onRefresh()).called(1);
    });

    testWidgets('paginates and limits initially displayed items to 20',
        (tester) async {
      final history = List.generate(
        25,
        (i) => _createHistoryItem(id: 'h$i', barcode: 'barcode_$i'),
      );
      final products = List.generate(
        25,
        (i) => _createProduct(
          barcode: 'barcode_$i',
          nameIt: 'Prodotto $i',
          ingredientsIt: 'Riso',
        ),
      );

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: products,
      );

      expect(find.text('Prodotto 0'), findsOneWidget);
      expect(find.text('Prodotto 19'), findsOneWidget);
      expect(find.text('Prodotto 20'), findsNothing);
    });

    testWidgets('scrolling to the bottom loads next 20 items (pagination expands to 40)',
        (tester) async {
      final history = List.generate(
        45,
        (i) => _createHistoryItem(id: 'h$i', barcode: 'barcode_$i'),
      );
      final products = List.generate(
        45,
        (i) => _createProduct(
          barcode: 'barcode_$i',
          nameIt: 'Prodotto $i',
          ingredientsIt: 'Riso',
        ),
      );

      await _pumpHistoryList(
        tester,
        callbacks: mockCallbacks,
        history: history,
        liveProducts: products,
      );

      // Initially only first 20 items (0..19)
      expect(find.text('Prodotto 0'), findsOneWidget);
      expect(find.text('Prodotto 19'), findsOneWidget);
      expect(find.text('Prodotto 20'), findsNothing);

      // Scroll down towards bottom to trigger pagination threshold
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1500));
      await tester.pump();

      // Now items up to 39 are rendered in the tree, but item 40 is still pending next page
      expect(find.text('Prodotto 20'), findsOneWidget);
      expect(find.text('Prodotto 39'), findsOneWidget);
      expect(find.text('Prodotto 40'), findsNothing);
    });
  });
}


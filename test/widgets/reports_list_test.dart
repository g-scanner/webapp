// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget & Business Logic Tests: ReportsList

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gscanner/models/models.dart';
import 'package:gscanner/widgets/reports_list.dart';
import 'package:gscanner/widgets/report_detail_card.dart';
import '../mocks/shared_mocks.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock Callbacks Class
// ─────────────────────────────────────────────────────────────────────────────

class MockReportsListCallbacks extends Mock {
  void onSelectItem(String barcode);
  Future<void> onRefresh();
  Future<void> onDeleteReport(String reportId);
}

// ─────────────────────────────────────────────────────────────────────────────
// Test Helpers & Builders
// ─────────────────────────────────────────────────────────────────────────────

Product _createReportedProduct({
  required String barcode,
  String nameIt = 'Prodotto Segnalato',
  String brandIt = 'Marca Test',
  String ingredientsIt = 'Farina di riso',
  List<String> allergensIt = const [],
  int pendingReportsCount = 1,
  String lastUpdated = '2026-08-10T12:00:00Z',
}) {
  return Product(
    barcode: barcode,
    nameMap: {'it': nameIt, 'en': nameIt},
    brandMap: {'it': brandIt, 'en': brandIt},
    ingredientsMap: {'it': ingredientsIt, 'en': ingredientsIt},
    allergensMap: {'it': allergensIt, 'en': allergensIt},
    lastUpdated: lastUpdated,
    pendingReportsCount: pendingReportsCount,
  );
}

ProductReport _createProductReport({
  required String id,
  required String barcode,
  String submittedAt = '2026-08-10T14:00:00Z',
}) {
  return ProductReport(
    id: id,
    barcode: barcode,
    productName: 'Nome Report',
    brand: 'Brand Report',
    type: 'label_unclear',
    comments: 'Commento report',
    submittedAt: submittedAt,
    status: 'open',
  );
}

Future<void> _pumpReportsList(
  WidgetTester tester, {
  required MockReportsListCallbacks callbacks,
  required List<Product> products,
  List<String> reportedBarcodes = const [],
  bool isSynced = true,
  UserSettings? userSettings,
  List<ProductReport>? userReports,
  bool passOnDeleteReport = true,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final settings = userSettings ??
      UserSettings(
        userId: 'user_test',
        strictMode: false,
        alertLactose: false,
        warnAdditives: false,
        autoSaveHistory: true,
        preferredLanguage: 'it',
        preferredTheme: 'system',
        reportedBarcodes: reportedBarcodes,
      );

  await tester.pumpWidget(
    createTestApp(
      child: Scaffold(
        body: ReportsList(
          products: products,
          reportedBarcodes: reportedBarcodes,
          onSelectItem: (barcode) => callbacks.onSelectItem(barcode),
          onRefresh: () => callbacks.onRefresh(),
          isSynced: isSynced,
          userSettings: settings,
          userReports: userReports,
          onDeleteReport:
              passOnDeleteReport ? (id) => callbacks.onDeleteReport(id) : null,
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

  late MockReportsListCallbacks mockCallbacks;

  setUpAll(() async {
    setupMocktailFallbacks();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    mockCallbacks = MockReportsListCallbacks();
    when(() => mockCallbacks.onSelectItem(any())).thenReturn(null);
    when(() => mockCallbacks.onRefresh()).thenAnswer((_) async {});
    when(() => mockCallbacks.onDeleteReport(any())).thenAnswer((_) async {});
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1: Header & Page Titles
  // ═══════════════════════════════════════════════════════════════════════════
  group('Header & Page Titles', () {
    testWidgets('renders page title and subtitle', (tester) async {
      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [],
        isSynced: true,
      );

      expect(find.text('report.listTitle'), findsOneWidget);
      expect(find.text('report.subtitle'), findsOneWidget);
      expect(find.text('report.empty.title'), findsWidgets);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2: Active Reports Summary Card
  // ═══════════════════════════════════════════════════════════════════════════
  group('Active Reports Summary Card', () {
    testWidgets('displays active reports count and label when reports exist',
        (tester) async {
      final p1 = _createReportedProduct(barcode: '111', pendingReportsCount: 2);
      final p2 = _createReportedProduct(barcode: '222', pendingReportsCount: 1);
      final pNormal = _createReportedProduct(
        barcode: '333',
        pendingReportsCount: 0, // not a reported product
      );

      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [p1, p2, pNormal],
        isSynced: true,
      );

      expect(find.text('report.lists.activeReports'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2 reported products
      expect(find.byIcon(Icons.pending_actions), findsOneWidget);
    });

    testWidgets('summary card is hidden when there are no reported products and synced',
        (tester) async {
      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [
          _createReportedProduct(barcode: '111', pendingReportsCount: 0),
        ],
        isSynced: true,
      );

      expect(find.text('report.lists.activeReports'), findsNothing);
      expect(find.byIcon(Icons.pending_actions), findsNothing);
    });

    testWidgets('summary card shows skeleton when empty and NOT synced',
        (tester) async {
      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [],
        isSynced: false, // showSkeleton = true
      );

      expect(find.text('report.lists.activeReports'), findsOneWidget);
      expect(find.text('99'), findsOneWidget); // skeleton placeholder count
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3: Empty State & Skeleton
  // ═══════════════════════════════════════════════════════════════════════════
  group('Empty State & Skeleton', () {
    testWidgets('shows empty state when no products have pending reports',
        (tester) async {
      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [
          _createReportedProduct(barcode: '111', pendingReportsCount: 0),
        ],
        isSynced: true,
      );

      expect(find.byIcon(Icons.task_alt), findsOneWidget);
      expect(find.text('report.empty.title'), findsWidgets);
    });

    testWidgets('shows empty search state when search returns 0 results',
        (tester) async {
      final p1 = _createReportedProduct(barcode: '111', nameIt: 'Pasta Riso');

      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [p1],
        isSynced: true,
      );

      expect(find.text('Pasta Riso'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Pizza');
      await tester.pump();

      expect(find.text('Pasta Riso'), findsNothing);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      expect(find.text('report.search.noResultsTitle'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4: Report Card Content & Sorting
  // ═══════════════════════════════════════════════════════════════════════════
  group('Report Card Content & Sorting', () {
    testWidgets('displays product name, brand, barcode, date and CTA',
        (tester) async {
      final p1 = _createReportedProduct(
        barcode: '8001234567890',
        nameIt: 'Biscotti Senza Glutine',
        brandIt: 'Mulino Buono',
        lastUpdated: '2026-08-15T10:00:00Z',
      );

      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [p1],
        isSynced: true,
      );

      expect(find.text('Biscotti Senza Glutine'), findsOneWidget);
      expect(find.text('Mulino Buono'), findsOneWidget);
      expect(find.text('8001234567890'), findsOneWidget);
      expect(find.text('report.lists.examineDetails'), findsOneWidget);
      expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_2), findsOneWidget);
    });

    testWidgets('sorts reported products by lastUpdated descending',
        (tester) async {
      final pOlder = _createReportedProduct(
        barcode: '111',
        nameIt: 'Prodotto Vecchio',
        lastUpdated: '2026-08-01T10:00:00Z',
      );
      final pNewer = _createReportedProduct(
        barcode: '222',
        nameIt: 'Prodotto Recente',
        lastUpdated: '2026-08-15T10:00:00Z',
      );

      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [pOlder, pNewer],
        isSynced: true,
      );

      // Verify newer item appears first
      final newerFinder = find.text('Prodotto Recente');
      final olderFinder = find.text('Prodotto Vecchio');
      expect(newerFinder, findsOneWidget);
      expect(olderFinder, findsOneWidget);

      final newerY = tester.getTopLeft(newerFinder).dy;
      final olderY = tester.getTopLeft(olderFinder).dy;
      expect(newerY, lessThan(olderY));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5: Search & "Tutte" / "Mie" Filter Dropdown
  // ═══════════════════════════════════════════════════════════════════════════
  group('Search & Report Filter Dropdown', () {
    testWidgets('searches by product name', (tester) async {
      final p1 = _createReportedProduct(barcode: '111', nameIt: 'Pasta Riso');
      final p2 = _createReportedProduct(barcode: '222', nameIt: 'Biscotti Mais');

      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [p1, p2],
        isSynced: true,
      );

      expect(find.text('Pasta Riso'), findsOneWidget);
      expect(find.text('Biscotti Mais'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'biscotti');
      await tester.pump();

      expect(find.text('Pasta Riso'), findsNothing);
      expect(find.text('Biscotti Mais'), findsOneWidget);
    });

    testWidgets('searches by brand', (tester) async {
      final p1 = _createReportedProduct(
        barcode: '111',
        nameIt: 'Pasta',
        brandIt: 'Barilla',
      );
      final p2 = _createReportedProduct(
        barcode: '222',
        nameIt: 'Pane',
        brandIt: 'Schär',
      );

      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [p1, p2],
        isSynced: true,
      );

      await tester.enterText(find.byType(TextField), 'schär');
      await tester.pump();

      expect(find.text('Pasta'), findsNothing);
      expect(find.text('Pane'), findsOneWidget);
    });

    testWidgets('searches by barcode', (tester) async {
      final p1 = _createReportedProduct(barcode: '800111222', nameIt: 'Pasta');
      final p2 = _createReportedProduct(barcode: '800333444', nameIt: 'Pane');

      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [p1, p2],
        isSynced: true,
      );

      await tester.enterText(find.byType(TextField), '333444');
      await tester.pump();

      expect(find.text('Pasta'), findsNothing);
      expect(find.text('Pane'), findsOneWidget);
    });

    testWidgets('clear search button resets query', (tester) async {
      final p1 = _createReportedProduct(barcode: '111', nameIt: 'Pasta');

      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [p1],
        isSynced: true,
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Query');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('clearIcon')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('clearIcon')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pasta'), findsOneWidget);
    });

    testWidgets('filter "Mie" shows only user-reported products',
        (tester) async {
      final pMine = _createReportedProduct(
        barcode: '111',
        nameIt: 'Mia Segnalazione',
      );
      final pOthers = _createReportedProduct(
        barcode: '222',
        nameIt: 'Altra Segnalazione',
      );

      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [pMine, pOthers],
        reportedBarcodes: ['111'], // only '111' is reported by user
        isSynced: true,
      );

      expect(find.text('Mia Segnalazione'), findsOneWidget);
      expect(find.text('Altra Segnalazione'), findsOneWidget);

      // Change dropdown filter to "Mie"
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('report.dropdown.mine').last);
      await tester.pumpAndSettle();

      expect(find.text('Mia Segnalazione'), findsOneWidget);
      expect(find.text('Altra Segnalazione'), findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 6: Navigation to ReportDetailCard on Tap
  // ═══════════════════════════════════════════════════════════════════════════
  group('Navigation on Tap', () {
    testWidgets('tapping card navigates to ReportDetailCard', (tester) async {
      final p1 = _createReportedProduct(
        barcode: '111',
        nameIt: 'Pasta Da Esaminare',
      );
      final report = _createProductReport(id: 'rep_1', barcode: '111');

      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [p1],
        userReports: [report],
        isSynced: true,
      );

      await tester.tap(find.text('Pasta Da Esaminare'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ReportDetailCard), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 7: Long-Press Deletion Flow
  // ═══════════════════════════════════════════════════════════════════════════
  group('Long-Press Deletion Flow', () {
    testWidgets('long press on own report opens delete confirmation dialog',
        (tester) async {
      final p1 = _createReportedProduct(
        barcode: '111',
        nameIt: 'Mio Prodotto Segnalato',
      );
      final report = _createProductReport(id: 'rep_1', barcode: '111');

      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [p1],
        reportedBarcodes: ['111'], // own report
        userReports: [report],
        isSynced: true,
      );

      await tester.longPress(find.text('Mio Prodotto Segnalato'));
      await tester.pumpAndSettle();

      expect(find.text('report.ui.deleteConfirmTitle'), findsOneWidget);
      expect(find.text('report.ui.deleteConfirmBody'), findsOneWidget);
      expect(find.text('common.actions.cancel'), findsOneWidget);
      expect(find.text('common.actions.delete'), findsOneWidget);
    });

    testWidgets('long press on other users report does NOT open dialog',
        (tester) async {
      final p1 = _createReportedProduct(
        barcode: '111',
        nameIt: 'Prodotto di Altri',
      );

      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [p1],
        reportedBarcodes: [], // NOT own report
        isSynced: true,
      );

      await tester.longPress(find.text('Prodotto di Altri'));
      await tester.pumpAndSettle();

      expect(find.text('report.ui.deleteConfirmTitle'), findsNothing);
    });

    testWidgets('cancelling dialog does NOT call onDeleteReport',
        (tester) async {
      final p1 = _createReportedProduct(barcode: '111', nameIt: 'Mio Prodotto');
      final report = _createProductReport(id: 'rep_1', barcode: '111');

      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [p1],
        reportedBarcodes: ['111'],
        userReports: [report],
        isSynced: true,
      );

      await tester.longPress(find.text('Mio Prodotto'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.actions.cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockCallbacks.onDeleteReport(any()));
    });

    testWidgets('confirming dialog calls onDeleteReport with correct report id',
        (tester) async {
      final p1 = _createReportedProduct(barcode: '111', nameIt: 'Mio Prodotto');
      final report = _createProductReport(id: 'rep_999_xyz', barcode: '111');

      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [p1],
        reportedBarcodes: ['111'],
        userReports: [report],
        isSynced: true,
      );

      await tester.longPress(find.text('Mio Prodotto'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.actions.delete'));
      await tester.pumpAndSettle();

      verify(() => mockCallbacks.onDeleteReport('rep_999_xyz')).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 8: Pull to Refresh
  // ═══════════════════════════════════════════════════════════════════════════
  group('Pull to Refresh', () {
    testWidgets('pull to refresh triggers onRefresh callback', (tester) async {
      final p1 = _createReportedProduct(barcode: '111', nameIt: 'Pasta');

      await _pumpReportsList(
        tester,
        callbacks: mockCallbacks,
        products: [p1],
        isSynced: true,
      );

      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      verify(() => mockCallbacks.onRefresh()).called(1);
    });
  });
}

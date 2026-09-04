// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget & Business Logic Tests: ProductDetailCard

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gscanner/models/models.dart';
import 'package:gscanner/features/product_detail/product_detail_card.dart';
import '../mocks/shared_mocks.dart';

class MockCallbacks extends Mock {
  void onBack();
  Future<void> onReportSubmit(String barcode, Map<String, dynamic> reportData);
  Future<void> onProductUpdate(Product updatedProduct);
  Future<void> onDeleteHistoryByBarcode(String barcode);
  Future<void> onDeleteReport(String reportId);
  void onViewReport(Product product);
}

class FakeProduct extends Fake implements Product {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCallbacks mockCallbacks;
  late UserSettings defaultSettings;

  setUpAll(() async {
    setupMocktailFallbacks();
    registerFallbackValue(FakeProduct());
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    mockCallbacks = MockCallbacks();
    defaultSettings = UserSettings(
      userId: 'user_123',
      strictMode: false,
      alertLactose: false,
      warnAdditives: false,
      autoSaveHistory: true,
      preferredLanguage: 'it',
      preferredTheme: 'system',
      reportedBarcodes: [],
    );

    when(() => mockCallbacks.onReportSubmit(any(), any())).thenAnswer((_) async {});
    when(() => mockCallbacks.onProductUpdate(any())).thenAnswer((_) async {});
    when(() => mockCallbacks.onDeleteHistoryByBarcode(any())).thenAnswer((_) async {});
    when(() => mockCallbacks.onDeleteReport(any())).thenAnswer((_) async {});
  });

  Product createSampleProduct({
    String barcode = '8001234567890',
    Map<String, String>? nameMap,
    Map<String, String>? brandMap,
    Map<String, String>? ingredientsMap,
    Map<String, List<String>>? allergensMap,
    int pendingReportsCount = 0,
    String? imageUrl,
    String? lastUpdated,
  }) {
    return Product(
      barcode: barcode,
      nameMap: nameMap ?? {'it': 'Pasta Senza Glutine', 'en': 'Gluten Free Pasta'},
      brandMap: brandMap ?? {'it': 'Marca Buona', 'en': 'Good Brand'},
      ingredientsMap: ingredientsMap ?? {
        'it': 'Farina di riso, farina di mais.',
        'en': 'Rice flour, corn flour.',
      },
      allergensMap: allergensMap ?? {'it': [], 'en': []},
      pendingReportsCount: pendingReportsCount,
      imageUrl: imageUrl,
      lastUpdated: lastUpdated ?? '2026-08-17T12:00:00Z',
    );
  }

  Future<void> pumpProductDetailCard(
    WidgetTester tester, {
    required Product product,
    ValueNotifier<Product?>? productNotifier,
    ValueNotifier<String?>? reportIdNotifier,
    ValueNotifier<bool>? isInHistoryNotifier,
    bool isLoading = false,
    UserSettings? userSettings,
    bool hasReportedThisSession = false,
    String? userReportId,
    bool showReportLink = true,
    bool showScanDate = true,
    String? scannedAt,
    bool passDeleteHistoryCallback = true,
    bool passDeleteReportCallback = true,
    bool passViewReportCallback = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      createTestApp(
        child: ProductDetailCard(
          product: product,
          productNotifier: productNotifier,
          reportIdNotifier: reportIdNotifier,
          isInHistoryNotifier: isInHistoryNotifier,
          isLoading: isLoading,
          onBack: mockCallbacks.onBack,
          onReportSubmit: mockCallbacks.onReportSubmit,
          onProductUpdate: mockCallbacks.onProductUpdate,
          userSettings: userSettings ?? defaultSettings,
          onDeleteHistoryByBarcode:
              passDeleteHistoryCallback ? mockCallbacks.onDeleteHistoryByBarcode : null,
          hasReportedThisSession: hasReportedThisSession,
          userReportId: userReportId,
          onDeleteReport:
              passDeleteReportCallback ? mockCallbacks.onDeleteReport : null,
          showReportLink: showReportLink,
          showScanDate: showScanDate,
          scannedAt: scannedAt,
          onViewReport: passViewReportCallback ? mockCallbacks.onViewReport : null,
        ),
      ),
    );
    if (isLoading) {
      await tester.pump(const Duration(milliseconds: 100));
    } else {
      await tester.pumpAndSettle();
    }
  }

  group('ProductDetailCard Widget & Business Logic Tests', () {
    // ==========================================
    // 1. HEADER & APP BAR NAVIGATION
    // ==========================================
    testWidgets('Header renders title and back button triggers onBack callback',
        (WidgetTester tester) async {
      final product = createSampleProduct();

      await pumpProductDetailCard(tester, product: product);

      expect(find.text('product.titles.scanDetail'), findsOneWidget);

      final backButtonFinder = find.byIcon(Icons.arrow_back_ios_new);
      expect(backButtonFinder, findsOneWidget);
      await tester.tap(backButtonFinder);

      verify(() => mockCallbacks.onBack()).called(1);
    });

    // ==========================================
    // 2. 3-DOTS MENU & HISTORY DELETION
    // ==========================================
    testWidgets('3-Dots menu: delete history dialog flow (cancel vs confirm)',
        (WidgetTester tester) async {
      final product = createSampleProduct(barcode: '8009999999999');

      await pumpProductDetailCard(
        tester,
        product: product,
        isInHistoryNotifier: ValueNotifier<bool>(true),
      );

      final moreVertFinder = find.byIcon(Icons.more_vert);
      expect(moreVertFinder, findsOneWidget);
      await tester.tap(moreVertFinder);
      await tester.pumpAndSettle();

      // Verifica opzione "Elimina dalla cronologia"
      final deleteHistoryItem = find.text('product.deleteHistory.menuLabel');
      expect(deleteHistoryItem, findsOneWidget);
      await tester.tap(deleteHistoryItem);
      await tester.pumpAndSettle();

      // Dialog di conferma presente
      expect(find.text('product.deleteHistory.confirmTitle'), findsOneWidget);
      expect(find.text('product.deleteHistory.confirmBody'), findsOneWidget);

      // Annulla chiude il dialog senza eliminare
      final cancelBtn = find.text('common.actions.cancel');
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();
      verifyNever(() => mockCallbacks.onDeleteHistoryByBarcode(any()));

      // Riapri dialog e conferma eliminazione
      await tester.tap(moreVertFinder);
      await tester.pumpAndSettle();
      await tester.tap(deleteHistoryItem);
      await tester.pumpAndSettle();

      final deleteBtn = find.text('common.actions.delete');
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      verify(() => mockCallbacks.onDeleteHistoryByBarcode('8009999999999')).called(1);
      verify(() => mockCallbacks.onBack()).called(1);
    });

    testWidgets('3-Dots menu: delete report dialog flow triggers onDeleteReport',
        (WidgetTester tester) async {
      final product = createSampleProduct();

      await pumpProductDetailCard(
        tester,
        product: product,
        userReportId: 'report_abc',
        isInHistoryNotifier: ValueNotifier<bool>(false),
      );

      final moreVertFinder = find.byIcon(Icons.more_vert);
      expect(moreVertFinder, findsOneWidget);
      await tester.tap(moreVertFinder);
      await tester.pumpAndSettle();

      final deleteReportItem = find.text('product.deleteReport.menuLabel');
      expect(deleteReportItem, findsOneWidget);
      await tester.tap(deleteReportItem);
      await tester.pumpAndSettle();

      expect(find.text('product.deleteReport.confirmTitle'), findsOneWidget);
      expect(find.text('product.deleteReport.confirmBody'), findsOneWidget);

      final deleteBtn = find.text('common.actions.delete');
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      verify(() => mockCallbacks.onDeleteReport('report_abc')).called(1);
    });

    testWidgets('3-Dots menu: renders and opens when isInHistoryNotifier is null but onDeleteHistoryByBarcode is provided',
        (WidgetTester tester) async {
      final product = createSampleProduct(barcode: '8001234567890');

      await pumpProductDetailCard(
        tester,
        product: product,
        isInHistoryNotifier: null, // null notifier should not block popup menu
      );

      final moreVertFinder = find.byIcon(Icons.more_vert);
      expect(moreVertFinder, findsOneWidget);
      await tester.tap(moreVertFinder);
      await tester.pumpAndSettle();

      expect(find.text('product.deleteHistory.menuLabel'), findsOneWidget);
    });

    // ==========================================
    // 3. GLUTEN SAFETY STATUS EVALUATION
    // ==========================================
    testWidgets('Status Safe: displays safe status banner for gluten-free product',
        (WidgetTester tester) async {
      final safeProduct = createSampleProduct(
        ingredientsMap: {'it': 'Riso 100% senza glutine'},
        allergensMap: {'it': []},
      );

      await pumpProductDetailCard(tester, product: safeProduct);

      expect(find.text('product.bigStatus.safe'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Status Unsafe: displays unsafe status banner for product with gluten ingredients',
        (WidgetTester tester) async {
      final unsafeProduct = createSampleProduct(
        nameMap: {'it': 'Biscotti al Frumento'},
        ingredientsMap: {'it': 'Farina di frumento, zucchero, burro.'},
        allergensMap: {'it': ['frumento', 'glutine']},
      );

      await pumpProductDetailCard(tester, product: unsafeProduct);

      expect(find.text('product.bigStatus.unsafe'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('Status Uncertain: reports elevate status to uncertain with warning banner',
        (WidgetTester tester) async {
      final reportedProduct = createSampleProduct(
        pendingReportsCount: 2,
      );

      await pumpProductDetailCard(tester, product: reportedProduct);

      expect(find.text('product.bigStatus.uncertain'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.text('product.report.goToReport'), findsOneWidget);
    });

    testWidgets('Status Unknown: loading skeleton displays unknown grey status',
        (WidgetTester tester) async {
      final product = createSampleProduct();

      await pumpProductDetailCard(
        tester,
        product: product,
        isLoading: true,
        productNotifier: ValueNotifier<Product?>(null),
      );

      expect(find.text('product.bigStatus.unknown'), findsOneWidget);
      expect(find.byIcon(Icons.help), findsOneWidget);
    });

    // ==========================================
    // 4. LACTOSE ALERT
    // ==========================================
    testWidgets('Lactose alert: displayed when alertLactose is enabled and product has lactose',
        (WidgetTester tester) async {
      final lactoseSettings = UserSettings(
        userId: 'user_123',
        strictMode: false,
        alertLactose: true,
        warnAdditives: false,
        autoSaveHistory: true,
        preferredLanguage: 'it',
        preferredTheme: 'system',
        reportedBarcodes: [],
      );

      final lactoseProduct = createSampleProduct(
        ingredientsMap: {'it': 'Latte intero, farina di riso.'},
        allergensMap: {'it': ['latte']},
      );

      await pumpProductDetailCard(
        tester,
        product: lactoseProduct,
        userSettings: lactoseSettings,
      );

      expect(find.text('product.titles.lactosePresence'), findsOneWidget);
      expect(find.text('product.warnings.lactoseAlertBody'), findsOneWidget);
    });

    testWidgets('Lactose alert: hidden when alertLactose setting is disabled',
        (WidgetTester tester) async {
      final lactoseProduct = createSampleProduct(
        ingredientsMap: {'it': 'Latte intero, farina di riso.'},
        allergensMap: {'it': ['latte']},
      );

      await pumpProductDetailCard(
        tester,
        product: lactoseProduct,
        userSettings: defaultSettings, // alertLactose: false
      );

      expect(find.text('product.titles.lactosePresence'), findsNothing);
    });

    // ==========================================
    // 5. ALLERGENS AND INGREDIENTS EDGE CASES
    // ==========================================
    testWidgets('Allergens: shows insufficientDataLabel for ghost/incomplete products',
        (WidgetTester tester) async {
      final ghostProduct = Product(
        barcode: '123456',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: '2026-08-17T12:00:00Z',
      );

      await pumpProductDetailCard(tester, product: ghostProduct);

      expect(find.text('product.titles.declaredAllergens'), findsOneWidget);
      expect(find.text('product.ingredients.insufficientDataLabel'), findsWidgets);
    });

    testWidgets('Allergens: shows noneLabel when ingredients exist with no declared allergens',
        (WidgetTester tester) async {
      final cleanProduct = createSampleProduct(
        ingredientsMap: {'it': 'Farina di riso, acqua.'},
        allergensMap: {'it': []},
      );

      await pumpProductDetailCard(tester, product: cleanProduct);

      expect(find.text('product.ingredients.noneLabel'), findsOneWidget);
    });

    testWidgets('Allergens: renders individual chips for declared allergens',
        (WidgetTester tester) async {
      final allergenProduct = createSampleProduct(
        allergensMap: {
          'it': ['soia', 'frutta a guscio']
        },
      );

      await pumpProductDetailCard(tester, product: allergenProduct);

      expect(find.text('Soia'), findsOneWidget);
      expect(find.text('Frutta a guscio'), findsOneWidget);
    });

    testWidgets('Allergens: does NOT render chip for "Senza Glutine" or "en:gluten-free" and shows noneLabel when ingredients exist',
        (WidgetTester tester) async {
      final safeGlutenAllergenProduct = createSampleProduct(
        ingredientsMap: {'it': 'Acqua, aromi'},
        allergensMap: {
          'it': ['Senza Glutine', 'it:senza-glutine', 'en:gluten-free']
        },
      );

      await pumpProductDetailCard(tester, product: safeGlutenAllergenProduct);

      expect(find.text('Senza Glutine'), findsNothing);
      expect(find.text('it:senza-glutine'), findsNothing);
      expect(find.text('en:gluten-free'), findsNothing);
      expect(find.text('product.ingredients.noneLabel'), findsOneWidget);
    });

    testWidgets('Allergens: does NOT render chip for "Senza Glutine" but renders real allergens alongside it',
        (WidgetTester tester) async {
      final mixedProduct = createSampleProduct(
        ingredientsMap: {'it': 'Farina di riso, soia, latte'},
        allergensMap: {
          'it': ['Senza Glutine', 'soia', 'en:gluten-free', 'latte']
        },
      );

      await pumpProductDetailCard(tester, product: mixedProduct);

      expect(find.text('Senza Glutine'), findsNothing);
      expect(find.text('en:gluten-free'), findsNothing);
      expect(find.text('Soia'), findsOneWidget);
      expect(find.text('Latte'), findsOneWidget);
    });

    // ==========================================
    // 6. REPORT BOTTOM SHEET FLOW
    // ==========================================
    testWidgets('Report sheet: open, select reason, enter comment, submit',
        (WidgetTester tester) async {
      final product = createSampleProduct(barcode: '8005555555555');

      await pumpProductDetailCard(tester, product: product);

      // Trova e tocca il pulsante "Segnala dati errati o poco chiari"
      final reportBtn = find.text('product.actions.reportError');
      expect(reportBtn, findsOneWidget);
      await tester.ensureVisible(reportBtn);
      await tester.pumpAndSettle();
      await tester.tap(reportBtn);
      await tester.pumpAndSettle();

      // Verifica apertura bottom sheet
      expect(find.text('product.report.communityCallout'), findsOneWidget);
      expect(find.text('product.report.reasonLabel'), findsOneWidget);

      // Inserisci un commento nel TextField
      final commentField = find.byType(TextField);
      expect(commentField, findsOneWidget);
      await tester.enterText(commentField, 'Etichetta non corrispondente al retro');
      await tester.pumpAndSettle();

      // Tap sul pulsante Invia segnalazione
      final submitBtn = find.widgetWithText(FilledButton, 'product.report.submit');
      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verifica che la callback onReportSubmit sia stata invocata con i dati corretti
      verify(() => mockCallbacks.onReportSubmit(
            '8005555555555',
            any(that: isA<Map<String, dynamic>>().having(
              (m) => m['comments'],
              'comments',
              'Etichetta non corrispondente al retro',
            )),
          )).called(1);

      // Dopo l'invio, il bottone diventa disabilitato con "product.actions.alreadyReported"
      expect(find.text('product.actions.alreadyReported'), findsOneWidget);
    });

    // ==========================================
    // 7. REACTIVE NOTIFIERS
    // ==========================================
    testWidgets('Reactivity: productNotifier updates product details in place',
        (WidgetTester tester) async {
      final initialProduct = createSampleProduct(
        nameMap: {'it': 'Nome Iniziale'},
      );
      final productNotifier = ValueNotifier<Product?>(initialProduct);

      await pumpProductDetailCard(
        tester,
        product: initialProduct,
        productNotifier: productNotifier,
      );

      expect(find.text('Nome Iniziale'), findsOneWidget);

      // Aggiorna tramite notifier
      productNotifier.value = createSampleProduct(
        nameMap: {'it': 'Nome Aggiornato'},
      );
      await tester.pumpAndSettle();

      expect(find.text('Nome Aggiornato'), findsOneWidget);
    });

    testWidgets('Reactivity: reportIdNotifier toggles user report state',
        (WidgetTester tester) async {
      final product = createSampleProduct();
      final reportIdNotifier = ValueNotifier<String?>(null);

      await pumpProductDetailCard(
        tester,
        product: product,
        reportIdNotifier: reportIdNotifier,
      );

      expect(find.text('product.actions.reportError'), findsOneWidget);

      // Imposta un report id
      reportIdNotifier.value = 'rep_999';
      await tester.pumpAndSettle();

      expect(find.text('product.actions.alreadyReported'), findsOneWidget);
    });

    // ==========================================
    // 8. VIEW REPORT LINK NAVIGATION
    // ==========================================
    testWidgets('View Report: navigates to report details when tapping report banner link',
        (WidgetTester tester) async {
      final reportedProduct = createSampleProduct(pendingReportsCount: 1);

      await pumpProductDetailCard(
        tester,
        product: reportedProduct,
        showReportLink: true,
      );

      final goToReportBtn = find.text('product.report.goToReport');
      expect(goToReportBtn, findsOneWidget);

      await tester.tap(goToReportBtn);
      await tester.pumpAndSettle();

      verify(() => mockCallbacks.onViewReport(any())).called(1);
    });
  });
}

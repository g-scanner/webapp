// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget & Business Logic Tests: ReportDetailCard

// ignore_for_file: unused_import

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gscanner/models/models.dart';
import 'package:gscanner/widgets/report_detail_card.dart';
import 'package:gscanner/widgets/product_detail_card.dart';
import '../mocks/shared_mocks.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock Callback Class
// ─────────────────────────────────────────────────────────────────────────────

class MockReportCallbacks extends Mock {
  void onBack();
  Future<void> onVote(int direction);
  Future<Map<String, int>> onInitVote();
  Future<void> onDeleteReport(String reportId);
}

// ─────────────────────────────────────────────────────────────────────────────
// Firestore Mock Chain Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Configura Firestore per restituire uno snapshot vuoto (nessun report attivo).
void _stubFirestoreEmptyQuery(MockFirebaseFirestore mockFirestore) {
  final mockCollection = MockCollectionReference();
  final mockQuery1 = MockQuery();
  final mockQuery2 = MockQuery();
  final mockSnapshot = MockQuerySnapshot();

  when(() => mockFirestore.collection('reports')).thenReturn(mockCollection);
  when(() => mockCollection.where('barcode', isEqualTo: any(named: 'isEqualTo')))
      .thenReturn(mockQuery1);
  when(() => mockQuery1.where('status', isEqualTo: any(named: 'isEqualTo')))
      .thenReturn(mockQuery2);
  when(() => mockQuery2.limit(any())).thenReturn(mockQuery2);
  when(() => mockQuery2.get()).thenAnswer((_) async => mockSnapshot);
  when(() => mockSnapshot.docs).thenReturn([]);
}

/// Configura Firestore per restituire UN documento (report attivo).
void _stubFirestoreWithReport(
  MockFirebaseFirestore mockFirestore,
  Map<String, dynamic> reportData,
) {
  final mockCollection = MockCollectionReference();
  final mockQuery1 = MockQuery();
  final mockQuery2 = MockQuery();
  final mockSnapshot = MockQuerySnapshot();
  final mockDocSnap = MockQueryDocumentSnapshot();

  when(() => mockFirestore.collection('reports')).thenReturn(mockCollection);
  when(() => mockCollection.where('barcode', isEqualTo: any(named: 'isEqualTo')))
      .thenReturn(mockQuery1);
  when(() => mockQuery1.where('status', isEqualTo: any(named: 'isEqualTo')))
      .thenReturn(mockQuery2);
  when(() => mockQuery2.limit(any())).thenReturn(mockQuery2);
  when(() => mockQuery2.get()).thenAnswer((_) async => mockSnapshot);
  when(() => mockSnapshot.docs).thenReturn([mockDocSnap]);
  when(() => mockDocSnap.data()).thenReturn(reportData);
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers & Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kBarcode = '8001234567890';
const _kReportId = 'report_id_abc123';

Product _createSampleProduct({
  String barcode = _kBarcode,
  String lastUpdated = '2026-08-10T10:00:00Z',
}) {
  return Product(
    barcode: barcode,
    nameMap: const {'it': 'Pasta Senza Glutine', 'en': 'Gluten Free Pasta'},
    brandMap: const {'it': 'Marca Buona', 'en': 'Good Brand'},
    ingredientsMap: const {'it': 'Farina di riso.'},
    allergensMap: const {'it': []},
    lastUpdated: lastUpdated,
    pendingReportsCount: 1,
  );
}

Future<void> _pumpReportDetailCard(
  WidgetTester tester, {
  required MockReportCallbacks callbacks,
  required MockFirebaseFirestore mockFirestore,
  Product? product,
  GlutenSafetyStatus originalStatus = GlutenSafetyStatus.adatto,
  String reportReasonKey = 'label_unclear',
  String reportComment = 'Etichetta illeggibile',
  String reportDate = '2026-08-10T10:00:00Z',
  int score = 5,
  bool isOwnReport = false,
  String? reportId = _kReportId,
  bool showProductLink = true,
  bool passOnVote = true,
  bool passOnInitVote = true,
  bool passOnDeleteReport = true,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final testProduct = product ?? _createSampleProduct();

  await tester.pumpWidget(
    createTestApp(
      child: ReportDetailCard(
        product: testProduct,
        onBack: callbacks.onBack,
        originalStatus: originalStatus,
        reportReasonKey: reportReasonKey,
        reportComment: reportComment,
        reportDate: reportDate,
        score: score,
        onVote: passOnVote ? (int v) => callbacks.onVote(v) : null,
        onInitVote: passOnInitVote ? () => callbacks.onInitVote() : null,
        isOwnReport: isOwnReport,
        reportId: reportId,
        onDeleteReport: passOnDeleteReport
            ? (String id) => callbacks.onDeleteReport(id)
            : null,
        showProductLink: showProductLink,
        useResponsiveWrapper: false,
        firebaseFirestore: mockFirestore,
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// pumpAndSettle ignorando i RenderFlex overflow (errori cosmétici nel popup menu).
Future<void> _pumpAndSettleIgnoringOverflow(WidgetTester tester) async {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    // Ignora solo gli overflow di layout
    if (details.exceptionAsString().contains('overflowed')) return;
    originalOnError?.call(details);
  };
  await tester.pumpAndSettle();
  FlutterError.onError = originalOnError;
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReportCallbacks mockCallbacks;
  late MockFirebaseFirestore mockFirestore;

  setUpAll(() async {
    setupMocktailFallbacks();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    mockCallbacks = MockReportCallbacks();
    mockFirestore = MockFirebaseFirestore();

    when(() => mockCallbacks.onBack()).thenReturn(null);
    when(() => mockCallbacks.onVote(any())).thenAnswer((_) async {});
    when(() => mockCallbacks.onInitVote()).thenAnswer((_) async => {});
    when(() => mockCallbacks.onDeleteReport(any())).thenAnswer((_) async {});
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1: AppBar & Header
  // ═══════════════════════════════════════════════════════════════════════════
  group('AppBar & Header', () {
    testWidgets('renders AppBar title (report.title key)', (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks, mockFirestore: mockFirestore);
      expect(find.text('report.title'), findsOneWidget);
    });

    testWidgets('back button calls onBack callback', (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks, mockFirestore: mockFirestore);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pump();
      verify(() => mockCallbacks.onBack()).called(1);
    });

    testWidgets('product name displayed in hero section', (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks, mockFirestore: mockFirestore);
      expect(find.text('Pasta Senza Glutine'), findsOneWidget);
    });

    testWidgets('product brand displayed in hero section', (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks, mockFirestore: mockFirestore);
      expect(find.text('Marca Buona'), findsOneWidget);
    });

    testWidgets('product barcode displayed in hero section', (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks, mockFirestore: mockFirestore);
      expect(find.text(_kBarcode), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2: Previous Status Card
  // ═══════════════════════════════════════════════════════════════════════════
  group('Previous Status Card', () {
    testWidgets('shows "product.bigStatus.safe" for adatto', (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          originalStatus: GlutenSafetyStatus.adatto);
      expect(find.text('product.bigStatus.safe'), findsOneWidget);
    });

    testWidgets('shows "product.bigStatus.unsafe" for nonAdatto',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          originalStatus: GlutenSafetyStatus.nonAdatto);
      expect(find.text('product.bigStatus.unsafe'), findsOneWidget);
    });

    testWidgets('shows "product.bigStatus.uncertain" for incerto',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          originalStatus: GlutenSafetyStatus.incerto);
      expect(find.text('product.bigStatus.uncertain'), findsOneWidget);
    });

    testWidgets('shows "product.bigStatus.unknown" for sconosciuto',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          originalStatus: GlutenSafetyStatus.sconosciuto);
      expect(find.text('product.bigStatus.unknown'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3: Report Details Section (reason & comment)
  // ═══════════════════════════════════════════════════════════════════════════

  // Il motivo è dentro un RichText (TextSpan) → usa byWidgetPredicate
  Finder findRichTextContaining(String substring) =>
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains(substring),
      );

  group('Report Details Section', () {
    testWidgets('shows translated reason for "label_unclear"', (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportReasonKey: 'label_unclear');
      expect(findRichTextContaining('report.ui.labelUnclear'),
          findsAtLeastNWidgets(1));
    });

    testWidgets('shows translated reason for "outdated"', (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportReasonKey: 'outdated');
      expect(findRichTextContaining('report.ui.outdated'),
          findsAtLeastNWidgets(1));
    });

    testWidgets('shows translated reason for "incorrect_status"',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportReasonKey: 'incorrect_status');
      expect(findRichTextContaining('report.ui.incorrectStatus'),
          findsAtLeastNWidgets(1));
    });

    testWidgets('shows translated reason for "other"', (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportReasonKey: 'other');
      expect(findRichTextContaining('report.ui.other'),
          findsAtLeastNWidgets(1));
    });

    testWidgets('shows "report.ui.generic" for unknown reason key',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportReasonKey: 'some_unknown_key_xyz');
      expect(findRichTextContaining('report.ui.generic'),
          findsAtLeastNWidgets(1));
    });

    testWidgets('shows user comment in blockquote when non-empty',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportComment: 'Il prodotto non è certificato.');
      expect(find.text('"Il prodotto non è certificato."'), findsOneWidget);
    });

    testWidgets(
        'shows "report.ui.noAdditionalComment" when reportComment is empty',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportComment: '');
      expect(find.text('report.ui.noAdditionalComment'), findsOneWidget);
    });

    testWidgets(
        'shows "report.ui.noAdditionalComment" when reportComment is "Nessun commento"',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportComment: 'Nessun commento');
      expect(find.text('report.ui.noAdditionalComment'), findsOneWidget);
    });

    testWidgets(
        'shows "report.ui.noAdditionalComment" when reportComment is whitespace',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportComment: '   ');
      expect(find.text('report.ui.noAdditionalComment'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4: Report Date Display
  // ═══════════════════════════════════════════════════════════════════════════
  group('Report Date Display', () {
    testWidgets('shows "report.ui.reportDate.today" for today ISO date',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      final now = DateTime.now();
      final todayIso = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T10:30:00Z';
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportDate: todayIso);
      expect(find.textContaining('report.ui.reportDate.today'), findsOneWidget);
    });

    testWidgets('shows "report.ui.reportDate.yesterday" for yesterday',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final iso = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}T08:00:00Z';
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportDate: iso);
      expect(find.textContaining('report.ui.reportDate.yesterday'), findsOneWidget);
    });

    testWidgets('shows "report.ui.reportDate.default" for older dates',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportDate: '2024-01-15T14:30:00Z');
      expect(find.textContaining('report.ui.reportDate.default'), findsOneWidget);
    });

    testWidgets('falls back to raw string if date is malformed', (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportDate: 'not-a-valid-date');
      expect(find.text('not-a-valid-date'), findsOneWidget);
    });

    testWidgets('shows nothing when reportDate and lastUpdated are both empty',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      final productNoDate = _createSampleProduct(lastUpdated: '');
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          product: productNoDate,
          reportDate: '');
      expect(find.textContaining('report.ui.reportDate'), findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5: Voting System
  // ═══════════════════════════════════════════════════════════════════════════
  group('Voting System', () {
    testWidgets('shows initial score from widget.score parameter',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks, mockFirestore: mockFirestore, score: 42);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('shows score from onInitVote when it returns non-empty map',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      when(() => mockCallbacks.onInitVote())
          .thenAnswer((_) async => {'score': 99, 'userVote': 0});
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks, mockFirestore: mockFirestore, score: 5);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('99'), findsOneWidget);
    });

    testWidgets('upvote increases score by 1 and calls onVote(1)',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      when(() => mockCallbacks.onInitVote())
          .thenAnswer((_) async => {'score': 10, 'userVote': 0});
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks, mockFirestore: mockFirestore, score: 10);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(Icons.thumb_up_outlined));
      await tester.pump();

      expect(find.text('11'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
      verify(() => mockCallbacks.onVote(1)).called(1);
    });

    testWidgets('tapping upvote twice retracts vote (score back to initial)',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      when(() => mockCallbacks.onInitVote())
          .thenAnswer((_) async => {'score': 10, 'userVote': 0});
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks, mockFirestore: mockFirestore, score: 10);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(Icons.thumb_up_outlined));
      await tester.pump();
      expect(find.text('11'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.thumb_up));
      await tester.pump();
      expect(find.text('10'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);

      verifyInOrder([
        () => mockCallbacks.onVote(1),
        () => mockCallbacks.onVote(0),
      ]);
    });

    testWidgets('downvote decreases score by 1 and calls onVote(-1)',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      when(() => mockCallbacks.onInitVote())
          .thenAnswer((_) async => {'score': 10, 'userVote': 0});
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks, mockFirestore: mockFirestore, score: 10);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(Icons.thumb_down_outlined));
      await tester.pump();

      expect(find.text('9'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_down), findsOneWidget);
      verify(() => mockCallbacks.onVote(-1)).called(1);
    });

    testWidgets('tapping downvote twice retracts vote (score back to initial)',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      when(() => mockCallbacks.onInitVote())
          .thenAnswer((_) async => {'score': 10, 'userVote': 0});
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks, mockFirestore: mockFirestore, score: 10);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(Icons.thumb_down_outlined));
      await tester.pump();
      expect(find.text('9'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.thumb_down));
      await tester.pump();
      expect(find.text('10'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);

      verifyInOrder([
        () => mockCallbacks.onVote(-1),
        () => mockCallbacks.onVote(0),
      ]);
    });

    testWidgets('switching upvote -> downvote decreases score by 2',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      when(() => mockCallbacks.onInitVote())
          .thenAnswer((_) async => {'score': 10, 'userVote': 0});
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks, mockFirestore: mockFirestore, score: 10);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(Icons.thumb_up_outlined));
      await tester.pump();
      expect(find.text('11'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.thumb_down_outlined));
      await tester.pump();
      expect(find.text('9'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_down), findsOneWidget);

      verifyInOrder([
        () => mockCallbacks.onVote(1),
        () => mockCallbacks.onVote(-1),
      ]);
    });

    testWidgets('switching downvote -> upvote increases score by 2',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      when(() => mockCallbacks.onInitVote())
          .thenAnswer((_) async => {'score': 10, 'userVote': 0});
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks, mockFirestore: mockFirestore, score: 10);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(Icons.thumb_down_outlined));
      await tester.pump();
      expect(find.text('9'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.thumb_up_outlined));
      await tester.pump();
      expect(find.text('11'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up), findsOneWidget);

      verifyInOrder([
        () => mockCallbacks.onVote(-1),
        () => mockCallbacks.onVote(1),
      ]);
    });

    testWidgets('score shows "0" (not negative) when it goes below zero',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      when(() => mockCallbacks.onInitVote())
          .thenAnswer((_) async => {'score': 0, 'userVote': 0});
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks, mockFirestore: mockFirestore, score: 0);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(Icons.thumb_down_outlined));
      await tester.pump();

      // _displayScore is -1 internally, but widget shows "0" when < 0
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('onVote is NOT called when onVote param is null',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      when(() => mockCallbacks.onInitVote())
          .thenAnswer((_) async => {'score': 5, 'userVote': 0});
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          score: 5,
          passOnVote: false);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(Icons.thumb_up_outlined));
      await tester.pump();

      expect(find.text('6'), findsOneWidget);
      verifyNever(() => mockCallbacks.onVote(any()));
    });

    testWidgets('onInitVote userVote=1 shows filled thumb_up icon',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      when(() => mockCallbacks.onInitVote())
          .thenAnswer((_) async => {'score': 7, 'userVote': 1});
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks, mockFirestore: mockFirestore, score: 5);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('onInitVote userVote=-1 shows filled thumb_down icon',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      when(() => mockCallbacks.onInitVote())
          .thenAnswer((_) async => {'score': 3, 'userVote': -1});
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks, mockFirestore: mockFirestore, score: 5);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.thumb_down), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 6: Loading Skeleton State
  // ═══════════════════════════════════════════════════════════════════════════
  group('Loading Skeleton State', () {
    testWidgets('shows placeholder icons while _isVoteLoading is true',
        (tester) async {
      final completer = Completer<QuerySnapshot<Map<String, dynamic>>>();
      final mockCollection = MockCollectionReference();
      final mockQuery1 = MockQuery();
      final mockQuery2 = MockQuery();

      when(() => mockFirestore.collection('reports')).thenReturn(mockCollection);
      when(() => mockCollection.where('barcode',
              isEqualTo: any(named: 'isEqualTo')))
          .thenReturn(mockQuery1);
      when(() => mockQuery1.where('status', isEqualTo: any(named: 'isEqualTo')))
          .thenReturn(mockQuery2);
      when(() => mockQuery2.limit(any())).thenReturn(mockQuery2);
      when(() => mockQuery2.get()).thenAnswer((_) => completer.future);

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          child: ReportDetailCard(
            product: _createSampleProduct(),
            onBack: mockCallbacks.onBack,
            originalStatus: GlutenSafetyStatus.adatto,
            reportReasonKey: 'label_unclear',
            reportComment: 'Test',
            reportDate: '2026-08-10T10:00:00Z',
            score: 5,
            onInitVote: () => mockCallbacks.onInitVote(),
            isOwnReport: false,
            useResponsiveWrapper: false,
            firebaseFirestore: mockFirestore,
          ),
        ),
      );

      await tester.pump(); // First frame only, Future still pending

      // Skeleton shows placeholder outlined icons (thumb_up_outlined)
      expect(find.byIcon(Icons.thumb_up_outlined), findsWidgets);

      // Complete Future to avoid test leak
      final emptySnapshot = MockQuerySnapshot();
      when(() => emptySnapshot.docs).thenReturn([]);
      completer.complete(emptySnapshot);
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 7: Delete Report (3-Dots Menu)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Delete Report (3-dots menu)', () {
    testWidgets(
        'PopupMenuButton visible when isOwnReport=true and onDeleteReport is set',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          isOwnReport: true);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('PopupMenuButton hidden when isOwnReport=false', (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          isOwnReport: false);
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets(
        'PopupMenuButton hidden when onDeleteReport=null even if isOwnReport=true',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          isOwnReport: true,
          passOnDeleteReport: false);
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('tapping 3-dots opens popup with deleteReport item',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          isOwnReport: true);

      await tester.tap(find.byIcon(Icons.more_vert));
      await _pumpAndSettleIgnoringOverflow(tester);

      expect(find.text('report.dropdown.deleteReport'), findsOneWidget);
    });

    testWidgets('selecting delete opens AlertDialog with confirm title/body',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          isOwnReport: true);

      await tester.tap(find.byIcon(Icons.more_vert));
      await _pumpAndSettleIgnoringOverflow(tester);
      await tester.tap(find.text('report.dropdown.deleteReport'));
      await _pumpAndSettleIgnoringOverflow(tester);

      expect(find.text('history.actions.clearAllConfirmTitle'), findsOneWidget);
      expect(find.text('history.actions.clearAllConfirmBody'), findsOneWidget);
    });

    testWidgets('cancelling delete dialog does NOT call onDeleteReport or onBack',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          isOwnReport: true);

      await tester.tap(find.byIcon(Icons.more_vert));
      await _pumpAndSettleIgnoringOverflow(tester);
      await tester.tap(find.text('report.dropdown.deleteReport'));
      await _pumpAndSettleIgnoringOverflow(tester);
      await tester.tap(find.text('common.actions.cancel'));
      await _pumpAndSettleIgnoringOverflow(tester);

      verifyNever(() => mockCallbacks.onDeleteReport(any()));
      verifyNever(() => mockCallbacks.onBack());
    });

    testWidgets(
        'confirming delete calls onDeleteReport with widget.reportId then onBack',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          isOwnReport: true,
          reportId: 'test_report_id_999');

      await tester.tap(find.byIcon(Icons.more_vert));
      await _pumpAndSettleIgnoringOverflow(tester);
      await tester.tap(find.text('report.dropdown.deleteReport'));
      await _pumpAndSettleIgnoringOverflow(tester);
      await tester.tap(find.text('common.actions.delete'));
      await _pumpAndSettleIgnoringOverflow(tester);

      verify(() => mockCallbacks.onDeleteReport('test_report_id_999')).called(1);
      verify(() => mockCallbacks.onBack()).called(1);
    });

    testWidgets(
        'confirming delete uses _activeReport.id as fallback when reportId is null',
        (tester) async {
      _stubFirestoreWithReport(mockFirestore, {
        'id': 'firestore_report_id',
        'barcode': _kBarcode,
        'productName': 'Pasta',
        'brand': 'Marca',
        'type': 'label_unclear',
        'comments': '',
        'submittedAt': '2026-08-10T10:00:00Z',
        'status': 'open',
        'score': 5,
      });

      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          isOwnReport: true,
          reportId: null);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(Icons.more_vert));
      await _pumpAndSettleIgnoringOverflow(tester);
      await tester.tap(find.text('report.dropdown.deleteReport'));
      await _pumpAndSettleIgnoringOverflow(tester);
      await tester.tap(find.text('common.actions.delete'));
      await _pumpAndSettleIgnoringOverflow(tester);

      verify(() => mockCallbacks.onDeleteReport('firestore_report_id')).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 8: _loadInitialData – Firestore Active Report
  // ═══════════════════════════════════════════════════════════════════════════
  group('_loadInitialData – Firestore active report', () {
    testWidgets('Firestore comment overrides widget.reportComment',
        (tester) async {
      _stubFirestoreWithReport(mockFirestore, {
        'id': 'report_123',
        'barcode': _kBarcode,
        'productName': 'Pasta',
        'brand': 'Marca',
        'type': 'label_unclear',
        'comments': 'Commento dal server Firestore.',
        'submittedAt': '2026-08-10T10:00:00Z',
        'status': 'open',
        'score': 5,
      });

      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportComment: 'Questo commento non deve apparire.');
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('"Commento dal server Firestore."'), findsOneWidget);
      expect(find.textContaining('non deve apparire'), findsNothing);
    });

    testWidgets('Firestore report type overrides widget.reportReasonKey',
        (tester) async {
      _stubFirestoreWithReport(mockFirestore, {
        'id': 'report_123',
        'barcode': _kBarcode,
        'productName': 'Pasta',
        'brand': 'Marca',
        'type': 'incorrect_status',
        'comments': '',
        'submittedAt': '2026-08-10T10:00:00Z',
        'status': 'open',
        'score': 5,
      });

      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportReasonKey: 'label_unclear');
      await tester.pump(const Duration(milliseconds: 200));

      // Il motivo è in un RichText (TextSpan), non in un semplice Text
      expect(findRichTextContaining('report.ui.incorrectStatus'),
          findsAtLeastNWidgets(1));
    });

    testWidgets('Firestore submittedAt used for date display over widget.reportDate',
        (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayIso =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}T09:00:00Z';

      _stubFirestoreWithReport(mockFirestore, {
        'id': 'report_123',
        'barcode': _kBarcode,
        'productName': 'Pasta',
        'brand': 'Marca',
        'type': 'label_unclear',
        'comments': '',
        'submittedAt': yesterdayIso,
        'status': 'open',
        'score': 5,
      });

      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportDate: '2024-01-01T00:00:00Z');
      await tester.pump(const Duration(milliseconds: 200));

      expect(
          find.textContaining('report.ui.reportDate.yesterday'), findsOneWidget);
    });

    testWidgets('Firestore exception: widget loads and shows fallback data',
        (tester) async {
      final mockCollection = MockCollectionReference();
      final mockQuery1 = MockQuery();
      final mockQuery2 = MockQuery();

      when(() => mockFirestore.collection('reports')).thenReturn(mockCollection);
      when(() => mockCollection.where('barcode',
              isEqualTo: any(named: 'isEqualTo')))
          .thenReturn(mockQuery1);
      when(() => mockQuery1.where('status', isEqualTo: any(named: 'isEqualTo')))
          .thenReturn(mockQuery2);
      when(() => mockQuery2.limit(any())).thenReturn(mockQuery2);
      when(() => mockQuery2.get()).thenThrow(Exception('Firestore Error!'));

      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          reportComment: 'Fallback comment',
          score: 3);
      await tester.pump(const Duration(milliseconds: 300));

      // No crash; shows the fallback data from widget params
      expect(find.text('"Fallback comment"'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 9: Product Link Navigation
  // ═══════════════════════════════════════════════════════════════════════════
  group('Product Link Navigation', () {
    testWidgets('shows showProductCard card when showProductLink=true',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          showProductLink: true);

      expect(find.text('report.ui.showProductCard'), findsOneWidget);
      expect(find.text('report.ui.ingredientsAllergensNotes'), findsOneWidget);
    });

    testWidgets('hides product card link when showProductLink=false',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          showProductLink: false);

      expect(find.text('report.ui.showProductCard'), findsNothing);
    });

    testWidgets('tapping product link navigates to ProductDetailCard',
        (tester) async {
      _stubFirestoreEmptyQuery(mockFirestore);
      await _pumpReportDetailCard(tester,
          callbacks: mockCallbacks,
          mockFirestore: mockFirestore,
          showProductLink: true);

      await tester.tap(find.text('report.ui.showProductCard'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // ProductDetailCard should be in the widget tree after navigation
      expect(find.byType(ProductDetailCard), findsWidgets);
    });
  });
}

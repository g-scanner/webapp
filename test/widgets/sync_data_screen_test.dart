// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget Tests: SyncDataScreen

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gscanner/features/sync/sync_data_screen.dart';
import 'package:gscanner/models/models.dart';
import '../mocks/shared_mocks.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock Callbacks
// ─────────────────────────────────────────────────────────────────────────────

class _SyncCallbacks {
  void onDecision(bool keep, [SyncChoices? choices]) {}
}

class MockSyncCallbacks extends Mock implements _SyncCallbacks {}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

AnonymousDataSummary _fullSummary() => AnonymousDataSummary(
      history: [
        ScanHistoryItem(
          id: 'h1',
          barcode: '111',
          scannedAt: DateTime.now().toIso8601String(),
        ),
        ScanHistoryItem(
          id: 'h2',
          barcode: '222',
          scannedAt: DateTime.now().toIso8601String(),
        ),
      ],
      reports: [
        ProductReport(
          id: 'r1',
          barcode: '333',
          productName: 'Biscotti',
          brand: 'Brand',
          type: 'label_unclear',
          comments: 'Test',
          submittedAt: DateTime.now().toIso8601String(),
          status: 'pending',
        ),
      ],
      hasSettings: true,
    );

Future<void> _pumpSyncDataScreen(
  WidgetTester tester, {
  required MockSyncCallbacks cb,
  AnonymousDataSummary? dataSummary,
  Size surfaceSize = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    createTestApp(
      child: SyncDataScreen(
        dataSummary: dataSummary ?? _fullSummary(),
        useResponsiveWrapper: false,
        onDecision: (keep, [choices = const SyncChoices()]) =>
            cb.onDecision(keep, choices),
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

  late MockSyncCallbacks cb;

  setUpAll(() async {
    setupMocktailFallbacks();
    registerFallbackValue(const SyncChoices());
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    cb = MockSyncCallbacks();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1 – UI Presentation & Structure
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 1 – UI Presentation & Structure', () {
    testWidgets('renders decorative cloud sync icon', (tester) async {
      await _pumpSyncDataScreen(tester, cb: cb);

      expect(find.byIcon(Icons.cloud_sync_rounded), findsOneWidget);
    });

    testWidgets('renders title and body text keys', (tester) async {
      await _pumpSyncDataScreen(tester, cb: cb);

      expect(find.text('sync.localDataFound.title'), findsOneWidget);
      expect(find.text('sync.localDataFound.body'), findsOneWidget);
    });

    testWidgets('renders sync and discard action buttons', (tester) async {
      await _pumpSyncDataScreen(tester, cb: cb);

      // Merge / Sync button (FilledButton)
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);

      // Discard / Delete button (TextButton with delete icon)
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('renders toSync header label', (tester) async {
      await _pumpSyncDataScreen(tester, cb: cb);

      expect(find.text('sync.localDataFound.toSync'), findsOneWidget);
    });

    testWidgets('shows all 3 category tiles when all data present',
        (tester) async {
      await _pumpSyncDataScreen(tester, cb: cb);

      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
      expect(find.byIcon(Icons.flag_rounded), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });

    testWidgets('hides categories with no data', (tester) async {
      await _pumpSyncDataScreen(
        tester,
        cb: cb,
        dataSummary: const AnonymousDataSummary(
          hasSettings: true,
        ),
      );

      // Only settings tile should be visible
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      // History and reports should NOT be shown
      expect(find.byIcon(Icons.history_rounded), findsNothing);
      expect(find.byIcon(Icons.flag_rounded), findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2 – Decision Callbacks & Interactions
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 2 – Decision Callbacks & Interactions', () {
    testWidgets('tapping sync button invokes onDecision(true) with all choices',
        (tester) async {
      await _pumpSyncDataScreen(tester, cb: cb);

      // Tap the FilledButton (sync)
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      final captured =
          verify(() => cb.onDecision(true, captureAny())).captured;
      final choices = captured.first as SyncChoices;
      expect(choices.syncHistory, isTrue);
      expect(choices.syncReports, isTrue);
      expect(choices.syncSettings, isTrue);
      verifyNever(() => cb.onDecision(false, any()));
    });

    testWidgets(
        'tapping sync with deselected category passes granular SyncChoices',
        (tester) async {
      await _pumpSyncDataScreen(tester, cb: cb);

      // Deselect history tile
      await tester.tap(find.text('common.navigation.history'));
      await tester.pump();

      // Tap sync
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      final captured =
          verify(() => cb.onDecision(true, captureAny())).captured;
      final choices = captured.first as SyncChoices;
      expect(choices.syncHistory, isFalse);
      expect(choices.syncReports, isTrue);
      expect(choices.syncSettings, isTrue);
    });

    testWidgets('tapping discard button shows confirmation dialog',
        (tester) async {
      await _pumpSyncDataScreen(tester, cb: cb);

      // Tap discard text button
      await tester.tap(find.text('sync.localDataFound.discard'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(
          find.text('sync.localDataFound.discardConfirmTitle'), findsOneWidget);
      expect(
          find.text('sync.localDataFound.discardConfirmAction'), findsOneWidget);
    });

    testWidgets(
        'confirming discard dialog invokes onDecision(false)',
        (tester) async {
      await _pumpSyncDataScreen(tester, cb: cb);

      // Open discard dialog
      await tester.tap(find.text('sync.localDataFound.discard'));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('sync.localDataFound.discardConfirmAction'));
      await tester.pumpAndSettle();

      verify(() => cb.onDecision(false, any())).called(1);
    });

    testWidgets('cancelling discard dialog does NOT invoke onDecision',
        (tester) async {
      await _pumpSyncDataScreen(tester, cb: cb);

      // Open discard dialog
      await tester.tap(find.text('sync.localDataFound.discard'));
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('common.actions.cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => cb.onDecision(any(), any()));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3 – Category Selection
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 3 – Category Selection', () {
    testWidgets('tapping a tile toggles its selection', (tester) async {
      await _pumpSyncDataScreen(tester, cb: cb);

      // All 3 should be selected initially → all check icons visible
      expect(find.byIcon(Icons.check), findsNWidgets(3));

      // Tap history tile to deselect
      await tester.tap(find.text('common.navigation.history'));
      await tester.pump();

      // Now 2 check icons
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('deselecting all disables sync button', (tester) async {
      await _pumpSyncDataScreen(
        tester,
        cb: cb,
        dataSummary: const AnonymousDataSummary(hasSettings: true),
      );

      // 1 category selected → deselect it
      await tester.tap(find.text('common.navigation.settings'));
      await tester.pump();

      // Sync button should be disabled
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });
}

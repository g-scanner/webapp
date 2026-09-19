// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget Tests: SyncDataScreen

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gscanner/features/sync/sync_data_screen.dart';
import '../mocks/shared_mocks.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock Callbacks
// ─────────────────────────────────────────────────────────────────────────────

class _SyncCallbacks {
  void onDecision(bool keep) {}
}

class MockSyncCallbacks extends Mock implements _SyncCallbacks {}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _pumpSyncDataScreen(
  WidgetTester tester, {
  required MockSyncCallbacks cb,
  Size surfaceSize = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    createTestApp(
      child: Scaffold(
        body: SyncDataScreen(
          onDecision: (keep) => cb.onDecision(keep),
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

  late MockSyncCallbacks cb;

  setUpAll(() async {
    setupMocktailFallbacks();
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

      expect(find.byIcon(Icons.cloud_sync_outlined), findsOneWidget);
    });

    testWidgets('renders title and body text keys', (tester) async {
      await _pumpSyncDataScreen(tester, cb: cb);

      expect(find.text('sync.localDataFound.title'), findsOneWidget);
      expect(find.text('sync.localDataFound.body'), findsOneWidget);
    });

    testWidgets('renders both action buttons with proper icons and labels',
        (tester) async {
      await _pumpSyncDataScreen(tester, cb: cb);

      // Merge / Keep button
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('sync.localDataFound.merge'), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);

      // Discard / Delete button
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('sync.localDataFound.discard'), findsOneWidget);
      expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2 – Decision Callbacks & Interactions
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 2 – Decision Callbacks & Interactions', () {
    testWidgets('tapping merge button invokes onDecision(true)', (tester) async {
      await _pumpSyncDataScreen(tester, cb: cb);

      await tester.tap(find.text('sync.localDataFound.merge'));
      await tester.pump();

      verify(() => cb.onDecision(true)).called(1);
      verifyNever(() => cb.onDecision(false));
    });

    testWidgets('tapping discard button invokes onDecision(false)',
        (tester) async {
      await _pumpSyncDataScreen(tester, cb: cb);

      await tester.tap(find.text('sync.localDataFound.discard'));
      await tester.pump();

      verify(() => cb.onDecision(false)).called(1);
      verifyNever(() => cb.onDecision(true));
    });
  });
}

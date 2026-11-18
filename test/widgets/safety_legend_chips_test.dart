// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gscanner/features/scanner/widgets/safety_legend_chips.dart';
import 'package:gscanner/core/widgets/app_status_pill.dart';

void main() {
  Widget buildTestableWidget() {
    return const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: SafetyLegendChips(),
          ),
        ),
      ),
    );
  }

  group('SafetyLegendChips Widget Tests', () {
    testWidgets('renders title, 4 indicators with white icons in 36dp solid circles, no subtitles',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Check title
      expect(find.text('scanner.legend.title'), findsOneWidget);

      // Check 4 indicators in grid
      expect(find.text('product.status.safe'), findsOneWidget);
      expect(find.text('product.status.uncertain'), findsOneWidget);
      expect(find.text('product.status.unsafe'), findsOneWidget);
      expect(find.text('product.status.unknown'), findsOneWidget);

      // Verify new icons matching SafetyStatusCard (product detail)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.help), findsOneWidget);

      // Verify old subtitles are NOT present
      expect(find.text('scanner.legend.subtitles.glutenFree'), findsNothing);
      expect(find.text('scanner.legend.subtitles.checkLabel'), findsNothing);
      expect(find.text('scanner.legend.subtitles.hasGluten'), findsNothing);
      expect(find.text('scanner.legend.subtitles.notFound'), findsNothing);

      // Check rest state text
      expect(find.text('scanner.legend.hintTitle'), findsOneWidget);
      expect(find.text('scanner.legend.hintSubtitle'), findsOneWidget);

      // Verify slot height via key
      final slotFinder = find.byKey(const ValueKey('_safetyLegendDetailSlot'));
      expect(slotFinder, findsOneWidget);
      final sizeBefore = tester.getSize(slotFinder);
      expect(sizeBefore.height, 118.0);
    });

    testWidgets(
        'tap on Sicuro activates card and displays AppStatusPill with zero layout shift',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final slotFinder = find.byKey(const ValueKey('_safetyLegendDetailSlot'));
      final initialSlotSize = tester.getSize(slotFinder);

      // Tap on Sicuro
      await tester.tap(find.text('product.status.safe'));
      await tester.pumpAndSettle();

      // AppStatusPill should now be visible with safe variant
      expect(find.byType(AppStatusPill), findsOneWidget);
      expect(find.text('scanner.legend.safe.pill'), findsOneWidget);
      expect(find.text('scanner.legend.safe.description'), findsOneWidget);

      // Verify ZERO LAYOUT SHIFT
      final activeSlotSize = tester.getSize(slotFinder);
      expect(activeSlotSize.height, initialSlotSize.height);
      expect(activeSlotSize.width, initialSlotSize.width);
    });

    testWidgets('tap on another indicator switches detail seamlessly',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Tap Sicuro
      await tester.tap(find.text('product.status.safe'));
      await tester.pumpAndSettle();
      expect(find.text('scanner.legend.safe.pill'), findsOneWidget);

      // Tap Vietato
      await tester.tap(find.text('product.status.unsafe'));
      await tester.pumpAndSettle();
      expect(find.text('scanner.legend.unsafe.pill'), findsOneWidget);
      expect(find.text('scanner.legend.unsafe.description'), findsOneWidget);

      // Slot height remains rigidly 118.0
      final slotFinder = find.byKey(const ValueKey('_safetyLegendDetailSlot'));
      expect(tester.getSize(slotFinder).height, 118.0);
    });

    testWidgets('tap on same indicator deselects and returns to rest state',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Tap Incerto
      await tester.tap(find.text('product.status.uncertain'));
      await tester.pumpAndSettle();
      expect(find.text('scanner.legend.uncertain.pill'), findsOneWidget);

      // Tap Incerto again -> deselect
      await tester.tap(find.text('product.status.uncertain'));
      await tester.pumpAndSettle();

      // Should be back to rest state
      expect(find.text('scanner.legend.hintTitle'), findsOneWidget);
      expect(find.text('scanner.legend.hintSubtitle'), findsOneWidget);

      // Slot height remains rigidly 118.0
      final slotFinder = find.byKey(const ValueKey('_safetyLegendDetailSlot'));
      expect(tester.getSize(slotFinder).height, 118.0);
    });
  });
}

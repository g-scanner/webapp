// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gscanner/features/product_detail/widgets/report_action_button.dart';

void main() {
  Widget buildTestableWidget({
    required bool hasUserReported,
    required int pendingReportsCount,
    VoidCallback? onReportPressed,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ReportActionButton(
            hasUserReported: hasUserReported,
            pendingReportsCount: pendingReportsCount,
            onReportPressed: onReportPressed ?? () {},
          ),
        ),
      ),
    );
  }

  group('ReportActionButton Tests', () {
    testWidgets('Normal state (unreported): renders tonal button with 50dp fixed height',
        (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        buildTestableWidget(
          hasUserReported: false,
          pendingReportsCount: 0,
          onReportPressed: () => pressed = true,
        ),
      );

      // Verify button exists and uses flag_outlined icon
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
      expect(find.text('product.actions.reportError'), findsOneWidget);

      // Verify no checkmark or red styling
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsNothing);

      // Verify exact height is 50.0dp
      final buttonFinder = find.byType(ReportActionButton);
      expect(tester.getSize(buttonFinder).height, 50.0);

      // Verify tap works
      await tester.tap(find.byType(FilledButton));
      expect(pressed, isTrue);
    });

    testWidgets('Already reported state: renders pure text and flag icon with zero button and 50dp height',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          hasUserReported: true,
          pendingReportsCount: 0,
        ),
      );

      // Verify NO BUTTON, NO INKWELL, NO RIPPLE
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(InkWell), findsNothing);

      // Verify NO CHECKMARK
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.task_alt), findsNothing);
      expect(find.byIcon(Icons.done), findsNothing);

      // Verify flag_rounded icon and already reported text
      expect(find.byIcon(Icons.flag_rounded), findsOneWidget);
      expect(find.text('product.actions.alreadyReported'), findsOneWidget);

      // Verify exact height is 50.0dp (ZERO LAYOUT SHIFT)
      final buttonFinder = find.byType(ReportActionButton);
      expect(tester.getSize(buttonFinder).height, 50.0);
    });

    testWidgets('Community reported state (pendingReportsCount > 0): renders same discreet pure text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          hasUserReported: false,
          pendingReportsCount: 3,
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
      expect(find.byIcon(Icons.flag_rounded), findsOneWidget);
      expect(find.text('product.actions.alreadyReported'), findsOneWidget);
      expect(tester.getSize(find.byType(ReportActionButton)).height, 50.0);
    });
  });
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget Tests: AppSnackBar

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gscanner/core/widgets/app_snackbar.dart';

void main() {
  Widget buildTestScaffold({required VoidCallback onTrigger}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: onTrigger,
            child: const Text('Show SnackBar'),
          ),
        ),
      ),
    );
  }

  tearDown(() {
    AppSnackBar.dismiss();
  });

  group('AppSnackBar Widget & Gesture Tests', () {
    testWidgets('shows message and default styling', (tester) async {
      await tester.pumpWidget(
        buildTestScaffold(
          onTrigger: () {
            // Note: need a valid context
          },
        ),
      );

      final BuildContext context = tester.element(find.text('Show SnackBar'));
      showAppSnackBar(context, 'Test Message', icon: Icons.check);
      await tester.pumpAndSettle();

      expect(find.byType(AppSnackBarWidget), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('dismisses downwards when swiped DOWN', (tester) async {
      await tester.pumpWidget(
        buildTestScaffold(
          onTrigger: () {},
        ),
      );

      final BuildContext context = tester.element(find.text('Show SnackBar'));
      showAppSnackBar(
        context,
        'Swipe Me Down',
        duration: const Duration(seconds: 10),
      );
      await tester.pumpAndSettle();

      expect(find.text('Swipe Me Down'), findsOneWidget);

      // Drag downwards past dismissal threshold
      await tester.drag(find.byType(AppSnackBarWidget), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(find.byType(AppSnackBarWidget), findsNothing);
      expect(find.text('Swipe Me Down'), findsNothing);
    });

    testWidgets('does NOT dismiss when swiped HORIZONTALLY', (tester) async {
      await tester.pumpWidget(
        buildTestScaffold(
          onTrigger: () {},
        ),
      );

      final BuildContext context = tester.element(find.text('Show SnackBar'));
      showAppSnackBar(
        context,
        'Cannot Swipe Horizontal',
        duration: const Duration(seconds: 10),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cannot Swipe Horizontal'), findsOneWidget);

      // Drag horizontal
      await tester.drag(find.byType(AppSnackBarWidget), const Offset(300, 0));
      await tester.pumpAndSettle();

      // Should still be present
      expect(find.text('Cannot Swipe Horizontal'), findsOneWidget);
    });

    testWidgets('holding with pointer pauses auto-dismiss', (tester) async {
      await tester.pumpWidget(
        buildTestScaffold(
          onTrigger: () {},
        ),
      );

      final BuildContext context = tester.element(find.text('Show SnackBar'));
      showAppSnackBar(
        context,
        'Hold Me',
        duration: const Duration(milliseconds: 500),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(tester.getCenter(find.text('Hold Me')));
      // Wait past duration while holding
      await tester.pump(const Duration(milliseconds: 700));

      // Still visible because pointer is down
      expect(find.text('Hold Me'), findsOneWidget);

      // Release pointer
      await gesture.up();
      // Pump past duration + animation
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Hold Me'), findsNothing);
    });

    testWidgets('new snackbar replaces current immediately', (tester) async {
      await tester.pumpWidget(
        buildTestScaffold(
          onTrigger: () {},
        ),
      );

      final BuildContext context = tester.element(find.text('Show SnackBar'));
      showAppSnackBar(context, 'First Message', duration: const Duration(seconds: 10));
      await tester.pumpAndSettle();

      expect(find.text('First Message'), findsOneWidget);

      showAppSnackBar(context, 'Second Message', duration: const Duration(seconds: 10));
      await tester.pumpAndSettle();

      expect(find.text('First Message'), findsNothing);
      expect(find.text('Second Message'), findsOneWidget);
    });
  });
}

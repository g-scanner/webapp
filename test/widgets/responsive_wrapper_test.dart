// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget Tests: ResponsiveMaxCardWidth

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gscanner/core/utils/responsive_wrapper.dart';
import '../mocks/shared_mocks.dart';

Future<void> _pumpWrapper(
  WidgetTester tester, {
  required Widget child,
  Size surfaceSize = const Size(400, 800),
  double maxWidth = 500,
  double maxHeight = 900,
  Color? backgroundColor,
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    createTestApp(
      child: Scaffold(
        body: ResponsiveMaxCardWidth(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          backgroundColor: backgroundColor,
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ResponsiveMaxCardWidth Widget Tests', () {
    testWidgets(
        'narrow screen (width <= 600) renders child directly without Card wrapper',
        (tester) async {
      await _pumpWrapper(
        tester,
        surfaceSize: const Size(400, 800),
        child: const Text('Child Content'),
      );

      // Child is rendered
      expect(find.text('Child Content'), findsOneWidget);

      // No wrapping Card or ClipRRect is added in narrow mobile mode
      expect(find.byType(Card), findsNothing);
      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets(
        'wide screen with normal height (width > 600, height > 500) renders Card with shadow and constraints',
        (tester) async {
      await _pumpWrapper(
        tester,
        surfaceSize: const Size(1000, 800),
        maxWidth: 500,
        maxHeight: 900,
        child: const Text('Child Content'),
      );

      expect(find.text('Child Content'), findsOneWidget);

      // In wide mode, Card and ClipRRect are present
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ClipRRect), findsOneWidget);

      // Verify constraints applied to the inner container
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(ClipRRect),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints?.maxWidth, 500);
      expect(container.constraints?.maxHeight, 900);
    });

    testWidgets(
        'wide screen with low height (width > 600, height <= 500) applies landscape low-height layout with capped maxWidth',
        (tester) async {
      await _pumpWrapper(
        tester,
        surfaceSize: const Size(800, 450), // Low height landscape
        maxWidth: 500,
        maxHeight: 400,
        child: const Text('Child Content'),
      );

      expect(find.text('Child Content'), findsOneWidget);

      // In low-height landscape mode, the heavy Card wrapper is NOT used
      expect(find.byType(Card), findsNothing);

      // Find inner constrained Container
      final containers = tester.widgetList<Container>(find.byType(Container));
      final innerContainer = containers.firstWhere(
        (c) => c.constraints != null && c.constraints!.maxWidth <= 450,
      );

      // Width is capped at 450 (maxWidth 500 -> capped to 450)
      expect(innerContainer.constraints?.maxWidth, 450);
      expect(innerContainer.constraints?.maxHeight, 400);
    });

    testWidgets('custom backgroundColor is applied to Card in wide mode',
        (tester) async {
      const customBg = Color(0xFF123456);

      await _pumpWrapper(
        tester,
        surfaceSize: const Size(1000, 800),
        backgroundColor: customBg,
        child: const Text('Child Content'),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, customBg);
    });

    testWidgets('custom maxWidth and maxHeight are respected',
        (tester) async {
      await _pumpWrapper(
        tester,
        surfaceSize: const Size(1000, 800),
        maxWidth: 380,
        maxHeight: 650,
        child: const Text('Child Content'),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(ClipRRect),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints?.maxWidth, 380);
      expect(container.constraints?.maxHeight, 650);
    });
  });
}

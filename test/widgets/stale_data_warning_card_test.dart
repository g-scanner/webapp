// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget Tests: StaleDataWarningCard

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gscanner/features/product_detail/widgets/stale_data_warning_card.dart';
import 'package:gscanner/features/product_detail/widgets/section_card.dart';
import '../mocks/shared_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('StaleDataWarningCard Widget Tests', () {
    testWidgets('renders SectionCard with history_toggle_off icon and warning texts', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: StaleDataWarningCard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StaleDataWarningCard), findsOneWidget);
      expect(find.byType(SectionCard), findsOneWidget);
      expect(find.byIcon(Icons.safety_check_outlined), findsOneWidget);

      // SectionCard is caution styled with default grey background (identical to ProductWarningCard)
      final sectionCard = tester.widget<SectionCard>(find.byType(SectionCard));
      expect(sectionCard.isCaution, isTrue);
      expect(sectionCard.bgColor, isNull);

      // Verifies text widgets are present
      expect(find.byType(Text), findsNWidgets(3)); // title in SectionCard + body + caution
    });

    testWidgets('renders cleanly in dark theme mode without overflow', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          themeMode: ThemeMode.dark,
          child: const Scaffold(
            body: StaleDataWarningCard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StaleDataWarningCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

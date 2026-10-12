// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget Tests: Offline Warning Cards

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gscanner/features/product_detail/widgets/offline_database_warning_card.dart';
import 'package:gscanner/features/product_detail/widgets/offline_not_found_warning_card.dart';
import 'package:gscanner/features/product_detail/widgets/section_card.dart';
import '../mocks/shared_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('OfflineDatabaseWarningCard Widget Tests', () {
    testWidgets('renders SectionCard with cloud_off icon and warning texts', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: OfflineDatabaseWarningCard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OfflineDatabaseWarningCard), findsOneWidget);
      expect(find.byType(SectionCard), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);

      final sectionCard = tester.widget<SectionCard>(find.byType(SectionCard));
      expect(sectionCard.isCaution, isTrue);

      // Titolo in SectionCard + Body + Caution
      expect(find.byType(Text), findsNWidgets(3));
    });

    testWidgets('renders cleanly in dark theme without overflow', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          themeMode: ThemeMode.dark,
          child: const Scaffold(
            body: OfflineDatabaseWarningCard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OfflineDatabaseWarningCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('OfflineNotFoundWarningCard Widget Tests', () {
    testWidgets('renders SectionCard with search_off icon and explanation texts', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: OfflineNotFoundWarningCard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OfflineNotFoundWarningCard), findsOneWidget);
      expect(find.byType(SectionCard), findsOneWidget);
      expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);

      final sectionCard = tester.widget<SectionCard>(find.byType(SectionCard));
      expect(sectionCard.isCaution, isTrue);

      // Titolo + Body + Action
      expect(find.byType(Text), findsNWidgets(3));
    });

    testWidgets('renders cleanly in dark theme without overflow', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          themeMode: ThemeMode.dark,
          child: const Scaffold(
            body: OfflineNotFoundWarningCard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OfflineNotFoundWarningCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

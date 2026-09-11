// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget Tests: ProductDetailAppBarActions

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:gscanner/features/product_detail/widgets/product_detail_app_bar_actions.dart';
import '../mocks/shared_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget buildActionsWidget({
    bool showActionsSkeleton = false,
    bool canDeleteHistory = false,
    bool canDeleteReport = false,
    String barcode = '8001234567890',
    String? effectiveUserReportId,
    Future<void> Function(String barcode)? onDeleteHistoryByBarcode,
    Future<void> Function(String reportId)? onDeleteReport,
    VoidCallback? onBack,
  }) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.green);
    return createTestApp(
      child: Scaffold(
        appBar: AppBar(
          actions: [
            ProductDetailAppBarActions(
              showActionsSkeleton: showActionsSkeleton,
              canDeleteHistory: canDeleteHistory,
              canDeleteReport: canDeleteReport,
              barcode: barcode,
              effectiveUserReportId: effectiveUserReportId,
              onDeleteHistoryByBarcode: onDeleteHistoryByBarcode,
              onDeleteReport: onDeleteReport,
              onBack: onBack ?? () {},
              cardBg: Colors.white,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  group('ProductDetailAppBarActions Widget Tests', () {
    testWidgets('shows Skeletonizer when showActionsSkeleton is true', (tester) async {
      await tester.pumpWidget(
        buildActionsWidget(
          showActionsSkeleton: true,
          canDeleteHistory: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final skeletonFinder = find.byWidgetPredicate((w) => w is Skeletonizer);
      expect(skeletonFinder, findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('renders SizedBox.shrink when both delete options are false', (tester) async {
      await tester.pumpWidget(
        buildActionsWidget(
          showActionsSkeleton: false,
          canDeleteHistory: false,
          canDeleteReport: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Skeletonizer), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('shows delete history option, cancels dialog on cancel press', (tester) async {
      bool deletedHistory = false;
      bool backed = false;

      await tester.pumpWidget(
        buildActionsWidget(
          showActionsSkeleton: false,
          canDeleteHistory: true,
          onDeleteHistoryByBarcode: (b) async {
            deletedHistory = true;
          },
          onBack: () {
            backed = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      final popupMenu = find.byType(PopupMenuButton<String>);
      expect(popupMenu, findsOneWidget);

      await tester.tap(popupMenu);
      await tester.pumpAndSettle();

      expect(find.text('common.actions.deleteHistoryConfirmTitle'), findsOneWidget);

      // Tap on the item to open confirmation dialog
      await tester.tap(find.text('common.actions.deleteHistoryConfirmTitle'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Cancel button
      await tester.tap(find.text('common.actions.cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(deletedHistory, isFalse);
      expect(backed, isFalse);
    });

    testWidgets('confirms delete history, calls callback and onBack', (tester) async {
      String? deletedBarcode;
      bool backed = false;

      await tester.pumpWidget(
        buildActionsWidget(
          showActionsSkeleton: false,
          canDeleteHistory: true,
          barcode: '999888777',
          onDeleteHistoryByBarcode: (b) async {
            deletedBarcode = b;
          },
          onBack: () {
            backed = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.actions.deleteHistoryConfirmTitle'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Confirm delete button
      await tester.tap(find.text('common.actions.delete'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(deletedBarcode, '999888777');
      expect(backed, isTrue);
    });

    testWidgets('confirms delete report, calls onDeleteReport with reportId', (tester) async {
      String? deletedReportId;

      await tester.pumpWidget(
        buildActionsWidget(
          showActionsSkeleton: false,
          canDeleteReport: true,
          effectiveUserReportId: 'rep_123',
          onDeleteReport: (rId) async {
            deletedReportId = rId;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('common.actions.deleteReportConfirmTitle'), findsOneWidget);

      await tester.tap(find.text('common.actions.deleteReportConfirmTitle'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Cancel first
      await tester.tap(find.text('common.actions.cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(deletedReportId, isNull);

      // Open again and confirm delete
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.actions.deleteReportConfirmTitle'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.actions.delete'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(deletedReportId, 'rep_123');
    });
  });
}

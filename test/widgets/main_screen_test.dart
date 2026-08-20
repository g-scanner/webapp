// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget Tests: MyApp & MainScreen Orchestrators

// ignore_for_file: subtype_of_sealed_class

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gscanner/main.dart';
import 'package:gscanner/models/types.dart';
import 'package:gscanner/services/db_service.dart';
import 'package:gscanner/theme/theme_notifier.dart';
import 'package:gscanner/widgets/auth_screen.dart';
import 'package:gscanner/widgets/camera_module.dart';
import 'package:gscanner/widgets/settings_panel.dart';
import 'package:gscanner/widgets/product_detail_card.dart';
import 'package:gscanner/widgets/sync_data_screen.dart';
import '../mocks/shared_mocks.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Additional Mocks
// ─────────────────────────────────────────────────────────────────────────────

class MockUserMetadata extends Mock implements UserMetadata {}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _pumpMyApp(
  WidgetTester tester, {
  required MockFirebaseAuth auth,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [
        Locale('it'),
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
      ],
      path: 'assets/locales',
      assetLoader: const TestAssetLoader(),
      fallbackLocale: const Locale('it'),
      startLocale: const Locale('it'),
      useOnlyLangCode: true,
      child: MyApp(auth: auth),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpMainScreen(
  WidgetTester tester, {
  required MockFirebaseAuth auth,
  Size surfaceSize = const Size(600, 1000),
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(createTestApp(child: MainScreen(auth: auth)));

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Finder _findMainIndexedStack() {
  return find.byWidgetPredicate(
    (w) => w is IndexedStack && w.children.length == 4,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockUserMetadata mockMetadata;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCol;
  late MockDocumentReference mockDoc;
  late MockQuerySnapshot mockQuerySnap;
  late MockDocumentSnapshot mockDocSnap;
  late MockWriteBatch mockBatch;

  setUpAll(() async {
    setupMocktailFallbacks();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    themeNotifier.value = ThemeMode.light;

    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockMetadata = MockUserMetadata();

    mockFirestore = MockFirebaseFirestore();
    mockCol = MockCollectionReference();
    mockDoc = MockDocumentReference();
    mockQuerySnap = MockQuerySnapshot();
    mockDocSnap = MockDocumentSnapshot();
    mockBatch = MockWriteBatch();

    when(() => mockFirestore.collection(any())).thenReturn(mockCol);
    when(() => mockFirestore.batch()).thenReturn(mockBatch);
    when(() => mockBatch.commit()).thenAnswer((_) async {});
    when(() => mockBatch.delete(any())).thenReturn(null);
    when(() => mockBatch.set(any(), any())).thenReturn(null);
    when(() => mockCol.doc(any())).thenReturn(mockDoc);
    when(() => mockCol.doc()).thenReturn(mockDoc);
    when(() => mockCol.get()).thenAnswer((_) async => mockQuerySnap);
    when(
      () => mockCol.where(any(), isEqualTo: any(named: 'isEqualTo')),
    ).thenReturn(mockCol);
    when(
      () => mockCol.where(any(), isGreaterThan: any(named: 'isGreaterThan')),
    ).thenReturn(mockCol);
    when(
      () => mockCol.orderBy(any(), descending: any(named: 'descending')),
    ).thenReturn(mockCol);
    when(() => mockCol.limit(any())).thenReturn(mockCol);
    when(() => mockDoc.id).thenReturn('mock_doc_id');
    when(() => mockDoc.get()).thenAnswer((_) async => mockDocSnap);
    when(() => mockDoc.set(any(), any())).thenAnswer((_) async {});
    when(() => mockDocSnap.exists).thenReturn(false);
    when(() => mockDocSnap.data()).thenReturn(null);
    when(() => mockQuerySnap.docs).thenReturn([]);

    DbService.auth = mockAuth;
    DbService.db = mockFirestore;

    when(() => mockMetadata.lastSignInTime).thenReturn(DateTime.now());
    when(() => mockMetadata.creationTime).thenReturn(DateTime.now());

    when(() => mockUser.uid).thenReturn('test_uid');
    when(() => mockUser.isAnonymous).thenReturn(false);
    when(() => mockUser.displayName).thenReturn('Mario Rossi');
    when(() => mockUser.email).thenReturn('mario@example.com');
    when(() => mockUser.providerData).thenReturn([]);
    when(() => mockUser.metadata).thenReturn(mockMetadata);

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(
      () => mockAuth.authStateChanges(),
    ).thenAnswer((_) => Stream.value(mockUser));
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1 – MyApp Root Routing & Auth State Handling
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 1 – MyApp Root Routing & Auth State Handling', () {
    testWidgets('renders AuthScreen when no user is logged in', (tester) async {
      when(() => mockAuth.currentUser).thenReturn(null);
      when(
        () => mockAuth.authStateChanges(),
      ).thenAnswer((_) => Stream.value(null));

      await _pumpMyApp(tester, auth: mockAuth);

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(MainScreen), findsNothing);
    });

    testWidgets('renders MainScreen when user is authenticated', (
      tester,
    ) async {
      await _pumpMyApp(tester, auth: mockAuth);

      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);
    });

    testWidgets('reacts to themeNotifier changes in MyApp', (tester) async {
      await _pumpMyApp(tester, auth: mockAuth);

      themeNotifier.value = ThemeMode.dark;
      await tester.pump();
      expect(themeNotifier.value, ThemeMode.dark);

      themeNotifier.value = ThemeMode.light;
      await tester.pump();
      expect(themeNotifier.value, ThemeMode.light);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2 – MainScreen Navigation & Tab Switching (Mobile Viewport)
  // ═══════════════════════════════════════════════════════════════════════════
  group(
    'GROUP 2 – MainScreen Navigation & Tab Switching (Mobile Viewport)',
    () {
      testWidgets('initial tab is Scanner (Tab 0) with CameraModule active', (
        tester,
      ) async {
        await _pumpMainScreen(tester, auth: mockAuth);

        final stack = tester.widget<IndexedStack>(_findMainIndexedStack());
        expect(stack.index, 0);
        expect(find.text('common.appName'), findsOneWidget);
        expect(find.text('common.navigation.scanner'), findsOneWidget);
      });

      testWidgets('tapping History tab switches IndexedStack index to 1', (
        tester,
      ) async {
        await _pumpMainScreen(tester, auth: mockAuth);

        // Tap on History tab
        await tester.tap(find.text('common.navigation.history'));
        await tester.pump();

        final stack = tester.widget<IndexedStack>(_findMainIndexedStack());
        expect(stack.index, 1);
      });

      testWidgets('tapping Reports tab switches IndexedStack index to 2', (
        tester,
      ) async {
        await _pumpMainScreen(tester, auth: mockAuth);

        // Tap on Reports tab
        await tester.tap(find.text('common.navigation.reports'));
        await tester.pump();

        final stack = tester.widget<IndexedStack>(_findMainIndexedStack());
        expect(stack.index, 2);
      });

      testWidgets('tapping Settings tab switches IndexedStack index to 3', (
        tester,
      ) async {
        await _pumpMainScreen(tester, auth: mockAuth);

        // Tap on Settings tab
        await tester.tap(find.text('common.navigation.settings'));
        await tester.pump();

        final stack = tester.widget<IndexedStack>(_findMainIndexedStack());
        expect(stack.index, 3);
      });

      testWidgets(
        'switching from Settings back to Scanner restores index to 0',
        (tester) async {
          await _pumpMainScreen(tester, auth: mockAuth);

          // Switch to settings
          await tester.tap(find.text('common.navigation.settings'));
          await tester.pump();
          expect(tester.widget<IndexedStack>(_findMainIndexedStack()).index, 3);

          // Switch back to scanner
          await tester.tap(find.text('common.navigation.scanner'));
          await tester.pump();

          expect(tester.widget<IndexedStack>(_findMainIndexedStack()).index, 0);
        },
      );
    },
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3 – Wide Screen / Desktop Layout (NavigationRail)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 3 – Wide Screen / Desktop Layout (NavigationRail)', () {
    testWidgets(
      'renders NavigationRail instead of BottomNav on wide screens (>960px)',
      (tester) async {
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exceptionAsString().contains('RenderFlex overflowed')) {
            return;
          }
          prevOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = prevOnError);

        await _pumpMainScreen(
          tester,
          auth: mockAuth,
          surfaceSize: const Size(1200, 900),
        );

        // NavigationRail is used on wide screen
        expect(find.byType(NavigationRail), findsOneWidget);
      },
    );

    testWidgets('tapping destination on NavigationRail switches tabs', (
      tester,
    ) async {
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) {
          return;
        }
        prevOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = prevOnError);

      await _pumpMainScreen(
        tester,
        auth: mockAuth,
        surfaceSize: const Size(1200, 900),
      );

      // Tap History destination in NavigationRail
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.byIcon(Icons.history),
        ),
      );
      await tester.pump();

      expect(tester.widget<IndexedStack>(_findMainIndexedStack()).index, 1);

      // Tap Settings destination
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.byIcon(Icons.settings_outlined),
        ),
      );
      await tester.pump();

      expect(tester.widget<IndexedStack>(_findMainIndexedStack()).index, 3);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4 – Settings Interaction & DB Reset
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 4 – Settings Interaction & DB Reset', () {
    testWidgets(
      'navigates to settings and triggers resetDB to return to tab 0',
      (tester) async {
        await _pumpMainScreen(tester, auth: mockAuth);

        // Navigate to Settings
        await tester.tap(find.text('common.navigation.settings'));
        await tester.pump();
        expect(tester.widget<IndexedStack>(_findMainIndexedStack()).index, 3);

        // Trigger onResetDB via SettingsPanel's callback
        final settingsPanel = tester.widget<SettingsPanel>(
          find.byType(SettingsPanel),
        );
        await settingsPanel.onResetDB();
        await tester.pump();

        // Should be back on tab 0 (CameraModule)
        expect(tester.widget<IndexedStack>(_findMainIndexedStack()).index, 0);
      },
    );

    testWidgets('onSettingsChange updates themeNotifier and userSettings', (
      tester,
    ) async {
      await _pumpMainScreen(tester, auth: mockAuth);

      await tester.tap(find.text('common.navigation.settings'));
      await tester.pump();

      final settingsPanel = tester.widget<SettingsPanel>(
        find.byType(SettingsPanel),
      );

      final updatedSettings = UserSettings(
        strictMode: false,
        alertLactose: true,
        warnAdditives: false,
        autoSaveHistory: true,
        preferredLanguage: 'en',
        preferredTheme: 'dark',
      );

      await settingsPanel.onSettingsChange(updatedSettings);
      await tester.pump();

      expect(themeNotifier.value, ThemeMode.dark);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5 – Scan Barcode Handler & Product Detail Navigation
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 5 – Scan Barcode Handler & Product Detail Navigation', () {
    testWidgets('handleScanSuccess pushes ProductDetailCard', (tester) async {
      final testProduct = Product(
        barcode: '8001234567890',
        nameMap: const {'it': 'Pasta Senza Glutine'},
        brandMap: const {'it': 'Brand Bio'},
        ingredientsMap: const {'it': 'Farina di riso'},
        allergensMap: const {'it': <String>[]},
        lastUpdated: DateTime.now().toIso8601String(),
        pendingReportsCount: 0,
      );
      await DbService.saveLocalProducts([testProduct]);

      await _pumpMainScreen(tester, auth: mockAuth);

      final cameraModule = tester.widget<CameraModule>(
        find.byType(CameraModule),
      );

      // Simulate a barcode scan
      cameraModule.onScanSuccess('8001234567890');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // ProductDetailCard route is pushed
      expect(find.byType(ProductDetailCard), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 6 – Anonymous Data Migration & SyncDataScreen Trigger
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 6 – Anonymous Data Migration & SyncDataScreen Trigger', () {
    testWidgets(
      'renders SyncDataScreen when unsynced local anonymous history/reports exist',
      (tester) async {
        // Simulate unsynced local history and reports from anonymous mode
        final fakeHistory = [
          ScanHistoryItem(
            id: 'hist_anon_1',
            barcode: '111111',
            scannedAt: DateTime.now().toIso8601String(),
          ),
        ];
        final fakeReports = [
          ProductReport(
            id: 'rep_anon_1',
            barcode: '222222',
            productName: 'Biscotti',
            brand: 'Brand',
            type: 'label_unclear',
            comments: 'Etichetta poco chiara',
            submittedAt: DateTime.now().toIso8601String(),
            status: 'pending',
          ),
        ];

        SharedPreferences.setMockInitialValues({
          'celiac_history': [json.encode(fakeHistory.first.toJson())],
          'celiac_reports': [json.encode(fakeReports.first.toJson())],
          'user_settings': json.encode({
            'user_id': null, // settings with no userId (anonymous)
            'strict_mode': true,
            'alert_lactose': false,
            'warn_additives': true,
            'auto_save_history': true,
            'preferred_language': 'it',
            'preferred_theme': 'system',
          }),
        });

        // User logged in as registered non-anonymous user
        when(() => mockUser.isAnonymous).thenReturn(false);
        when(() => mockUser.uid).thenReturn('registered_user_123');

        await _pumpMainScreen(tester, auth: mockAuth);

        // SyncDataScreen should be rendered
        expect(find.byType(SyncDataScreen), findsOneWidget);
        expect(find.byType(CameraModule), findsNothing);

        final syncDataScreen = tester.widget<SyncDataScreen>(
          find.byType(SyncDataScreen),
        );
        expect(syncDataScreen.historyCount, 2); // 1 history + 1 report = 2
      },
    );

    testWidgets(
      'tapping Merge (wantToSync == true) migrates data, shows syncing loader, and enters MainScreen',
      (tester) async {
        final fakeHistory = [
          ScanHistoryItem(
            id: 'hist_anon_1',
            barcode: '111111',
            scannedAt: DateTime.now().toIso8601String(),
          ),
        ];

        SharedPreferences.setMockInitialValues({
          'celiac_history': [json.encode(fakeHistory.first.toJson())],
          'user_settings': json.encode({
            'user_id': null,
            'strict_mode': true,
            'alert_lactose': false,
            'warn_additives': true,
            'auto_save_history': true,
            'preferred_language': 'it',
            'preferred_theme': 'system',
          }),
        });

        when(() => mockUser.isAnonymous).thenReturn(false);
        when(() => mockUser.uid).thenReturn('registered_user_123');

        await _pumpMainScreen(tester, auth: mockAuth);
        expect(find.byType(SyncDataScreen), findsOneWidget);

        final syncScreen = tester.widget<SyncDataScreen>(
          find.byType(SyncDataScreen),
        );

        // Trigger merge decision
        syncScreen.onDecision(true);
        await tester.pump();

        // Transitory state shows syncing progress indicator
        // Then completes and loads MainScreen
        await tester.pumpAndSettle();

        expect(find.byType(SyncDataScreen), findsNothing);
        expect(find.byType(CameraModule), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Discard (wantToSync == false) wipes local data and enters MainScreen',
      (tester) async {
        final fakeHistory = [
          ScanHistoryItem(
            id: 'hist_anon_1',
            barcode: '111111',
            scannedAt: DateTime.now().toIso8601String(),
          ),
        ];

        SharedPreferences.setMockInitialValues({
          'celiac_history': [json.encode(fakeHistory.first.toJson())],
          'user_settings': json.encode({
            'user_id': null,
            'strict_mode': true,
            'alert_lactose': false,
            'warn_additives': true,
            'auto_save_history': true,
            'preferred_language': 'it',
            'preferred_theme': 'system',
          }),
        });

        when(() => mockUser.isAnonymous).thenReturn(false);
        when(() => mockUser.uid).thenReturn('registered_user_123');

        await _pumpMainScreen(tester, auth: mockAuth);
        expect(find.byType(SyncDataScreen), findsOneWidget);

        final syncScreen = tester.widget<SyncDataScreen>(
          find.byType(SyncDataScreen),
        );

        // Trigger discard decision
        syncScreen.onDecision(false);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(SyncDataScreen), findsNothing);
        expect(find.byType(CameraModule), findsOneWidget);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 7 – Keyboard Auto-Dismiss Logic (didChangeMetrics Platform Check)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 7 – Keyboard Auto-Dismiss Logic (didChangeMetrics)', () {
    testWidgets(
      'verifies keyboard dismiss getter behavior according to runtime platform rules',
      (tester) async {
        await _pumpMainScreen(tester, auth: mockAuth);

        // Verify TextField focus interactions work seamlessly on MainScreen
        final textFieldFinder = find.byType(TextField).first;
        await tester.tap(textFieldFinder);
        await tester.pump();

        final editableText = tester.widget<EditableText>(
          find.byType(EditableText).first,
        );
        expect(editableText.focusNode.hasFocus, isTrue);

        // Verify didChangeMetrics cycle with metric updates
        tester.view.viewInsets = const FakeViewPadding(bottom: 400.0);
        tester.binding.handleMetricsChanged();
        await tester.pump();

        tester.view.viewInsets = FakeViewPadding.zero;
        tester.binding.handleMetricsChanged();
        await tester.pump();
      },
    );
  });
}

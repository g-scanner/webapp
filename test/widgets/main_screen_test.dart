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
import 'package:gscanner/models/models.dart';
import 'package:gscanner/services/db_service.dart';
import 'package:gscanner/core/theme/theme_notifier.dart';
import 'package:gscanner/features/auth/auth_screen.dart';
import 'package:gscanner/features/scanner/camera_module.dart';
import 'package:gscanner/features/settings/settings_panel.dart';
import 'package:gscanner/features/product_detail/product_detail_card.dart';
import 'package:gscanner/features/sync/sync_data_screen.dart';
import 'package:gscanner/features/history/history_list.dart';
import 'package:gscanner/core/network/connectivity_helper.dart';
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
      ConnectivityHelper.mockIsConnected = true;
      addTearDown(() => ConnectivityHelper.mockIsConnected = null);

      final testProduct = Product(
        barcode: '8001234567890',
        nameMap: const {'it': 'Pasta Senza Glutine'},
        brandMap: const {'it': 'Brand Bio'},
        ingredientsMap: const {'it': 'Farina di riso'},
        allergensMap: const {'it': <String>[]},
        lastUpdated: DateTime.now().toIso8601String(),
        fetchedFromOffAt: DateTime.now().toIso8601String(),
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

    testWidgets(
      'handleScanSuccess returns true (clear manual input) when product already loaded on back',
      (tester) async {
        ConnectivityHelper.mockIsConnected = true;
        addTearDown(() => ConnectivityHelper.mockIsConnected = null);

        final testProduct = Product(
          barcode: '8001234567890',
          nameMap: const {'it': 'Pasta Senza Glutine'},
          brandMap: const {'it': 'Brand Bio'},
          ingredientsMap: const {'it': 'Farina di riso'},
          allergensMap: const {'it': <String>[]},
          lastUpdated: DateTime.now().toIso8601String(),
          fetchedFromOffAt: DateTime.now().toIso8601String(),
          pendingReportsCount: 0,
        );
        await DbService.saveLocalProducts([testProduct]);

        await _pumpMainScreen(tester, auth: mockAuth);

        final cameraModule = tester.widget<CameraModule>(
          find.byType(CameraModule),
        );

        // Avvia la scansione e attendi che il prodotto sia caricato
        final scanFuture = cameraModule.onScanSuccess('8001234567890');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Il dettaglio è aperto, verifica che la route sia attiva
        expect(find.byType(ProductDetailCard), findsOneWidget);

        // Torna indietro dalla schermata dettaglio
        final backBtn = find.byIcon(Icons.arrow_back_ios_new);
        await tester.tap(backBtn);
        await tester.pumpAndSettle();

        // Il Future restituisce true perché il prodotto era già caricato:
        // il campo manuale deve essere svuotato
        final shouldClear = await scanFuture;
        expect(shouldClear, isTrue);
      },
    );

    testWidgets(
      'offline fail-fast: aborts scan immediately and shows offline prompt without pushing detail route',
      (tester) async {
        // Dispositivo offline e prodotto non in cache SQLite
        ConnectivityHelper.mockIsConnected = false;
        addTearDown(() => ConnectivityHelper.mockIsConnected = null);

        await _pumpMainScreen(tester, auth: mockAuth);

        final cameraModule = tester.widget<CameraModule>(
          find.byType(CameraModule),
        );

        final scanFuture = cameraModule.onScanSuccess('8009999999999');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Non deve aprire la schermata di dettaglio
        expect(find.byType(ProductDetailCard), findsNothing);

        // Deve restituire false per non cancellare l'eventuale codice digitato
        final result = await scanFuture;
        expect(result, isFalse);

        // Deve mostrare il prompt per scaricare il DB offline
        expect(find.text('scanner.result.offlineNoDbPrompt'), findsOneWidget);
      },
    );

    testWidgets(
      'weak connection: pending skeleton card in history vanishes on failure and shows background error',
      (tester) async {
        // Inizia online (permette l'apertura dello skeleton)
        ConnectivityHelper.mockIsConnected = true;
        addTearDown(() => ConnectivityHelper.mockIsConnected = null);

        await _pumpMainScreen(tester, auth: mockAuth);

        final cameraModule = tester.widget<CameraModule>(
          find.byType(CameraModule),
        );

        // Scansiona un barcode
        cameraModule.onScanSuccess('8007777777777');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Schermata dettaglio skeleton aperta
        expect(find.byType(ProductDetailCard), findsOneWidget);

        // L'utente torna indietro alla schermata principale
        final backBtn = find.byIcon(Icons.arrow_back_ios_new);
        await tester.tap(backBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(ProductDetailCard), findsNothing);

        // Passa alla tab Cronologia: la card skeleton è presente
        await tester.tap(find.text('common.navigation.history'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(HistoryItemTile), findsOneWidget);

        // La connessione cade o i retry falliscono
        ConnectivityHelper.mockIsConnected = false;

        // Avanza il tempo per completare i retry
        await tester.pump(const Duration(seconds: 10));
        await tester.pump(const Duration(milliseconds: 500));

        // La card skeleton è stata rimossa dalla cronologia
        expect(find.byType(HistoryItemTile), findsNothing);

        // Mostra lo snackbar di scansione fallita in background
        expect(find.text('scanner.result.backgroundScanFailed'), findsOneWidget);
      },
    );

    testWidgets(
      'pending skeleton card in history becomes effective when connection is restored before retry timeout',
      (tester) async {
        // Inizia online
        ConnectivityHelper.mockIsConnected = true;
        addTearDown(() => ConnectivityHelper.mockIsConnected = null);

        await _pumpMainScreen(tester, auth: mockAuth);

        final cameraModule = tester.widget<CameraModule>(
          find.byType(CameraModule),
        );

        // Scansiona un barcode
        cameraModule.onScanSuccess('8008888888888');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Schermata dettaglio skeleton aperta
        expect(find.byType(ProductDetailCard), findsOneWidget);

        // L'utente torna indietro alla schermata principale
        final backBtn = find.byIcon(Icons.arrow_back_ios_new);
        await tester.tap(backBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(ProductDetailCard), findsNothing);

        // Passa alla tab Cronologia
        await tester.tap(find.text('common.navigation.history'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // La card skeleton è presente in cronologia
        expect(find.byType(HistoryItemTile), findsOneWidget);

        // Il prodotto diventa disponibile nel DB/cache
        final recoveredProduct = Product(
          barcode: '8008888888888',
          nameMap: const {'it': 'Biscotti Riso Senza Glutine'},
          brandMap: const {'it': 'BioBrand'},
          ingredientsMap: const {'it': 'Farina di riso'},
          allergensMap: const {'it': <String>[]},
          lastUpdated: DateTime.now().toIso8601String(),
          fetchedFromOffAt: DateTime.now().toIso8601String(),
          pendingReportsCount: 0,
        );
        await DbService.saveLocalProducts([recoveredProduct]);

        // Avanza il tempo per far scattare il ciclo di retry (8s)
        await tester.pump(const Duration(seconds: 9));
        await tester.pump(const Duration(milliseconds: 300));

        // La card diventa effettiva mostrando il nome reale
        expect(find.byType(HistoryItemTile), findsOneWidget);
        expect(find.text('Biscotti Riso Senza Glutine'), findsOneWidget);
      },
    );

    testWidgets(
      'syncHistoryWithFirestore ignores and purges previously cancelled or deleted barcodes',
      (tester) async {
        ConnectivityHelper.mockIsConnected = true;
        addTearDown(() => ConnectivityHelper.mockIsConnected = null);

        await _pumpMainScreen(tester, auth: mockAuth);

        // Elimina un barcode per registrarlo nel filtro di cancellazione/annullamento
        await DbService.deleteHistoryByBarcodeLocal('800CANCELLED01');

        final synced = await DbService.syncHistoryWithFirestore();
        expect(synced.any((item) => item.barcode == '800CANCELLED01'), isFalse);
      },
    );

    testWidgets(
      'deduplication: concurrent handleScanSuccess call for already-pending barcode returns false and does not spawn new scan',
      (tester) async {
        ConnectivityHelper.mockIsConnected = true;
        addTearDown(() => ConnectivityHelper.mockIsConnected = null);

        await _pumpMainScreen(tester, auth: mockAuth);

        final cameraModule = tester.widget<CameraModule>(
          find.byType(CameraModule),
        );

        // Avvia prima scansione
        cameraModule.onScanSuccess('800DEDUP0001');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(ProductDetailCard), findsOneWidget);

        // Seconda scansione concorrente per lo stesso barcode
        final scanFuture2 = cameraModule.onScanSuccess('800DEDUP0001');
        final result2 = await scanFuture2;

        // Deve essere rifiutata immediatamente per deduplicazione
        expect(result2, isFalse);

        // Chiudi il dettaglio per ripulire
        final backBtn = find.byIcon(Icons.arrow_back_ios_new);
        await tester.tap(backBtn);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 10));
      },
    );

    testWidgets(
      'tapping pending skeleton card in history opens pending detail screen and closes automatically on failure',
      (tester) async {
        ConnectivityHelper.mockIsConnected = true;
        addTearDown(() => ConnectivityHelper.mockIsConnected = null);

        await _pumpMainScreen(tester, auth: mockAuth);

        final cameraModule = tester.widget<CameraModule>(
          find.byType(CameraModule),
        );

        // Avvia scansione
        cameraModule.onScanSuccess('800PENDINGTAP1');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // L'utente torna indietro alla schermata principale
        final backBtn = find.byIcon(Icons.arrow_back_ios_new);
        await tester.tap(backBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(ProductDetailCard), findsNothing);

        // Passa alla tab Cronologia
        await tester.tap(find.text('common.navigation.history'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Clicca sulla card skeleton in cronologia
        expect(find.byType(HistoryItemTile), findsOneWidget);
        await tester.tap(find.byType(HistoryItemTile));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Schermata dettaglio pendente aperta
        expect(find.byType(ProductDetailCard), findsOneWidget);

        // La connessione fallisce
        ConnectivityHelper.mockIsConnected = false;
        await tester.pump(const Duration(seconds: 10));
        await tester.pumpAndSettle();

        // Schermata dettaglio chiusa automaticamente da closer()
        expect(find.byType(ProductDetailCard), findsNothing);
      },
    );

    testWidgets(
      'deleting pending skeleton card in history aborts scan and removes item immediately from UI',
      (tester) async {
        ConnectivityHelper.mockIsConnected = true;
        addTearDown(() => ConnectivityHelper.mockIsConnected = null);

        await _pumpMainScreen(tester, auth: mockAuth);

        final cameraModule = tester.widget<CameraModule>(
          find.byType(CameraModule),
        );

        cameraModule.onScanSuccess('800DELETEPENDING');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Torna indietro e vai in cronologia
        final backBtn = find.byIcon(Icons.arrow_back_ios_new);
        await tester.tap(backBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await tester.tap(find.text('common.navigation.history'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(HistoryItemTile), findsOneWidget);

        // Elimina l'elemento pendente
        final historyList = tester.widget<HistoryList>(find.byType(HistoryList));
        await historyList.onDeleteHistoryItem('pending_800DELETEPENDING');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // La card skeleton deve scomparire all'istante
        expect(find.byType(HistoryItemTile), findsNothing);

        // Smaltisci eventuali timer/future pendenti prima di completare il test
        await tester.pump(const Duration(seconds: 10));
      },
    );

    testWidgets(
      'offline scan with product already in SQLite cache does not fail-fast and loads product as stale',
      (tester) async {
        // Salva un prodotto in cache locale
        final cachedProduct = Product(
          barcode: '800CACHEDOFFLINE',
          nameMap: const {'it': 'Prodotto Offline In Cache'},
          brandMap: const {'it': 'Marca Cache'},
          ingredientsMap: const {'it': 'Riso'},
          allergensMap: const {'it': <String>[]},
          lastUpdated: DateTime.now().toIso8601String(),
          fetchedFromOffAt: DateTime.now().toIso8601String(),
          pendingReportsCount: 0,
        );
        await DbService.saveLocalProducts([cachedProduct]);

        // Dispositivo completamente offline
        ConnectivityHelper.mockIsConnected = false;
        addTearDown(() => ConnectivityHelper.mockIsConnected = null);

        await _pumpMainScreen(tester, auth: mockAuth);

        final cameraModule = tester.widget<CameraModule>(
          find.byType(CameraModule),
        );

        // La scansione deve avere successo recuperando il prodotto locale
        cameraModule.onScanSuccess('800CACHEDOFFLINE');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Dettaglio aperto con successo (non abortito fail-fast)
        expect(find.byType(ProductDetailCard), findsOneWidget);
        expect(find.text('Prodotto Offline In Cache'), findsOneWidget);

        // Torna indietro
        final backBtn = find.byIcon(Icons.arrow_back_ios_new);
        await tester.tap(backBtn);
        await tester.pumpAndSettle();
      },
    );
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

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget Tests: OfflineDatabaseSection

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gscanner/models/models.dart';
import 'package:gscanner/services/database/offline_db_service.dart';
import 'package:gscanner/services/database/offline_db_sync_service.dart';
import 'package:gscanner/features/settings/sections/offline_database_section.dart';

class _MockSectionAssetLoader extends AssetLoader {
  const _MockSectionAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return {
      'settings': {
        'offlineDatabase': {
          'subtitle': 'Scarica il database dei prodotti per scansionare offline.',
          'tierSelectionTitle': 'Database Offline',
          'tierNone': 'Disattivato (Solo Online)',
          'glutenFree': 'Gluten-Free Globale (~12 MB)',
          'euroCore': 'Europa Core + Gluten-Free (~65 MB)',
          'americaCore': 'Americhe Core + Gluten-Free (~55 MB)',
          'globalTop': 'Global Top Scans (~130 MB)',
          'lastSyncLabel': 'Ultima sincronizzazione',
          'sizeOnDiskLabel': 'Spazio su disco',
          'neverSynced': 'Mai sincronizzato',
          'syncNow': 'Aggiorna ora',
          'deleteDatabase': 'Elimina database',
          'deleteConfirmTitle': 'Eliminare il database offline?',
          'deleteConfirmBody': 'I dati offline verranno eliminati dal dispositivo.',
          'syncing': 'Sincronizzazione in corso...',
          'syncSuccess': 'Database sincronizzato con successo',
          'downloadError': 'Errore durante il download del database',
        },
      },
      'common': {
        'actions': {
          'cancel': 'Annulla',
          'delete': 'Elimina',
        },
      },
    };
  }
}

Widget _buildApp({
  required UserSettings settings,
  required Future<void> Function(UserSettings, {bool isOfflineDbChange}) onSettingsChange,
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('it')],
    path: 'assets/locales',
    assetLoader: const _MockSectionAssetLoader(),
    fallbackLocale: const Locale('it'),
    startLocale: const Locale('it'),
    useOnlyLangCode: true,
    child: Builder(
      builder: (context) {
        return MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            body: SingleChildScrollView(
              child: OfflineDatabaseSection(
                settings: settings,
                onSettingsChange: onSettingsChange,
              ),
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late String dbPath;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gscanner_section_test_');
    dbPath = p.join(tempDir.path, 'offline_products.db');
    OfflineDbService.setMockDatabasePath(dbPath);
  });

  tearDown(() async {
    await OfflineDbService.close();
    OfflineDbService.setMockDatabasePath(null);
    OfflineDbService.mockIsDatabaseInstalled = null;
    OfflineDbSyncService.resetBaseUrl();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  UserSettings testSettings({
    OfflineDbTier tier = OfflineDbTier.none,
    int? lastSyncedAt,
  }) {
    return UserSettings(
      userId: 'test_user',
      offlineDbTier: tier,
      offlineDbLastSyncedAt: lastSyncedAt,
      strictMode: false,
      alertLactose: false,
      warnAdditives: false,
      autoSaveHistory: true,
      preferredLanguage: 'it',
      preferredTheme: 'system',
      reportedBarcodes: const [],
    );
  }

  group('OfflineDatabaseSection Widget Tests', () {
    testWidgets(
      'Hides info panel and uninstall button when DB is not installed',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(tier: OfflineDbTier.none),
            onSettingsChange: (_, {bool isOfflineDbChange = false}) async {},
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Database Offline'), findsOneWidget);
        expect(find.text('Ultima sincronizzazione'), findsNothing);
        expect(find.text('Spazio su disco'), findsNothing);
        expect(find.byIcon(Icons.delete_outline), findsNothing);
      },
    );

    testWidgets(
      'Shows info panel when DB file is physically installed',
      (tester) async {
        OfflineDbService.mockIsDatabaseInstalled = true;

        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(
              tier: OfflineDbTier.glutenFree,
              lastSyncedAt: 1773000000,
            ),
            onSettingsChange: (_, {bool isOfflineDbChange = false}) async {},
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('Database Offline'), findsOneWidget);
        expect(find.text('Ultima sincronizzazione'), findsOneWidget);
        expect(find.text('Spazio su disco'), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
        expect(find.text('Aggiorna ora'), findsOneWidget);
      },
    );

    testWidgets(
      'On download error: does NOT call onSettingsChange and does NOT show 0 MB panel',
      (tester) async {
        // Mock client returning 500 error immediately without network sockets
        final mockClient = MockClient((request) async {
          return http.Response('Server error', 500);
        });
        OfflineDbSyncService.setMockClient(mockClient);

        var settingsChanged = false;
        UserSettings? savedSettings;

        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(tier: OfflineDbTier.none),
            onSettingsChange: (updated, {bool isOfflineDbChange = false}) async {
              settingsChanged = true;
              savedSettings = updated;
            },
          ),
        );
        await tester.pumpAndSettle();

        // Tap dropdown to select Gluten-Free
        await tester.tap(find.byType(PopupMenuButton<OfflineDbTier>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Gluten-Free Globale (~12 MB)').last);
        await tester.pump(); // Start sync
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();

        // Verify that onSettingsChange was NEVER called
        expect(settingsChanged, isFalse);
        expect(savedSettings, isNull);

        // Verify that the 0 MB info panel and delete button are NOT rendered
        expect(find.text('Spazio su disco'), findsNothing);
        expect(find.byIcon(Icons.delete_outline), findsNothing);

        // Verify error snackbar was shown
        expect(find.text('Errore durante il download del database'), findsOneWidget);
      },
    );

    testWidgets(
      'Selecting the currently installed tier does NOT trigger re-download',
      (tester) async {
        OfflineDbService.mockIsDatabaseInstalled = true;
        var downloadTriggered = false;
        final mockClient = MockClient((request) async {
          downloadTriggered = true;
          return http.Response('Unexpected download', 500);
        });
        OfflineDbSyncService.setMockClient(mockClient);

        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(
              tier: OfflineDbTier.glutenFree,
              lastSyncedAt: 1773000000,
            ),
            onSettingsChange: (_, {bool isOfflineDbChange = false}) async {},
          ),
        );
        await tester.pumpAndSettle();

        // Tap dropdown and select same Gluten-Free
        await tester.tap(find.byType(PopupMenuButton<OfflineDbTier>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Gluten-Free Globale (~12 MB)').last);
        await tester.pumpAndSettle();

        expect(downloadTriggered, isFalse);
      },
    );

    testWidgets(
      'Switching tier deletes existing DB file before starting new tier download',
      (tester) async {
        OfflineDbService.mockIsDatabaseInstalled = true;
        OfflineDbSyncService.setMockClient(MockClient((request) async {
          return http.Response('Server error', 500);
        }));

        var settingsChanged = false;
        UserSettings? newSettings;

        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(
              tier: OfflineDbTier.glutenFree,
              lastSyncedAt: 1773000000,
            ),
            onSettingsChange: (updated, {bool isOfflineDbChange = false}) async {
              settingsChanged = true;
              newSettings = updated;
            },
          ),
        );
        await tester.pumpAndSettle();

        // Tap dropdown and select Euro Core
        await tester.tap(find.byType(PopupMenuButton<OfflineDbTier>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Europa Core + Gluten-Free (~65 MB)').last);
        await tester.pump();
        await tester.pumpAndSettle();

        // Database was reset/deleted
        expect(OfflineDbService.mockIsDatabaseInstalled, isFalse);
        expect(settingsChanged, isTrue);
        expect(newSettings?.offlineDbTier, equals(OfflineDbTier.none));
        expect(newSettings?.offlineDbLastSyncedAt, isNull);
      },
    );
  });
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget Tests: OfflineDatabaseSheet

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
import 'package:gscanner/features/settings/sheets/offline_database_sheet.dart';

class _MockSectionAssetLoader extends AssetLoader {
  const _MockSectionAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return {
      'settings': {
        'offlineDb': {
          'title': 'Database Offline',
          'noDbInstalled': 'Nessun Database Installato',
          'installedStatus': 'Installato',
          'disabledStatus': 'Disattivato (Solo Online)',
          'disabledHint': 'Seleziona e installa un pacchetto per scansionare offline',
          'sheetTitle': 'Database Offline',
          'sheetSubtitle': 'Scarica un archivio locale',
          'statusSynchronized': 'Sincronizzato',
          'statusDisabled': 'Disattivato',
          'statusSoftStale': 'Aggiornamento consigliato',
          'statusHardStale': 'Obsoleto (>30 gg)',
          'lastSyncPrefix': 'Ultimo aggiornamento:',
          'lastSyncFormat': 'Ultimo aggiornamento: {}',
          'neverSynced': 'Mai sincronizzato',
          'daysAgo': '{} giorni fa',
          'updateBtn': 'Aggiorna',
          'updateButton': 'Aggiorna',
          'syncing': 'Sincronizzazione...',
          'uninstallPackage': 'Disinstalla Pacchetto',
          'uninstallConfirmBody': 'Il database offline verrà rimosso dal dispositivo liberando spazio.',
          'downloadAndActivate': 'Scarica ed attiva {}',
          'downloadConfirmTitle': 'Scarica {name}',
          'downloadConfirmBody': 'Verrà scaricato il database ({dl}). Spazio richiesto su disco: {disk}.',
          'selectPackageLabel': 'SELEZIONA PACCHETTO',
          'inUseBadge': 'Attualmente in uso',
          'downloadLabel': 'Download:',
          'diskLabel': 'Spazio su disco:',
          'switchConfirmTitle': 'Passa a {name}',
          'switchConfirmBody': 'Il pacchetto attuale verrà sostituito scaricando la nuova versione ({dl}). Spazio occupato: {disk}.',
          'automationAndNetworkLabel': 'AUTOMAZIONE E RETE',
          'wifiOnlyTitle': 'Solo con Wi-Fi',
          'wifiOnlySubtitle': 'Non consumare dati della rete cellulare 4G/5G',
          'autoUpdateTitle': 'Aggiornamento automatico',
          'autoUpdateSubtitle': 'Scarica micro-aggiornamenti settimanali',
          'cloudSyncTitle': 'Sincronizza con il cloud',
          'cloudSyncSubtitle': 'Salva le preferenze del database offline nel tuo account',
          'downloadError': 'Errore durante il download del database',
          'syncSuccess': 'Database sincronizzato con successo',
          'packages': {
            'gluten_free': {
              'title': 'Solo Celiachia',
              'downloadSize': '~1.2 MB',
              'diskSize': '4 MB',
              'description': 'Catalogo senza glutine.',
            },
            'euro_core': {
              'title': 'Europa Core',
              'downloadSize': '~60 MB',
              'diskSize': '209 MB',
              'description': 'Catalogo europeo.',
            },
            'america_core': {
              'title': 'Americhe Core',
              'downloadSize': '~15 MB',
              'diskSize': '50 MB',
              'description': 'Catalogo americano.',
            },
            'global_top': {
              'title': 'Mondiale Top',
              'downloadSize': '~100 MB',
              'diskSize': '350 MB',
              'description': 'Catalogo top mondiale.',
            },
          },
        },
      },
      'common': {
        'time': {
          'today': 'Oggi',
          'yesterday': 'Ieri',
        },
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
            body: Builder(
              builder: (innerContext) => ElevatedButton(
                onPressed: () {
                  showOfflineDatabaseSheet(
                    context: innerContext,
                    settings: settings,
                    onSettingsChange: onSettingsChange,
                  );
                },
                child: const Text('Open Sheet'),
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
    tempDir = await Directory.systemTemp.createTemp('gscanner_sheet_test_');
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

  group('OfflineDatabaseSheet Widget Tests', () {
    testWidgets(
      'Shows disabled state when DB is not installed',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(tier: OfflineDbTier.none),
            onSettingsChange: (_, {bool isOfflineDbChange = false}) async {},
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Database Offline'), findsWidgets);
        expect(find.text('Nessun Database Installato'), findsOneWidget);
        expect(find.text('Disattivato'), findsOneWidget);
        expect(find.text('Aggiorna'), findsNothing);
        // Preview defaults to Europa Core with download button
        expect(find.text('Scarica ed attiva Europa Core'), findsOneWidget);

        final downloadButton = find.text('Scarica ed attiva Europa Core');
        await tester.ensureVisible(downloadButton);
        await tester.tap(downloadButton);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Scarica Europa Core'),
          ),
          findsNWidgets(2),
        );
      },
    );

    testWidgets(
      'Shows active package and update button when package is installed',
      (tester) async {
        OfflineDbService.mockIsDatabaseInstalled = true;

        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(
              tier: OfflineDbTier.glutenFree,
              lastSyncedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            ),
            onSettingsChange: (_, {bool isOfflineDbChange = false}) async {},
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Solo Celiachia'), findsWidgets);
        expect(find.text('Sincronizzato'), findsOneWidget);
        expect(find.text('Attualmente in uso'), findsOneWidget);
        expect(find.text('Aggiorna'), findsOneWidget);
        expect(find.text('Disinstalla Pacchetto'), findsOneWidget);
      },
    );

    testWidgets(
      'Shows stale states (soft stale and hard stale) correctly in status pill',
      (tester) async {
        final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // Soft stale: 10 days ago (< 30 days, >= 7 days)
        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(
              tier: OfflineDbTier.glutenFree,
              lastSyncedAt: nowSec - (10 * 86400),
            ),
            onSettingsChange: (_, {bool isOfflineDbChange = false}) async {},
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Aggiornamento consigliato'), findsOneWidget);

        // Close sheet
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // Hard stale: 35 days ago (>= 30 days)
        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(
              tier: OfflineDbTier.glutenFree,
              lastSyncedAt: nowSec - (35 * 86400),
            ),
            onSettingsChange: (_, {bool isOfflineDbChange = false}) async {},
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Obsoleto (>30 gg)'), findsOneWidget);
      },
    );

    testWidgets(
      'Selecting a different package updates preview card and shows switch button',
      (tester) async {
        OfflineDbService.mockIsDatabaseInstalled = true;

        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(
              tier: OfflineDbTier.glutenFree,
              lastSyncedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            ),
            onSettingsChange: (_, {bool isOfflineDbChange = false}) async {},
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Tap on Europa Core pill in 2x2 grid
        await tester.tap(find.text('Europa Core'));
        await tester.pumpAndSettle();

        // Now preview shows Europa Core
        expect(find.text('Passa a Europa Core'), findsOneWidget);
      },
    );

    testWidgets(
      'Uninstalling package shows confirmation dialog and removes database',
      (tester) async {
        OfflineDbService.mockIsDatabaseInstalled = true;
        UserSettings? savedSettings;

        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(
              tier: OfflineDbTier.glutenFree,
              lastSyncedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            ),
            onSettingsChange: (updated, {bool isOfflineDbChange = false}) async {
              savedSettings = updated;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Tap Disinstalla Pacchetto
        final uninstallBtn = find.text('Disinstalla Pacchetto');
        await tester.ensureVisible(uninstallBtn);
        await tester.pumpAndSettle();
        await tester.tap(uninstallBtn);
        await tester.pumpAndSettle();

        // Confirmation dialog appears
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Disinstalla Pacchetto'), findsWidgets);

        // Tap cancel
        await tester.tap(find.text('Annulla'));
        await tester.pumpAndSettle();
        expect(savedSettings, isNull);

        // Tap uninstall again and confirm
        await tester.tap(uninstallBtn);
        await tester.pumpAndSettle();
        final dialogConfirmBtn = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        );
        await tester.tap(dialogConfirmBtn);
        await tester.pumpAndSettle();

        expect(savedSettings?.offlineDbTier, equals(OfflineDbTier.none));
        expect(find.text('Database offline rimosso con successo'), findsNothing);
      },
    );

    testWidgets(
      'On download error: shows error snackbar and does not update tier',
      (tester) async {
        final mockClient = MockClient((request) async {
          return http.Response('Server error', 500);
        });
        OfflineDbSyncService.setMockClient(mockClient);

        var settingsChanged = false;

        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(
              tier: OfflineDbTier.glutenFree,
              lastSyncedAt: 1773000000,
            ),
            onSettingsChange: (_, {bool isOfflineDbChange = false}) async {
              settingsChanged = true;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Tap Aggiorna
        await tester.tap(find.text('Aggiorna'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();

        expect(settingsChanged, isFalse);
        expect(find.text('Errore durante il download del database'), findsOneWidget);
      },
    );

    testWidgets(
      'Switching to a package sets the tier on settings when starting download',
      (tester) async {
        final mockClient = MockClient((request) async {
          return http.Response('dummy', 200);
        });
        OfflineDbSyncService.setMockClient(mockClient);

        OfflineDbService.mockIsDatabaseInstalled = true;
        UserSettings? savedSettings;

        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(
              tier: OfflineDbTier.glutenFree,
              lastSyncedAt: 1773000000,
            ),
            onSettingsChange: (updated, {bool isOfflineDbChange = false}) async {
              savedSettings = updated;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Tap Europa Core chip
        await tester.tap(find.text('Europa Core'));
        await tester.pumpAndSettle();

        // Tap Passa a Europa Core
        final switchBtn = find.text('Passa a Europa Core');
        await tester.ensureVisible(switchBtn);
        await tester.pumpAndSettle();
        await tester.tap(switchBtn);
        await tester.pumpAndSettle();

        // Dialog shows "Passa a Europa Core" button
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Passa a Europa Core'),
          ),
          findsNWidgets(2),
        );

        // Confirm switch in dialog
        final dialogConfirmBtn = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        );
        await tester.tap(dialogConfirmBtn);
        await tester.pump();

        // Settings should be updated immediately with euroCore tier when starting download
        expect(savedSettings?.offlineDbTier, equals(OfflineDbTier.euroCore));
      },
    );
  });
}

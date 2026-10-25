// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget Tests: OfflineDatabaseSheet

import 'dart:async';
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
          'disabledHint':
              'Seleziona e installa un pacchetto per scansionare offline',
          'sheetTitle': 'Database Offline',
          'sheetSubtitle': 'Scarica un archivio locale',
          'statusSynchronized': 'Sincronizzato',
          'statusDisabled': 'Disattivato',
          'statusDownloading': 'Download in corso',
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
          'uninstallConfirmBody':
              'Il database offline verrà rimosso dal dispositivo liberando spazio.',
          'downloadAndActivate': 'Scarica ed attiva {}',
          'downloadConfirmTitle': 'Scarica {name}',
          'downloadConfirmBody':
              'Verrà scaricato il database ({dl}). Spazio richiesto su disco: {disk}.',
          'selectPackageLabel': 'SELEZIONA PACCHETTO',
          'inUseBadge': 'Attualmente in uso',
          'downloadLabel': 'Download:',
          'diskLabel': 'Spazio su disco:',
          'switchConfirmTitle': 'Passa a {name}',
          'switchConfirmBody':
              'Il pacchetto attuale verrà sostituito scaricando la nuova versione ({dl}). Spazio occupato: {disk}.',
          'automationAndNetworkLabel': 'AUTOMAZIONE E RETE',
          'wifiOnlyTitle': 'Solo con Wi-Fi',
          'wifiOnlySubtitle': 'Non consumare dati della rete cellulare 4G/5G',
          'autoUpdateTitle': 'Aggiornamento automatico',
          'autoUpdateSubtitle': 'Scarica micro-aggiornamenti settimanali',
          'cloudSyncTitle': 'Sincronizza con il cloud',
          'cloudSyncSubtitle':
              'Salva le preferenze del database offline nel tuo account',
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
        'time': {'today': 'Oggi', 'yesterday': 'Ieri'},
        'actions': {'cancel': 'Annulla', 'delete': 'Elimina'},
      },
    };
  }
}

Widget _buildApp({
  required UserSettings settings,
  required Future<void> Function(UserSettings, {bool isOfflineDbChange})
  onSettingsChange,
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
    OfflineDbSyncService.setMockClient(null);
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
    testWidgets('Shows disabled state when DB is not installed', (
      tester,
    ) async {
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
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(OutlinedButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'Automation and network settings remain editable without an installed DB',
      (tester) async {
        UserSettings? savedSettings;

        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(tier: OfflineDbTier.none),
            onSettingsChange:
                (updated, {bool isOfflineDbChange = false}) async {
                  savedSettings = updated;
                },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        final switches = find.byType(Switch);
        expect(switches, findsNWidgets(3));
        for (var i = 0; i < 3; i++) {
          expect(tester.widget<Switch>(switches.at(i)).onChanged, isNotNull);
        }

        await tester.ensureVisible(switches.at(0));
        await tester.tap(switches.at(0));
        await tester.pumpAndSettle();
        expect(savedSettings?.offlineDbAutoSync, isFalse);

        await tester.ensureVisible(switches.at(1));
        await tester.tap(switches.at(1));
        await tester.pumpAndSettle();
        expect(savedSettings?.offlineDbWifiOnly, isFalse);

        await tester.ensureVisible(switches.at(2));
        await tester.tap(switches.at(2));
        await tester.pumpAndSettle();
        expect(savedSettings?.offlineDbCloudSync, isTrue);
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
      'Shows downloading state, percentage and cancel button (X) when sync is in progress, and allows cancelling',
      (tester) async {
        final completer = Completer<http.Response>();
        final mockClient = MockClient((request) => completer.future);
        OfflineDbSyncService.setMockClient(mockClient);

        OfflineDbService.mockIsDatabaseInstalled = true;

        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(
              tier: OfflineDbTier.glutenFree,
              lastSyncedAt: 0,
            ),
            onSettingsChange: (_, {bool isOfflineDbChange = false}) async {},
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Tap Aggiorna to trigger sync/download
        await tester.tap(find.text('Aggiorna'));
        await tester.pump();

        // During sync, status pill should display "Download in corso"
        expect(find.text('Download in corso'), findsOneWidget);
        // Percentage is explicitly displayed
        expect(find.text('5%'), findsOneWidget);
        // Cancel button (X) is present to the right
        final cancelBtn = find.byKey(const ValueKey('cancelSyncButton'));
        expect(cancelBtn, findsOneWidget);

        // Tap cancel button (X)
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        // Sync stopped: cancel button and percentage are gone, "Aggiorna" is restored
        expect(find.byKey(const ValueKey('cancelSyncButton')), findsNothing);
        expect(find.text('5%'), findsNothing);
        expect(find.text('Aggiorna'), findsOneWidget);
      },
    );

    testWidgets(
      'Cancelling an initial download resets state back to disabled/no database',
      (tester) async {
        final completer = Completer<http.Response>();
        final mockClient = MockClient((request) => completer.future);
        OfflineDbSyncService.setMockClient(mockClient);

        OfflineDbService.mockIsDatabaseInstalled = false;
        UserSettings? savedSettings;

        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(tier: OfflineDbTier.none),
            onSettingsChange:
                (updated, {bool isOfflineDbChange = false}) async {
                  savedSettings = updated;
                },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Tap download Europa Core
        final downloadBtn = find.text('Scarica ed attiva Europa Core');
        await tester.ensureVisible(downloadBtn);
        await tester.tap(downloadBtn);
        await tester.pumpAndSettle();

        // Confirm download in dialog
        final dialogConfirmBtn = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        );
        await tester.tap(dialogConfirmBtn);
        await tester.pump();

        // While downloading: "Download in corso", percentage and cancel button visible
        expect(find.text('Download in corso'), findsOneWidget);
        final cancelBtn = find.byKey(const ValueKey('cancelSyncButton'));
        expect(cancelBtn, findsOneWidget);

        // Ensure cancel button is scrolled into view before tapping
        await tester.ensureVisible(cancelBtn);
        await tester.pumpAndSettle();

        // Tap cancel button (X)
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        // Resets back to disabled and settings were never mutated
        expect(find.text('Disattivato'), findsOneWidget);
        expect(find.text('Nessun Database Installato'), findsOneWidget);
        expect(savedSettings, isNull);
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
            onSettingsChange:
                (updated, {bool isOfflineDbChange = false}) async {
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
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(OutlinedButton),
          ),
          findsOneWidget,
        );

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
        expect(
          find.text('Database offline rimosso con successo'),
          findsNothing,
        );
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
        expect(
          find.text('Errore durante il download del database'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Switching to a package does not prematurely mutate settings until download completes',
      (tester) async {
        final completer = Completer<http.Response>();
        final mockClient = MockClient((request) => completer.future);
        OfflineDbSyncService.setMockClient(mockClient);

        OfflineDbService.mockIsDatabaseInstalled = true;
        UserSettings? savedSettings;

        await tester.pumpWidget(
          _buildApp(
            settings: testSettings(
              tier: OfflineDbTier.glutenFree,
              lastSyncedAt: 1773000000,
            ),
            onSettingsChange:
                (updated, {bool isOfflineDbChange = false}) async {
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

        // Confirm switch in dialog
        final dialogConfirmBtn = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        );
        await tester.tap(dialogConfirmBtn);
        await tester.pump();

        // During download: settings have NOT been mutated prematurely to euroCore
        expect(savedSettings, isNull);

        // Hero card shows the package being downloaded: Europa Core
        expect(find.text('Europa Core'), findsWidgets);
        expect(find.text('Download in corso'), findsOneWidget);

        // Cancel switch via (X) button
        final cancelBtn = find.byKey(const ValueKey('cancelSyncButton'));
        expect(cancelBtn, findsOneWidget);
        await tester.ensureVisible(cancelBtn);
        await tester.pumpAndSettle();
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        // Rollback: Hero card rolls back to previous DB (Solo Celiachia)
        expect(find.text('Solo Celiachia'), findsWidgets);
        expect(find.text('Download in corso'), findsNothing);
      },
    );

    testWidgets(
      'On switch error: rolls back to previous installed package and retains original settings',
      (tester) async {
        final mockClient = MockClient((request) async {
          return http.Response('Server Error', 500);
        });
        OfflineDbSyncService.setMockClient(mockClient);

        OfflineDbService.mockIsDatabaseInstalled = true;
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

        // Tap Europa Core
        await tester.tap(find.text('Europa Core'));
        await tester.pumpAndSettle();

        final switchBtn = find.text('Passa a Europa Core');
        await tester.ensureVisible(switchBtn);
        await tester.pumpAndSettle();
        await tester.tap(switchBtn);
        await tester.pumpAndSettle();

        // Confirm in dialog
        final dialogConfirmBtn = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        );
        await tester.tap(dialogConfirmBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();

        // Because download failed with error:
        // 1. Error snackbar is shown
        expect(
          find.text('Errore durante il download del database'),
          findsOneWidget,
        );
        // 2. Settings were never changed
        expect(settingsChanged, isFalse);
        // 3. UI rolled back to previous package: Solo Celiachia
        expect(find.text('Solo Celiachia'), findsWidgets);
        expect(find.text('Download in corso'), findsNothing);
      },
    );
  });
}

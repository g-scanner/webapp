// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget Tests: Offline Warning Cards

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gscanner/models/models.dart';
import 'package:gscanner/features/product_detail/widgets/offline_database_warning_card.dart';
import 'package:gscanner/features/product_detail/widgets/offline_not_found_warning_card.dart';
import 'package:gscanner/features/product_detail/widgets/section_card.dart';
import '../mocks/shared_mocks.dart';

class _MockWarningAssetLoader extends AssetLoader {
  const _MockWarningAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return {
      'product': {
        'offlineWarnings': {
          'databaseWarningTitle': 'SCANSIONE OFFLINE',
          'databaseWarningBody': 'I dati di questo prodotto provengono dal database offline. L\'aggiornamento automatico delle informazioni avverrà appena il dispositivo sarà connesso a Internet.',
          'databaseWarningCaution': 'Le ricette e gli stabilimenti possono cambiare nel tempo. Leggi l\'etichetta fisica per sicurezza.',
          'databaseStaleWarningTitle': 'DATABASE NON AGGIORNATO',
          'databaseStaleWarningBody': 'I dati di questo prodotto provengono da un database offline non aggiornato. Aggiorna il database per rendere sicure le tue scansioni offline. L\'aggiornamento automatico delle informazioni avverrà appena il dispositivo sarà connesso a Internet.',
          'notFoundTitle': 'PRODOTTO NON PRESENTE NEL DB OFFLINE',
          'notFoundBody': 'Questo codice a barre non è presente nella versione {tier} del database offline.',
          'notFoundBodyGeneric': 'Questo codice a barre non è presente nella copia del database offline installata sul dispositivo.',
          'notFoundUpgradeHint': 'Prova a installare una versione più ricca del database offline.',
          'notFoundAction': 'Connettiti a Internet per ricercare il prodotto nel catalogo globale in tempo reale o verifica direttamente l\'etichetta fisica.',
        },
      },
      'settings': {
        'offlineDb': {
          'disabledStatus': 'Disattivato (Solo Online)',
          'packages': {
            'gluten_free': {'title': 'Gluten-Free Globale (~12 MB)'},
            'euro_core': {'title': 'Europa Core + Gluten-Free (~65 MB)'},
            'america_core': {'title': 'Americhe Core + Gluten-Free (~55 MB)'},
            'global_top': {'title': 'Global Top Scans (~130 MB)'},
          },
        },
      },
    };
  }
}

Widget createCustomWarningApp(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('it')],
    path: 'assets/locales',
    assetLoader: const _MockWarningAssetLoader(),
    fallbackLocale: const Locale('it'),
    startLocale: const Locale('it'),
    useOnlyLangCode: true,
    child: Builder(
      builder: (context) {
        return MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(body: child),
        );
      },
    ),
  );
}

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

    testWidgets('isDbStale: false shows standard title and body', (tester) async {
      await tester.pumpWidget(
        createCustomWarningApp(
          const OfflineDatabaseWarningCard(isDbStale: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SCANSIONE OFFLINE'), findsOneWidget);
      expect(find.textContaining('I dati di questo prodotto provengono dal database offline.'), findsOneWidget);
      expect(find.textContaining('Le ricette e gli stabilimenti possono cambiare nel tempo.'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets('isDbStale: true shows DATABASE NON AGGIORNATO, updated body and reused caution', (tester) async {
      await tester.pumpWidget(
        createCustomWarningApp(
          const OfflineDatabaseWarningCard(isDbStale: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DATABASE NON AGGIORNATO'), findsOneWidget);
      expect(find.textContaining('I dati di questo prodotto provengono da un database offline non aggiornato.'), findsOneWidget);
      expect(find.textContaining('Aggiorna il database per rendere sicure le tue scansioni offline.'), findsOneWidget);
      expect(find.textContaining('Le ricette e gli stabilimenti possono cambiare nel tempo.'), findsOneWidget);
      expect(find.byIcon(Icons.update_disabled_outlined), findsOneWidget);
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

    testWidgets('glutenFree displays package name and upgrade hint', (tester) async {
      await tester.pumpWidget(
        createCustomWarningApp(
          const OfflineNotFoundWarningCard(tier: OfflineDbTier.glutenFree),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Gluten-Free Globale (~12 MB)'), findsOneWidget);
      expect(find.textContaining('Prova a installare una versione più ricca del database offline.'), findsOneWidget);
    });

    testWidgets('euroCore displays package name and upgrade hint', (tester) async {
      await tester.pumpWidget(
        createCustomWarningApp(
          const OfflineNotFoundWarningCard(tier: OfflineDbTier.euroCore),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Europa Core + Gluten-Free (~65 MB)'), findsOneWidget);
      expect(find.textContaining('Prova a installare una versione più ricca del database offline.'), findsOneWidget);
    });

    testWidgets('globalTop displays package name but omits upgrade hint', (tester) async {
      await tester.pumpWidget(
        createCustomWarningApp(
          const OfflineNotFoundWarningCard(tier: OfflineDbTier.globalTop),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Global Top Scans (~130 MB)'), findsOneWidget);
      expect(find.textContaining('Prova a installare una versione più ricca del database offline.'), findsNothing);
    });

    testWidgets('tier none displays generic message and upgrade hint', (tester) async {
      await tester.pumpWidget(
        createCustomWarningApp(
          const OfflineNotFoundWarningCard(tier: OfflineDbTier.none),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('copia del database offline installata sul dispositivo'), findsOneWidget);
      expect(find.textContaining('Prova a installare una versione più ricca del database offline.'), findsOneWidget);
    });
  });
}

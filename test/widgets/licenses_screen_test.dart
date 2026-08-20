// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget Tests: CustomLicensesPage

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:gscanner/widgets/licenses_screen.dart';
import '../mocks/shared_mocks.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Registers a fake license entry in the Flutter LicenseRegistry for testing.
void _registerFakeLicense(String packageName, String licenseText) {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([packageName], licenseText);
  });
}

/// Pumps the page wrapped in a Navigator so pop() works.
Future<void> _pumpLicensesPage(
  WidgetTester tester, {
  Size surfaceSize = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
      child: Builder(
        builder: (context) {
          return MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0D631B),
                brightness: Brightness.light,
              ),
            ),
            // Use a Navigator route so that Navigator.pop() works
            home: const CustomLicensesPage(),
          );
        },
      ),
    ),
  );

  // First pump settles EasyLocalization
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupMocktailFallbacks();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    // Register a known OSS license for GROUP 4 tests
    _registerFakeLicense('flutter_test_package', 'MIT License text here.');
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1 – AppBar
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 1 – AppBar', () {
    testWidgets('renders AppBar with title key', (tester) async {
      await _pumpLicensesPage(tester);

      expect(find.text('settings.licensesPage.title'), findsOneWidget);
    });

    testWidgets('renders back button (arrow_back_ios_new)', (tester) async {
      await _pumpLicensesPage(tester);

      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('tapping back button pops the route', (tester) async {
      // Wrap in a Navigator with an initial route so pop() can actually work
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('it')],
          path: 'assets/locales',
          assetLoader: const TestAssetLoader(),
          fallbackLocale: const Locale('it'),
          startLocale: const Locale('it'),
          useOnlyLangCode: true,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                theme: ThemeData(useMaterial3: true),
                home: const _NavigationHost(),
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Push the licenses page
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.byType(CustomLicensesPage), findsOneWidget);

      // Tap back
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      // We should be back on the host (licenses page popped)
      expect(find.byType(CustomLicensesPage), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2 – Proprietary License Section
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 2 – Proprietary License Section', () {
    testWidgets('renders copyright section header icon and title',
        (tester) async {
      await _pumpLicensesPage(tester);

      expect(find.byIcon(Icons.copyright), findsOneWidget);
      expect(
        find.text('settings.licensesPage.appLicenseTitle'),
        findsOneWidget,
      );
    });

    testWidgets('renders proprietary license text spans', (tester) async {
      await _pumpLicensesPage(tester);

      expect(
        find.text('settings.licensesPage.appLicenseCopyright'),
        findsNothing, // it's inside a RichText span, not a standalone Text
      );
      // The RichText containing the copyright info is rendered
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('renders tappable license link text', (tester) async {
      await _pumpLicensesPage(tester);

      expect(
        find.text('settings.licensesPage.appLicenseLink'),
        findsNothing, // inline in RichText, not standalone
      );
      // RichText nodes are present (one for each section)
      expect(find.byType(RichText), findsWidgets);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3 – Data Source & Disclaimer Section
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 3 – Data Source & Disclaimer Section', () {
    testWidgets('renders data source section header icon and title',
        (tester) async {
      await _pumpLicensesPage(tester);

      expect(find.byIcon(Icons.source_outlined), findsOneWidget);
      expect(
        find.text('settings.licensesPage.dataSourceTitle'),
        findsOneWidget,
      );
    });

    testWidgets('renders "Open Food Facts" link text inside RichText',
        (tester) async {
      await _pumpLicensesPage(tester);

      // "Open Food Facts" is a TextSpan inside RichText — use textContaining
      expect(find.textContaining('Open Food Facts'), findsWidgets);
    });

    testWidgets('renders "Open Database License (ODbL)" link text inside RichText',
        (tester) async {
      await _pumpLicensesPage(tester);

      expect(find.textContaining('Open Database License'), findsWidgets);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4 – Open Source Licenses Section (Loading & Loaded)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 4 – Open Source Licenses Section', () {
    testWidgets('renders OSS section header icon and title', (tester) async {
      await _pumpLicensesPage(tester);

      expect(find.byIcon(Icons.code_rounded), findsOneWidget);
      expect(
        find.text('settings.licensesPage.openSourceTitle'),
        findsOneWidget,
      );
    });

    testWidgets('shows Skeletonizer loading state initially', (tester) async {
      await _pumpLicensesPage(tester);

      // Skeletonizer should be present in the tree
      final skeletonFinder =
          find.byWidgetPredicate((w) => w is Skeletonizer);
      expect(skeletonFinder, findsWidgets);
    });

    testWidgets('shows fake placeholder packages initially or loaded packages',
        (tester) async {
      await _pumpLicensesPage(tester);

      // Either placeholders or real packages appear without error
      expect(
        find.byWidgetPredicate((w) => w is ExpansionTile),
        findsWidgets,
      );
    });

    testWidgets(
        'after async load completes, Skeletonizer is disabled',
        (tester) async {
      await _pumpLicensesPage(tester);
      await tester.pumpAndSettle();

      final skeletonFinder =
          find.byWidgetPredicate((w) => w is Skeletonizer && !w.enabled);
      expect(skeletonFinder, findsWidgets);
    });

    testWidgets('renders registered package as ExpansionTile after loading',
        (tester) async {
      await _pumpLicensesPage(tester);
      await tester.pumpAndSettle();

      // The fake license registered in setUpAll should appear
      expect(find.text('flutter_test_package'), findsOneWidget);
    });

    testWidgets(
        'tapping an ExpansionTile reveals its license text', (tester) async {
      await _pumpLicensesPage(tester);
      await tester.pumpAndSettle();

      // License text is hidden before expansion
      expect(find.text('MIT License text here.'), findsNothing);

      // Tap the tile to expand it
      await tester.tap(find.text('flutter_test_package'));
      await tester.pumpAndSettle();

      // License text should now be visible
      expect(find.text('MIT License text here.'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5 – Scroll & Layout
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 5 – Scroll & Layout', () {
    testWidgets('page uses a ListView and is scrollable', (tester) async {
      await _pumpLicensesPage(tester);

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('all three section headers are present', (tester) async {
      await _pumpLicensesPage(tester);

      // All 3 section header icons must coexist
      expect(find.byIcon(Icons.copyright), findsOneWidget);
      expect(find.byIcon(Icons.source_outlined), findsOneWidget);
      expect(find.byIcon(Icons.code_rounded), findsOneWidget);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widget: navigation host for back-button test
// ─────────────────────────────────────────────────────────────────────────────

class _NavigationHost extends StatelessWidget {
  const _NavigationHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('HOME'),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CustomLicensesPage(),
                  ),
                );
              },
              child: const Text('OPEN'),
            ),
          ],
        ),
      ),
    );
  }
}

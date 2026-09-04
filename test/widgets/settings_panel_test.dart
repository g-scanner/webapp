// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget Tests: SettingsPanel

// ignore_for_file: subtype_of_sealed_class

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:gscanner/models/models.dart';
import 'package:gscanner/services/db_service.dart';
import 'package:gscanner/features/settings/settings_panel.dart';
import 'package:gscanner/features/licenses/licenses_screen.dart';
import '../mocks/shared_mocks.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Additional Mocks
// ─────────────────────────────────────────────────────────────────────────────

class MockUserMetadata extends Mock implements UserMetadata {}

class MockUserInfo extends Mock implements UserInfo {}

class _Callbacks {
  Future<void> onSettingsChange(UserSettings s) async {}
  Future<void> onResetDB() async {}
  Future<void> onClearHistory() async {}
}

class MockCallbacks extends Mock implements _Callbacks {}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

UserSettings _settings({
  bool strictMode = false,
  bool alertLactose = false,
  bool warnAdditives = false,
  String preferredLanguage = 'it',
  String preferredTheme = 'system',
}) => UserSettings(
  userId: 'u1',
  strictMode: strictMode,
  alertLactose: alertLactose,
  warnAdditives: warnAdditives,
  autoSaveHistory: true,
  preferredLanguage: preferredLanguage,
  preferredTheme: preferredTheme,
  reportedBarcodes: const [],
);

Future<void> _pump(
  WidgetTester tester, {
  required MockCallbacks cb,
  required MockFirebaseAuth auth,
  UserSettings? settings,
  Size surfaceSize = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    createTestApp(
      child: Scaffold(
        body: SettingsPanel(
          settings: settings ?? _settings(),
          onSettingsChange: (s) => cb.onSettingsChange(s),
          onResetDB: () => cb.onResetDB(),
          onClearHistory: () => cb.onClearHistory(),
          firebaseAuth: auth,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCallbacks cb;
  late MockFirebaseAuth auth;
  late MockFirebaseFirestore mockDb;
  late MockUser user;
  late MockUserMetadata metadata;

  setUpAll(() async {
    setupMocktailFallbacks();
    registerFallbackValue(_settings());
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    cb = MockCallbacks();
    auth = MockFirebaseAuth();
    mockDb = MockFirebaseFirestore();
    user = MockUser();
    metadata = MockUserMetadata();

    // Inject mocks into DbService static fields so account-deletion helpers
    // use the mock instances instead of FirebaseAuth/Firestore singletons.
    // Note: no tearDown needed — setUp re-injects fresh mocks before every test.
    DbService.auth = auth;
    DbService.db = mockDb;

    when(() => cb.onSettingsChange(any())).thenAnswer((_) async {});
    when(() => cb.onResetDB()).thenAnswer((_) async {});
    when(() => cb.onClearHistory()).thenAnswer((_) async {});

    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.signOut()).thenAnswer((_) async {});

    when(() => user.uid).thenReturn('test_uid_123');
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.displayName).thenReturn('Mario Rossi');
    when(() => user.email).thenReturn('mario@example.com');
    when(() => user.phoneNumber).thenReturn(null);
    when(() => user.providerData).thenReturn([]);
    when(() => user.metadata).thenReturn(metadata);
    when(() => user.delete()).thenAnswer((_) async {});
    when(() => user.updateDisplayName(any())).thenAnswer((_) async {});

    when(() => metadata.lastSignInTime).thenReturn(DateTime.now());
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1 – Header & section titles
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 1 – Header & section titles', () {
    testWidgets('renders page title, subtitle and all section headers', (
      tester,
    ) async {
      await _pump(tester, cb: cb, auth: auth);

      expect(find.text('settings.title'), findsOneWidget);
      expect(find.text('settings.subtitle'), findsOneWidget);
      expect(find.text('settings.sectionTitles.account'), findsOneWidget);
      expect(find.text('settings.sectionTitles.analysisRules'), findsOneWidget);
      expect(find.text('settings.sectionTitles.appearance'), findsOneWidget);
      expect(find.text('settings.sectionTitles.language'), findsOneWidget);
      expect(
        find.text('settings.sectionTitles.dataAndHistory'),
        findsOneWidget,
      );
      expect(find.text('settings.sectionTitles.legalInfo'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2 – Account card presentation
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 2 – Account card presentation', () {
    testWidgets('anonymous user renders anonymous key and sign-in button', (
      tester,
    ) async {
      when(() => user.isAnonymous).thenReturn(true);
      when(() => auth.currentUser).thenReturn(user);

      await _pump(tester, cb: cb, auth: auth);

      expect(find.text('auth.social.anonymousUser'), findsOneWidget);
      expect(find.text('auth.social.anonymousLocalSubtitle'), findsOneWidget);
      expect(find.text('auth.social.signInOrRegister'), findsOneWidget);
    });

    testWidgets('registered user renders displayName and manage button', (
      tester,
    ) async {
      when(() => user.isAnonymous).thenReturn(false);
      when(() => user.displayName).thenReturn('Mario Rossi');
      when(() => auth.currentUser).thenReturn(user);

      await _pump(tester, cb: cb, auth: auth);

      expect(find.text('Mario Rossi'), findsOneWidget);
      expect(find.text('settings.account.syncedCloudSubtitle'), findsOneWidget);
      expect(find.text('settings.account.manageAccount'), findsOneWidget);
    });

    testWidgets('registered user with empty displayName renders fallback key', (
      tester,
    ) async {
      when(() => user.isAnonymous).thenReturn(false);
      when(() => user.displayName).thenReturn('');
      when(() => auth.currentUser).thenReturn(user);

      await _pump(tester, cb: cb, auth: auth);

      expect(find.text('auth.social.registeredUser'), findsOneWidget);
      expect(find.text('settings.account.manageAccount'), findsOneWidget);
    });

    testWidgets('null currentUser renders anonymous state', (tester) async {
      when(() => auth.currentUser).thenReturn(null);
      await _pump(tester, cb: cb, auth: auth);
      expect(find.text('auth.social.anonymousUser'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3 – Analysis Rule Toggles
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 3 – Analysis rule toggles', () {
    testWidgets(
      'warnAdditives switch calls onSettingsChange(warnAdditives:true)',
      (tester) async {
        await _pump(
          tester,
          cb: cb,
          auth: auth,
          settings: _settings(warnAdditives: false),
        );

        final switches = tester
            .widgetList<Switch>(find.byType(Switch))
            .toList();
        expect(switches.length, greaterThanOrEqualTo(3));

        await tester.tap(find.byType(Switch).at(0));
        await tester.pump();

        verify(
          () => cb.onSettingsChange(
            any(
              that: isA<UserSettings>().having(
                (s) => s.warnAdditives,
                'warnAdditives',
                true,
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets('strictMode switch calls onSettingsChange(strictMode:true)', (
      tester,
    ) async {
      await _pump(
        tester,
        cb: cb,
        auth: auth,
        settings: _settings(strictMode: false),
      );

      await tester.tap(find.byType(Switch).at(1));
      await tester.pump();

      verify(
        () => cb.onSettingsChange(
          any(
            that: isA<UserSettings>().having(
              (s) => s.strictMode,
              'strictMode',
              true,
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets(
      'alertLactose switch calls onSettingsChange(alertLactose:true)',
      (tester) async {
        await _pump(
          tester,
          cb: cb,
          auth: auth,
          settings: _settings(alertLactose: false),
        );

        await tester.tap(find.byType(Switch).at(2));
        await tester.pump();

        verify(
          () => cb.onSettingsChange(
            any(
              that: isA<UserSettings>().having(
                (s) => s.alertLactose,
                'alertLactose',
                true,
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets('toggling warnAdditives OFF to ON preserves other settings', (
      tester,
    ) async {
      await _pump(
        tester,
        cb: cb,
        auth: auth,
        settings: _settings(
          warnAdditives: false,
          strictMode: true,
          alertLactose: true,
        ),
      );

      await tester.tap(find.byType(Switch).at(0));
      await tester.pump();

      verify(
        () => cb.onSettingsChange(
          any(
            that: isA<UserSettings>()
                .having((s) => s.warnAdditives, 'warnAdditives', true)
                .having((s) => s.strictMode, 'strictMode', true)
                .having((s) => s.alertLactose, 'alertLactose', true),
          ),
        ),
      ).called(1);
    });

    testWidgets('section toggle titles are visible', (tester) async {
      await _pump(tester, cb: cb, auth: auth);
      expect(find.text('settings.toggles.warnAdditivesTitle'), findsOneWidget);
      expect(find.text('settings.toggles.strictFilterTitle'), findsOneWidget);
      expect(
        find.text('settings.toggles.lactoseIntoleranceTitle'),
        findsOneWidget,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4 – Theme selector
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 4 – Theme selector', () {
    testWidgets('theme PopupMenuButton is present', (tester) async {
      await _pump(tester, cb: cb, auth: auth);
      expect(find.byType(PopupMenuButton<String>), findsNWidgets(2));
    });

    testWidgets(
      'selecting dark theme calls onSettingsChange(preferredTheme:dark)',
      (tester) async {
        await _pump(
          tester,
          cb: cb,
          auth: auth,
          settings: _settings(preferredTheme: 'system'),
        );

        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('common.themes.dark').last);
        await tester.pumpAndSettle();

        verify(
          () => cb.onSettingsChange(
            any(
              that: isA<UserSettings>().having(
                (s) => s.preferredTheme,
                'preferredTheme',
                'dark',
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'selecting light theme calls onSettingsChange(preferredTheme:light)',
      (tester) async {
        await _pump(
          tester,
          cb: cb,
          auth: auth,
          settings: _settings(preferredTheme: 'system'),
        );

        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('common.themes.light').last);
        await tester.pumpAndSettle();

        verify(
          () => cb.onSettingsChange(
            any(
              that: isA<UserSettings>().having(
                (s) => s.preferredTheme,
                'preferredTheme',
                'light',
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'selecting already-active theme does NOT call onSettingsChange',
      (tester) async {
        await _pump(
          tester,
          cb: cb,
          auth: auth,
          settings: _settings(preferredTheme: 'system'),
        );

        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('common.themes.system').last);
        await tester.pumpAndSettle();

        verifyNever(() => cb.onSettingsChange(any()));
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5 – Language selector
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 5 – Language selector', () {
    testWidgets('selecting a different language calls onSettingsChange', (
      tester,
    ) async {
      await _pump(
        tester,
        cb: cb,
        auth: auth,
        settings: _settings(preferredLanguage: 'it'),
      );

      await tester.tap(find.byType(PopupMenuButton<String>).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.languages.en').last);
      await tester.pumpAndSettle();

      verify(
        () => cb.onSettingsChange(
          any(
            that: isA<UserSettings>().having(
              (s) => s.preferredLanguage,
              'preferredLanguage',
              'en',
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets(
      'selecting already-active language does NOT call onSettingsChange',
      (tester) async {
        await _pump(
          tester,
          cb: cb,
          auth: auth,
          settings: _settings(preferredLanguage: 'it'),
        );

        await tester.tap(find.byType(PopupMenuButton<String>).last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('common.languages.it').last);
        await tester.pumpAndSettle();

        verifyNever(() => cb.onSettingsChange(any()));
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 6 – Clear History flow
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 6 – Clear History flow', () {
    testWidgets('tapping clear history shows confirmation dialog', (
      tester,
    ) async {
      await _pump(tester, cb: cb, auth: auth);

      await tester.tap(
        find.text('settings.destructive.clearHistoryTitle').first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('settings.data.clearHistoryConfirm'), findsOneWidget);
    });

    testWidgets('cancelling dialog does NOT call onClearHistory', (
      tester,
    ) async {
      await _pump(tester, cb: cb, auth: auth);

      await tester.tap(
        find.text('settings.destructive.clearHistoryTitle').first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.actions.cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => cb.onClearHistory());
    });

    testWidgets('confirming dialog calls onClearHistory', (tester) async {
      await _pump(tester, cb: cb, auth: auth);

      await tester.tap(
        find.text('settings.destructive.clearHistoryTitle').first,
      );
      await tester.pumpAndSettle();

      final allMatches = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('settings.destructive.clearHistoryTitle'),
      );
      await tester.tap(allMatches.last);
      await tester.pumpAndSettle();

      verify(() => cb.onClearHistory()).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 7 – Legal information section
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 7 – Legal information section', () {
    testWidgets('all three legal items are rendered', (tester) async {
      await _pump(tester, cb: cb, auth: auth);
      expect(
        find.text('settings.legalMenu.termsAndConditionsTitle'),
        findsOneWidget,
      );
      expect(
        find.text('settings.legalMenu.privacyPolicyTitle'),
        findsOneWidget,
      );
      expect(find.text('settings.legalMenu.licensesTitle'), findsOneWidget);
    });

    testWidgets('tapping Terms & Conditions opens a bottom sheet', (
      tester,
    ) async {
      await _pump(tester, cb: cb, auth: auth);

      await tester.tap(find.text('settings.legalMenu.termsAndConditionsTitle'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('tapping Privacy Policy opens a bottom sheet', (tester) async {
      await _pump(tester, cb: cb, auth: auth);

      await tester.tap(find.text('settings.legalMenu.privacyPolicyTitle'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('tapping Licenses navigates to CustomLicensesPage', (
      tester,
    ) async {
      await _pump(
        tester,
        cb: cb,
        auth: auth,
        surfaceSize: const Size(1080, 4800),
      );

      await tester.tap(find.text('settings.legalMenu.licensesTitle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CustomLicensesPage), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 8 – Anonymous User Conversion Flow (_handleAnonymousAction)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 8 – Anonymous User Conversion Flow', () {
    testWidgets('tapping signInOrRegister opens conversion dialog', (
      tester,
    ) async {
      when(() => user.isAnonymous).thenReturn(true);
      when(() => auth.currentUser).thenReturn(user);

      await _pump(tester, cb: cb, auth: auth);

      await tester.tap(find.text('auth.social.signInOrRegister'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('auth.social.signInAction'), findsOneWidget);
      expect(find.text('auth.social.signInCloudPrompt'), findsOneWidget);
      expect(find.text('common.actions.cancel'), findsOneWidget);
      expect(find.text('auth.social.proceed'), findsOneWidget);
    });

    testWidgets(
      'cancelling conversion dialog does NOT delete user or sign out',
      (tester) async {
        when(() => user.isAnonymous).thenReturn(true);
        when(() => auth.currentUser).thenReturn(user);

        await _pump(tester, cb: cb, auth: auth);

        await tester.tap(find.text('auth.social.signInOrRegister'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('common.actions.cancel'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        verifyNever(() => user.delete());
        verifyNever(() => auth.signOut());
      },
    );

    testWidgets('confirming conversion dialog deletes user and signs out', (
      tester,
    ) async {
      when(() => user.isAnonymous).thenReturn(true);
      when(() => auth.currentUser).thenReturn(user);

      await _pump(tester, cb: cb, auth: auth);

      await tester.tap(find.text('auth.social.signInOrRegister'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('auth.social.proceed'));
      await tester.pumpAndSettle();

      verify(() => user.delete()).called(1);
      verify(() => auth.signOut()).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 9 – Profile Bottom Sheet Presentation (_showAccountManagementMenu)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 9 – Profile Bottom Sheet Presentation', () {
    testWidgets(
      'opens bottom sheet with profile info and Google provider data',
      (tester) async {
        final googleInfo = MockUserInfo();
        when(() => googleInfo.providerId).thenReturn('google.com');

        when(() => user.isAnonymous).thenReturn(false);
        when(() => user.displayName).thenReturn('Mario Rossi');
        when(() => user.email).thenReturn('mario@example.com');
        when(() => user.providerData).thenReturn([googleInfo]);
        when(() => auth.currentUser).thenReturn(user);

        await _pump(tester, cb: cb, auth: auth);

        await tester.tap(find.text('settings.account.manageAccount'));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text('Mario Rossi'), findsWidgets);
        expect(find.text('mario@example.com'), findsOneWidget);
        expect(find.text('settings.account.editName'), findsOneWidget);
        expect(find.text('settings.account.signOut'), findsOneWidget);
        expect(find.text('settings.account.deleteAccount'), findsOneWidget);
      },
    );

    testWidgets(
      'renders fallback "addYourName" when displayName is empty in bottom sheet',
      (tester) async {
        when(() => user.isAnonymous).thenReturn(false);
        when(() => user.displayName).thenReturn('');
        when(() => user.email).thenReturn('mario@example.com');
        when(() => auth.currentUser).thenReturn(user);

        await _pump(tester, cb: cb, auth: auth);

        await tester.tap(find.text('settings.account.manageAccount'));
        await tester.pumpAndSettle();

        expect(find.text('auth.social.addYourName'), findsOneWidget);
      },
    );

    testWidgets('renders phone number when email is null', (tester) async {
      final phoneInfo = MockUserInfo();
      when(() => phoneInfo.providerId).thenReturn('phone');

      when(() => user.isAnonymous).thenReturn(false);
      when(() => user.displayName).thenReturn('Mario Phone');
      when(() => user.email).thenReturn(null);
      when(() => user.phoneNumber).thenReturn('+39123456789');
      when(() => user.providerData).thenReturn([phoneInfo]);
      when(() => auth.currentUser).thenReturn(user);

      await _pump(tester, cb: cb, auth: auth);

      await tester.tap(find.text('settings.account.manageAccount'));
      await tester.pumpAndSettle();

      expect(find.text('+39123456789'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 10 – Edit Name Flow with Optimistic Update
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 10 – Edit Name Flow with Optimistic Update', () {
    testWidgets('tapping edit name switches view to edit name form', (
      tester,
    ) async {
      when(() => user.isAnonymous).thenReturn(false);
      when(() => user.displayName).thenReturn('Mario Rossi');
      when(() => auth.currentUser).thenReturn(user);

      await _pump(tester, cb: cb, auth: auth);

      await tester.tap(find.text('settings.account.manageAccount'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('settings.account.editName'));
      await tester.pumpAndSettle();

      expect(find.text('settings.account.editNameSubtitle'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TextField),
          matching: find.text('Mario Rossi'),
        ),
        findsOneWidget,
      ); // Prepopulated in TextField
      expect(find.text('common.actions.cancel'), findsOneWidget);
      expect(find.text('common.actions.save'), findsOneWidget);
    });

    testWidgets(
      'back button in edit name view returns to menu view without updating',
      (tester) async {
        when(() => user.isAnonymous).thenReturn(false);
        when(() => user.displayName).thenReturn('Mario Rossi');
        when(() => auth.currentUser).thenReturn(user);

        await _pump(tester, cb: cb, auth: auth);

        await tester.tap(find.text('settings.account.manageAccount'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('settings.account.editName'));
        await tester.pumpAndSettle();

        // Tap back button in header
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Returned to menu view
        expect(find.text('settings.account.signOut'), findsOneWidget);
        verifyNever(() => user.updateDisplayName(any()));
      },
    );

    testWidgets('cancelling edit name form returns to menu view', (
      tester,
    ) async {
      when(() => user.isAnonymous).thenReturn(false);
      when(() => user.displayName).thenReturn('Mario Rossi');
      when(() => auth.currentUser).thenReturn(user);

      await _pump(tester, cb: cb, auth: auth);

      await tester.tap(find.text('settings.account.manageAccount'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('settings.account.editName'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.actions.cancel'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('settings.account.signOut'), findsOneWidget);
      verifyNever(() => user.updateDisplayName(any()));
    });

    testWidgets('clearing name makes Save button disabled', (tester) async {
      when(() => user.isAnonymous).thenReturn(false);
      when(() => user.displayName).thenReturn('Mario Rossi');
      when(() => auth.currentUser).thenReturn(user);

      await _pump(tester, cb: cb, auth: auth);

      await tester.tap(find.text('settings.account.manageAccount'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('settings.account.editName'));
      await tester.pumpAndSettle();

      // Clear text field
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();

      // Save button should be disabled (FilledButton with onPressed == null)
      final saveBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'common.actions.save'),
      );
      expect(saveBtn.onPressed, isNull);
    });

    testWidgets(
      'saving new name triggers Optimistic Update and calls user.updateDisplayName',
      (tester) async {
        when(() => user.isAnonymous).thenReturn(false);
        when(() => user.displayName).thenReturn('Mario Rossi');
        when(() => auth.currentUser).thenReturn(user);

        await _pump(tester, cb: cb, auth: auth);

        await tester.tap(find.text('settings.account.manageAccount'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('settings.account.editName'));
        await tester.pumpAndSettle();

        // Enter new name
        await tester.enterText(find.byType(TextField), 'Luigi Verdi');
        await tester.pump();

        await tester.tap(find.text('common.actions.save'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // updateDisplayName was called with new name
        verify(() => user.updateDisplayName('Luigi Verdi')).called(1);

        // Optimistic update: UI shows "Luigi Verdi" in the menu view immediately
        expect(find.text('Luigi Verdi'), findsWidgets);
      },
    );

    testWidgets('saving unchanged name does NOT call user.updateDisplayName', (
      tester,
    ) async {
      when(() => user.isAnonymous).thenReturn(false);
      when(() => user.displayName).thenReturn('Mario Rossi');
      when(() => auth.currentUser).thenReturn(user);

      await _pump(tester, cb: cb, auth: auth);

      await tester.tap(find.text('settings.account.manageAccount'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('settings.account.editName'));
      await tester.pumpAndSettle();

      // Keep same name and tap save
      await tester.tap(find.text('common.actions.save'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      verifyNever(() => user.updateDisplayName(any()));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 11 – Logout Flow (_handleLogout)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 11 – Logout Flow', () {
    testWidgets('tapping signOut in bottom sheet opens logout confirm dialog', (
      tester,
    ) async {
      when(() => user.isAnonymous).thenReturn(false);
      when(() => user.displayName).thenReturn('Mario Rossi');
      when(() => auth.currentUser).thenReturn(user);

      await _pump(tester, cb: cb, auth: auth);

      await tester.tap(find.text('settings.account.manageAccount'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('settings.account.signOut'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('settings.account.signOutConfirmTitle'), findsOneWidget);
      expect(find.text('settings.account.signOutConfirmBody'), findsOneWidget);
      expect(find.text('common.actions.cancel'), findsOneWidget);
      expect(find.text('settings.account.signOutShort'), findsOneWidget);
    });

    testWidgets('cancelling logout dialog does NOT call auth.signOut', (
      tester,
    ) async {
      when(() => user.isAnonymous).thenReturn(false);
      when(() => user.displayName).thenReturn('Mario Rossi');
      when(() => auth.currentUser).thenReturn(user);

      await _pump(tester, cb: cb, auth: auth);

      await tester.tap(find.text('settings.account.manageAccount'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('settings.account.signOut'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.actions.cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => auth.signOut());
    });

    testWidgets('confirming logout dialog calls auth.signOut', (tester) async {
      when(() => user.isAnonymous).thenReturn(false);
      when(() => user.displayName).thenReturn('Mario Rossi');
      when(() => auth.currentUser).thenReturn(user);

      await _pump(tester, cb: cb, auth: auth);

      await tester.tap(find.text('settings.account.manageAccount'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('settings.account.signOut'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('settings.account.signOutShort'));
      await tester.pumpAndSettle();

      verify(() => auth.signOut()).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 12 – Account Deletion Flow (_handleDeleteAccount)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 12 – Account Deletion Flow', () {
    testWidgets(
      'Scenario A: Needs Re-auth when lastSignIn is older than 5 minutes',
      (tester) async {
        // Login happened 10 minutes ago -> triggers re-auth security check
        when(
          () => metadata.lastSignInTime,
        ).thenReturn(DateTime.now().subtract(const Duration(minutes: 10)));
        when(() => user.isAnonymous).thenReturn(false);
        when(() => user.displayName).thenReturn('Mario Rossi');
        when(() => auth.currentUser).thenReturn(user);

        await _pump(tester, cb: cb, auth: auth);

        await tester.tap(find.text('settings.account.manageAccount'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('settings.account.deleteAccount'));
        await tester.pumpAndSettle();

        // Security re-auth dialog is shown
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.byIcon(Icons.security_rounded), findsOneWidget);
        expect(find.text('settings.account.deleteReauthTitle'), findsOneWidget);
        expect(find.text('settings.account.deleteReauthBody'), findsOneWidget);
        expect(find.text('common.actions.cancel'), findsOneWidget);
        expect(find.text('auth.social.proceed'), findsOneWidget);
      },
    );

    testWidgets('Scenario A: Cancelling re-auth dialog does NOT sign out', (
      tester,
    ) async {
      when(
        () => metadata.lastSignInTime,
      ).thenReturn(DateTime.now().subtract(const Duration(minutes: 10)));
      when(() => user.isAnonymous).thenReturn(false);
      when(() => user.displayName).thenReturn('Mario Rossi');
      when(() => auth.currentUser).thenReturn(user);

      await _pump(tester, cb: cb, auth: auth);

      await tester.tap(find.text('settings.account.manageAccount'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('settings.account.deleteAccount'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.actions.cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => auth.signOut());
    });

    testWidgets(
      'Scenario A: Proceeding in re-auth dialog signs out user to re-authenticate',
      (tester) async {
        when(
          () => metadata.lastSignInTime,
        ).thenReturn(DateTime.now().subtract(const Duration(minutes: 10)));
        when(() => user.isAnonymous).thenReturn(false);
        when(() => user.displayName).thenReturn('Mario Rossi');
        when(() => auth.currentUser).thenReturn(user);

        await _pump(tester, cb: cb, auth: auth);

        await tester.tap(find.text('settings.account.manageAccount'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('settings.account.deleteAccount'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('auth.social.proceed'));
        await tester.pumpAndSettle();

        verify(() => auth.signOut()).called(1);
      },
    );

    testWidgets(
      'Scenario B: Immediate deletion when lastSignIn is recent (within 5 min)',
      (tester) async {
        // Login happened 1 minute ago -> recent login allows immediate deletion
        when(
          () => metadata.lastSignInTime,
        ).thenReturn(DateTime.now().subtract(const Duration(minutes: 1)));
        when(() => user.isAnonymous).thenReturn(false);
        when(() => user.displayName).thenReturn('Mario Rossi');
        when(() => auth.currentUser).thenReturn(user);

        await _pump(tester, cb: cb, auth: auth);

        await tester.tap(find.text('settings.account.manageAccount'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('settings.account.deleteAccount'));
        await tester.pumpAndSettle();

        // Immediate delete confirmation dialog is shown
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(
          find.text('settings.account.deleteConfirmTitle'),
          findsOneWidget,
        );
        expect(find.text('settings.account.deleteConfirmBody'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario B: Cancelling immediate delete dialog does NOT delete user',
      (tester) async {
        when(
          () => metadata.lastSignInTime,
        ).thenReturn(DateTime.now().subtract(const Duration(minutes: 1)));
        when(() => user.isAnonymous).thenReturn(false);
        when(() => user.displayName).thenReturn('Mario Rossi');
        when(() => auth.currentUser).thenReturn(user);

        await _pump(tester, cb: cb, auth: auth);

        await tester.tap(find.text('settings.account.manageAccount'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('settings.account.deleteAccount'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('common.actions.cancel'));
        await tester.pumpAndSettle();

        verifyNever(() => user.delete());
        verifyNever(() => auth.signOut());
      },
    );

    testWidgets(
      'Scenario B: Confirming immediate delete deletes user account and signs out',
      (tester) async {
        when(
          () => metadata.lastSignInTime,
        ).thenReturn(DateTime.now().subtract(const Duration(minutes: 1)));
        when(() => user.isAnonymous).thenReturn(false);
        when(() => user.displayName).thenReturn('Mario Rossi');
        when(() => auth.currentUser).thenReturn(user);

        await _pump(tester, cb: cb, auth: auth);

        await tester.tap(find.text('settings.account.manageAccount'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('settings.account.deleteAccount'));
        await tester.pumpAndSettle();

        // Tap confirm FilledButton in AlertDialog
        final confirmBtn = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        );
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        verify(() => user.delete()).called(1);
        verify(() => auth.signOut()).called(1);
      },
    );

    testWidgets(
      'Scenario C: FirebaseAuthException requires-recent-login forces sign out',
      (tester) async {
        when(
          () => metadata.lastSignInTime,
        ).thenReturn(DateTime.now().subtract(const Duration(minutes: 1)));
        when(() => user.isAnonymous).thenReturn(false);
        when(() => user.displayName).thenReturn('Mario Rossi');
        when(() => auth.currentUser).thenReturn(user);
        when(
          () => user.delete(),
        ).thenThrow(FirebaseAuthException(code: 'requires-recent-login'));

        await _pump(tester, cb: cb, auth: auth);

        await tester.tap(find.text('settings.account.manageAccount'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('settings.account.deleteAccount'));
        await tester.pumpAndSettle();

        final confirmBtn = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        );
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Forces signOut on requires-recent-login exception
        verify(() => auth.signOut()).called(1);
      },
    );
  });
}

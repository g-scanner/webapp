// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget & Business Logic Tests: AuthScreen

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gscanner/widgets/auth_screen.dart';
import 'package:gscanner/services/db_service.dart';
import '../mocks/shared_mocks.dart';

class MockAccessToken extends Mock implements AccessToken {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockGoogleSignInAccount mockGoogleUser;
  late MockGoogleSignInAuthentication mockGoogleAuth;
  late MockFacebookAuth mockFacebookAuth;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;
  late MockAccessToken mockAccessToken;

  setUpAll(() async {
    setupMocktailFallbacks();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'gscanner_terms_accepted': true});

    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockGoogleUser = MockGoogleSignInAccount();
    mockGoogleAuth = MockGoogleSignInAuthentication();
    mockFacebookAuth = MockFacebookAuth();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();
    mockAccessToken = MockAccessToken();

    when(() => mockUser.displayName).thenReturn('Test User');
    when(() => mockUserCredential.user).thenReturn(mockUser);
  });

  Future<void> pumpAuthScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      createTestApp(
        child: AuthScreen(
          firebaseAuth: mockAuth,
          googleSignIn: mockGoogleSignIn,
          facebookAuth: mockFacebookAuth,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AuthScreen Pure Widget & Business Logic Tests', () {
    testWidgets('Renders all branding, social buttons, and guest entry elements',
        (WidgetTester tester) async {
      await pumpAuthScreen(tester);

      // Verifica Branding
      expect(find.text('G-Scanner'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);

      // Verifica Bottoni Social e Anonimo
      expect(find.text('auth.social.continueWithGoogle'), findsOneWidget);
      expect(find.text('auth.social.continueWithFacebook'), findsOneWidget);
      expect(find.text('auth.social.enterAnonymously'), findsOneWidget);
      expect(find.text('auth.social.or'), findsOneWidget);
    });

    testWidgets(
        'Legal consent dialog flow: shown when terms not accepted, enables start button on checkbox tap, saves consent',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'gscanner_terms_accepted': false});

      await pumpAuthScreen(tester);

      // Tap su "Entra come Ospite" -> Mostra il dialog di consenso legale
      final guestBtn = find.text('auth.social.enterAnonymously');
      await tester.tap(guestBtn);
      await tester.pumpAndSettle();

      expect(find.text('auth.legal.dialogTitle'), findsOneWidget);
      expect(find.text('auth.legal.dialogIntro'), findsOneWidget);

      // Il bottone INIZIA deve essere inizialmente disabilitato
      final startBtnFinder = find.widgetWithText(FilledButton, 'auth.legal.startButton');
      expect(startBtnFinder, findsOneWidget);
      FilledButton startBtn = tester.widget(startBtnFinder);
      expect(startBtn.onPressed, isNull);

      // Tap sulla checkbox
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Bottone INIZIA attivo
      startBtn = tester.widget(startBtnFinder);
      expect(startBtn.onPressed, isNotNull);

      // Simula successo login anonimo dopo consenso
      when(() => mockAuth.signInAnonymously()).thenAnswer((_) async => mockUserCredential);

      await tester.tap(startBtnFinder);
      await tester.pump(const Duration(milliseconds: 100));

      final termsAccepted = await DbService.hasAcceptedTerms();
      expect(termsAccepted, isTrue);
      verify(() => mockAuth.signInAnonymously()).called(1);
    });

    // ==========================================
    // ANONYMOUS SIGN IN BRANCHES
    // ==========================================
    testWidgets('_signInAnonymously: executes successfully and calls signInAnonymously',
        (WidgetTester tester) async {
      when(() => mockAuth.signInAnonymously()).thenAnswer((_) async => mockUserCredential);

      await pumpAuthScreen(tester);

      final guestBtn = find.text('auth.social.enterAnonymously');
      await tester.tap(guestBtn);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockAuth.signInAnonymously()).called(1);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('_signInAnonymously: handles FirebaseAuthException and displays error SnackBar',
        (WidgetTester tester) async {
      when(() => mockAuth.signInAnonymously()).thenThrow(
        FirebaseAuthException(code: 'operation-not-allowed', message: 'Anonymous auth disabled'),
      );

      await pumpAuthScreen(tester);

      final guestBtn = find.text('auth.social.enterAnonymously');
      await tester.tap(guestBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Anonymous auth disabled'), findsOneWidget);
      // Il CircularProgressIndicator deve scomparire al termine dell'errore
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('_signInAnonymously: handles generic Exception and displays generic error SnackBar',
        (WidgetTester tester) async {
      when(() => mockAuth.signInAnonymously()).thenThrow(Exception('Network socket error'));

      await pumpAuthScreen(tester);

      final guestBtn = find.text('auth.social.enterAnonymously');
      await tester.tap(guestBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('auth.errors.genericError'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    // ==========================================
    // GOOGLE SIGN IN BRANCHES
    // ==========================================
    testWidgets('_signInWithGoogle: mobile flow success',
        (WidgetTester tester) async {
      when(() => mockGoogleSignIn.initialize(serverClientId: any(named: 'serverClientId')))
          .thenAnswer((_) async {});
      when(() => mockGoogleSignIn.authenticate()).thenAnswer((_) async => mockGoogleUser);
      when(() => mockGoogleUser.authentication).thenReturn(mockGoogleAuth);
      when(() => mockGoogleAuth.idToken).thenReturn('mock_id_token');
      when(() => mockAuth.signInWithCredential(any())).thenAnswer((_) async => mockUserCredential);

      await pumpAuthScreen(tester);

      final googleBtn = find.text('auth.social.continueWithGoogle');
      await tester.tap(googleBtn);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockGoogleSignIn.authenticate()).called(1);
      verify(() => mockAuth.signInWithCredential(any())).called(1);
    });

    testWidgets('_signInWithGoogle: handles FirebaseAuthException cancellation (popup-closed/cancel)',
        (WidgetTester tester) async {
      when(() => mockGoogleSignIn.initialize(serverClientId: any(named: 'serverClientId')))
          .thenAnswer((_) async {});
      when(() => mockGoogleSignIn.authenticate()).thenAnswer((_) async => mockGoogleUser);
      when(() => mockGoogleUser.authentication).thenReturn(mockGoogleAuth);
      when(() => mockGoogleAuth.idToken).thenReturn('mock_id_token');
      when(() => mockAuth.signInWithCredential(any())).thenThrow(
        FirebaseAuthException(code: 'popup-closed-by-user', message: 'Popup closed'),
      );

      await pumpAuthScreen(tester);

      final googleBtn = find.text('auth.social.continueWithGoogle');
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('auth.errors.googleCancelled'), findsOneWidget);
    });

    testWidgets('_signInWithGoogle: handles FirebaseAuthException non-cancel error',
        (WidgetTester tester) async {
      when(() => mockGoogleSignIn.initialize(serverClientId: any(named: 'serverClientId')))
          .thenAnswer((_) async {});
      when(() => mockGoogleSignIn.authenticate()).thenAnswer((_) async => mockGoogleUser);
      when(() => mockGoogleUser.authentication).thenReturn(mockGoogleAuth);
      when(() => mockGoogleAuth.idToken).thenReturn('mock_id_token');
      when(() => mockAuth.signInWithCredential(any())).thenThrow(
        FirebaseAuthException(code: 'account-exists-with-different-credential', message: 'Account exists'),
      );

      await pumpAuthScreen(tester);

      final googleBtn = find.text('auth.social.continueWithGoogle');
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('auth.errors.firebaseError'), findsOneWidget);
    });

    testWidgets('_signInWithGoogle: handles Google API cancellation (12501/12502/cancel)',
        (WidgetTester tester) async {
      when(() => mockGoogleSignIn.initialize(serverClientId: any(named: 'serverClientId')))
          .thenAnswer((_) async {});
      when(() => mockGoogleSignIn.authenticate()).thenThrow(Exception('PlatformException(12501, cancel)'));

      await pumpAuthScreen(tester);

      final googleBtn = find.text('auth.social.continueWithGoogle');
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('auth.errors.googleCancelledShort'), findsOneWidget);
    });

    testWidgets('_signInWithGoogle: handles Google API generic error',
        (WidgetTester tester) async {
      when(() => mockGoogleSignIn.initialize(serverClientId: any(named: 'serverClientId')))
          .thenAnswer((_) async {});
      when(() => mockGoogleSignIn.authenticate()).thenThrow(Exception('Internal Google Play Services Error'));

      await pumpAuthScreen(tester);

      final googleBtn = find.text('auth.social.continueWithGoogle');
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('auth.errors.googleSignInError'), findsOneWidget);
    });

    // ==========================================
    // FACEBOOK SIGN IN BRANCHES
    // ==========================================
    testWidgets('_signInWithFacebook: handles LoginStatus.cancelled',
        (WidgetTester tester) async {
      final mockLoginResult = MockLoginResult();
      when(() => mockLoginResult.status).thenReturn(LoginStatus.cancelled);
      when(() => mockFacebookAuth.login(permissions: any(named: 'permissions')))
          .thenAnswer((_) async => mockLoginResult);

      await pumpAuthScreen(tester);

      final fbBtn = find.text('auth.social.continueWithFacebook');
      await tester.tap(fbBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('auth.errors.facebookCancelled'), findsOneWidget);
    });

    testWidgets('_signInWithFacebook: handles LoginStatus.failed',
        (WidgetTester tester) async {
      final mockLoginResult = MockLoginResult();
      when(() => mockLoginResult.status).thenReturn(LoginStatus.failed);
      when(() => mockLoginResult.message).thenReturn('Facebook SDK error');
      when(() => mockFacebookAuth.login(permissions: any(named: 'permissions')))
          .thenAnswer((_) async => mockLoginResult);

      await pumpAuthScreen(tester);

      final fbBtn = find.text('auth.social.continueWithFacebook');
      await tester.tap(fbBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('auth.errors.facebookError'), findsOneWidget);
    });

    testWidgets('_signInWithFacebook: success flow and retrieves user data if displayName is empty',
        (WidgetTester tester) async {
      final mockLoginResult = MockLoginResult();
      when(() => mockLoginResult.status).thenReturn(LoginStatus.success);
      when(() => mockAccessToken.tokenString).thenReturn('mock_fb_token_string');
      when(() => mockLoginResult.accessToken).thenReturn(mockAccessToken);
      when(() => mockFacebookAuth.login(permissions: any(named: 'permissions')))
          .thenAnswer((_) async => mockLoginResult);

      final userWithoutName = MockUser();
      when(() => userWithoutName.displayName).thenReturn('');
      when(() => userWithoutName.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => userWithoutName.reload()).thenAnswer((_) async {});

      final userCredWithoutName = MockUserCredential();
      when(() => userCredWithoutName.user).thenReturn(userWithoutName);

      when(() => mockAuth.signInWithCredential(any())).thenAnswer((_) async => userCredWithoutName);
      when(() => mockFacebookAuth.getUserData(fields: any(named: 'fields')))
          .thenAnswer((_) async => {'name': 'Mario Rossi', 'email': 'mario@example.com'});

      await pumpAuthScreen(tester);

      final fbBtn = find.text('auth.social.continueWithFacebook');
      await tester.tap(fbBtn);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockFacebookAuth.getUserData(fields: 'name,email')).called(1);
      verify(() => userWithoutName.updateDisplayName('Mario Rossi')).called(1);
    });

    testWidgets('_signInWithFacebook: success flow but skips getUserData if displayName is already present',
        (WidgetTester tester) async {
      final mockLoginResult = MockLoginResult();
      when(() => mockLoginResult.status).thenReturn(LoginStatus.success);
      when(() => mockAccessToken.tokenString).thenReturn('mock_fb_token_string');
      when(() => mockLoginResult.accessToken).thenReturn(mockAccessToken);
      when(() => mockFacebookAuth.login(permissions: any(named: 'permissions')))
          .thenAnswer((_) async => mockLoginResult);

      final userWithName = MockUser();
      when(() => userWithName.displayName).thenReturn('Emanuele Ciotola');

      final userCredWithName = MockUserCredential();
      when(() => userCredWithName.user).thenReturn(userWithName);

      when(() => mockAuth.signInWithCredential(any())).thenAnswer((_) async => userCredWithName);

      await pumpAuthScreen(tester);

      final fbBtn = find.text('auth.social.continueWithFacebook');
      await tester.tap(fbBtn);
      await tester.pump(const Duration(milliseconds: 100));

      // Verifica che NON venga chiamata l'API getUserData di Facebook
      verifyNever(() => mockFacebookAuth.getUserData(fields: any(named: 'fields')));
    });

    testWidgets('_signInWithFacebook: handles FirebaseAuthException cancellation',
        (WidgetTester tester) async {
      final mockLoginResult = MockLoginResult();
      when(() => mockLoginResult.status).thenReturn(LoginStatus.success);
      when(() => mockAccessToken.tokenString).thenReturn('mock_fb_token_string');
      when(() => mockLoginResult.accessToken).thenReturn(mockAccessToken);
      when(() => mockFacebookAuth.login(permissions: any(named: 'permissions')))
          .thenAnswer((_) async => mockLoginResult);

      when(() => mockAuth.signInWithCredential(any())).thenThrow(
        FirebaseAuthException(code: 'popup-closed', message: 'User closed popup'),
      );

      await pumpAuthScreen(tester);

      final fbBtn = find.text('auth.social.continueWithFacebook');
      await tester.tap(fbBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('auth.errors.facebookCancelledOrInProgress'), findsOneWidget);
    });

    testWidgets('_signInWithFacebook: handles FirebaseAuthException non-cancel error',
        (WidgetTester tester) async {
      final mockLoginResult = MockLoginResult();
      when(() => mockLoginResult.status).thenReturn(LoginStatus.success);
      when(() => mockAccessToken.tokenString).thenReturn('mock_fb_token_string');
      when(() => mockLoginResult.accessToken).thenReturn(mockAccessToken);
      when(() => mockFacebookAuth.login(permissions: any(named: 'permissions')))
          .thenAnswer((_) async => mockLoginResult);

      when(() => mockAuth.signInWithCredential(any())).thenThrow(
        FirebaseAuthException(code: 'user-disabled', message: 'User account disabled'),
      );

      await pumpAuthScreen(tester);

      final fbBtn = find.text('auth.social.continueWithFacebook');
      await tester.tap(fbBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('auth.errors.firebaseError'), findsOneWidget);
    });

    testWidgets('_signInWithFacebook: handles generic exception',
        (WidgetTester tester) async {
      when(() => mockFacebookAuth.login(permissions: any(named: 'permissions')))
          .thenThrow(Exception('Facebook unexpected fatal error'));

      await pumpAuthScreen(tester);

      final fbBtn = find.text('auth.social.continueWithFacebook');
      await tester.tap(fbBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('auth.errors.facebookSignInError'), findsOneWidget);
    });
  });
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.
// This is a basic Flutter widget test.

// flutter test test/widgets/

// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gscanner/widgets/auth_screen.dart';
import 'mocks/shared_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupMocktailFallbacks();
    SharedPreferences.setMockInitialValues({'gscanner_terms_accepted': true});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('Auth screen smoke test', (WidgetTester tester) async {
    final mockAuth = MockFirebaseAuth();
    final mockGoogle = MockGoogleSignIn();
    final mockFacebook = MockFacebookAuth();

    await tester.pumpWidget(
      createTestApp(
        child: AuthScreen(
          firebaseAuth: mockAuth,
          googleSignIn: mockGoogle,
          facebookAuth: mockFacebook,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AuthScreen), findsOneWidget);
  });
}

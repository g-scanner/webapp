// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Shared Mocks for Widget & Unit Tests.

// ignore_for_file: subtype_of_sealed_class

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:easy_localization/easy_localization.dart';

// ==========================================
// MOCK CLASSES VIA MOCKTAIL
// ==========================================

class MockHttpClient extends Mock implements http.Client {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockWriteBatch extends Mock implements WriteBatch {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockFacebookAuth extends Mock implements FacebookAuth {}

class MockLoginResult extends Mock implements LoginResult {}

// Fake classes for Mocktail registerFallbackValue
class FakeUri extends Fake implements Uri {}

class FakeAuthCredential extends Fake implements AuthCredential {}

class FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {}

// Falso caricatore per evitare i delay asincroni nei test
class TestAssetLoader extends AssetLoader {
  const TestAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return {}; // Restituisce un dizionario vuoto istantaneamente
  }
}

// ==========================================
// TEST WRAPPER & ENVIRONMENT SETUP HELPERS
// ==========================================

/// Inizializza i fallback values per mocktail
void setupMocktailFallbacks() {
  registerFallbackValue(FakeUri());
  registerFallbackValue(FakeAuthCredential());
  registerFallbackValue(FakeDocumentReference());
}

/// Crea un widget wrapper con localizzazione (EasyLocalization) e tema per i test UI
Widget createTestApp({
  required Widget child,
  Locale locale = const Locale('it'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  return EasyLocalization(
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
    startLocale: locale,
    useOnlyLangCode: true,
    child: Builder(
      builder: (context) {
        return MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D631B),
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D631B),
              brightness: Brightness.dark,
            ),
          ),
          home: child,
        );
      },
    ),
  );
}

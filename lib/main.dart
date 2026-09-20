// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:easy_localization/easy_localization.dart';

import 'firebase_options.dart';
import 'services/database/app_database.dart';
import 'core/theme/theme.dart';
import 'core/localization/modular_asset_loader.dart';
import 'features/auth/auth_screen.dart';
import 'features/shell/shell.dart';

// Re-export per garantire compatibilità con test e consumer storici
export 'features/shell/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();
  await AppDatabase.instance.database;

  usePathUrlStrategy();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('it'),
        Locale('en'),
        Locale('de'),
        Locale('fr'),
        Locale('es'),
      ],
      path: 'assets/locales',
      fallbackLocale: const Locale('it'),
      useOnlyLangCode: true,
      assetLoader: const ModularAssetLoader(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  final FirebaseAuth? auth;
  const MyApp({super.key, this.auth});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FirebaseAuth _firebaseAuth;
  late final Stream<User?> _authStateStream;

  @override
  void initState() {
    super.initState();
    _firebaseAuth = widget.auth ?? FirebaseAuth.instance;
    // Lo stream viene creato una sola volta: così StreamBuilder non si
    // ri-sottoscrive (e non flashia il loading spinner) quando il tema cambia.
    _authStateStream = _firebaseAuth.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: 'G-Scanner',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: currentThemeMode,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: StreamBuilder<User?>(
            stream: _authStateStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }

              if (snapshot.hasData && snapshot.data != null) {
                return MainScreen(auth: _firebaseAuth);
              }

              return AuthScreen(firebaseAuth: _firebaseAuth);
            },
          ),
        );
      },
    );
  }
}

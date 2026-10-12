// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:easy_localization/easy_localization.dart';

import 'firebase_options.dart';
import 'services/database/app_database.dart';
import 'core/theme/theme.dart';
import 'core/localization/modular_asset_loader.dart';
import 'models/models.dart';
import 'services/db_service.dart';
import 'features/sync/sync_data_screen.dart';
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

// ─────────────────────────────────────────────────────────────────────────────
// Stato di routing risolto: contiene user + eventuale sync summary.
// Immutable: ogni cambiamento di rotta produce un nuovo oggetto.
// ─────────────────────────────────────────────────────────────────────────────

class ResolvedAuth {
  final User user;
  final AnonymousDataSummary? syncSummary;
  const ResolvedAuth({required this.user, this.syncSummary});
}

// ─────────────────────────────────────────────────────────────────────────────
// MyApp — Root Widget
// ─────────────────────────────────────────────────────────────────────────────

class MyApp extends StatefulWidget {
  final FirebaseAuth? auth;
  const MyApp({super.key, this.auth});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FirebaseAuth _firebaseAuth;
  late final StreamSubscription<User?> _authSubscription;

  /// null = non autenticato (AuthScreen) oppure cold-start in corso.
  ResolvedAuth? _resolved;

  /// true solo durante il cold-start di un utente già autenticato,
  /// mentre il check sync è in corso. In produzione dura ~10-50ms.
  bool _coldStartResolving = false;

  @override
  void initState() {
    super.initState();
    _firebaseAuth = widget.auth ?? FirebaseAuth.instance;

    // Cold start: se l'utente è già autenticato, risolvi la route.
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      _coldStartResolving = true;
      _resolveForUser(currentUser);
    }

    // Ascolta cambiamenti futuri (login, logout, cambio utente).
    // skip(1): il primo evento è lo stato attuale, già gestito sopra.
    _authSubscription = _firebaseAuth.authStateChanges().skip(1).listen(
      _onAuthChanged,
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  /// Gestisce login, logout e cambio utente dallo stream Firebase.
  ///
  /// Su login: NON aggiorna subito lo stato → l'AuthScreen con lo spinner
  /// resta visibile mentre [_resolveForUser] esegue il check sync locale.
  /// Solo al completamento avviene il setState e la transizione di schermata.
  void _onAuthChanged(User? user) {
    if (user == null) {
      // Logout: torna immediatamente all'AuthScreen.
      if (mounted) setState(() => _resolved = null);
    } else {
      // Login o cambio utente: risolvi sync PRIMA di cambiare schermata.
      _resolveForUser(user);
    }
  }

  /// Esegue il check dati anonimi pendenti (DB locale, ~10-50ms),
  /// poi aggiorna lo stato provocando la transizione di schermata.
  Future<void> _resolveForUser(User user) async {
    AnonymousDataSummary? summary;
    if (!user.isAnonymous) {
      summary = await DbService.getPendingAnonymousSyncData();
    }
    if (mounted) {
      setState(() {
        _resolved = ResolvedAuth(user: user, syncSummary: summary);
        _coldStartResolving = false;
      });
    }
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
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    final resolved = _resolved;

    // ── Non autenticato ──
    if (resolved == null) {
      // Cold start con utente già loggato: check in corso (~10-50ms).
      // Scaffold vuoto con sfondo tema, impercettibile.
      if (_coldStartResolving) {
        return const _BlankScaffold();
      }
      return AuthScreen(firebaseAuth: _firebaseAuth);
    }

    // ── Dati anonimi pendenti → schermata sincronizzazione ──
    if (resolved.syncSummary != null) {
      return SyncDataScreen(
        dataSummary: resolved.syncSummary!,
        onDecision: (bool wantToSync, [
          SyncChoices choices = const SyncChoices(),
        ]) async {
          if (wantToSync) {
            await DbService.migrateLocalDataToFirestore(
              resolved.user.uid,
              syncHistory: choices.syncHistory,
              syncReports: choices.syncReports,
              syncSettings: choices.syncSettings,
            );
          } else {
            await DbService.wipeAnonymousData();
          }
          if (mounted) {
            setState(() {
              _resolved = ResolvedAuth(user: resolved.user);
            });
          }
        },
      );
    }

    // ── MainScreen ──
    return MainScreen(
      key: ValueKey(resolved.user.uid),
      auth: _firebaseAuth,
    );
  }
}

/// Scaffold vuoto usato solo durante il cold-start (~10-50ms)
/// di un utente già autenticato. Utilizza automaticamente il colore
/// di sfondo del tema corrente. Nessuno spinner.
class _BlankScaffold extends StatelessWidget {
  const _BlankScaffold();
  @override
  Widget build(BuildContext context) => const Scaffold();
}

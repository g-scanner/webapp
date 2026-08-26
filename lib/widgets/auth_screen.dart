// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/db_service.dart';
import 'package:gscanner/utils/popup_tracker_stub.dart'
    if (dart.library.js_interop) 'package:gscanner/utils/popup_tracker_web.dart';

import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  final FirebaseAuth? firebaseAuth;
  final GoogleSignIn? googleSignIn;
  final FacebookAuth? facebookAuth;

  const AuthScreen({
    super.key,
    this.firebaseAuth,
    this.googleSignIn,
    this.facebookAuth,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  static bool _isGoogleSignInInitialized = false;

  FirebaseAuth get _auth => widget.firebaseAuth ?? FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn => widget.googleSignIn ?? GoogleSignIn.instance;
  FacebookAuth get _facebookAuth => widget.facebookAuth ?? FacebookAuth.instance;

  Future<void> _checkAndShowLegalPopup(Future<void> Function() onAccepted) async {
    final hasAccepted = await DbService.hasAcceptedTerms();
    if (hasAccepted) {
      await onAccepted();
      return;
    }

    final settings = await DbService.getLocalSettings();
    final lang = settings.preferredLanguage;

    if (!mounted) return;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LegalConsentDialog(lang: lang),
    );

    if (accepted == true) {
      await DbService.saveTermsAccepted();
      await onAccepted();
    }
  }

  // ==========================================
  // LOGICA ACCESSO ANONIMO
  // ==========================================
  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInAnonymously();
      // Se ha successo, lo StreamBuilder nel main.dart cambia pagina da solo.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(e.message ?? "auth.errors.anonymousFailed".tr());
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      _showError("auth.errors.genericError".tr(namedArgs: {"error": e.toString()}));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // LOGICA ACCESSO CON GOOGLE
  // ==========================================
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        final cred = await _signInWithPopupTracked(
          GoogleAuthProvider(),
          "Google",
        );
        if (cred == null && mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Mobile: usa authenticate() direttamente per mostrare il bottom sheet nativo (Credential Manager)
      final googleSignIn = _googleSignIn;
      if (!_isGoogleSignInInitialized) {
        await googleSignIn.initialize(
          serverClientId:
              '1026607445667-17rnkrlq2rb5csff47m8832htnco8964.apps.googleusercontent.com',
        );
        _isGoogleSignInInitialized = true;
      }

      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final errStr = (e.code + (e.message ?? '')).toLowerCase();
      if (errStr.contains('popup-closed') ||
          errStr.contains('cancel') ||
          errStr.contains('already-opened') ||
          errStr.contains('already-in-progress') ||
          errStr.contains('abort')) {
        _showInfo("auth.errors.googleCancelled".tr());
      } else {
        _showError("auth.errors.firebaseError".tr(namedArgs: {"message": e.message ?? ""}));
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('12501') ||
          errStr.contains('12502') ||
          errStr.contains('cancel') ||
          errStr.contains('abort')) {
        _showInfo("auth.errors.googleCancelledShort".tr());
      } else {
        _showError("auth.errors.googleSignInError".tr(namedArgs: {"error": e.toString()}));
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // LOGICA ACCESSO CON FACEBOOK (flutter_facebook_auth v7+)
  // ==========================================
  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        final cred = await _signInWithPopupTracked(
          FacebookAuthProvider(),
          "Facebook",
        );
        if (cred == null && mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // 1. Avvia il flusso nativo di Facebook usando .instance
      final LoginResult result = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );

      // Se l'utente annulla l'operazione o c'è un errore
      if (result.status != LoginStatus.success) {
        if (result.status == LoginStatus.cancelled) {
          _showInfo("auth.errors.facebookCancelled".tr());
        } else if (result.status == LoginStatus.failed) {
          if (!mounted) return;
          _showError("auth.errors.facebookError".tr(namedArgs: {"message": result.message ?? ""}));
        }
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. Recupera il token di accesso
      final AccessToken accessToken = result.accessToken!;

      // 3. Crea le credenziali per Firebase
      // Attenzione: nella v7 si usa .tokenString e non più .token
      final credential = FacebookAuthProvider.credential(
        accessToken.tokenString,
      );

      // 4. Esegui il login su Firebase
      final UserCredential userCredential = await _auth
          .signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null &&
          (user.displayName == null || user.displayName!.isEmpty)) {
        try {
          final userData = await _facebookAuth.getUserData(
            fields: "name,email",
          );
          final name = userData['name'] as String?;
          if (name != null && name.isNotEmpty) {
            await user.updateDisplayName(name);
            await user.reload();
          }
        } catch (e) {
          debugPrint("Errore recupero info Facebook: $e");
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final errStr = (e.code + (e.message ?? '')).toLowerCase();
      if (errStr.contains('popup-closed') ||
          errStr.contains('cancel') ||
          errStr.contains('already-opened') ||
          errStr.contains('already-in-progress') ||
          errStr.contains('abort')) {
        _showInfo("auth.errors.facebookCancelledOrInProgress".tr());
      } else {
        _showError("auth.errors.firebaseError".tr(namedArgs: {"message": e.message ?? ""}));
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      _showError("auth.errors.facebookSignInError".tr(namedArgs: {"error": e.toString()}));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // WEB: Login con popup e rilevamento rapido chiusura
  // ==========================================
  Future<UserCredential?> _signInWithPopupTracked(
    AuthProvider provider,
    String providerName,
  ) async {
    bool completed = false;
    bool timerHandled = false;

    // Polling rapido: controlla ogni 150ms se il popup è stato chiuso dall'utente
    final checkTimer = Timer.periodic(const Duration(milliseconds: 150), (
      timer,
    ) {
      if (_isPopupClosed() && !completed) {
        timer.cancel();
        timerHandled = true;
        if (mounted && _isLoading) {
          setState(() => _isLoading = false);
          _showInfo("auth.errors.popupCancelled".tr(namedArgs: {"provider": providerName}));
        }
      }
    });

    try {
      final cred = await FirebaseAuth.instance.signInWithPopup(provider);
      completed = true;
      return cred;
    } catch (e) {
      completed = true;
      if (timerHandled) {
        // Se il timer ha già gestito la chiusura del popup, non facciamo rethrow
        return null;
      }
      rethrow;
    } finally {
      checkTimer.cancel();
    }
  }

  /// Chiama la funzione JS definita in index.html per verificare se il popup è chiuso
  bool _isPopupClosed() => jsIsLastPopupClosed();

  // Helper per mostrare gli errori
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper per mostrare informazioni generiche (non errori)
  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: Stack(
        children: [
          // Sfondo decorativo: Blob alto a sinistra
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colorScheme.secondaryContainer.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: context.colorScheme.secondaryContainer.withValues(alpha: 0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          // Sfondo decorativo: Blob basso a destra
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colorScheme.primaryContainer.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: context.colorScheme.primaryContainer.withValues(alpha: 0.15),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          // Contenuto Centrato
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                width: double.infinity,
                // Limitiamo la larghezza a 400 per tablet/desktop
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: context.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: context.colorScheme.shadow.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- BRANDING ---
                    Container(
                      width: 96,
                      height: 96,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.colorScheme.primaryContainer.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: const Image(
                        image: AssetImage(
                          'assets/logo/app_icon_foreground.png',
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "G-Scanner",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "auth.branding.tagline".tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- SOCIAL LOGINS ---
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: context.colorScheme.primary),
                      )
                    else ...[
                      _buildSocialBtn(
                        text: "auth.social.continueWithGoogle".tr(),
                        iconWidget: Image.asset(
                          'assets/icons/google.png',
                          width: 20,
                          height: 20,
                        ),
                        bgColor: context.colorScheme.primary,
                        textColor: context.colorScheme.onPrimary,
                        onTap: () => _checkAndShowLegalPopup(_signInWithGoogle),
                      ),
                      const SizedBox(height: 12),

                      _buildSocialBtn(
                        text: "auth.social.continueWithFacebook".tr(),
                        iconWidget: Image.asset(
                          'assets/icons/facebook.png',
                          width: 20,
                          height: 20,
                        ),
                        bgColor: context.cardBackground,
                        textColor: context.colorScheme.onSurface,
                        borderColor: context.colorScheme.outlineVariant,
                        onTap: () => _checkAndShowLegalPopup(_signInWithFacebook),
                      ),
                      const SizedBox(height: 24),

                      // --- GUEST ENTRY ---
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
                              thickness: 1.5,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              "auth.social.or".tr(),
                              style: TextStyle(
                                fontSize: 14,
                                color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
                              thickness: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () => _checkAndShowLegalPopup(_signInAnonymously),
                        icon: const Icon(Icons.person_off, size: 18),
                        label: Text(
                          "auth.social.enterAnonymously".tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: context.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "auth.social.anonymousDisclaimer".tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialBtn({
    required String text,
    required Widget iconWidget,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
    Color? borderColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: borderColor == null
              ? [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: borderColor == null
                  ? const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: iconWidget,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalConsentDialog extends StatefulWidget {
  final String lang;
  const _LegalConsentDialog({required this.lang});

  @override
  State<_LegalConsentDialog> createState() => _LegalConsentDialogState();
}

class _LegalConsentDialogState extends State<_LegalConsentDialog> {
  bool _isChecked = false;

  late final TapGestureRecognizer _tosRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  String get tosUrl {
    switch (widget.lang) {
      case 'it': return 'https://g-scanner.github.io/it/TerminiDiServizio.html';
      case 'es': return 'https://g-scanner.github.io/es/TerminosYCondiciones.html';
      case 'de': return 'https://g-scanner.github.io/de/Nutzungsbedingungen.html';
      case 'fr': return 'https://g-scanner.github.io/fr/ConditionsDUtilisation.html';
      default:   return 'https://g-scanner.github.io/TermsOfService.html';
    }
  }

  String get privacyUrl {
    switch (widget.lang) {
      case 'it': return 'https://g-scanner.github.io/it/InformativaSullaPrivacy.html';
      case 'es': return 'https://g-scanner.github.io/es/PoliticaDePrivacidad.html';
      case 'de': return 'https://g-scanner.github.io/de/Datenschutzerklaerung.html';
      case 'fr': return 'https://g-scanner.github.io/fr/PolitiqueDeConfidentialite.html';
      default:   return 'https://g-scanner.github.io/PrivacyPolicy.html';
    }
  }

  @override
  void initState() {
    super.initState();
    _tosRecognizer = TapGestureRecognizer()..onTap = () => _launchURL(tosUrl);
    _privacyRecognizer = TapGestureRecognizer()..onTap = () => _launchURL(privacyUrl);
  }

  @override
  void dispose() {
    _tosRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Dialog(
        backgroundColor: context.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con Icona e Titolo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.gavel_rounded,
                    color: context.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    "auth.legal.dialogTitle".tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Testo introduttivo
            Text(
              "auth.legal.dialogIntro".tr(),
              style: TextStyle(
                fontSize: 14,
                color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // Bullets
            _buildBulletItem(
              title: "auth.legal.bullet1Title".tr(),
              description: "auth.legal.bullet1Body".tr(),
            ),
            const SizedBox(height: 10),
            _buildBulletItem(
              title: "auth.legal.bullet2Title".tr(),
              description: "auth.legal.bullet2Body".tr(),
            ),
            const SizedBox(height: 10),
            _buildBulletItem(
              title: "auth.legal.bullet3Title".tr(),
              description: "auth.legal.bullet3Body".tr(),
            ),
            const SizedBox(height: 18),

            Divider(color: context.colorScheme.outlineVariant.withValues(alpha: 0.4), height: 1),
            const SizedBox(height: 14),

            // Checkbox con link a ToS e Privacy
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _isChecked,
                    activeColor: context.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) {
                      setState(() => _isChecked = val ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _isChecked = !_isChecked);
                    },
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: context.colorScheme.onSurface,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: "auth.legal.checkboxPre".tr(),
                          ),
                          TextSpan(
                            text: "auth.legal.checkboxTos".tr(),
                            style: TextStyle(
                              color: context.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: _tosRecognizer,
                          ),
                          TextSpan(text: "auth.legal.checkboxMid".tr()),
                          TextSpan(
                            text: "auth.legal.checkboxPrivacy".tr(),
                            style: TextStyle(
                              color: context.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: _privacyRecognizer,
                          ),
                          TextSpan(text: "auth.legal.checkboxPost".tr()),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Pulsante INIZIA
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isChecked
                    ? () => Navigator.pop(context, true)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colorScheme.primary,
                  disabledBackgroundColor: context.colorScheme.surfaceContainerHighest,
                  disabledForegroundColor: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "auth.legal.startButton".tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    ),
    );
  }

  Widget _buildBulletItem({
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: context.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: context.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: "$title: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

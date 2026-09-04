// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/utils.dart';
import '../../services/db_service.dart';
import 'widgets/widgets.dart';

export 'widgets/widgets.dart';

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
      builder: (context) => LegalConsentDialog(lang: lang),
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

      final LoginResult result = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );

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

      final AccessToken accessToken = result.accessToken!;
      final credential = FacebookAuthProvider.credential(
        accessToken.tokenString,
      );

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
        return null;
      }
      rethrow;
    } finally {
      checkTimer.cancel();
    }
  }

  bool _isPopupClosed() => jsIsLastPopupClosed();

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
                    const AuthBrandingHeader(),
                    const SizedBox(height: 32),
                    SocialAuthButtons(
                      isLoading: _isLoading,
                      onGoogleSignIn: () => _checkAndShowLegalPopup(_signInWithGoogle),
                      onFacebookSignIn: () => _checkAndShowLegalPopup(_signInWithFacebook),
                      onAnonymousSignIn: () => _checkAndShowLegalPopup(_signInAnonymously),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

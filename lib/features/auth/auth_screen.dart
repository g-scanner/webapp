// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — See LICENSE file in root for terms.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/utils.dart';
import '../../core/widgets/widgets.dart';
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
    } on FirebaseAuthException {
      if (!mounted) return;
      _showError("auth.errors.loginGenericError".tr());
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      _showError("auth.errors.loginGenericError".tr());
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
        _showError("auth.errors.loginGenericError".tr());
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
        _showError("auth.errors.loginGenericError".tr());
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
          _showError("auth.errors.loginGenericError".tr());
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
        _showError("auth.errors.loginGenericError".tr());
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      _showError("auth.errors.loginGenericError".tr());
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

    final checkTimer = Timer.periodic(const Duration(milliseconds: 250), (
      timer,
    ) async {
      if (_isPopupClosed() && !completed && !timerHandled) {
        // Grace period: quando il popup OAuth si chiude dopo il login,
        // FirebaseAuth impiega una frazione di secondo per completare il Future.
        await Future.delayed(const Duration(milliseconds: 400));
        if (completed) {
          timer.cancel();
          return;
        }
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
    showAppSnackBar(context, message, isError: true);
  }

  void _showInfo(String message) {
    if (!mounted) return;
    showAppSnackBar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: AppCard.primary(
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(
                vertical: 32,
                horizontal: 24,
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
      ),
    );
  }
}

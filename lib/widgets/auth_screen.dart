import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:gscanner/utils/popup_tracker_stub.dart'
    if (dart.library.js_interop) 'package:gscanner/utils/popup_tracker_web.dart';

const Color surfaceContainerLowest = Color(0xFFFFFFFF);
const Color iconForeground = Color(0xFFBFDEB4);
const Color surfaceVariant = Color(0xFFE3E2E6);
const Color primary = Color(0xFF0D631B);
const Color onPrimary = Color(0xFFFFFFFF);
const Color primaryContainer = Color(0xFF2E7D32);
const Color secondaryContainer = Color(0xFF54A0FE);
const Color onSurface = Color(0xFF1B1B1E);
const Color onSurfaceVariant = Color(0xFF40493D);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  static bool _isGoogleSignInInitialized = false;

  // ==========================================
  // LOGICA ACCESSO ANONIMO
  // ==========================================
  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      // Se ha successo, lo StreamBuilder nel main.dart cambia pagina da solo.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(e.message ?? "Errore di accesso anonimo");
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      _showError("Si è verificato un errore: $e");
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
      final googleSignIn = GoogleSignIn.instance;
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
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final errStr = (e.code + (e.message ?? '')).toLowerCase();
      if (errStr.contains('popup-closed') ||
          errStr.contains('cancel') ||
          errStr.contains('already-opened') ||
          errStr.contains('already-in-progress') ||
          errStr.contains('abort')) {
        _showInfo("Accesso con Google annullato o già in corso.");
      } else {
        _showError("Errore Firebase: ${e.message}");
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('12501') ||
          errStr.contains('12502') ||
          errStr.contains('cancel') ||
          errStr.contains('abort')) {
        _showInfo("Accesso con Google annullato.");
      } else {
        _showError("Errore Google Sign-In: $e");
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
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      // Se l'utente annulla l'operazione o c'è un errore
      if (result.status != LoginStatus.success) {
        if (result.status == LoginStatus.cancelled) {
          _showInfo("Accesso con Facebook annullato.");
        } else if (result.status == LoginStatus.failed) {
          if (!mounted) return;
          _showError("Errore Facebook: ${result.message}");
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
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null &&
          (user.displayName == null || user.displayName!.isEmpty)) {
        try {
          final userData = await FacebookAuth.instance.getUserData(
            fields: "name,email",
          );
          final name = userData['name'] as String?;
          if (name != null && name.isNotEmpty) {
            await user.updateDisplayName(name);
            await user.reload();
          }
        } catch (e) {
          print("Errore recupero info Facebook: $e");
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
        _showInfo("Accesso con Facebook annullato o già in corso.");
      } else {
        _showError("Errore Firebase: ${e.message}");
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      _showError("Errore Facebook Sign-In: $e");
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
          _showInfo("Accesso con $providerName annullato.");
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
        backgroundColor: onSurfaceVariant,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FC),
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
                color: secondaryContainer.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: secondaryContainer.withValues(alpha: 0.15),
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
                color: primaryContainer.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: primaryContainer.withValues(alpha: 0.15),
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
                  color: surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: surfaceVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
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
                        color: iconForeground,
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
                    const Text(
                      "G-Scanner",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Il tuo assistente affidabile per le scelte senza\u00A0glutine.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- SOCIAL LOGINS ---
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: primary),
                      )
                    else ...[
                      _buildSocialBtn(
                        text: "Continua con Google",
                        iconWidget: Image.asset(
                          'assets/icons/google.png',
                          width: 20,
                          height: 20,
                        ),
                        bgColor: primary,
                        textColor: onPrimary,
                        onTap: _signInWithGoogle,
                      ),
                      const SizedBox(height: 12),

                      _buildSocialBtn(
                        text: "Continua con Facebook",
                        iconWidget: Image.asset(
                          'assets/icons/facebook.png',
                          width: 20,
                          height: 20,
                        ),
                        bgColor: Colors.white,
                        textColor: onSurface,
                        borderColor: surfaceVariant,
                        onTap: _signInWithFacebook,
                      ),
                      const SizedBox(height: 24),

                      // --- GUEST ENTRY ---
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              color: surfaceVariant,
                              thickness: 1.5,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              "Oppure",
                              style: TextStyle(
                                fontSize: 14,
                                color: onSurfaceVariant.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(
                              color: surfaceVariant,
                              thickness: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: _signInAnonymously,
                        icon: const Icon(Icons.person_off, size: 18),
                        label: const Text(
                          "Entra senza autenticazione",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "La cronologia scansioni e le impostazioni utente verranno salvate solo localmente.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurfaceVariant.withValues(alpha: 0.7),
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
          boxShadow: bgColor == primary
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.3),
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
              decoration: bgColor == primary
                  ? const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: iconWidget,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

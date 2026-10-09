// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../services/db_service.dart';

/// Mostra il dialog "serve riautenticazione" e, se confermato, effettua il signOut
/// e chiude il Bottom Sheet settings. Restituisce true se l'utente ha confermato.
Future<bool> _showReauthDialog(BuildContext context, FirebaseAuth auth) async {
  final colorScheme = context.colorScheme;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.cardBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      icon: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.security_rounded,
            color: colorScheme.primary,
            size: 28,
          ),
        ),
      ),
      title: Text(
        "settings.account.deleteReauthTitle".tr(),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        "settings.account.deleteReauthBody".tr(),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Azione 1: Procedi con il login (Primaria a pillola)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                "auth.social.proceed".tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Azione 2: Annulla (Outlined neutro a pillola)
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                "common.actions.cancel".tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  if (confirm == true) {
    await auth.signOut();
    // Lo StreamBuilder in main.dart reagisce automaticamente all'evento null di
    // authStateChanges() e sostituisce MainScreen con AuthScreen.
    // Non è necessario (e sarebbe dannoso) fare Navigator.pop qui:
    // a quel punto il context di MainScreen/BottomSheet è già smontato.
    return true;
  }
  return false;
}

/// Flusso di cancellazione account utente (verifica reautenticazione ed eliminazione dati).
Future<void> showDeleteAccountFlow({
  required BuildContext context,
  required FirebaseAuth auth,
  required void Function(String) onTriggerToast,
}) async {
  final user = auth.currentUser;
  if (user == null) return;

  final lastSignIn = user.metadata.lastSignInTime;
  final bool needsReauth =
      lastSignIn == null ||
      DateTime.now().difference(lastSignIn) > const Duration(minutes: 5);

  if (needsReauth) {
    // CASO 2: Sessione vecchia — serve riautenticazione
    await _showReauthDialog(context, auth);
    return;
  }

  // CASO 1: Può procedere immediatamente
  bool isDeletingAccount = false;
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) {
        final colorScheme = dialogCtx.colorScheme;

        return AlertDialog(
          backgroundColor: dialogCtx.cardBackground,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          icon: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_rounded,
                color: colorScheme.onErrorContainer,
                size: 28,
              ),
            ),
          ),
          title: Text(
            "settings.account.deleteConfirmTitle".tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: colorScheme.onSurface,
            ),
          ),
          content: Text(
            "settings.account.deleteConfirmBody".tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pulsante 1: Elimina definitivamente (Azione Distruttiva)
                FilledButton(
                  onPressed: isDeletingAccount
                      ? null
                      : () async {
                          setDialogState(() {
                            isDeletingAccount = true;
                          });
                          try {
                            final String uid = user.uid;

                            // Ri-verifica freschezza sessione
                            final lastSignInNow =
                                auth.currentUser?.metadata.lastSignInTime;
                            final bool sessionStillFresh =
                                lastSignInNow != null &&
                                DateTime.now().difference(lastSignInNow) <=
                                    const Duration(minutes: 5);
                            if (!sessionStillFresh) {
                              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                              if (context.mounted) {
                                await _showReauthDialog(context, auth);
                              }
                              return;
                            }

                            // STEP 1: Elimina account Auth
                            await user.delete();

                            // STEP 2: Elimina dati DB e cache
                            await Future.wait([
                              DbService.deleteUserSettings(uid),
                              DbService.deleteUserHistory(uid),
                              DbService.anonymizeUserReports(uid),
                              DbService.wipeCurrentUserLocalData(),
                            ]);

                            if (dialogCtx.mounted) {
                              Navigator.of(
                                dialogCtx,
                              ).popUntil((route) => route.isFirst);
                            }

                            await auth.signOut();
                          } on FirebaseAuthException catch (e) {
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            if (e.code == 'requires-recent-login') {
                              if (context.mounted) {
                                await _showReauthDialog(context, auth);
                              }
                            } else {
                              onTriggerToast("Errore: ${e.message}");
                            }
                          } catch (e) {
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            onTriggerToast("Errore imprevisto: $e");
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    disabledBackgroundColor: colorScheme.error.withValues(
                      alpha: 0.6,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isDeletingAccount
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: colorScheme.onError,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "settings.account.deleteConfirmAction".tr(),
                            key: const ValueKey('text'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                // Pulsante 2: Annulla (Outlined neutro a pillola)
                OutlinedButton(
                  onPressed: isDeletingAccount
                      ? null
                      : () => Navigator.pop(dialogCtx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    "common.actions.cancel".tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

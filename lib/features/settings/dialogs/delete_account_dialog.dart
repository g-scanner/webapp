// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../services/db_service.dart';

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
      DateTime.now().difference(lastSignIn).inMinutes > 5;

  if (needsReauth) {
    // CASO 2: Serve riautenticazione/re-login per motivi di sicurezza
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: ctx.colorScheme.outlineVariant, width: 1.5),
        ),
        icon: Icon(Icons.security_rounded, color: ctx.colorScheme.primary, size: 36),
        title: Text(
          "settings.account.deleteReauthTitle".tr(),
          style: TextStyle(
            color: ctx.colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          "settings.account.deleteReauthBody".tr(),
          style: TextStyle(color: ctx.colorScheme.onSurfaceVariant, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: ctx.colorScheme.onSurfaceVariant),
            child: Text("common.actions.cancel".tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: ctx.colorScheme.primary,
              foregroundColor: ctx.colorScheme.onPrimary,
            ),
            child: Text("auth.social.proceed".tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await auth.signOut();
      if (context.mounted) {
        Navigator.pop(context); // Chiude il Bottom Sheet settings
      }
    }
    return;
  }

  // CASO 1: Può procedere immediatamente
  bool isDeletingAccount = false;
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) => AlertDialog(
        backgroundColor: dialogCtx.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: dialogCtx.colorScheme.errorContainer, width: 2),
        ),
        icon: Icon(Icons.warning_amber_rounded, color: dialogCtx.colorScheme.error, size: 36),
        title: Text(
          "settings.account.deleteConfirmTitle".tr(),
          style: TextStyle(
            color: dialogCtx.colorScheme.error,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          "settings.account.deleteConfirmBody".tr(),
          style: TextStyle(color: dialogCtx.colorScheme.onSurface, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: isDeletingAccount
                ? null
                : () => Navigator.pop(dialogCtx),
            style: TextButton.styleFrom(foregroundColor: dialogCtx.colorScheme.onSurfaceVariant),
            child: Text("common.actions.cancel".tr()),
          ),
          FilledButton(
            onPressed: isDeletingAccount
                ? null
                : () async {
                    setDialogState(() {
                      isDeletingAccount = true;
                    });
                    try {
                      final String uid = user.uid;
                      await Future.wait([
                        DbService.deleteUserSettings(uid),
                        DbService.deleteUserHistory(uid),
                        DbService.anonymizeUserReports(uid),
                        DbService.wipeCurrentUserLocalData(),
                      ]);

                      // Chiude il popup e la bottom sheet tornando a MainScreen
                      if (dialogCtx.mounted) {
                        Navigator.of(
                          dialogCtx,
                        ).popUntil((route) => route.isFirst);
                      }

                      await user.delete();
                      await auth.signOut();
                    } on FirebaseAuthException catch (e) {
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      if (e.code == 'requires-recent-login') {
                        onTriggerToast("common.status.securityForcedLogout".tr());
                        await auth.signOut();
                      } else {
                        onTriggerToast("Errore: ${e.message}");
                      }
                    } catch (e) {
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      onTriggerToast("Errore imprevisto: $e");
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: dialogCtx.colorScheme.error,
              foregroundColor: dialogCtx.colorScheme.onError,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: isDeletingAccount ? 0.0 : 1.0,
                  child: const Text(
                    "Elimina definitivamente",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (isDeletingAccount)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: dialogCtx.colorScheme.onError.withValues(alpha: 0.7),
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

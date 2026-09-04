// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../services/db_service.dart';
import '../dialogs/dialogs.dart';

/// Sezione Account (Visualizzazione card utente, login anonimo e trigger gestione account).
class AccountSection extends StatelessWidget {
  final FirebaseAuth auth;
  final String? optimisticDisplayName;
  final void Function(String) onTriggerToast;
  final void Function(String) onUpdateOptimisticDisplayName;

  const AccountSection({
    super.key,
    required this.auth,
    required this.optimisticDisplayName,
    required this.onTriggerToast,
    required this.onUpdateOptimisticDisplayName,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = auth.currentUser;
    final bool isAnonymous = currentUser == null || currentUser.isAnonymous;
    final String displayName =
        optimisticDisplayName ?? currentUser?.displayName ?? "";
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              buildUserAvatar(context, isAnonymous, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAnonymous
                          ? "auth.social.anonymousUser".tr()
                          : (displayName.isNotEmpty
                                ? displayName
                                : "auth.social.registeredUser".tr()),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAnonymous
                          ? "auth.social.anonymousLocalSubtitle".tr()
                          : "settings.account.syncedCloudSubtitle".tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: isAnonymous
                ? FilledButton.tonalIcon(
                    onPressed: () => _handleAnonymousAction(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.login, size: 20),
                    label: Text(
                      "auth.social.signInOrRegister".tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: () => showAccountManagementSheet(
                      context: context,
                      auth: auth,
                      optimisticDisplayName: optimisticDisplayName,
                      onTriggerToast: onTriggerToast,
                      onUpdateOptimisticDisplayName: onUpdateOptimisticDisplayName,
                      onLogout: _handleLogout,
                      buildAvatar: buildUserAvatar,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.manage_accounts_outlined, size: 20),
                    label: Text(
                      "settings.account.manageAccount".tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static Widget buildUserAvatar(BuildContext context, bool isAnonymous, {double size = 56}) {
    final colorScheme = context.colorScheme;
    if (isAnonymous) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person_outline,
          color: colorScheme.onSurfaceVariant,
          size: size * 0.5,
        ),
      );
    } else {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person, color: colorScheme.primary, size: size * 0.5),
      );
    }
  }

  Future<void> _handleAnonymousAction(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "auth.social.signInAction".tr(),
          style: TextStyle(color: ctx.colorScheme.onSurface),
        ),
        content: Text(
          "auth.social.signInCloudPrompt".tr(),
          style: TextStyle(color: ctx.colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: ctx.colorScheme.onSurfaceVariant),
            child: Text("common.actions.cancel".tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.colorScheme.primary),
            child: Text("auth.social.proceed".tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      onTriggerToast("auth.social.preparingLogin".tr());
      try {
        await DbService.wipeAllLocalData();
        await auth.currentUser?.delete();
        await auth.signOut();
      } catch (e) {
        onTriggerToast("Errore: $e");
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("settings.account.signOutConfirmTitle".tr(), style: TextStyle(color: ctx.colorScheme.onSurface)),
        content: Text(
          "settings.account.signOutConfirmBody".tr(),
          style: TextStyle(color: ctx.colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: ctx.colorScheme.onSurfaceVariant),
            child: Text("common.actions.cancel".tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.colorScheme.error),
            child: Text("settings.account.signOutShort".tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      onTriggerToast("settings.account.signingOut".tr());
      try {
        await DbService.wipeAllLocalData();
        await auth.signOut();
      } catch (e) {
        onTriggerToast("Errore durante la disconnessione: $e");
      }
    }
  }
}

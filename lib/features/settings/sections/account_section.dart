// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../services/db_service.dart';
import '../dialogs/dialogs.dart';

/// Sezione Account (Visualizzazione card utente, login anonimo e trigger gestione account).
class AccountSection extends StatelessWidget {
  final FirebaseAuth auth;
  final String? optimisticDisplayName;
  final void Function(String message, {bool isError}) onTriggerToast;
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
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
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
          isAnonymous
              ? AppSecondaryButton(
                  onPressed: () => _handleAnonymousAction(context),
                  icon: Icons.login,
                  label: "auth.social.signInOrRegister".tr(),
                  fullWidth: true,
                )
              : AppTertiaryButton(
                  onPressed: () => showAccountManagementSheet(
                    context: context,
                    auth: auth,
                    optimisticDisplayName: optimisticDisplayName,
                    onTriggerToast: onTriggerToast,
                    onUpdateOptimisticDisplayName:
                        onUpdateOptimisticDisplayName,
                    onLogout: _handleLogout,
                    buildAvatar: buildUserAvatar,
                  ),
                  icon: Icons.manage_accounts_outlined,
                  label: "settings.account.manageAccount".tr(),
                  fullWidth: true,
                ),
        ],
      ),
    );
  }

  static Widget buildUserAvatar(
    BuildContext context,
    bool isAnonymous, {
    double size = 56,
  }) {
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
          color: colorScheme.iconCirclePrimaryBg,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person, color: colorScheme.primary, size: size * 0.5),
      );
    }
  }

  Future<void> _handleAnonymousAction(BuildContext context) async {
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
              color: colorScheme.iconCirclePrimaryBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_upload_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
        ),
        title: Text(
          "auth.social.signInAction".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "auth.social.signInCloudPrompt".tr(),
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
              AppPrimaryButton(
                onPressed: () => Navigator.pop(ctx, true),
                label: "auth.social.proceed".tr(),
              ),
              const SizedBox(height: 10),
              AppTertiaryButton(
                onPressed: () => Navigator.pop(ctx, false),
                label: "common.actions.cancel".tr(),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      onTriggerToast("auth.social.preparingLogin".tr());
      try {
        await auth.currentUser?.delete();
        await auth.signOut();
      } catch (e) {
        onTriggerToast(
          "settings.account.deleteAccountError".tr(),
          isError: true,
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
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
              color: colorScheme.iconCircleErrorBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.logout_rounded,
              color: colorScheme.error,
              size: 28,
            ),
          ),
        ),
        title: Text(
          "settings.account.signOutConfirmTitle".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "settings.account.signOutConfirmBody".tr(),
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
              // Azione 1: Esci dall'account
              AppPrimaryDestructiveButton(
                onPressed: () => Navigator.pop(ctx, true),
                label: "common.actions.signOut".tr(),
              ),
              const SizedBox(height: 10),

              // Azione 2: Annulla
              AppTertiaryButton(
                onPressed: () => Navigator.pop(ctx, false),
                label: "common.actions.cancel".tr(),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DbService.wipeCurrentUserLocalData();
        await auth.signOut();
      } catch (e) {
        onTriggerToast(
          "settings.account.signOutError".tr(),
          isError: true,
        );
      }
    }
  }
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../dialogs/dialogs.dart';

/// Mostra il bottom sheet di gestione account per l'utente loggato.
void showAccountManagementSheet({
  required BuildContext context,
  required FirebaseAuth auth,
  required String? optimisticDisplayName,
  required void Function(String) onTriggerToast,
  required void Function(String) onUpdateOptimisticDisplayName,
  required Future<void> Function(BuildContext) onLogout,
  required Widget Function(BuildContext, bool, {double size}) buildAvatar,
}) {
  final currentUser = auth.currentUser;
  if (currentUser == null) return;

  bool isEditingName = false;
  final TextEditingController nameController = TextEditingController(
    text: optimisticDisplayName ?? currentUser.displayName ?? "",
  );
  final FocusNode nameFocusNode = FocusNode();

  String providerName = "Account";
  IconData providerIcon = Icons.account_circle_outlined;
  if (currentUser.providerData.isNotEmpty) {
    final pid = currentUser.providerData.first.providerId;
    if (pid.contains('google')) {
      providerName = "Google";
      providerIcon = Icons.g_mobiledata;
    } else if (pid.contains('facebook')) {
      providerName = "Facebook";
      providerIcon = Icons.facebook;
    } else if (pid.contains('password')) {
      providerName = "Email";
      providerIcon = Icons.email_outlined;
    } else if (pid.contains('phone')) {
      providerName = "Telefono";
      providerIcon = Icons.phone_android;
    }
  }
  final String identifier =
      (currentUser.email != null && currentUser.email!.isNotEmpty)
          ? currentUser.email!
          : ((currentUser.phoneNumber != null &&
                    currentUser.phoneNumber!.isNotEmpty)
                ? currentUser.phoneNumber!
                : "Dati cloud");

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: false,
    constraints: const BoxConstraints(maxWidth: 500),
    backgroundColor: context.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) {
      final colorScheme = ctx.colorScheme;
      final cardBg = ctx.cardBackground;
      return StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setModalState) {
          final String currentDisplayName =
              optimisticDisplayName ?? currentUser.displayName ?? "";

          void goBackToMenu() {
            nameFocusNode.unfocus();
            Future.delayed(const Duration(milliseconds: 200), () {
              if (ctx.mounted) {
                setModalState(() => isEditingName = false);
              }
            });
          }

          Widget buildMenuView() {
            return Column(
              key: const ValueKey("MenuView"),
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(top: 16, bottom: 24),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                buildAvatar(ctx, false, size: 80),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    currentDisplayName.isNotEmpty
                        ? currentDisplayName
                        : "auth.social.addYourName".tr(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    nameController.text = currentDisplayName;
                    setModalState(() => isEditingName = true);
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (ctx.mounted && nameFocusNode.canRequestFocus) {
                        nameFocusNode.requestFocus();
                      }
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    "settings.account.editName".tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: (providerName == "Google" ||
                                        providerName == "Facebook")
                                    ? Colors.transparent
                                    : colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: providerName == "Google"
                                  ? Image.asset(
                                      'assets/icons/google.png',
                                      width: 28,
                                      height: 28,
                                    )
                                  : providerName == "Facebook"
                                  ? Image.asset(
                                      'assets/icons/facebook.png',
                                      width: 28,
                                      height: 28,
                                    )
                                  : Icon(
                                      providerIcon,
                                      color: colorScheme.onSurfaceVariant,
                                      size: 24,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    identifier,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.link,
                                        size: 14,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          "auth.social.connectedWith".tr(namedArgs: {"provider": providerName}),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(
                          height: 1,
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              onLogout(context);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              foregroundColor: colorScheme.onSurface,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            icon: const Icon(Icons.logout, size: 20),
                            label: Text(
                              "settings.account.signOut".tr(),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              showDeleteAccountFlow(
                                context: context,
                                auth: auth,
                                onTriggerToast: onTriggerToast,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              backgroundColor: colorScheme.errorContainer.withValues(
                                alpha: 0.3,
                              ),
                              side: BorderSide(color: colorScheme.errorContainer),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            icon: const Icon(
                              Icons.person_remove_outlined,
                              size: 20,
                            ),
                            label: Text(
                              "settings.account.deleteAccount".tr(),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: isEditingName
                    ? buildEditNameView(
                        context: ctx,
                        colorScheme: colorScheme,
                        nameController: nameController,
                        nameFocusNode: nameFocusNode,
                        currentDisplayName: currentDisplayName,
                        onGoBack: goBackToMenu,
                        onSaveName: (newName) async {
                          if (newName != currentDisplayName) {
                            onUpdateOptimisticDisplayName(newName);
                            goBackToMenu();
                            try {
                              await currentUser.updateDisplayName(newName);
                            } catch (_) {}
                          } else {
                            goBackToMenu();
                          }
                        },
                      )
                    : buildMenuView(),
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    nameFocusNode.dispose();
  });
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — See LICENSE file in root for terms.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import 'app_buttons.dart';

/// Mostra un dialogo di conferma modale coordinato con il design system di GlutiEnd.
Future<void> showAppConfirmDialog({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
  required FutureOr<void> Function() onConfirm,
  String? cancelLabel,
  bool isDestructive = true,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final colorScheme = ctx.colorScheme;
      final cardBg = ctx.cardBackground;

      return AlertDialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        icon: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDestructive
                  ? colorScheme.iconCircleErrorBg
                  : colorScheme.iconCirclePrimaryBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDestructive
                  ? colorScheme.error
                  : colorScheme.primary,
              size: 28,
            ),
          ),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
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
              if (isDestructive)
                AppPrimaryDestructiveButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await onConfirm();
                  },
                  label: confirmLabel,
                )
              else
                AppPrimaryButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await onConfirm();
                  },
                  label: confirmLabel,
                ),
              const SizedBox(height: 10),
              AppTertiaryButton(
                onPressed: () => Navigator.pop(ctx),
                label: cancelLabel ?? "common.actions.cancel".tr(),
              ),
            ],
          ),
        ],
      );
    },
  );
}

/// Mostra il dialogo standard di conferma per l'eliminazione di un elemento dalla cronologia.
Future<void> showDeleteHistoryConfirmDialog({
  required BuildContext context,
  required FutureOr<void> Function() onConfirm,
}) {
  return showAppConfirmDialog(
    context: context,
    icon: Icons.delete_outline_rounded,
    title: "common.actions.deleteHistoryConfirmTitle".tr(),
    message: "common.actions.deleteHistoryConfirmBody".tr(),
    confirmLabel: "common.actions.delete".tr(),
    onConfirm: onConfirm,
  );
}

/// Mostra il dialogo standard di conferma per l'eliminazione di una segnalazione.
Future<void> showDeleteReportConfirmDialog({
  required BuildContext context,
  required FutureOr<void> Function() onConfirm,
}) {
  return showAppConfirmDialog(
    context: context,
    icon: Icons.report_gmailerrorred_rounded,
    title: "common.actions.deleteReportConfirmTitle".tr(),
    message: "common.actions.deleteReportConfirmBody".tr(),
    confirmLabel: "common.actions.delete".tr(),
    onConfirm: onConfirm,
  );
}


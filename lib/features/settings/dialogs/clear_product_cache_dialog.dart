// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';

/// Dialog di conferma eliminazione cache prodotti locali.
Future<bool?> showClearProductCacheDialog(BuildContext context) {
  final colorScheme = context.colorScheme;

  return showDialog<bool>(
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
            color: colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            color: colorScheme.onErrorContainer,
            size: 28,
          ),
        ),
      ),
      title: Text(
        "settings.dataAndHistory.clearProductsTitle".tr(),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        "settings.dataAndHistory.clearProductsConfirm".tr(),
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
            // Azione Distruttiva: Cancella cache prodotti
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                "settings.dataAndHistory.clearProductsAction".tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Azione Neutra: Annulla
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
}

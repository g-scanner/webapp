// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

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
            color: colorScheme.iconCircleErrorBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            color: colorScheme.error,
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
            AppPrimaryDestructiveButton(
              onPressed: () => Navigator.pop(ctx, true),
              label: "settings.dataAndHistory.clearProductsAction".tr(),
            ),
            const SizedBox(height: 10),

            // Azione Neutra: Annulla
            AppTertiaryButton(
              onPressed: () => Navigator.pop(ctx, false),
              label: "common.actions.cancel".tr(),
            ),
          ],
        ),
      ],
    ),
  );
}

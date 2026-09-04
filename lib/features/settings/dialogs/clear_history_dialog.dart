// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';

/// Dialog di conferma eliminazione cronologia.
Future<bool?> showClearHistoryDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.cardBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text(
        "settings.destructive.clearHistoryTitle".tr(),
        style: TextStyle(color: ctx.colorScheme.onSurface),
      ),
      content: Text(
        "settings.data.clearHistoryConfirm".tr(),
        style: TextStyle(color: ctx.colorScheme.onSurfaceVariant),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: TextButton.styleFrom(
            foregroundColor: ctx.colorScheme.onSurfaceVariant,
          ),
          child: Text("common.actions.cancel".tr()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: ctx.colorScheme.error),
          child: Text("settings.destructive.clearHistoryTitle".tr()),
        ),
      ],
    ),
  );
}

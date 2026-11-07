// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pulsante riutilizzabile per azioni distruttive secondarie / tonali,
/// coordinato con il design system di G-Scanner per operazioni critiche
/// (elimina account, disinstalla pacchetto offline, cancella cronologia).
class AppDestructiveActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool fullWidth;

  const AppDestructiveActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    final button = OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.destructiveButtonFg,
        backgroundColor: colorScheme.destructiveButtonBg,
        side: BorderSide(color: colorScheme.destructiveButtonBorder),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return colorScheme.splashError;
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return colorScheme.selectedErrorItemBg;
          }
          return null;
        }),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}
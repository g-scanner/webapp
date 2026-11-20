// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'app_buttons.dart';

/// Pulsante riutilizzabile per azioni distruttive terziarie / tonali,
/// coordinato con il design system di GlutiEnd per operazioni critiche
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
    return AppTertiaryDestructiveButton(
      onPressed: onPressed,
      icon: icon,
      label: label,
      fullWidth: fullWidth,
    );
  }
}

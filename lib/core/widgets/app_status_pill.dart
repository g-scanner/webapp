// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner - See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import '../../models/models.dart';

/// Varianti di colore predefinite per [AppStatusPill.preset].
///
/// I colori sono ricavati interamente dal [ColorScheme] del tema attivo,
/// quindi si adattano automaticamente a light/dark mode.
enum AppStatusPillVariant {
  /// Verde — adatto, sicuro, sincronizzato.
  /// bg: primaryContainer · text: primary
  primary,

  /// Rosso — non adatto, errore, obsoleto.
  /// bg: errorContainer · text: error
  error,

  /// Ambra/arancione — incerto, warning, aggiornamento consigliato.
  /// bg: tertiaryContainer · text: tertiary
  tertiary,

  /// Grigio neutro — sconosciuto, disabilitato, in attesa.
  /// bg: surfaceContainerHighest · text: onSurfaceVariant
  neutral,
}

/// Pillola di stato riutilizzabile con sfondo colorato e testo opzionalmente
/// accompagnato da icona.
///
/// ---
/// **Costruttore con variante predefinita** — colori dal tema, nessun hardcode:
/// ```dart
/// AppStatusPill.preset(
///   variant: AppStatusPillVariant.error,
///   label: "Non adatto",
///   icon: Icons.cancel_outlined,
/// )
/// ```
///
/// **Costruttore con colori personalizzati** — per casi fuori dalle 4 varianti:
/// ```dart
/// AppStatusPill(
///   label: "In download",
///   bgColor: colorScheme.surfaceContainerHighest,
///   textColor: colorScheme.onSurfaceVariant,
/// )
/// ```
class AppStatusPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color bgColor;
  final Color textColor;

  /// Costruttore con colori personalizzati.
  const AppStatusPill({
    super.key,
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.icon,
  });

  // ---------------------------------------------------------------------------
  // Helper statici — source of truth per colori e mapping status
  // ---------------------------------------------------------------------------

  /// Mappa un [GlutenSafetyStatus] alla variante colore corrispondente.
  static AppStatusPillVariant variantForStatus(GlutenSafetyStatus status) {
    switch (status) {
      case GlutenSafetyStatus.adatto:
        return AppStatusPillVariant.primary;
      case GlutenSafetyStatus.nonAdatto:
        return AppStatusPillVariant.error;
      case GlutenSafetyStatus.incerto:
        return AppStatusPillVariant.tertiary;
      case GlutenSafetyStatus.sconosciuto:
        return AppStatusPillVariant.neutral;
    }
  }

  /// Restituisce `bg` e `text` color per una [variant] dato un [colorScheme].
  ///
  /// Unica source of truth per tutti i widget che devono usare i colori
  /// delle varianti senza costruire una pillola (es. BentoStats, SafetyStatusCard).
  static ({Color bg, Color text}) colorsForVariant(
    AppStatusPillVariant variant,
    ColorScheme colorScheme,
  ) {
    switch (variant) {
      case AppStatusPillVariant.primary:
        return (
          bg: colorScheme.primaryContainer.withValues(alpha: 0.15),
          text: colorScheme.primary,
        );
      case AppStatusPillVariant.error:
        return (
          bg: colorScheme.errorContainer.withValues(alpha: 0.5),
          text: colorScheme.error,
        );
      case AppStatusPillVariant.tertiary:
        return (
          bg: colorScheme.tertiaryContainer.withValues(alpha: 0.1),
          text: colorScheme.tertiary,
        );
      case AppStatusPillVariant.neutral:
        return (
          bg: colorScheme.surfaceContainerHighest,
          text: colorScheme.onSurfaceVariant,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Costruttore con variante predefinita
  // ---------------------------------------------------------------------------

  /// Costruttore con variante predefinita — risolve i colori dal [ColorScheme].
  static Widget preset({
    Key? key,
    required AppStatusPillVariant variant,
    required String label,
    IconData? icon,
  }) {
    return Builder(
      key: key,
      builder: (context) {
        final colors = colorsForVariant(variant, Theme.of(context).colorScheme);
        return AppStatusPill(
          key: key,
          label: label,
          bgColor: colors.bg,
          textColor: colors.text,
          icon: icon,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

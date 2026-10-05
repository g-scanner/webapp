// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gscanner/core/theme/app_theme.dart';

/// Sezione "Lingua" con selettore lingua a popup.
class LanguageSection extends StatelessWidget {
  final String preferredLanguage;
  final void Function(String) onLanguageChange;

  const LanguageSection({
    super.key,
    required this.preferredLanguage,
    required this.onLanguageChange,
  });

  @override
  Widget build(BuildContext context) {
    final langLabels = {
      'it': 'common.languages.it'.tr(),
      'en': 'common.languages.en'.tr(),
      'es': 'common.languages.es'.tr(),
      'de': 'common.languages.de'.tr(),
      'fr': 'common.languages.fr'.tr(),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "settings.uiOptions.preferredLanguageTitle".tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "settings.uiOptions.preferredLanguageSubtitle".tr(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Pulsante con effetto splash M3
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: PopupMenuButton<String>(
              tooltip: "Scegli lingua",
              elevation: 6,
              shadowColor: Colors.black.withValues(alpha: 0.12),
              position: PopupMenuPosition.under,
              offset: const Offset(0, 8),
              color: context.cardBackground,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
              onSelected: onLanguageChange,
              itemBuilder: (context) {
                final colorScheme = context.colorScheme;

                return [
                  _buildLanguageMenuItem(
                    value: 'it',
                    label: "common.languages.it".tr(),
                    isSelected: preferredLanguage == 'it',
                    colorScheme: colorScheme,
                  ),
                  _buildLanguageMenuItem(
                    value: 'en',
                    label: "common.languages.en".tr(),
                    isSelected: preferredLanguage == 'en',
                    colorScheme: colorScheme,
                  ),
                  _buildLanguageMenuItem(
                    value: 'es',
                    label: "common.languages.es".tr(),
                    isSelected: preferredLanguage == 'es',
                    colorScheme: colorScheme,
                  ),
                  _buildLanguageMenuItem(
                    value: 'de',
                    label: "common.languages.de".tr(),
                    isSelected: preferredLanguage == 'de',
                    colorScheme: colorScheme,
                  ),
                  _buildLanguageMenuItem(
                    value: 'fr',
                    label: "common.languages.fr".tr(),
                    isSelected: preferredLanguage == 'fr',
                    colorScheme: colorScheme,
                  ),
                ];
              },
              // ── Trigger a Pillola Larga Identica a quella del Tema ──
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 130, maxWidth: 160),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          langLabels[preferredLanguage] ?? 'Italiano',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 22,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

PopupMenuItem<String> _buildLanguageMenuItem({
  required String value,
  required String label,
  required bool isSelected,
  required ColorScheme colorScheme,
}) {
  return PopupMenuItem<String>(
    value: value,
    // AZZERA il padding nativo per evitare il rettangolo grigio spigoloso
    padding: EdgeInsets.zero,
    height: 48,
    child: Padding(
      // Distanza dai bordi del menu a tendina
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          // Overlay primario semitrasparente che ti piaceva!
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          // Raggio interno che non toccherà mai i bordi del menu
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Checkbox circolare
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: isSelected
                    ? null
                    : Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.6,
                        ),
                        width: 1.5,
                      ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14, color: colorScheme.onPrimary)
                  : null,
            ),
          ],
        ),
      ),
    ),
  );
}

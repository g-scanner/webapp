// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gscanner/core/theme/app_theme.dart';
import 'package:gscanner/core/widgets/app_popup_menu_item.dart';

/// Sezione "Aspetto" con selettore tema a popup.
class AppearanceSection extends StatelessWidget {
  final String preferredTheme;
  final void Function(String) onThemeChange;

  const AppearanceSection({
    super.key,
    required this.preferredTheme,
    required this.onThemeChange,
  });

  @override
  Widget build(BuildContext context) {
    final themeLabels = {
      'system': 'common.themes.system'.tr(),
      'light': 'common.themes.light'.tr(),
      'dark': 'common.themes.dark'.tr(),
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
                  "settings.uiOptions.appThemeTitle".tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "settings.uiOptions.appThemeSubtitle".tr(),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: PopupMenuButton<String>(
              tooltip: "Scegli tema",
              elevation: 6,
              offset: const Offset(0, 8),
              shadowColor: Colors.black.withValues(alpha: 0.12),
              position: PopupMenuPosition.under,
              color: context.cardBackground,
              surfaceTintColor: Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
              onSelected: onThemeChange,
              itemBuilder: (context) {
                final colorScheme = context.colorScheme;

                return [
                  _buildThemeMenuItem(
                    value: 'system',
                    label: "common.themes.system".tr(),
                    isSelected: preferredTheme == 'system',
                    colorScheme: colorScheme,
                  ),
                  _buildThemeMenuItem(
                    value: 'light',
                    label: "common.themes.light".tr(),
                    isSelected: preferredTheme == 'light',
                    colorScheme: colorScheme,
                  ),
                  _buildThemeMenuItem(
                    value: 'dark',
                    label: "common.themes.dark".tr(),
                    isSelected: preferredTheme == 'dark',
                    colorScheme: colorScheme,
                  ),
                ];
              },
              // ── Trigger a Pillola GRANDE (Stile Lingua) ──
              child: ConstrainedBox(
                // Constraints più ampi per matchare il selettore "Italiano"
                constraints: const BoxConstraints(minWidth: 130, maxWidth: 160),
                child: Container(
                  // Padding maggiorato per rendere la pillola più spessa e cliccabile
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
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Distanzia testo e freccia
                    children: [
                      Flexible(
                        child: Text(
                          themeLabels[preferredTheme] ?? 'Sistema',
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
                        size: 22, // Freccia leggermente più grande
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

AppPopupMenuItem<String> _buildThemeMenuItem({
  required String value,
  required String label,
  required bool isSelected,
  required ColorScheme colorScheme,
}) {
  return AppPopupMenuItem<String>(
    value: value,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
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
  );
}

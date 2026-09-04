// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

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
          // Pulsante con effetto splash M3
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: PopupMenuButton<String>(
              tooltip: "Scegli tema",
              initialValue: preferredTheme,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme.of(context).cardColor,
              position: PopupMenuPosition.under,
              onSelected: onThemeChange,
              itemBuilder: (context) => [
                PopupMenuItem(value: 'system', child: Text("common.themes.system".tr())),
                PopupMenuItem(value: 'light', child: Text("common.themes.light".tr())),
                PopupMenuItem(value: 'dark', child: Text("common.themes.dark".tr())),
              ],
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 100, maxWidth: 140),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            themeLabels[preferredTheme] ?? 'Sistema',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
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

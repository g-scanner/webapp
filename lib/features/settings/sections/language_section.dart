// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

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
              initialValue: preferredLanguage,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme.of(context).cardColor,
              position: PopupMenuPosition.under,
              onSelected: onLanguageChange,
              itemBuilder: (context) => [
                PopupMenuItem(value: 'it', child: Text("common.languages.it".tr())),
                PopupMenuItem(value: 'en', child: Text("common.languages.en".tr())),
                PopupMenuItem(value: 'es', child: Text("common.languages.es".tr())),
                PopupMenuItem(value: 'de', child: Text("common.languages.de".tr())),
                PopupMenuItem(value: 'fr', child: Text("common.languages.fr".tr())),
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
                            langLabels[preferredLanguage] ?? 'Italiano',
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

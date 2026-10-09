// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_radio_popup_menu_item.dart';

/// Modello per una singola opzione del menu a discesa delle impostazioni.
class SettingsDropdownOption<T> {
  final T value;
  final String label;

  const SettingsDropdownOption({
    required this.value,
    required this.label,
  });
}

/// Riga standard delle impostazioni con titolo, sottotitolo e selettore a pillola popup,
/// conforme al design system di G-Scanner.
class SettingsDropdownTile<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tooltip;
  final T selectedValue;
  final List<SettingsDropdownOption<T>> options;
  final ValueChanged<T> onSelected;

  const SettingsDropdownTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tooltip,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    final selectedOption = options.firstWhere(
      (opt) => opt.value == selectedValue,
      orElse: () => options.first,
    );

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
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: PopupMenuButton<T>(
              tooltip: tooltip,
              elevation: 6,
              shadowColor: Colors.black.withValues(alpha: 0.12),
              position: PopupMenuPosition.under,
              offset: const Offset(0, 8),
              color: cardBg,
              surfaceTintColor: Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              onSelected: onSelected,
              itemBuilder: (context) {
                return options.map((opt) {
                  return AppRadioPopupMenuItem<T>(
                    value: opt.value,
                    label: opt.label,
                    isSelected: opt.value == selectedValue,
                    colorScheme: colorScheme,
                  );
                }).toList();
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 130, maxWidth: 160),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          selectedOption.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 22,
                        color: colorScheme.onSurfaceVariant,
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

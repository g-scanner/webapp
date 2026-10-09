// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_radio_popup_menu_item.dart';

/// Opzione per il menu popup a pillola con supporto a colori dinamici di stato.
class AppPillFilterOption<T> {
  final T value;
  final String label;
  final Color? color;
  final Color? textColor;

  const AppPillFilterOption({
    required this.value,
    required this.label,
    this.color,
    this.textColor,
  });
}

/// Dropdown a pillola riutilizzabile per i filtri (es. cronologia, segnalazioni),
/// conforme al design system di G-Scanner.
class AppPillFilterDropdown<T> extends StatelessWidget {
  final String tooltip;
  final T selectedValue;
  final List<AppPillFilterOption<T>> options;
  final ValueChanged<T> onSelected;
  final BoxConstraints? constraints;

  const AppPillFilterDropdown({
    super.key,
    required this.tooltip,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    final selectedOption = options.firstWhere(
      (opt) => opt.value == selectedValue,
      orElse: () => options.first,
    );

    final pillColor =
        selectedOption.color ?? colorScheme.surfaceContainerHighest;
    final pillTextColor =
        selectedOption.textColor ?? colorScheme.onSurfaceVariant;

    Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(999),
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
                color: pillTextColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.filter_list_rounded,
            size: 20,
            color: pillTextColor,
          ),
        ],
      ),
    );

    if (constraints != null) {
      pill = ConstrainedBox(constraints: constraints!, child: pill);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: PopupMenuButton<T>(
        tooltip: tooltip,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        offset: const Offset(0, 48),
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
            final isSelected = opt.value == selectedValue;
            final optColor = opt.color ?? colorScheme.surfaceContainerHighest;
            final optTextColor = opt.textColor ?? colorScheme.primary;

            return AppRadioPopupMenuItem<T>(
              value: opt.value,
              label: opt.label,
              isSelected: isSelected,
              colorScheme: colorScheme,
              activeColor: optTextColor,
              activeTextColor: optTextColor,
              activeBgColor: optColor,
              onTap: () => onSelected(opt.value),
            );
          }).toList();
        },
        child: pill,
      ),
    );
  }
}

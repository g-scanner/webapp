// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/app_popup_menu_item.dart';
import '../../../models/models.dart';

class HistoryFilterChips extends StatelessWidget {
  final GlutenSafetyStatus? filter;
  final ValueChanged<GlutenSafetyStatus?> onChanged;

  const HistoryFilterChips({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  Color _getFilterColorFor(BuildContext context, GlutenSafetyStatus? status) {
    final colorScheme = context.colorScheme;
    switch (status) {
      case GlutenSafetyStatus.adatto:
        return colorScheme.primary.withValues(alpha: 0.12);
      case GlutenSafetyStatus.incerto:
        return colorScheme.tertiary.withValues(alpha: 0.12);
      case GlutenSafetyStatus.nonAdatto:
        return colorScheme.error.withValues(alpha: 0.12);
      case GlutenSafetyStatus.sconosciuto:
        return colorScheme.outlineVariant.withValues(alpha: 0.2);
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Color _getFilterTextColorFor(
    BuildContext context,
    GlutenSafetyStatus? status,
  ) {
    final colorScheme = context.colorScheme;
    switch (status) {
      case GlutenSafetyStatus.adatto:
        return colorScheme.primary;
      case GlutenSafetyStatus.incerto:
        return colorScheme.tertiary;
      case GlutenSafetyStatus.nonAdatto:
        return colorScheme.error;
      case GlutenSafetyStatus.sconosciuto:
        return colorScheme.onSurfaceVariant;
      default:
        return colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    }
  }

  Color _getFilterIconColor(BuildContext context) {
    return _getFilterTextColorFor(context, filter);
  }

  String _getFilterLabel(GlutenSafetyStatus? status) {
    switch (status) {
      case GlutenSafetyStatus.adatto:
        return "history.filters.safe".tr();
      case GlutenSafetyStatus.incerto:
        return "history.filters.uncertain".tr();
      case GlutenSafetyStatus.nonAdatto:
        return "history.filters.unsafe".tr();
      case GlutenSafetyStatus.sconosciuto:
        return "history.filters.unknown".tr();
      default:
        return "history.filters.all".tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: PopupMenuButton<GlutenSafetyStatus?>(
        tooltip: "Filtra cronologia",
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        offset: const Offset(0, 48),
        color: context.cardBackground,
        surfaceTintColor: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        itemBuilder: (context) {
          final options = [
            null,
            GlutenSafetyStatus.adatto,
            GlutenSafetyStatus.incerto,
            GlutenSafetyStatus.nonAdatto,
            GlutenSafetyStatus.sconosciuto,
          ];

          return options.map((status) {
            final isSelected = filter == status;
            final statusBgColor = _getFilterColorFor(context, status);
            final statusTextColor = _getFilterTextColorFor(context, status);

            return AppPopupMenuItem<GlutenSafetyStatus?>(
              value: status,
              onTap: () => onChanged(status),
              customSplashColor: statusTextColor.withValues(alpha: 0.12),
              customHighlightColor: statusTextColor.withValues(alpha: 0.08),
              customHoverColor: statusTextColor.withValues(alpha: 0.06),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? statusBgColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getFilterLabel(status),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? statusTextColor
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Checkbox circolare coordinata
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? statusTextColor
                            : Colors.transparent,
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
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: colorScheme.surface,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }).toList();
        },
      // ── Trigger a Pillola (Niente bordi, colore dinamico) ──
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _getFilterColorFor(context, filter),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                _getFilterLabel(filter),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getFilterTextColorFor(context, filter),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.filter_list_rounded,
              size: 20,
              color: _getFilterIconColor(context),
            ),
          ],
        ),
      ),
    ),
  );
}
}

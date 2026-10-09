// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
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
    const statuses = [
      null,
      GlutenSafetyStatus.adatto,
      GlutenSafetyStatus.incerto,
      GlutenSafetyStatus.nonAdatto,
      GlutenSafetyStatus.sconosciuto,
    ];

    return AppPillFilterDropdown<GlutenSafetyStatus?>(
      tooltip: "Filtra cronologia",
      selectedValue: filter,
      onSelected: onChanged,
      options: statuses.map((status) {
        return AppPillFilterOption<GlutenSafetyStatus?>(
          value: status,
          label: _getFilterLabel(status),
          color: _getFilterColorFor(context, status),
          textColor: _getFilterTextColorFor(context, status),
        );
      }).toList(),
    );
  }
}

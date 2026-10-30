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

  ({Color bg, Color text}) _getFilterColorsFor(
    BuildContext context,
    GlutenSafetyStatus? status,
  ) {
    final colorScheme = context.colorScheme;
    if (status == null) {
      return (
        bg: colorScheme.surfaceContainerHighest,
        text: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      );
    }
    return AppStatusPill.colorsForVariant(
      AppStatusPill.variantForStatus(status),
      colorScheme,
    );
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
      tooltip: "history.filters.tooltip".tr(),
      selectedValue: filter,
      onSelected: onChanged,
      constraints: const BoxConstraints(minWidth: 110, maxWidth: 150),
      options: statuses.map((status) {
        final colors = _getFilterColorsFor(context, status);
        return AppPillFilterOption<GlutenSafetyStatus?>(
          value: status,
          label: _getFilterLabel(status),
          color: colors.bg,
          textColor: colors.text,
        );
      }).toList(),
    );
  }
}

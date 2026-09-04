// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../models/models.dart';

class HistoryFilterChips extends StatelessWidget {
  final GlutenSafetyStatus? filter;
  final ValueChanged<GlutenSafetyStatus?> onChanged;

  const HistoryFilterChips({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  Color _getFilterColor(BuildContext context) {
    final colorScheme = context.colorScheme;
    switch (filter) {
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

  Color _getFilterTextColor(BuildContext context) {
    final colorScheme = context.colorScheme;
    switch (filter) {
      case GlutenSafetyStatus.adatto:
        return colorScheme.primary;
      case GlutenSafetyStatus.incerto:
        return colorScheme.tertiary;
      case GlutenSafetyStatus.nonAdatto:
        return colorScheme.error;
      case GlutenSafetyStatus.sconosciuto:
        return colorScheme.onSurfaceVariant;
      default:
        return colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
    }
  }

  Color _getFilterIconColor(BuildContext context) {
    final colorScheme = context.colorScheme;
    switch (filter) {
      case GlutenSafetyStatus.adatto:
        return colorScheme.primary;
      case GlutenSafetyStatus.incerto:
        return colorScheme.tertiary;
      case GlutenSafetyStatus.nonAdatto:
        return colorScheme.error;
      case GlutenSafetyStatus.sconosciuto:
        return colorScheme.onSurfaceVariant;
      default:
        return colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
    }
  }

  TextStyle _dropdownItemTextStyle(Color color) {
    return TextStyle(color: color, fontWeight: FontWeight.w600);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return DropdownButtonFormField<GlutenSafetyStatus?>(
      isExpanded: true,
      initialValue: filter,
      icon: Icon(
        Icons.filter_list,
        color: _getFilterIconColor(context),
        size: 20,
      ),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _getFilterTextColor(context),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: _getFilterColor(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text(
            "history.filters.all".tr(),
            style: _dropdownItemTextStyle(
              colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
        DropdownMenuItem(
          value: GlutenSafetyStatus.adatto,
          child: Text(
            "history.filters.safe".tr(),
            style: _dropdownItemTextStyle(colorScheme.primary),
          ),
        ),
        DropdownMenuItem(
          value: GlutenSafetyStatus.incerto,
          child: Text(
            "history.filters.uncertain".tr(),
            style: _dropdownItemTextStyle(colorScheme.tertiary),
          ),
        ),
        DropdownMenuItem(
          value: GlutenSafetyStatus.nonAdatto,
          child: Text(
            "history.filters.unsafe".tr(),
            style: _dropdownItemTextStyle(colorScheme.error),
          ),
        ),
        DropdownMenuItem(
          value: GlutenSafetyStatus.sconosciuto,
          child: Text(
            "product.glutenStatus.uncertain".tr(),
            style: _dropdownItemTextStyle(
              colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

class ReportsFilterHeader extends StatelessWidget {
  final int activeReportsCount;
  final bool showSkeleton;
  final bool hasReportedProducts;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool isSearchFocused;
  final String searchTerm;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final String reportFilter;
  final ValueChanged<String> onFilterChanged;

  const ReportsFilterHeader({
    super.key,
    required this.activeReportsCount,
    this.showSkeleton = false,
    this.hasReportedProducts = true,
    required this.searchController,
    required this.searchFocusNode,
    required this.isSearchFocused,
    required this.searchTerm,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.reportFilter,
    required this.onFilterChanged,
  });

  Color _getFilterColor(BuildContext context, String filter) {
    final colorScheme = context.colorScheme;
    if (filter == "Mie") {
      return colorScheme.secondaryContainer.withValues(alpha: 0.15);
    }
    return colorScheme.surfaceContainerHighest;
  }

  Color _getFilterTextColor(BuildContext context, String filter) {
    final colorScheme = context.colorScheme;
    if (filter == "Mie") {
      return colorScheme.onSecondaryContainer;
    }
    return colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
  }

  String _getFilterLabel(String filter) {
    if (filter == "Mie") {
      return "report.list.dropdown.mine".tr();
    }
    return "report.list.dropdown.all".tr();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Intestazione Pagina ─────────────────────────────────────
        Text(
          "report.list.title".tr(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: kIsWeb ? FontWeight.w600 : FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "report.list.subtitle".tr(),
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // ── Card "In attesa" (Separata e indipendente) ──────────────
        if (hasReportedProducts || showSkeleton) ...[
          Skeletonizer(
            enabled: showSkeleton,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.onSurface.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pending_actions,
                      size: 20,
                      color: colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "report.list.item.activeBadge".tr(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: showSkeleton
                          ? colorScheme.tertiary.withValues(alpha: 0.18)
                          : colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${showSkeleton ? 99 : activeReportsCount}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: showSkeleton
                            ? colorScheme.tertiary
                            : colorScheme.onTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Ricerca e Filtri ────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: AppSearchBar(
                controller: searchController,
                focusNode: searchFocusNode,
                isFocused: isSearchFocused,
                searchQuery: searchTerm,
                onChanged: onSearchChanged,
                onClear: onSearchClear,
              ),
            ),
            const SizedBox(width: 12),

            // ── Filtro a Pillola PopupMenuButton (Stesso Design System) ──
            AppPillFilterDropdown<String>(
              tooltip: "report.list.dropdown.tooltip".tr(),
              selectedValue: reportFilter,
              onSelected: onFilterChanged,
              constraints: const BoxConstraints(minWidth: 110, maxWidth: 150),
              options: ["Tutte", "Mie"].map((option) {
                return AppPillFilterOption<String>(
                  value: option,
                  label: _getFilterLabel(option),
                  color: _getFilterColor(context, option),
                  textColor: _getFilterTextColor(context, option),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }
}

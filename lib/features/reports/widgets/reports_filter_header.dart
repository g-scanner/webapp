// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/theme/theme.dart';

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

  TextStyle _dropdownItemTextStyle(Color color) {
    return TextStyle(color: color, fontWeight: FontWeight.w600);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    final bool showClearIcon = isSearchFocused && searchTerm.isNotEmpty;

    // --- Variabili di Stile Dinamiche per il Filtro ---
    final bool isMineSelected = reportFilter == "Mie";
    final Color filterBgColor = isMineSelected
        ? colorScheme.secondaryContainer.withValues(alpha: 0.15)
        : colorScheme.surfaceContainerHighest;
    final Color filterTextColor = isMineSelected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurface;
    final Color filterIconColor = isMineSelected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Intestazione Pagina ─────────────────────────────────────
        Text(
          "report.listTitle".tr(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: kIsWeb ? FontWeight.w600 : FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "report.subtitle".tr(),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
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
                    "report.lists.activeReports".tr(),
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
              flex: 5,
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                onChanged: onSearchChanged,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: "database.search.hint".tr(),
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                    fontSize: 14,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    maxWidth: 48,
                    minHeight: 48,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                      child: showClearIcon
                          ? IconButton(
                              key: const ValueKey('clearIcon'),
                              icon: Icon(
                                Icons.close,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: onSearchClear,
                            )
                          : Icon(
                              key: const ValueKey('searchIcon'),
                              Icons.search,
                              color: searchTerm.isNotEmpty
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    ),
                            ),
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: 2,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: reportFilter,
                icon: Icon(
                  Icons.filter_list,
                  color: filterIconColor,
                  size: 20,
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: filterTextColor,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: filterBgColor,
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
                    value: "Tutte",
                    child: Text(
                      "report.dropdown.all".tr(),
                      style: _dropdownItemTextStyle(
                        colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "Mie",
                    child: Text(
                      "report.dropdown.mine".tr(),
                      style: _dropdownItemTextStyle(
                        colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) onFilterChanged(val);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

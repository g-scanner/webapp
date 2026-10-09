// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/app_popup_menu_item.dart';

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

  Color _getFilterIconColor(BuildContext context, String filter) {
    final colorScheme = context.colorScheme;
    if (filter == "Mie") {
      return colorScheme.onSecondaryContainer;
    }
    return colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
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

    final bool showClearIcon = isSearchFocused && searchTerm.isNotEmpty;

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
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                onChanged: onSearchChanged,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: "common.actions.search".tr(),
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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

            // ── Filtro a Pillola PopupMenuButton (Stesso Design System) ──
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: PopupMenuButton<String>(
                tooltip: "Filtra segnalazioni",
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
                itemBuilder: (context) {
                  final options = ["Tutte", "Mie"];

                  return options.map((option) {
                    final isSelected = reportFilter == option;
                    final statusBg = _getFilterColor(context, option);
                    final statusText = _getFilterTextColor(context, option);

                    return AppPopupMenuItem<String>(
                      value: option,
                      onTap: () => onFilterChanged(option),
                      customSplashColor: statusText.withValues(alpha: 0.12),
                      customHighlightColor: statusText.withValues(alpha: 0.08),
                      customHoverColor: statusText.withValues(alpha: 0.06),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? statusBg : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getFilterLabel(option),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? statusText
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
                                    ? statusText
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? null
                                    : Border.all(
                                        color: colorScheme.outlineVariant
                                            .withValues(alpha: 0.6),
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
                // Trigger a Pillola (Senza bordi, colore coerente alla selezione)
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 110, maxWidth: 150),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _getFilterColor(context, reportFilter),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _getFilterLabel(reportFilter),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getFilterTextColor(context, reportFilter),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.filter_list_rounded,
                          size: 20,
                          color: _getFilterIconColor(context, reportFilter),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

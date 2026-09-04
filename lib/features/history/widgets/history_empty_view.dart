// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../models/models.dart';

class HistoryEmptyView extends StatelessWidget {
  final String searchQuery;
  final GlutenSafetyStatus? filter;

  const HistoryEmptyView({
    super.key,
    required this.searchQuery,
    this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    final IconData emptyIcon;
    final String emptyTitle;
    final String emptySubtitle;

    final trimmedSearch = searchQuery.trim();
    if (trimmedSearch.isNotEmpty) {
      // 1. La ricerca da textfield prevale sempre
      emptyIcon = Icons.search_off_rounded;
      emptyTitle = "history.search.noResultsTitle".tr();
      emptySubtitle = "history.search.noResults".tr(
        namedArgs: {"query": trimmedSearch},
      );
    } else if (filter != null) {
      // 2. Filtro attivo senza risultati
      emptyIcon = Icons.filter_alt_off_outlined;
      emptyTitle = "history.filters.noResultsTitle".tr();
      emptySubtitle = "history.filters.noResultsForFilter".tr();
    } else {
      // 3. Cronologia vuota di base
      emptyIcon = Icons.history;
      emptyTitle = "history.empty.title".tr();
      emptySubtitle = "history.empty.subtitle".tr();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 48,
        horizontal: 24,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              emptyIcon,
              size: 40,
              color: colorScheme.outlineVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            emptyTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            emptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

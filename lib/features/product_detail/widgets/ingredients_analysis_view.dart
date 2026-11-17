// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/models.dart';
import 'section_card.dart';

class IngredientsAnalysisView extends StatelessWidget {
  final String displayedIngredients;
  final List<IngredientAnalyzed> displayedIngredientsAnalyzed;

  const IngredientsAnalysisView({
    super.key,
    required this.displayedIngredients,
    required this.displayedIngredientsAnalyzed,
  });

  /// Builds a RichText with inline highlights for each analyzed ingredient
  /// found in the raw ingredient string.
  Widget _buildHighlightedIngredients(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final String rawText = displayedIngredients;
    if (rawText.trim().isEmpty) return const SizedBox.shrink();

    // Build a map of lowercase keyword → dangerLevel from the analyzed items.
    // Only include items whose ingredient name actually appears in the raw text
    // (skip synthetic labels like "Certificazione Senza Glutine").
    final String lowerRaw = rawText.toLowerCase();
    final List<_HighlightEntry> entries = [];

    for (final item in displayedIngredientsAnalyzed) {
      final String keyword = item.ingredient.toLowerCase();
      if (keyword.isEmpty) continue;

      // Try to find all occurrences of this keyword in the raw text
      int searchFrom = 0;
      while (true) {
        final int pos = lowerRaw.indexOf(keyword, searchFrom);
        if (pos == -1) break;

        entries.add(
          _HighlightEntry(
            start: pos,
            end: pos + keyword.length,
            dangerLevel: item.dangerLevel,
          ),
        );
        searchFrom = pos + keyword.length;
      }
    }

    // If nothing to highlight, return plain text
    if (entries.isEmpty) {
      return Text(
        rawText,
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface,
          height: 1.5,
        ),
      );
    }

    // Sort by start position, then by longest match first (to prefer longer matches)
    entries.sort((a, b) {
      final cmp = a.start.compareTo(b.start);
      if (cmp != 0) return cmp;
      return b.end.compareTo(a.end); // longer first
    });

    // Remove overlapping entries — keep the first (longest) match at each position
    final List<_HighlightEntry> resolved = [];
    int lastEnd = 0;
    for (final e in entries) {
      if (e.start >= lastEnd) {
        resolved.add(e);
        lastEnd = e.end;
      }
    }

    // Build TextSpans
    final List<InlineSpan> spans = [];
    final TextStyle baseStyle = TextStyle(
      fontSize: 14,
      color: colorScheme.onSurface,
      height: 1.5,
    );
    int cursor = 0;

    for (final entry in resolved) {
      // Plain text before this highlight
      if (cursor < entry.start) {
        spans.add(TextSpan(text: rawText.substring(cursor, entry.start)));
      }

      // Determine highlight color from the pill variant system
      final AppStatusPillVariant variant = _variantForDangerLevel(
        entry.dangerLevel,
      );
      final colors = AppStatusPill.colorsForVariant(variant, colorScheme);

      // Highlighted span with pill-colored background
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              rawText.substring(entry.start, entry.end),
              style: baseStyle.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );

      cursor = entry.end;
    }

    // Trailing plain text
    if (cursor < rawText.length) {
      spans.add(TextSpan(text: rawText.substring(cursor)));
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  static AppStatusPillVariant _variantForDangerLevel(String dangerLevel) {
    switch (dangerLevel) {
      case "danger":
        return AppStatusPillVariant.error;
      case "warning":
        return AppStatusPillVariant.tertiary;
      case "lactose":
        return AppStatusPillVariant.secondary;
      case "safe":
      default:
        return AppStatusPillVariant.primary;
    }
  }

  List<IngredientAnalyzed> _getSortedIngredientsAnalyzed() {
    if (displayedIngredients.trim().isEmpty ||
        displayedIngredientsAnalyzed.isEmpty) {
      return displayedIngredientsAnalyzed;
    }

    final String lowerText = displayedIngredients.toLowerCase();
    final indexedItems = displayedIngredientsAnalyzed.asMap().entries.toList();

    indexedItems.sort((entryA, entryB) {
      final a = entryA.value;
      final b = entryB.value;
      final posA = a.ingredient.isNotEmpty
          ? lowerText.indexOf(a.ingredient.toLowerCase())
          : -1;
      final posB = b.ingredient.isNotEmpty
          ? lowerText.indexOf(b.ingredient.toLowerCase())
          : -1;

      if (posA != -1 && posB != -1) {
        final cmp = posA.compareTo(posB);
        if (cmp != 0) return cmp;
        return entryA.key.compareTo(entryB.key);
      }
      if (posA != -1) return -1;
      if (posB != -1) return 1;
      return entryA.key.compareTo(entryB.key);
    });

    return indexedItems.map((e) => e.value).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final sortedIngredientsAnalyzed = _getSortedIngredientsAnalyzed();

    return SectionCard(
      title: "product.ingredients.title".tr(),
      icon: Icons.science,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (displayedIngredients.trim().isEmpty &&
              displayedIngredientsAnalyzed.isEmpty)
            Text(
              "product.analysis.missingDataReason".tr(),
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          if (displayedIngredients.trim().isNotEmpty)
            _buildHighlightedIngredients(context, colorScheme),
          if (sortedIngredientsAnalyzed.isNotEmpty) ...[
            // Single divider between raw text and analyzed items block
            if (displayedIngredients.trim().isNotEmpty)
              Divider(
                height: 24,
                thickness: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ...sortedIngredientsAnalyzed.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              AppStatusPillVariant pillVariant;
              String pillLabel;

              switch (item.dangerLevel) {
                case "danger":
                  pillVariant = AppStatusPillVariant.error;
                  pillLabel = "product.ingredients.dangerBadge".tr();
                  break;
                case "warning":
                  pillVariant = AppStatusPillVariant.tertiary;
                  pillLabel = "product.ingredients.warningBadge".tr();
                  break;
                case "lactose":
                  pillVariant = AppStatusPillVariant.secondary;
                  pillLabel = "product.ingredients.lactoseBadge".tr();
                  break;
                case "safe":
                default:
                  pillVariant = AppStatusPillVariant.primary;
                  pillLabel = "product.ingredients.safeBadge".tr();
                  break;
              }

              return Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.ingredient,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        AppStatusPill.preset(
                          variant: pillVariant,
                          label: pillLabel,
                        ),
                      ],
                    ),
                    if (item.reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.reason,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// Internal helper to track a highlight region in the ingredient string.
class _HighlightEntry {
  final int start;
  final int end;
  final String dangerLevel;

  const _HighlightEntry({
    required this.start,
    required this.end,
    required this.dangerLevel,
  });
}

class LactoseAlertSection extends StatelessWidget {
  const LactoseAlertSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return SectionCard(
      title: "product.lactoseAlert.title".tr(),
      icon: Icons.water_drop,
      isLactose: true,
      bgColor: colorScheme.lactoseBg,
      child: Text(
        "product.lactoseAlert.body".tr(),
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }
}

class ProductWarningCard extends StatelessWidget {
  const ProductWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return SectionCard(
      title: "product.disclaimer.title".tr(),
      icon: Icons.info_outline,
      isCaution: true,
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: colorScheme.onSurfaceVariant,
          ),
          children: <TextSpan>[
            TextSpan(text: "product.disclaimer.infoPre".tr()),
            TextSpan(
              text: "product.disclaimer.infoSource".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: "product.disclaimer.infoPost".tr()),
          ],
        ),
      ),
    );
  }
}

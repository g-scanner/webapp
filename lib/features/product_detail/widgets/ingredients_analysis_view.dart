// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../models/models.dart';
import 'section_card.dart';

class IngredientsAnalysisView extends StatelessWidget {
  final String displayedIngredients;
  final List<IngredientAnalyzed> displayedIngredientsAnalyzed;
  final bool hasIngredientData;

  const IngredientsAnalysisView({
    super.key,
    required this.displayedIngredients,
    required this.displayedIngredientsAnalyzed,
    required this.hasIngredientData,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return SectionCard(
      title: "product.titles.ingredientsAnalysis".tr(),
      icon: Icons.science,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (displayedIngredients.trim().isNotEmpty) ...[
            Text(
              displayedIngredients,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
                height: 1.5,
              ),
            ),
            if (displayedIngredientsAnalyzed.isNotEmpty)
              const SizedBox(height: 16),
          ],
          if (displayedIngredientsAnalyzed.isNotEmpty) ...[
            ...displayedIngredientsAnalyzed.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final bool showTopDivider =
                  displayedIngredients.trim().isNotEmpty || index > 0;

              Color pillBg;
              Color pillText;
              String pillLabel;

              switch (item.dangerLevel) {
                case "danger":
                  pillBg = colorScheme.errorContainer.withValues(
                    alpha: 0.2,
                  );
                  pillText = colorScheme.error;
                  pillLabel = "product.ingredients.dangerBadge".tr();
                  break;
                case "warning":
                  pillBg = colorScheme.tertiaryContainer.withValues(
                    alpha: 0.2,
                  );
                  pillText = colorScheme.tertiary;
                  pillLabel = "product.ingredients.warningBadge".tr();
                  break;
                case "uncertain":
                  pillBg = colorScheme.tertiaryContainer.withValues(
                    alpha: 0.15,
                  );
                  pillText = colorScheme.tertiary;
                  pillLabel = "product.ingredients.uncertainBadge".tr();
                  break;
                case "safe":
                default:
                  pillBg = colorScheme.primaryContainer.withValues(
                    alpha: 0.2,
                  );
                  pillText = colorScheme.primary;
                  pillLabel = "product.ingredients.safeBadge".tr();
                  break;
              }

              return Container(
                margin: EdgeInsets.only(top: showTopDivider ? 12 : 0),
                padding: EdgeInsets.only(top: showTopDivider ? 12 : 0),
                decoration: BoxDecoration(
                  border: showTopDivider
                      ? Border(
                          top: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        )
                      : null,
                ),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: pillBg,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            pillLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: pillText,
                            ),
                          ),
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
          ] else if (displayedIngredients.trim().isEmpty) ...[
            Text(
              // hasIngredientData=false → ghost product: dati non disponibili
              // hasIngredientData=true ma ingredienti vuoti → prodotto pulito, nessun rischio
              !hasIngredientData
                  ? "product.ingredients.insufficientDataLabel".tr()
                  : "product.ingredients.noRisksDetected".tr(),
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LactoseAlertSection extends StatelessWidget {
  const LactoseAlertSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return SectionCard(
      title: "product.titles.lactosePresence".tr(),
      icon: Icons.water_drop,
      isLactose: true,
      bgColor: colorScheme.secondaryContainer.withValues(alpha: 0.15),
      child: Text(
        "product.warnings.lactoseAlertBody".tr(),
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
      title: "product.warnings.infoTitle".tr(),
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
            TextSpan(text: "product.warnings.infoPre".tr()),
            TextSpan(
              text: "product.warnings.infoSource".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: "product.warnings.infoPost".tr()),
          ],
        ),
      ),
    );
  }
}

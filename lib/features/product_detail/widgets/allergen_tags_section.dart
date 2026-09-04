// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import 'section_card.dart';

class AllergenTagsSection extends StatelessWidget {
  final bool hasAllergenData;
  final List<String> displayedAllergens;

  const AllergenTagsSection({
    super.key,
    required this.hasAllergenData,
    required this.displayedAllergens,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return SectionCard(
      title: "product.titles.declaredAllergens".tr(),
      icon: Icons.coronavirus,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: !hasAllergenData
            // Stato 1: Nessun dato — informazioni non disponibili (stessa pillola neutrale degli allergeni)
            ? [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    "product.ingredients.insufficientDataLabel".tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ]
            : displayedAllergens.isNotEmpty
            // Stato 3: Allergeni dichiarati → mostra chips
            ? displayedAllergens.map((alg) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    alg,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList()
            // Stato 2: Dati presenti ma lista vuota → nessuno dichiarato (sicuro)
            : [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    "product.ingredients.noneLabel".tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
      ),
    );
  }
}

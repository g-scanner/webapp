// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner -- See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import 'section_card.dart';

/// Card di allerta visiva mostrata quando un prodotto proviene da cache locale
/// non aggiornata (>30 giorni) o incompleta, a causa dell'assenza di connessione
/// o di mancata risposta da parte dei server di Open Food Facts.
class StaleDataWarningCard extends StatelessWidget {
  const StaleDataWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return SectionCard(
      title: 'product.warnings.staleDataTitle'.tr(),
      icon: Icons.history_toggle_off_rounded,
      isCaution: true,
      bgColor: colorScheme.errorContainer.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'product.warnings.staleDataBody'.tr(),
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'product.warnings.staleDataCaution'.tr(),
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
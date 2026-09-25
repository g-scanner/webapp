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
      title: 'product.staleData.title'.tr(),
      icon: Icons.safety_check_outlined,
      isCaution: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'product.staleData.body'.tr(),
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'product.staleData.caution'.tr(),
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

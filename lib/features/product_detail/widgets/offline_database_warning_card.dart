// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import 'section_card.dart';

/// Card di avviso mostrata quando un prodotto proviene dal database offline salvato sul dispositivo.
/// Notifica l'utente sulla staticità del dato (o sull'obsolescenza del DB offline se stale)
/// e adempie alla clausola legale di attribuzione ODbL 1.0.
class OfflineDatabaseWarningCard extends StatelessWidget {
  final bool isDbStale;

  const OfflineDatabaseWarningCard({
    super.key,
    this.isDbStale = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    final title = isDbStale
        ? 'product.offlineWarnings.databaseStaleWarningTitle'.tr()
        : 'product.offlineWarnings.databaseWarningTitle'.tr();

    final body = isDbStale
        ? 'product.offlineWarnings.databaseStaleWarningBody'.tr()
        : 'product.offlineWarnings.databaseWarningBody'.tr();

    return SectionCard(
      title: title,
      icon: isDbStale ? Icons.update_disabled_outlined : Icons.cloud_off_outlined,
      isCaution: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'product.offlineWarnings.databaseWarningCaution'.tr(),
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

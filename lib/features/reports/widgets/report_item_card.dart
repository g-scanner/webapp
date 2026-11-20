// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/models.dart';

class ReportItemCard extends StatelessWidget {
  final Product prod;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ReportItemCard({
    super.key,
    required this.prod,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return AppCard.primary(
      borderRadius: 20,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PARTE SUPERIORE: Dettagli in nuovo formato
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NOME PRODOTTO
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    prod.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            prod.brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatRelativeDate(prod.lastUpdated),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 18,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          prod.barcode,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.8,
                            ),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bordo separatore solido
          Container(height: 1.5, color: colorScheme.cardPrimaryBorder),

          // PARTE INFERIORE: Call To Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: colorScheme.statusTertiaryBg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "report.list.item.examineDetails".tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.statusTertiaryText,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(6, 0),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colorScheme.statusTertiaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReportItemSkeleton extends StatelessWidget {
  const ReportItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return AppCard.primary(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 180,
              height: 18,
              color: colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Container(
              width: 100,
              height: 14,
              color: colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Container(
              width: 140,
              height: 12,
              color: colorScheme.surfaceContainerHighest,
            ),
          ],
        ),
      ),
    );
  }
}

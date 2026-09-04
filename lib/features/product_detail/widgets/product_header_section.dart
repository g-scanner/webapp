// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../models/models.dart';

class ProductHeaderSection extends StatelessWidget {
  final String productName;
  final String productBrand;
  final String barcode;
  final bool showScanDate;
  final String? scannedAt;
  final String? lastUpdated;
  final Color accentColor;

  const ProductHeaderSection({
    super.key,
    required this.productName,
    required this.productBrand,
    required this.barcode,
    this.showScanDate = true,
    this.scannedAt,
    this.lastUpdated,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Column(
      children: [
        Text(
          productName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          productBrand.isEmpty
              ? "product.status.unknownBrand".tr()
              : productBrand,
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Pillola Barcode
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code, size: 16, color: accentColor),
              const SizedBox(width: 8),
              SelectableText(
                barcode,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),

        // Data Scansione
        if (showScanDate) ...[
          const SizedBox(height: 4),
          Text(
            formatScanDate(scannedAt ?? lastUpdated ?? ''),
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withValues(
                alpha: 0.8,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

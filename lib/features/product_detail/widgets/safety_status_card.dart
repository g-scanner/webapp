// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../models/models.dart';
import 'product_header_section.dart';

class SafetyStatusCard extends StatelessWidget {
  final GlutenSafetyStatus effectiveStatus;
  final String productName;
  final String productBrand;
  final String barcode;
  final bool showScanDate;
  final String? scannedAt;
  final String? lastUpdated;

  const SafetyStatusCard({
    super.key,
    required this.effectiveStatus,
    required this.productName,
    required this.productBrand,
    required this.barcode,
    this.showScanDate = true,
    this.scannedAt,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    Color heroBgColor;
    Color heroTextColor;
    String statusBigText;
    IconData statusIcon;

    switch (effectiveStatus) {
      case GlutenSafetyStatus.adatto:
        heroBgColor = colorScheme.primaryContainer.withValues(alpha: 0.15);
        heroTextColor = colorScheme.primary;
        statusBigText = "product.bigStatus.safe".tr();
        statusIcon = Icons.check_circle;
        break;
      case GlutenSafetyStatus.nonAdatto:
        heroBgColor = colorScheme.errorContainer.withValues(alpha: 0.15);
        heroTextColor = colorScheme.error;
        statusBigText = "product.bigStatus.unsafe".tr();
        statusIcon = Icons.cancel;
        break;
      case GlutenSafetyStatus.incerto:
        heroBgColor = colorScheme.tertiaryContainer.withValues(alpha: 0.15);
        heroTextColor = colorScheme.tertiary;
        statusBigText = "product.bigStatus.uncertain".tr();
        statusIcon = Icons.warning;
        break;
      case GlutenSafetyStatus.sconosciuto:
        heroBgColor = colorScheme.surfaceContainerHighest;
        heroTextColor = colorScheme.onSurfaceVariant;
        statusBigText = "product.bigStatus.unknown".tr();
        statusIcon = Icons.help;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: heroBgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: heroTextColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: heroTextColor, size: 48),
          ),
          const SizedBox(height: 12),
          Text(
            statusBigText,
            style: TextStyle(
              fontSize: 45,
              fontWeight: FontWeight.w400,
              color: heroTextColor,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          ProductHeaderSection(
            productName: productName,
            productBrand: productBrand,
            barcode: barcode,
            showScanDate: showScanDate,
            scannedAt: scannedAt,
            lastUpdated: lastUpdated,
            accentColor: heroTextColor,
          ),
        ],
      ),
    );
  }
}

class GlutenEvaluationCard extends StatelessWidget {
  final String displayedReason;
  final bool hasActiveReport;
  final VoidCallback? onViewReport;

  const GlutenEvaluationCard({
    super.key,
    required this.displayedReason,
    this.hasActiveReport = false,
    this.onViewReport,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    final Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Row(
            children: [
              Icon(
                Icons.leaderboard,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "product.titles.glutenEvaluation".tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: hasActiveReport ? 20 : 24,
          ),
          child: Text(
            displayedReason,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        if (hasActiveReport) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: colorScheme.tertiary.withValues(alpha: 0.04),
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(
                    alpha: 0.2,
                  ),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "product.report.goToReport".tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.tertiary,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(6, 0),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasActiveReport && onViewReport != null
          ? InkWell(
              onTap: onViewReport,
              child: cardContent,
            )
          : cardContent,
    );
  }
}

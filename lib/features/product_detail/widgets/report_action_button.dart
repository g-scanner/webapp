// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';

class ReportActionButton extends StatelessWidget {
  static const double _kSlotHeight = 50.0;

  final bool hasUserReported;
  final int pendingReportsCount;
  final VoidCallback onReportPressed;

  const ReportActionButton({
    super.key,
    required this.hasUserReported,
    required this.pendingReportsCount,
    required this.onReportPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    if (hasUserReported || pendingReportsCount > 0) {
      final mutedColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.75);

      return SizedBox(
        height: _kSlotHeight,
        width: double.infinity,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flag_rounded,
                color: mutedColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  "product.actions.alreadyReported".tr(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mutedColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: _kSlotHeight,
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: onReportPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        icon: const Icon(Icons.flag_outlined, size: 20),
        label: Text(
          "product.actions.reportError".tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

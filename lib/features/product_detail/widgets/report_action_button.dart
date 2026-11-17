// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';

class ReportActionButton extends StatelessWidget {
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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.statusErrorBg,
          borderRadius: BorderRadius.circular(32),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: colorScheme.statusErrorText,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                "product.actions.alreadyReported".tr(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.statusErrorText,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
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

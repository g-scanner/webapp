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
          color: colorScheme.errorContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(32),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                "product.actions.alreadyReported".tr(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onReportPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.error,
        side: BorderSide(color: colorScheme.error, width: 1.5),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),
      icon: const Icon(Icons.flag_outlined, size: 20),
      label: Text(
        "product.actions.reportError".tr(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

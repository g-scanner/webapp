// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

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
      final mutedColor = colorScheme.textTertiary;

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
      child: AppTertiaryButton(
        onPressed: onReportPressed,
        icon: Icons.flag_outlined,
        label: "product.actions.reportError".tr(),
        fullWidth: true,
      ),
    );
  }
}

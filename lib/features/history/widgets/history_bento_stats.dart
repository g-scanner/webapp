// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/theme/theme.dart';

class HistoryBentoStats extends StatelessWidget {
  final int safeCount;
  final int uncertainCount;
  final int dangerCount;
  final int unknownCount;
  final bool showSkeleton;

  const HistoryBentoStats({
    super.key,
    required this.safeCount,
    required this.uncertainCount,
    required this.dangerCount,
    required this.unknownCount,
    this.showSkeleton = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    final safeColors = colorScheme.statusSafeColors;
    final uncertainColors = colorScheme.statusUncertainColors;
    final dangerColors = colorScheme.statusUnsafeColors;
    final unknownColors = colorScheme.statusUnknownColors;

    return Skeletonizer(
      enabled: showSkeleton,
      child: Row(
        children: [
          _buildStatBox(
            count: safeCount.toString(),
            label: "history.filters.safe".tr(),
            bgColor: safeColors.alpha, textColor: safeColors.solid,
            icon: Icons.check_circle,
          ),
          const SizedBox(width: 10),
          _buildStatBox(
            count: uncertainCount.toString(),
            label: "history.filters.uncertain".tr(),
            bgColor: uncertainColors.alpha, textColor: uncertainColors.solid,
            icon: Icons.warning,
          ),
          const SizedBox(width: 10),
          _buildStatBox(
            count: dangerCount.toString(),
            label: "history.filters.unsafe".tr(),
            bgColor: dangerColors.alpha, textColor: dangerColors.solid,
            icon: Icons.cancel,
          ),
          const SizedBox(width: 10),
          _buildStatBox(
            count: unknownCount.toString(),
            label: "history.filters.unknown".tr(),
            bgColor: unknownColors.alpha, textColor: unknownColors.solid,
            icon: Icons.help,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String count,
    required String label,
    required Color bgColor,
    required Color textColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


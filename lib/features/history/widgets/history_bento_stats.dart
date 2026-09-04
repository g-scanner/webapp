// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/theme/theme.dart';

class HistoryBentoStats extends StatelessWidget {
  final int safeCount;
  final int uncertainCount;
  final int dangerCount;
  final bool showSkeleton;

  const HistoryBentoStats({
    super.key,
    required this.safeCount,
    required this.uncertainCount,
    required this.dangerCount,
    this.showSkeleton = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Skeletonizer(
      enabled: showSkeleton,
      child: Row(
        children: [
          _buildStatBox(
            count: safeCount.toString(),
            label: "history.filters.safe".tr(),
            color: colorScheme.primary,
            icon: Icons.check_circle,
          ),
          const SizedBox(width: 12),
          _buildStatBox(
            count: uncertainCount.toString(),
            label: "history.filters.uncertain".tr(),
            color: colorScheme.tertiary,
            icon: Icons.warning_rounded,
          ),
          const SizedBox(width: 12),
          _buildStatBox(
            count: dangerCount.toString(),
            label: "history.filters.unsafe".tr(),
            color: colorScheme.error,
            icon: Icons.cancel,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gscanner/core/theme/app_theme.dart';

/// Barra di navigazione inferiore personalizzata per dispositivi mobili.
class MainCustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const MainCustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.2 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildNavItem(
                context,
                0,
                Icons.qr_code_scanner,
                Icons.qr_code_scanner,
                "common.navigation.scanner".tr(),
              ),
              _buildNavItem(
                context,
                1,
                Icons.history,
                Icons.history,
                "common.navigation.history".tr(),
              ),
              _buildNavItem(
                context,
                2,
                Icons.report_problem,
                Icons.report_problem_outlined,
                "common.navigation.reports".tr(),
              ),
              _buildNavItem(
                context,
                3,
                Icons.settings,
                Icons.settings_outlined,
                "common.navigation.settings".tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final bool isSelected = currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.secondaryContainer.withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

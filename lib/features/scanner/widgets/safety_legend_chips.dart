// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';

class SafetyLegendChips extends StatelessWidget {
  const SafetyLegendChips({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Text(
            "scanner.ui.safetyIndicators".tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: _buildIndicatorItem(
                  context: context,
                  icon: Icons.check_circle_rounded,
                  title: "scanner.states.safe".tr(),
                  subtitle: "scanner.states.glutenFree".tr(),
                  color: colorScheme.primaryContainer,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: _buildIndicatorItem(
                  context: context,
                  icon: Icons.warning_rounded,
                  title: "scanner.states.uncertain".tr(),
                  subtitle: "scanner.states.checkLabel".tr(),
                  color: colorScheme.tertiaryContainer,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: _buildIndicatorItem(
                  context: context,
                  icon: Icons.cancel_rounded,
                  title: "scanner.states.unsafe".tr(),
                  subtitle: "scanner.states.hasGluten".tr(),
                  color: colorScheme.error,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: _buildIndicatorItem(
                  context: context,
                  icon: Icons.help_rounded,
                  title: "scanner.states.unknown".tr(),
                  subtitle: "scanner.states.notFound".tr(),
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: cardBg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

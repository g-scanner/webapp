// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final Color? bgColor;
  final bool isCaution;
  final bool isLactose;

  const SectionCard({
    super.key,
    required this.title,
    this.icon,
    required this.child,
    this.bgColor,
    this.isCaution = false,
    this.isLactose = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
            bgColor ??
            (isCaution ? colorScheme.surfaceContainerHighest : cardBg),
        borderRadius: BorderRadius.circular(24),
        border: isCaution || isLactose
            ? null
            : Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
        boxShadow: [
          if (isCaution == false && (bgColor == null || bgColor == cardBg))
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isCaution
                      ? colorScheme.onSurface
                      : isLactose
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: isCaution
                        ? colorScheme.onSurface
                        : isLactose
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

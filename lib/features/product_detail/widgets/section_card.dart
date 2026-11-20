// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

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

    final cardContent = Column(
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
                    ? colorScheme.lactoseText
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
                      ? colorScheme.lactoseText
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );

    if (isCaution) {
      return AppCard.secondary(
        padding: const EdgeInsets.all(24),
        borderRadius: 24,
        bgColor: bgColor,
        child: cardContent,
      );
    }

    return AppCard.primary(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      hasBorder: !isLactose,
      bgColor: bgColor,
      child: cardContent,
    );
  }
}

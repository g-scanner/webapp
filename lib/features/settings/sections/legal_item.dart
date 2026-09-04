// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Singolo elemento testuale/cliccabile nella sezione legale
/// (stile gemello a _buildToggleItem).
Widget buildLegalItem({
  required String title,
  required Widget subtitle,
  VoidCallback? onTap,
  bool isFirst = false,
  bool showTrailingArrow = true,
  bool isLast = false,
}) {
  final bool hasTrailingArrow = onTap != null && showTrailingArrow;

  return Builder(
    builder: (context) {
      final colorScheme = context.colorScheme;
      return InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: isFirst ? 24.0 : 16.0,
            bottom: isLast ? 24.0 : 16.0,
          ),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
          ),
          child: hasTrailingArrow
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          subtitle,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Transform.translate(
                      offset: const Offset(8, 0),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        size: 26,
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      subtitle,
                    ],
                  ),
                ),
        ),
      );
    },
  );
}

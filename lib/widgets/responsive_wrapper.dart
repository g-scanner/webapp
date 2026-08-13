// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';

class ResponsiveMaxCardWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double maxHeight;
  final Color? backgroundColor;

  const ResponsiveMaxCardWidth({
    super.key,
    required this.child,
    this.maxWidth = 500,
    this.maxHeight = 900,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    if (width > 600) {
      final bool isLowHeight = height <= 500;

      if (isLowHeight) {
        final double constrainedWidth = maxWidth > 450 ? 450 : maxWidth;
        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          alignment: Alignment.center,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: constrainedWidth,
              maxHeight: maxHeight,
            ),
            child: child,
          ),
        );
      }

      return Container(
        color: const Color(0xFFFAF9FC),
        alignment: Alignment.center,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              color: backgroundColor ?? Theme.of(context).colorScheme.surface,
              child: child,
            ),
          ),
        ),
      );
    }

    return child;
  }
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Elemento di navigazione riutilizzabile all'interno dei container M3 delle impostazioni.
class SettingsNavigationItem extends StatelessWidget {
  final String title;
  final Widget subtitle;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;
  final bool showTrailingArrow;

  const SettingsNavigationItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isFirst = false,
    this.isLast = false,
    this.showTrailingArrow = true,
  });

  /// Costruttore di utilità per passare direttamente una stringa come sottotitolo.
  SettingsNavigationItem.textSubtitle({
    super.key,
    required this.title,
    required String subtitleText,
    this.onTap,
    this.isFirst = false,
    this.isLast = false,
    this.showTrailingArrow = true,
    TextStyle? subtitleStyle,
  }) : subtitle = Builder(
         builder: (context) => Text(
           subtitleText,
           style: subtitleStyle ??
               TextStyle(
                 fontSize: 13,
                 color: Theme.of(context).colorScheme.onSurfaceVariant,
                 height: 1.3,
               ),
         ),
       );

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final bool hasTrailingArrow = onTap != null && showTrailingArrow;

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
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
      ),
    );
  }
}

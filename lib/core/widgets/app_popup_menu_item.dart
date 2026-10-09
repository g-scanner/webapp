// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';

/// Menu item personalizzato per PopupMenuButton progettato per il design system di G-Scanner:
/// - Rispetta fedelmente il bordo arrotondato dell'elemento (default 12dp) durante hover, click e pressione prolungata.
/// - Elimina completamente i rettangoli neri squadrati nativi di PopupMenuItem che sbordavano fuori dagli angoli.
/// - Confinamento del margine esterno (default 8dp orizzontale, 2dp verticale) in modo che l'effetto Ink
///   non tocchi mai i bordi della card del popup né gli elementi adiacenti.
class AppPopupMenuItem<T> extends PopupMenuItem<T> {
  final BorderRadius? itemBorderRadius;
  final EdgeInsetsGeometry itemMargin;
  final Color? customSplashColor;
  final Color? customHighlightColor;
  final Color? customHoverColor;

  const AppPopupMenuItem({
    super.key,
    super.value,
    super.onTap,
    super.enabled = true,
    super.height = 48.0,
    super.padding = EdgeInsets.zero,
    super.textStyle,
    super.labelTextStyle,
    super.mouseCursor,
    this.itemBorderRadius,
    this.itemMargin = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    this.customSplashColor,
    this.customHighlightColor,
    this.customHoverColor,
    required super.child,
  });

  @override
  AppPopupMenuItemState<T, AppPopupMenuItem<T>> createState() =>
      AppPopupMenuItemState<T, AppPopupMenuItem<T>>();
}

class AppPopupMenuItemState<T, W extends AppPopupMenuItem<T>>
    extends PopupMenuItemState<T, W> {
  @override
  Widget build(BuildContext context) {
    final effectiveRadius =
        widget.itemBorderRadius ?? BorderRadius.circular(999);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final splash = widget.customSplashColor ??
        colorScheme.primary.withValues(alpha: 0.12);
    final highlight = widget.customHighlightColor ??
        colorScheme.primary.withValues(alpha: 0.08);
    final hover = widget.customHoverColor ??
        colorScheme.primary.withValues(alpha: 0.06);

    return MergeSemantics(
      child: buildSemantics(
        child: Padding(
          padding: widget.itemMargin,
          child: Material(
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            borderRadius: effectiveRadius,
            child: InkWell(
              borderRadius: effectiveRadius,
              splashColor: splash,
              highlightColor: highlight,
              hoverColor: hover,
              onTap: widget.enabled ? handleTap : null,
              canRequestFocus: widget.enabled,
              mouseCursor: widget.mouseCursor ?? SystemMouseCursors.click,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

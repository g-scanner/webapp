// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Spazio dei nomi unificato per tutte le Card del design system di GlutiEnd.
abstract final class AppCard {
  /// Card Principale: usata per contenuti standard, elementi di liste cliccabili
  /// (cronologia, segnalazioni) e sezioni informative card-based.
  static Widget primary({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onHover,
    Color? hoverColor,
    Color? highlightColor,
    Color? bgColor,
    Color? borderColor,
    bool hasBorder = true,
    double borderWidth = 1.5,
    double borderRadius = 24.0,
    bool hasShadow = true,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    return AppPrimaryCard(
      key: key,
      padding: padding,
      margin: margin,
      onTap: onTap,
      onLongPress: onLongPress,
      onHover: onHover,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      bgColor: bgColor,
      borderColor: borderColor,
      hasBorder: hasBorder,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      hasShadow: hasShadow,
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  /// Card Secondaria: usata per sezioni descrittive o contenitori tonali
  /// neutri/grigi (senza bordo marcato di default).
  static Widget secondary({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Color? bgColor,
    Color? borderColor,
    bool hasBorder = false,
    double borderWidth = 1.5,
    double borderRadius = 24.0,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    return AppSecondaryCard(
      key: key,
      padding: padding,
      margin: margin,
      onTap: onTap,
      onLongPress: onLongPress,
      bgColor: bgColor,
      borderColor: borderColor,
      hasBorder: hasBorder,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  /// Card ad Alta Evidenziazione (High Emphasis): usata per hero banner di stato
  /// (SafetyStatusCard), avvisi critici o sezioni con enfasi visiva marcata.
  static Widget highEmphasis({
    Key? key,
    required Widget child,
    Color? bgColor,
    Color? borderColor,
    bool hasBorder = false,
    double borderWidth = 1.5,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double borderRadius = 24.0,
    bool hasShadow = false,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    return AppHighEmphasisCard(
      key: key,
      bgColor: bgColor,
      borderColor: borderColor,
      hasBorder: hasBorder,
      borderWidth: borderWidth,
      padding: padding,
      margin: margin,
      onTap: onTap,
      borderRadius: borderRadius,
      hasShadow: hasShadow,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

// -----------------------------------------------------------------------------
// Implementazioni delle tre tipologie di Card
// -----------------------------------------------------------------------------

/// Card Principale
class AppPrimaryCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onHover;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? bgColor;
  final Color? borderColor;
  final bool hasBorder;
  final double borderWidth;
  final double borderRadius;
  final bool hasShadow;
  final Clip clipBehavior;

  const AppPrimaryCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.onHover,
    this.hoverColor,
    this.highlightColor,
    this.bgColor,
    this.borderColor,
    this.hasBorder = true,
    this.borderWidth = 1.5,
    this.borderRadius = 24.0,
    this.hasShadow = true,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final radius = BorderRadius.circular(borderRadius);
    final resolvedBg = bgColor ?? colorScheme.cardPrimaryBg;
    final resolvedBorderColor = borderColor ?? colorScheme.cardPrimaryBorder;

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (onTap != null || onLongPress != null || onHover != null) {
      content = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onHover: onHover,
        hoverColor: hoverColor ?? colorScheme.cardPrimaryHover,
        highlightColor: highlightColor ?? colorScheme.cardPrimaryHighlight,
        borderRadius: radius,
        child: content,
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: radius,
        border: hasBorder
            ? Border.all(color: resolvedBorderColor, width: borderWidth)
            : null,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: colorScheme.cardPrimaryShadow,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      clipBehavior: clipBehavior,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: content,
      ),
    );
  }
}

/// Card Secondaria (sfondo uniforme grigio pieno tonale)
class AppSecondaryCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? bgColor;
  final Color? borderColor;
  final bool hasBorder;
  final double borderWidth;
  final double borderRadius;
  final Clip clipBehavior;

  const AppSecondaryCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.bgColor,
    this.borderColor,
    this.hasBorder = false,
    this.borderWidth = 1.5,
    this.borderRadius = 24.0,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final radius = BorderRadius.circular(borderRadius);
    final resolvedBg = bgColor ?? colorScheme.cardSecondaryBg;

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (onTap != null || onLongPress != null) {
      content = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        child: content,
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: radius,
        border: hasBorder
            ? Border.all(
                color: borderColor ?? colorScheme.cardSecondaryBorder,
                width: borderWidth,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: colorScheme.cardSecondaryShadow,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: clipBehavior,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: content,
      ),
    );
  }
}

/// Card ad Alta Evidenziazione (High Emphasis)
class AppHighEmphasisCard extends StatelessWidget {
  final Widget child;
  final Color? bgColor;
  final Color? borderColor;
  final bool hasBorder;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool hasShadow;
  final Clip clipBehavior;

  const AppHighEmphasisCard({
    super.key,
    required this.child,
    this.bgColor,
    this.borderColor,
    this.hasBorder = false,
    this.borderWidth = 1.5,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = 24.0,
    this.hasShadow = false,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final radius = BorderRadius.circular(borderRadius);
    final resolvedBg = bgColor ?? colorScheme.cardHighEmphasisBg;

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: radius,
        border: hasBorder
            ? Border.all(
                color: borderColor ?? colorScheme.cardHighEmphasisBorder,
                width: borderWidth,
              )
            : null,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: colorScheme.cardHighEmphasisShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      clipBehavior: clipBehavior,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: content,
      ),
    );
  }
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Spazio dei nomi unificato per tutti i pulsanti del design system di GlutiEnd.
abstract final class AppButton {
  /// Pulsante Primario (pieno verde): azione principale della schermata o del flusso.
  static Widget primary({
    Key? key,
    required VoidCallback? onPressed,
    String? label,
    Widget? child,
    IconData? icon,
    Widget? iconWidget,
    bool fullWidth = false,
    bool isLoading = false,
    EdgeInsetsGeometry? padding,
    double? fontSize,
    FontWeight? fontWeight,
    BorderRadius? borderRadius,
  }) {
    return AppPrimaryButton(
      key: key,
      onPressed: onPressed,
      label: label,
      icon: icon,
      iconWidget: iconWidget,
      fullWidth: fullWidth,
      isLoading: isLoading,
      padding: padding,
      fontSize: fontSize,
      fontWeight: fontWeight,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Pulsante Secondario (pieno grigio tonale): azione secondaria importante ma non primaria.
  static Widget secondary({
    Key? key,
    required VoidCallback? onPressed,
    String? label,
    Widget? child,
    IconData? icon,
    Widget? iconWidget,
    bool fullWidth = false,
    bool isLoading = false,
    EdgeInsetsGeometry? padding,
    double? fontSize,
    FontWeight? fontWeight,
    BorderRadius? borderRadius,
  }) {
    return AppSecondaryButton(
      key: key,
      onPressed: onPressed,
      label: label,
      icon: icon,
      iconWidget: iconWidget,
      fullWidth: fullWidth,
      isLoading: isLoading,
      padding: padding,
      fontSize: fontSize,
      fontWeight: fontWeight,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Pulsante Terziario (outlined): azione neutrale/alternativa o pulsanti "Annulla".
  static Widget tertiary({
    Key? key,
    required VoidCallback? onPressed,
    String? label,
    Widget? child,
    IconData? icon,
    Widget? iconWidget,
    bool fullWidth = false,
    bool isLoading = false,
    EdgeInsetsGeometry? padding,
    double? fontSize,
    FontWeight? fontWeight,
    BorderRadius? borderRadius,
  }) {
    return AppTertiaryButton(
      key: key,
      onPressed: onPressed,
      label: label,
      icon: icon,
      iconWidget: iconWidget,
      fullWidth: fullWidth,
      isLoading: isLoading,
      padding: padding,
      fontSize: fontSize,
      fontWeight: fontWeight,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Pulsante Primario Distruttivo (rosso pieno): azioni irreversibili di eliminazione.
  static Widget primaryDestructive({
    Key? key,
    required VoidCallback? onPressed,
    String? label,
    Widget? child,
    IconData? icon,
    Widget? iconWidget,
    bool fullWidth = false,
    bool isLoading = false,
    EdgeInsetsGeometry? padding,
    double? fontSize,
    FontWeight? fontWeight,
    BorderRadius? borderRadius,
  }) {
    return AppPrimaryDestructiveButton(
      key: key,
      onPressed: onPressed,
      label: label,
      icon: icon,
      iconWidget: iconWidget,
      fullWidth: fullWidth,
      isLoading: isLoading,
      padding: padding,
      fontSize: fontSize,
      fontWeight: fontWeight,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Pulsante Terziario Distruttivo (cancellazione account/cronologia):
  /// stile con outline e leggerissimo riempimento rosso tenue.
  static Widget tertiaryDestructive({
    Key? key,
    required VoidCallback? onPressed,
    String? label,
    Widget? child,
    IconData? icon,
    Widget? iconWidget,
    bool fullWidth = false,
    bool isLoading = false,
    EdgeInsetsGeometry? padding,
    double? fontSize,
    FontWeight? fontWeight,
    BorderRadius? borderRadius,
  }) {
    return AppTertiaryDestructiveButton(
      key: key,
      onPressed: onPressed,
      label: label,
      icon: icon,
      iconWidget: iconWidget,
      fullWidth: fullWidth,
      isLoading: isLoading,
      padding: padding,
      fontSize: fontSize,
      fontWeight: fontWeight,
      borderRadius: borderRadius,
      child: child,
    );
  }
}

// -----------------------------------------------------------------------------
// Componenti Specifici dei Pulsanti
// -----------------------------------------------------------------------------

/// Base interna per la composizione del contenuto del pulsante (label, icona, loader).
Widget _buildButtonContent({
  required Color fgColor,
  String? label,
  Widget? child,
  IconData? icon,
  Widget? iconWidget,
  required bool isLoading,
  double? fontSize,
  FontWeight? fontWeight,
}) {
  if (isLoading) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: fgColor,
      ),
    );
  }

  final textWidget = child ??
      (label != null
          ? Text(
              label,
              style: TextStyle(
                fontSize: fontSize ?? 15,
                fontWeight: fontWeight ?? FontWeight.w600,
                color: fgColor,
              ),
            )
          : const SizedBox.shrink());

  final resolvedIcon = iconWidget ??
      (icon != null
          ? Icon(
              icon,
              size: 20,
              color: fgColor,
            )
          : null);

  if (resolvedIcon != null) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        resolvedIcon,
        if (label != null || child != null) ...[
          const SizedBox(width: 8),
          Flexible(child: textWidget),
        ],
      ],
    );
  }

  return textWidget;
}

/// Pulsante Primario (verde pieno)
class AppPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final IconData? icon;
  final Widget? iconWidget;
  final bool fullWidth;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final BorderRadius? borderRadius;

  const AppPrimaryButton({
    super.key,
    required this.onPressed,
    this.label,
    this.child,
    this.icon,
    this.iconWidget,
    this.fullWidth = false,
    this.isLoading = false,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final r = borderRadius ?? BorderRadius.circular(999);

    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.buttonPrimaryBg,
        foregroundColor: colorScheme.buttonPrimaryFg,
        disabledBackgroundColor: colorScheme.buttonPrimaryDisabledBg,
        disabledForegroundColor: colorScheme.buttonPrimaryDisabledFg,
        padding: padding ?? const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: r),
      ),
      child: _buildButtonContent(
        fgColor: colorScheme.buttonPrimaryFg,
        label: label,
        child: child,
        icon: icon,
        iconWidget: iconWidget,
        isLoading: isLoading,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// Pulsante Secondario (grigio pieno tonale)
class AppSecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final IconData? icon;
  final Widget? iconWidget;
  final bool fullWidth;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final BorderRadius? borderRadius;

  const AppSecondaryButton({
    super.key,
    required this.onPressed,
    this.label,
    this.child,
    this.icon,
    this.iconWidget,
    this.fullWidth = false,
    this.isLoading = false,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final r = borderRadius ?? BorderRadius.circular(999);

    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.buttonSecondaryBg,
        foregroundColor: colorScheme.buttonSecondaryFg,
        disabledBackgroundColor: colorScheme.buttonSecondaryDisabledBg,
        disabledForegroundColor: colorScheme.buttonSecondaryDisabledFg,
        padding: padding ?? const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: r),
      ),
      child: _buildButtonContent(
        fgColor: colorScheme.buttonSecondaryFg,
        label: label,
        child: child,
        icon: icon,
        iconWidget: iconWidget,
        isLoading: isLoading,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// Pulsante Terziario (outlined)
class AppTertiaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final IconData? icon;
  final Widget? iconWidget;
  final bool fullWidth;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final BorderRadius? borderRadius;

  const AppTertiaryButton({
    super.key,
    required this.onPressed,
    this.label,
    this.child,
    this.icon,
    this.iconWidget,
    this.fullWidth = false,
    this.isLoading = false,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final r = borderRadius ?? BorderRadius.circular(999);

    final button = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.buttonTertiaryFg,
        side: BorderSide(
          color: colorScheme.buttonTertiaryBorder,
          width: 1.5,
        ),
        disabledForegroundColor: colorScheme.buttonTertiaryDisabledFg,
        padding: padding ?? const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: r),
      ),
      child: _buildButtonContent(
        fgColor: colorScheme.buttonTertiaryFg,
        label: label,
        child: child,
        icon: icon,
        iconWidget: iconWidget,
        isLoading: isLoading,
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.w500,
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// Pulsante Primario Distruttivo (rosso pieno)
class AppPrimaryDestructiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final IconData? icon;
  final Widget? iconWidget;
  final bool fullWidth;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final BorderRadius? borderRadius;

  const AppPrimaryDestructiveButton({
    super.key,
    required this.onPressed,
    this.label,
    this.child,
    this.icon,
    this.iconWidget,
    this.fullWidth = false,
    this.isLoading = false,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final r = borderRadius ?? BorderRadius.circular(999);

    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.buttonPrimaryDestructiveBg,
        foregroundColor: colorScheme.buttonPrimaryDestructiveFg,
        disabledBackgroundColor: colorScheme.buttonPrimaryDestructiveDisabledBg,
        disabledForegroundColor: colorScheme.buttonPrimaryDestructiveDisabledFg,
        padding: padding ?? const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: r),
      ),
      child: _buildButtonContent(
        fgColor: colorScheme.buttonPrimaryDestructiveFg,
        label: label,
        child: child,
        icon: icon,
        iconWidget: iconWidget,
        isLoading: isLoading,
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.w600,
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// Pulsante Terziario Distruttivo (cancellazione account, cronologia, disinstallazione)
class AppTertiaryDestructiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final IconData? icon;
  final Widget? iconWidget;
  final bool fullWidth;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final BorderRadius? borderRadius;

  const AppTertiaryDestructiveButton({
    super.key,
    required this.onPressed,
    this.label,
    this.child,
    this.icon,
    this.iconWidget,
    this.fullWidth = false,
    this.isLoading = false,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final r = borderRadius ?? BorderRadius.circular(999);

    final button = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.buttonTertiaryDestructiveFg,
        backgroundColor: colorScheme.buttonTertiaryDestructiveBg,
        side: BorderSide(
          color: colorScheme.buttonTertiaryDestructiveBorder,
          width: 1.5,
        ),
        disabledForegroundColor: colorScheme.buttonTertiaryDestructiveDisabledFg,
        disabledBackgroundColor: colorScheme.buttonTertiaryDestructiveDisabledBg,
        padding: padding ?? const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: r),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return colorScheme.splashError;
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return colorScheme.selectedErrorItemBg;
          }
          return null;
        }),
      ),
      child: _buildButtonContent(
        fgColor: colorScheme.buttonTertiaryDestructiveFg,
        label: label,
        child: child,
        icon: icon,
        iconWidget: iconWidget,
        isLoading: isLoading,
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.w600,
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

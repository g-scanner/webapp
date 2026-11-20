// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import '../../models/gluten_safety_status.dart';
import 'app_colors.dart';

export 'app_colors.dart';

// ─── ThemeData ────────────────────────────────────────────────────────────────
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  brightness: Brightness.light,
  cardColor: lightCardBackground,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: lightPrimary,
    onPrimary: lightOnPrimary,
    primaryContainer: lightPrimaryContainer,
    onPrimaryContainer: lightOnPrimaryContainer,
    secondary: lightSecondaryContainer,
    onSecondary: lightOnSecondaryContainer,
    secondaryContainer: lightSecondaryContainer,
    onSecondaryContainer: lightOnSecondaryContainer,
    tertiary: lightStatusUncertainText,
    onTertiary: colorWhite,
    tertiaryContainer: lightTertiaryContainer,
    onTertiaryContainer: lightOnTertiaryContainer,
    error: lightError,
    onError: colorWhite,
    errorContainer: lightErrorContainer,
    onErrorContainer: lightOnErrorContainer,
    surface: lightSurface,
    onSurface: lightOnSurface,
    surfaceContainerHighest: lightSurfaceVariant,
    onSurfaceVariant: lightOnSurfaceVariant,
    outline: lightOutline,
    outlineVariant: lightCardPrimaryBorder,
    shadow: lightShadow,
    scrim: lightScrim,
    inverseSurface: darkSurface,
    onInverseSurface: lightSurface,
    inversePrimary: darkPrimary,
  ),
  scaffoldBackgroundColor: lightSurface,
  splashColor: lightPrimary.withValues(alpha: 0.12),
  highlightColor: lightPrimary.withValues(alpha: 0.08),
  appBarTheme: const AppBarTheme(
    backgroundColor: lightSurface,
    foregroundColor: lightOnSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: lightBottomNavBg,
    indicatorColor: lightSecondaryContainer,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: lightCardBackground,
    surfaceTintColor: colorTransparent,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: lightCardBackground,
    surfaceTintColor: colorTransparent,
    modalBackgroundColor: lightBottomSheetBg,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: lightCardBackground,
    elevation: 6,
    shadowColor: lightShadow,
    surfaceTintColor: colorTransparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: lightCardPrimaryBorder),
    ),
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  brightness: Brightness.dark,
  cardColor: darkCardBackground,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: darkPrimary,
    onPrimary: darkOnPrimary,
    primaryContainer: darkPrimaryContainer,
    onPrimaryContainer: darkOnPrimaryContainer,
    secondary: darkSecondaryContainer,
    onSecondary: darkOnSecondaryContainer,
    secondaryContainer: darkSecondaryContainer,
    onSecondaryContainer: darkOnSecondaryContainer,
    tertiary: darkStatusUncertainText,
    onTertiary: darkSurface,
    tertiaryContainer: darkTertiaryContainer,
    onTertiaryContainer: darkOnTertiaryContainer,
    error: darkError,
    onError: darkOnError,
    errorContainer: darkErrorContainer,
    onErrorContainer: darkOnErrorContainer,
    surface: darkSurface,
    onSurface: darkOnSurface,
    surfaceContainerHighest: darkSurfaceVariant,
    onSurfaceVariant: darkOnSurfaceVariant,
    outline: darkOutline,
    outlineVariant: darkCardPrimaryBorder,
    shadow: darkShadow,
    scrim: darkScrim,
    inverseSurface: lightSurface,
    onInverseSurface: darkSurface,
    inversePrimary: lightPrimary,
  ),
  scaffoldBackgroundColor: darkSurface,
  splashColor: darkPrimary.withValues(alpha: 0.12),
  highlightColor: darkPrimary.withValues(alpha: 0.08),
  appBarTheme: const AppBarTheme(
    backgroundColor: darkSurface,
    foregroundColor: darkOnSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: darkBottomNavBg,
    indicatorColor: darkSecondaryContainer,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: darkCardBackground,
    surfaceTintColor: colorTransparent,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: darkCardBackground,
    surfaceTintColor: colorTransparent,
    modalBackgroundColor: darkBottomSheetBg,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: darkCardBackground,
    elevation: 6,
    shadowColor: darkShadow,
    surfaceTintColor: colorTransparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: darkCardPrimaryBorder),
    ),
  ),
);

// ─── Context Extensions ────────────────────────────────────────────────────────
extension AppThemeContextExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get cardBackground =>
      isDarkMode ? darkCardBackground : lightCardBackground;
  Color get surfaceContainerLow =>
      isDarkMode ? darkSurfaceContainerLow : lightSurfaceContainerLow;
  Color get modalBackgroundColor =>
      isDarkMode ? darkBottomSheetBg : lightBottomSheetBg;
  Color get bottomNavBg => isDarkMode ? darkBottomNavBg : lightBottomNavBg;
  Color get textTertiary => isDarkMode ? darkTextTertiary : lightTextTertiary;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
ThemeMode themeModeFromString(String value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

String themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    default:
      return 'system';
  }
}

// ─── Semantic colour tokens ───────────────────────────────────────────────────
//
// Unica fonte di verità per tutti i colori dell'applicazione.
// Ogni widget deve usare questi getter invece di calcolare i colori inline
// o usare colori hardcoded.
//
// Le fonti di verità sono separate logicamente: se due elementi oggi condividono
// lo stesso valore cromatico ma rappresentano concetti diversi, hanno comunque
// due getter distinti per consentire variazioni future indipendenti.
//
extension AppColorTokens on ColorScheme {
  // ── 1. STATI DEL CIBO (4 STATI GLUTINE + LATTOSIO) ────────────────────────
  // Ciascuno stato possiede ESATTAMENTE una coppia:
  // - un colore solido (per testi, icone, elementi grafici primari)
  // - un colore con alpha / sfondo (per sfondi, pillole, container, hero card - già pastello al 100%)

  // STATO SICURO (Safe / Adatto) - Scollegato da primary / primaryContainer
  Color get statusSafeSolid =>
      brightness == Brightness.dark ? darkStatusSafeText : lightStatusSafeText;
  Color get statusSafeAlpha =>
      brightness == Brightness.dark ? darkStatusSafeBg : lightStatusSafeBg;
  ({Color solid, Color alpha}) get statusSafeColors =>
      (solid: statusSafeSolid, alpha: statusSafeAlpha);

  // STATO VIETATO (Unsafe / Non adatto)
  Color get statusUnsafeSolid => brightness == Brightness.dark
      ? darkStatusUnsafeText
      : lightStatusUnsafeText;
  Color get statusUnsafeAlpha =>
      brightness == Brightness.dark ? darkStatusUnsafeBg : lightStatusUnsafeBg;
  ({Color solid, Color alpha}) get statusUnsafeColors =>
      (solid: statusUnsafeSolid, alpha: statusUnsafeAlpha);

  // STATO INCERTO (Uncertain / Warning / Segnalazione)
  Color get statusUncertainSolid => brightness == Brightness.dark
      ? darkStatusUncertainText
      : lightStatusUncertainText;
  Color get statusUncertainAlpha => brightness == Brightness.dark
      ? darkStatusUncertainBg
      : lightStatusUncertainBg;
  ({Color solid, Color alpha}) get statusUncertainColors =>
      (solid: statusUncertainSolid, alpha: statusUncertainAlpha);

  // STATO IGNOTO (Unknown / Sconosciuto / Neutro)
  Color get statusUnknownSolid => brightness == Brightness.dark
      ? darkStatusUnknownText
      : lightStatusUnknownText;
  Color get statusUnknownAlpha => brightness == Brightness.dark
      ? darkStatusUnknownBg
      : lightStatusUnknownBg;
  ({Color solid, Color alpha}) get statusUnknownColors =>
      (solid: statusUnknownSolid, alpha: statusUnknownAlpha);

  // STATO LATTOSIO (Lactose Alert / Intolleranza) - Scollegato da secondaryContainer / navSelected
  Color get statusLactoseSolid =>
      brightness == Brightness.dark ? darkLactoseText : lightLactoseText;
  Color get statusLactoseAlpha =>
      brightness == Brightness.dark ? darkLactoseBg : lightLactoseBg;
  ({Color solid, Color alpha}) get statusLactoseColors =>
      (solid: statusLactoseSolid, alpha: statusLactoseAlpha);

  /// Helper unificato per ottenere la coppia ({solid, alpha}) per qualsiasi [GlutenSafetyStatus].
  ({Color solid, Color alpha}) statusColorsFor(GlutenSafetyStatus status) {
    switch (status) {
      case GlutenSafetyStatus.adatto:
        return statusSafeColors;
      case GlutenSafetyStatus.nonAdatto:
        return statusUnsafeColors;
      case GlutenSafetyStatus.incerto:
        return statusUncertainColors;
      case GlutenSafetyStatus.sconosciuto:
        return statusUnknownColors;
    }
  }

  // Pallini Legenda Scanner (pieni 100%)
  Color get statusSafeLegendDot => brightness == Brightness.dark
      ? darkStatusSafeText
      : lightStatusSafeLegendDot;
  Color get statusUncertainLegendDot => brightness == Brightness.dark
      ? darkStatusUncertainText
      : lightStatusUncertainLegendDot;
  Color get statusUnsafeLegendDot =>
      brightness == Brightness.dark ? darkError : lightStatusUnsafeLegendDot;
  Color get statusUnknownLegendDot => brightness == Brightness.dark
      ? darkStatusUnknownText
      : lightStatusUnknownLegendDot;

  // Alias semantici per compatibilità
  Color get statusPrimaryBg => statusSafeAlpha;
  Color get statusPrimaryText => statusSafeSolid;
  Color get statusErrorBg => statusUnsafeAlpha;
  Color get statusErrorText => statusUnsafeSolid;
  Color get statusTertiaryBg => statusUncertainAlpha;
  Color get statusTertiaryText => statusUncertainSolid;
  Color get statusNeutralBg => statusUnknownAlpha;
  Color get statusNeutralText => statusUnknownSolid;
  Color get statusSecondaryBg => statusLactoseAlpha;
  Color get statusSecondaryText => statusLactoseSolid;
  Color get lactoseBg => statusLactoseAlpha;
  Color get lactoseText => statusLactoseSolid;

  // ── 2. PULSANTI (BUTTONS) ─────────────────────────────────────────────────
  // Token cromatici dedicati per la gerarchia dei pulsanti dell'app.

  // Pulsante Primario (pieno blu Cobalt Mist; in dark mode usa darkButtonPrimaryBg anti-abbagliamento)
  Color get buttonPrimaryBg =>
      brightness == Brightness.dark ? darkButtonPrimaryBg : primary;
  Color get buttonPrimaryFg =>
      brightness == Brightness.dark ? darkButtonPrimaryFg : onPrimary;
  Color get buttonPrimaryDisabledBg => buttonPrimaryBg.withValues(alpha: 0.38);
  Color get buttonPrimaryDisabledFg => buttonPrimaryFg.withValues(alpha: 0.38);

  // Pulsante Secondario (grigio pieno)
  Color get buttonSecondaryBg => surfaceContainerHighest;
  Color get buttonSecondaryFg => onSurface;
  Color get buttonSecondaryDisabledBg =>
      surfaceContainerHighest.withValues(alpha: 0.38);
  Color get buttonSecondaryDisabledFg => onSurface.withValues(alpha: 0.38);

  // Pulsante Terziario (outlined blu)
  Color get buttonTertiaryBg => colorTransparent;
  Color get buttonTertiaryBorder => brightness == Brightness.dark
      ? darkButtonTertiaryBorder
      : lightButtonTertiaryBorder;
  Color get buttonTertiaryFg => primary;
  Color get buttonTertiaryDisabledBorder =>
      buttonTertiaryBorder.withValues(alpha: 0.2);
  Color get buttonTertiaryDisabledFg => primary.withValues(alpha: 0.38);

  // Pulsante Primario Distruttivo (rosso pieno di eliminazione)
  Color get buttonPrimaryDestructiveBg => error;
  Color get buttonPrimaryDestructiveFg => onError;
  Color get buttonPrimaryDestructiveDisabledBg => error.withValues(alpha: 0.6);
  Color get buttonPrimaryDestructiveDisabledFg =>
      onError.withValues(alpha: 0.6);

  // Pulsante Terziario Distruttivo (cancellazione, outline con leggerissimo riempimento)
  Color get buttonTertiaryDestructiveBg => brightness == Brightness.dark
      ? darkStatusUnsafeBg.withValues(alpha: 0.5)
      : lightStatusUnsafeBg.withValues(alpha: 0.5);
  Color get buttonTertiaryDestructiveBorder => brightness == Brightness.dark
      ? darkStatusUnsafeDestructiveBorder
      : lightStatusUnsafeDestructiveBorder;
  Color get buttonTertiaryDestructiveFg => error;
  Color get buttonTertiaryDestructiveDisabledBg =>
      buttonTertiaryDestructiveBg.withValues(alpha: 0.2);
  Color get buttonTertiaryDestructiveDisabledBorder =>
      buttonTertiaryDestructiveBorder.withValues(alpha: 0.2);
  Color get buttonTertiaryDestructiveDisabledFg =>
      error.withValues(alpha: 0.38);

  // Compatibilità per AppDestructiveActionButton
  Color get destructiveButtonBg => buttonTertiaryDestructiveBg;
  Color get destructiveButtonBorder => buttonTertiaryDestructiveBorder;
  Color get destructiveButtonFg => buttonTertiaryDestructiveFg;

  // ── 3. CARD (SCHEDE) ──────────────────────────────────────────────────────
  // Token cromatici dedicati per le tre tipologie di card.

  // Card Principale (sfondo tema chiaro/scuro con bordo sottile)
  Color get cardPrimaryBg =>
      brightness == Brightness.dark ? darkCardBackground : lightCardBackground;
  Color get cardPrimaryBorder => brightness == Brightness.dark
      ? darkCardPrimaryBorder
      : lightCardPrimaryBorder;
  Color get cardPrimaryShadow => shadow;
  Color get cardPrimaryHover => surfaceContainerHighest;
  Color get cardPrimaryHighlight => brightness == Brightness.dark
      ? darkSurfaceContainerLow
      : lightSurfaceContainerLow;

  // Card Secondaria (sfondo uniforme grigio neutro con bordo sottile neutro)
  Color get cardSecondaryBg => brightness == Brightness.dark
      ? darkCardSecondaryBg
      : lightCardSecondaryBg;
  Color get cardSecondaryBorder => brightness == Brightness.dark
      ? darkCardSecondaryBorder
      : lightCardSecondaryBorder;
  Color get cardSecondaryFg => onSurface;
  Color get cardSecondaryShadow => brightness == Brightness.dark
      ? shadow.withValues(alpha: 0.3)
      : shadow.withValues(alpha: 0.08);

  // Card ad Alta Evidenziazione (High Emphasis)
  Color get cardHighEmphasisBg => cardPrimaryBg;
  Color get cardHighEmphasisBorder => cardPrimaryBorder;
  Color get cardHighEmphasisShadow => shadow;

  // ── 4. CERCHI ICONA (ICON CIRCLES) ────────────────────────────────────────
  // Cerchio brand usa primaryContainer pieno; i cerchi stato usano gli sfondi pieni.
  Color get iconCirclePrimaryBg => primaryContainer;
  Color get iconCircleErrorBg => statusUnsafeAlpha;
  Color get iconCircleTertiaryBg => statusUncertainAlpha;
  Color get iconCircleNeutralBg => statusUnknownAlpha;
  Color get iconCircleSecondaryBg => statusLactoseAlpha;

  // ── 5. CALL TO ACTION BAR (FOOTER CARD SEGNALAZIONI/DETTAGLI) ────────────
  Color get ctaBarBg => cardSecondaryBg;
  Color get ctaBarBorder => cardSecondaryBorder;
  Color get ctaBarFg => primary;
  Color get ctaTertiaryBg => ctaBarBg;

  // ── 6. ELEMENTI SELEZIONABILI E NON SELEZIONATI ──────────────────────────
  Color get selectedItemBg => primaryContainer;
  Color get selectedItemBorder => primary.withValues(alpha: 0.35);
  Color get selectedErrorItemBg => statusUnsafeAlpha;
  Color get selectedErrorItemBorder => error.withValues(alpha: 0.35);
  Color get unselectedItemBg => surfaceContainerHighest;

  // ── 7. SELETTORI POPUP / PILL ─────────────────────────────────────────────
  Color get dropdownPillBg => surfaceContainerHighest;

  // ── 8. CONTAINER LEGENDA SCANNER ──────────────────────────────────────────
  Color get scannerLegendContainerBg => brightness == Brightness.dark
      ? darkScannerLegendBg
      : lightScannerLegendBg;

  // ── 9. NAVIGAZIONE E MODAL ───────────────────────────────────────────────
  Color get bottomNavBg =>
      brightness == Brightness.dark ? darkBottomNavBg : lightBottomNavBg;
  Color get modalBackgroundColor =>
      brightness == Brightness.dark ? darkBottomSheetBg : lightBottomSheetBg;
  Color get navSelectedBg => secondaryContainer;
  Color get navSelectedFg => onSecondaryContainer;

  // ── 10. ACCESSO ANONIMO ───────────────────────────────────────────────────
  Color get anonymousEntryFg => primary;

  // ── 11. EFFETTI SPLASH / OVERLAY ──────────────────────────────────────────
  Color get splashPrimary => primary.withValues(alpha: 0.12);
  Color get splashError => error.withValues(alpha: 0.12);

  // ── 12. TESTO TERZIARIO (Hint / Placeholder) ──────────────────────────────
  Color get textTertiary =>
      brightness == Brightness.dark ? darkTextTertiary : lightTextTertiary;
}

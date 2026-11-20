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
    tertiary: lightTertiaryContainer,
    onTertiary: lightOnTertiaryContainer,
    tertiaryContainer: lightTertiaryContainer,
    onTertiaryContainer: lightOnTertiaryContainer,
    error: lightError,
    onError: lightOnPrimary,
    errorContainer: lightErrorContainer,
    onErrorContainer: lightOnErrorContainer,
    surface: lightSurface,
    onSurface: lightOnSurface,
    surfaceContainerHighest: lightSurfaceVariant,
    onSurfaceVariant: lightOnSurfaceVariant,
    outline: lightOutline,
    outlineVariant: lightOutline,
    shadow: lightShadow,
    scrim: lightScrim,
    inverseSurface: lightOnSurface,
    onInverseSurface: lightSurface,
    inversePrimary: darkPrimary,
  ),
  scaffoldBackgroundColor: lightSurface,
  splashColor: lightPrimary.withValues(alpha: 0.12),
  highlightColor: lightPrimary.withValues(alpha: 0.08),
  appBarTheme: const AppBarTheme(
    backgroundColor: lightCardBackground,
    foregroundColor: lightOnSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: lightCardBackground,
    surfaceTintColor: colorTransparent,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: lightCardBackground,
    surfaceTintColor: colorTransparent,
    modalBackgroundColor: lightSurface,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: lightCardBackground,
    elevation: 6,
    shadowColor: lightShadow,
    surfaceTintColor: colorTransparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: lightOutline.withValues(alpha: 0.4)),
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
    tertiary: darkTertiaryContainer,
    onTertiary: darkOnTertiaryContainer,
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
    outlineVariant: darkOutline,
    shadow: darkShadow,
    scrim: darkScrim,
    inverseSurface: darkOnSurface,
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
  dialogTheme: const DialogThemeData(
    backgroundColor: darkCardBackground,
    surfaceTintColor: colorTransparent,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: darkCardBackground,
    surfaceTintColor: colorTransparent,
    modalBackgroundColor: darkSurface,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: darkCardBackground,
    elevation: 6,
    shadowColor: darkShadow,
    surfaceTintColor: colorTransparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: darkOutline.withValues(alpha: 0.4)),
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
  // - un colore con alpha (per sfondi, pillole, container, hero card)

  // STATO SICURO (Safe / Adatto) - Scollegato da primary / primaryContainer
  Color get statusSafeSolid =>
      brightness == Brightness.dark ? darkStatusSafeText : lightStatusSafeText;
  Color get statusSafeAlpha =>
      (brightness == Brightness.dark
              ? darkStatusSafeContainer
              : lightStatusSafeContainer)
          .withValues(alpha: 0.15);
  ({Color solid, Color alpha}) get statusSafeColors =>
      (solid: statusSafeSolid, alpha: statusSafeAlpha);

  // STATO VIETATO (Unsafe / Non adatto)
  Color get statusUnsafeSolid => error;
  Color get statusUnsafeAlpha => errorContainer.withValues(
    alpha: brightness == Brightness.dark ? 0.2 : 0.5,
  );
  ({Color solid, Color alpha}) get statusUnsafeColors =>
      (solid: statusUnsafeSolid, alpha: statusUnsafeAlpha);

  // STATO INCERTO (Uncertain / Warning / Segnalazione)
  Color get statusUncertainSolid => tertiary;
  Color get statusUncertainAlpha => tertiaryContainer.withValues(alpha: 0.1);
  ({Color solid, Color alpha}) get statusUncertainColors =>
      (solid: statusUncertainSolid, alpha: statusUncertainAlpha);

  // STATO IGNOTO (Unknown / Sconosciuto / Neutro)
  Color get statusUnknownSolid => onSurfaceVariant;
  Color get statusUnknownAlpha => surfaceContainerHighest;
  ({Color solid, Color alpha}) get statusUnknownColors =>
      (solid: statusUnknownSolid, alpha: statusUnknownAlpha);

  // STATO LATTOSIO (Lactose Alert / Intolleranza) - Scollegato da secondaryContainer / navSelected
  Color get statusLactoseSolid =>
      brightness == Brightness.dark ? darkLactoseText : lightLactoseText;
  Color get statusLactoseAlpha =>
      (brightness == Brightness.dark
              ? darkLactoseContainer
              : lightLactoseContainer)
          .withValues(alpha: 0.15);
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

  // Pulsante Primario (verde pieno)
  Color get buttonPrimaryBg => primary;
  Color get buttonPrimaryFg => onPrimary;
  Color get buttonPrimaryDisabledBg => primary.withValues(alpha: 0.38);
  Color get buttonPrimaryDisabledFg => onPrimary.withValues(alpha: 0.38);

  // Pulsante Secondario (grigio pieno)
  Color get buttonSecondaryBg => surfaceContainerHighest;
  Color get buttonSecondaryFg => onSurface;
  Color get buttonSecondaryDisabledBg =>
      surfaceContainerHighest.withValues(alpha: 0.38);
  Color get buttonSecondaryDisabledFg => onSurface.withValues(alpha: 0.38);

  // Pulsante Terziario (outlined)
  Color get buttonTertiaryBg => colorTransparent;
  Color get buttonTertiaryBorder => outlineVariant.withValues(alpha: 0.5);
  Color get buttonTertiaryFg => onSurface;
  Color get buttonTertiaryDisabledBorder =>
      outlineVariant.withValues(alpha: 0.2);
  Color get buttonTertiaryDisabledFg => onSurface.withValues(alpha: 0.38);

  // Pulsante Primario Distruttivo (rosso pieno di eliminazione)
  Color get buttonPrimaryDestructiveBg => error;
  Color get buttonPrimaryDestructiveFg => onError;
  Color get buttonPrimaryDestructiveDisabledBg => error.withValues(alpha: 0.6);
  Color get buttonPrimaryDestructiveDisabledFg => onError.withValues(alpha: 0.6);

  // Pulsante Terziario Distruttivo (cancellazione, outline con leggerissimo riempimento)
  Color get buttonTertiaryDestructiveBg => errorContainer.withValues(alpha: 0.3);
  Color get buttonTertiaryDestructiveBorder => errorContainer;
  Color get buttonTertiaryDestructiveFg => error;
  Color get buttonTertiaryDestructiveDisabledBg =>
      errorContainer.withValues(alpha: 0.1);
  Color get buttonTertiaryDestructiveDisabledBorder =>
      errorContainer.withValues(alpha: 0.2);
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
  Color get cardPrimaryBorder => outlineVariant.withValues(alpha: 0.3);
  Color get cardPrimaryShadow => shadow.withValues(alpha: 0.02);
  Color get cardPrimaryHover => surfaceContainerHighest;
  Color get cardPrimaryHighlight =>
      brightness == Brightness.dark ? darkSurfaceContainerLow : lightSurfaceContainerLow;

  // Card Secondaria (sfondo uniforme grigio pieno)
  Color get cardSecondaryBg => surfaceContainerHighest;
  Color get cardSecondaryBorder => colorTransparent;
  Color get cardSecondaryFg => onSurface;

  // Card ad Alta Evidenziazione (High Emphasis)
  Color get cardHighEmphasisBg => cardPrimaryBg;
  Color get cardHighEmphasisBorder => outlineVariant.withValues(alpha: 0.5);
  Color get cardHighEmphasisShadow => shadow.withValues(alpha: 0.04);

  // ── 4. CERCHI ICONA (ICON CIRCLES) ────────────────────────────────────────
  // Sfondi dedicati per i cerchi contenenti icone.
  Color get iconCirclePrimaryBg => primaryContainer.withValues(alpha: 0.15);
  Color get iconCircleErrorBg => errorContainer.withValues(
    alpha: brightness == Brightness.dark ? 0.2 : 0.5,
  );
  Color get iconCircleTertiaryBg => tertiaryContainer.withValues(alpha: 0.1);
  Color get iconCircleNeutralBg => onSurfaceVariant.withValues(alpha: 0.1);
  Color get iconCircleSecondaryBg => secondaryContainer.withValues(alpha: 0.15);

  // ── 5. CALL TO ACTION BAR (FOOTER CARD SEGNALAZIONI/DETTAGLI) ────────────
  Color get ctaBarBg => tertiaryContainer.withValues(alpha: 0.1);
  Color get ctaBarBorder => outlineVariant.withValues(alpha: 0.2);
  Color get ctaBarFg => tertiary;
  Color get ctaTertiaryBg => ctaBarBg;

  // ── 6. ELEMENTI SELEZIONABILI E NON SELEZIONATI ──────────────────────────
  Color get selectedItemBg => primaryContainer.withValues(alpha: 0.08);
  Color get selectedItemBorder => primary.withValues(alpha: 0.25);
  Color get selectedErrorItemBg => errorContainer.withValues(
    alpha: brightness == Brightness.dark ? 0.2 : 0.5,
  );
  Color get selectedErrorItemBorder => error.withValues(alpha: 0.25);
  Color get unselectedItemBg => surfaceContainerHighest.withValues(alpha: 0.35);

  // ── 7. SELETTORI POPUP / PILL ─────────────────────────────────────────────
  Color get dropdownPillBg => surfaceContainerHighest;

  // ── 8. CONTAINER LEGENDA SCANNER ──────────────────────────────────────────
  Color get scannerLegendContainerBg =>
      brightness == Brightness.dark ? darkScannerLegendBg : lightScannerLegendBg;

  // ── 9. NAVIGAZIONE ────────────────────────────────────────────────────────
  Color get navSelectedBg => secondaryContainer.withValues(alpha: 0.3);
  Color get navSelectedFg => onSecondaryContainer;

  // ── 10. ACCESSO ANONIMO ───────────────────────────────────────────────────
  Color get anonymousEntryFg => primary;

  // ── 11. EFFETTI SPLASH / OVERLAY ──────────────────────────────────────────
  Color get splashPrimary => primary.withValues(alpha: 0.12);
  Color get splashError => error.withValues(alpha: 0.12);
}

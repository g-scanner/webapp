// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'app_colors.dart';

export 'app_colors.dart';

// ─── ThemeData ────────────────────────────────────────────────────────────────
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  brightness: Brightness.light,
  cardColor: const Color(0xFFFFFFFF),
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
    shadow: Color(0x1F000000),
    scrim: Color(0x52000000),
    inverseSurface: lightOnSurface,
    onInverseSurface: lightSurface,
    inversePrimary: darkPrimary,
  ),
  scaffoldBackgroundColor: lightSurface,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFFFFFF),
    foregroundColor: lightOnSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: Color(0xFFFFFFFF),
    surfaceTintColor: Colors.transparent,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFFFFFFFF),
    surfaceTintColor: Colors.transparent,
    modalBackgroundColor: Color(0xFFFAF9FC),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: const Color(0xFFFFFFFF),
    elevation: 6,
    shadowColor: const Color(0x1F000000),
    surfaceTintColor: Colors.transparent,
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
  cardColor: const Color(0xFF1E1E22),
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
    shadow: Color(0x3F000000),
    scrim: Color(0x80000000),
    inverseSurface: darkOnSurface,
    onInverseSurface: darkSurface,
    inversePrimary: lightPrimary,
  ),
  scaffoldBackgroundColor: darkSurface,
  appBarTheme: const AppBarTheme(
    backgroundColor: darkSurface,
    foregroundColor: darkOnSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: Color(0xFF1E1E22),
    surfaceTintColor: Colors.transparent,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF1E1E22),
    surfaceTintColor: Colors.transparent,
    modalBackgroundColor: Color(0xFF121214),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: const Color(0xFF1E1E22),
    elevation: 6,
    shadowColor: const Color(0x3F000000),
    surfaceTintColor: Colors.transparent,
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
      isDarkMode ? const Color(0xFF1E1E22) : const Color(0xFFFFFFFF);
  Color get surfaceContainerLow =>
      isDarkMode ? const Color(0xFF18181C) : const Color(0xFFF5F3F7);
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
// Unica fonte di verità per tutti i colori semantici dell'app.
// Ogni widget deve usare questi getter invece di calcolare i colori inline.
//
// Varianti stato glutine
//   statusPrimaryBg / statusPrimaryText  → adatto / sicuro / primario
//   statusErrorBg  / statusErrorText     → non adatto / errore
//   statusTertiaryBg / statusTertiaryText → incerto / segnalazione / warning
//   statusNeutralBg / statusNeutralText  → sconosciuto / neutro
//
// Cerchi icona
//   iconCirclePrimaryBg  → sfondo cerchio icona per azioni primarie / info
//   iconCircleErrorBg    → sfondo cerchio icona per azioni distruttive
//   iconCircleTertiaryBg → sfondo cerchio icona per warning / segnalazioni
//
// Sfondo CTA bar (footer colorato nelle card)
//   ctaTertiaryBg → sfondo barra CTA segnalazioni / incerto
//
// Sfondo elementi selezionati (selettori, chip selezionata)
//   selectedItemBg → sfondo leggero quando un elemento è selezionato/attivo
//
extension AppColorTokens on ColorScheme {
  // ── Stato glutine ──────────────────────────────────────────────────────────
  Color get statusPrimaryBg => primaryContainer.withValues(alpha: 0.15);
  Color get statusPrimaryText => primary;

  Color get statusErrorBg => errorContainer.withValues(alpha: 0.5);
  Color get statusErrorText => error;

  Color get statusTertiaryBg => tertiaryContainer.withValues(alpha: 0.1);
  Color get statusTertiaryText => tertiary;

  Color get statusNeutralBg => surfaceContainerHighest;
  Color get statusNeutralText => onSurfaceVariant;

  // ── Cerchi icona ──────────────────────────────────────────────────────────
  Color get iconCirclePrimaryBg => primaryContainer.withValues(alpha: 0.15);
  Color get iconCircleErrorBg => errorContainer.withValues(alpha: 0.5);
  Color get iconCircleTertiaryBg => tertiaryContainer.withValues(alpha: 0.1);

  // ── CTA bar ───────────────────────────────────────────────────────────────
  Color get ctaTertiaryBg => tertiaryContainer.withValues(alpha: 0.1);

  // ── Elementi selezionati ──────────────────────────────────────────────────
  Color get selectedItemBg => primaryContainer.withValues(alpha: 0.08);

  // ── Pillola selettore popup (tema, lingua, motivo, …) ─────────────────────
  //   Sfondo neutro della pillola che apre un PopupMenuButton di scelta.
  Color get dropdownPillBg => surfaceContainerHighest;

  // ── Accesso anonimo ────────────────────────────────────────────────────────
  //   Colore del bottone "Entra senza autenticazione" nella schermata di login.
  Color get anonymousEntryFg => primary;
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';

// ─── Light Palette ────────────────────────────────────────────────────────────
const Color lightPrimary              = Color(0xFF0D631B);
const Color lightOnPrimary            = Color(0xFFFFFFFF);
const Color lightPrimaryContainer     = Color(0xFF2E7D32);
const Color lightOnPrimaryContainer   = Color(0xFFFFFFFF);
const Color lightSurface              = Color(0xFFFAF9FC);
const Color lightOnSurface            = Color(0xFF1B1B1E);
const Color lightSurfaceVariant       = Color(0xFFEFEDF1);
const Color lightOnSurfaceVariant     = Color(0xFF40493D);
const Color lightOutline              = Color(0xFFBFCABA);
const Color lightSecondaryContainer   = Color(0xFF54A0FE);
const Color lightOnSecondaryContainer = Color(0xFF003567);
const Color lightTertiaryContainer   = Color(0xFFAD5600);
const Color lightOnTertiaryContainer = Color(0xFFFFFFFF);
const Color lightError               = Color(0xFFBA1A1A);
const Color lightErrorContainer      = Color(0xFFFFDAD6);
const Color lightOnErrorContainer    = Color(0xFF410002);

// ─── Dark Palette ─────────────────────────────────────────────────────────────
const Color darkPrimary              = Color(0xFF81D683);
const Color darkOnPrimary            = Color(0xFF00390E);
const Color darkPrimaryContainer     = Color(0xFF065314);
const Color darkOnPrimaryContainer   = Color(0xFF9DF49E);
const Color darkSurface              = Color(0xFF121214);
const Color darkOnSurface            = Color(0xFFE4E2E6);
const Color darkSurfaceVariant       = Color(0xFF242528);
const Color darkOnSurfaceVariant     = Color(0xFFC1C9BE);
const Color darkOutline              = Color(0xFF8B9389);
const Color darkSecondaryContainer   = Color(0xFF004886);
const Color darkOnSecondaryContainer = Color(0xFFD0E4FF);
const Color darkTertiaryContainer   = Color(0xFFFFB68A);
const Color darkOnTertiaryContainer = Color(0xFF5C2D00);
const Color darkError               = Color(0xFFFFB4AB);
const Color darkErrorContainer      = Color(0xFF93000A);
const Color darkOnErrorContainer    = Color(0xFFFFDAD6);

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
    onError: darkOnPrimary,
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
);

// ─── Context Extensions ────────────────────────────────────────────────────────
extension AppThemeContextExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get cardBackground => isDarkMode ? const Color(0xFF1E1E22) : const Color(0xFFFFFFFF);
  Color get surfaceContainerLow => isDarkMode ? const Color(0xFF18181C) : const Color(0xFFF5F3F7);
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
ThemeMode themeModeFromString(String value) {
  switch (value) {
    case 'light':  return ThemeMode.light;
    case 'dark':   return ThemeMode.dark;
    default:       return ThemeMode.system;
  }
}

String themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:  return 'light';
    case ThemeMode.dark:   return 'dark';
    default:               return 'system';
  }
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — See LICENSE file in root for terms.

import 'package:flutter/material.dart';

// ─── Neutral & Base Colors ──────────────────────────────────────────────────
const Color colorWhite = Color(0xFFFFFFFF);
const Color colorBlack = Color(0xFF000000);
const Color colorTransparent = Color(0x00000000);

// ─── Light Palette (Brand & General M3) ───────────────────────────────────────
const Color lightPrimary = Color(0xFF0D631B);
const Color lightOnPrimary = Color(0xFFFFFFFF);
const Color lightPrimaryContainer = Color(0xFF2E7D32);
const Color lightOnPrimaryContainer = Color(0xFFFFFFFF);
const Color lightSurface = Color(0xFFFAF9FC);
const Color lightOnSurface = Color(0xFF1B1B1E);
const Color lightSurfaceVariant = Color(0xFFEFEDF1);
const Color lightOnSurfaceVariant = Color(0xFF40493D);
const Color lightOutline = Color(0xFFBFCABA);
const Color lightSecondaryContainer = Color(0xFF54A0FE);
const Color lightOnSecondaryContainer = Color(0xFF003567);
const Color lightTertiaryContainer = Color(0xFFAD5600);
const Color lightOnTertiaryContainer = Color(0xFFFFFFFF);
const Color lightError = Color(0xFFBA1A1A);
const Color lightErrorContainer = Color(0xFFFFDAD6);
const Color lightOnErrorContainer = Color(0xFF410002);

// Component-specific Light Tokens
const Color lightCardBackground = Color(0xFFFFFFFF);
const Color lightSurfaceContainerLow = Color(0xFFF5F3F7);
const Color lightScannerLegendBg = Color(0xFFECEEF3);
const Color lightShadow = Color(0x1F000000);
const Color lightScrim = Color(0x52000000);

// ─── Dark Palette (Brand & General M3) ────────────────────────────────────────
const Color darkPrimary = Color(0xFF3D9142); // verde medio — contrasto ~6:1 su bianco
const Color darkOnPrimary = Color(0xFFFFFFFF); // bianco leggibile su darkPrimary
const Color darkOnError = Color(0xFF1A0002); // scuro leggibile su darkError (rosa chiaro)
const Color darkPrimaryContainer = Color(0xFF065314);
const Color darkOnPrimaryContainer = Color(0xFF9DF49E);
const Color darkSurface = Color(0xFF121214);
const Color darkOnSurface = Color(0xFFE4E2E6);
const Color darkSurfaceVariant = Color(0xFF242528);
const Color darkOnSurfaceVariant = Color(0xFFC1C9BE);
const Color darkOutline = Color(0xFF8B9389);
const Color darkSecondaryContainer = Color(0xFF004886);
const Color darkOnSecondaryContainer = Color(0xFFD0E4FF);
const Color darkTertiaryContainer = Color(0xFFFFB68A);
const Color darkOnTertiaryContainer = Color(0xFF5C2D00);
const Color darkError = Color(0xFFFFB4AB);
const Color darkErrorContainer = Color(0xFF93000A);
const Color darkOnErrorContainer = Color(0xFFFFDAD6);

// Component-specific Dark Tokens
const Color darkCardBackground = Color(0xFF1E1E22);
const Color darkSurfaceContainerLow = Color(0xFF18181C);
const Color darkScannerLegendBg = Color(0xFF18181C);
const Color darkShadow = Color(0x3F000000);
const Color darkScrim = Color(0x80000000);

// ─── Safe Status Tokens (Scollegati da primary / primaryContainer) ───────────
// Fonte di verità autonoma per il cibo sicuro / adatto: modifiche al brand primary
// non impattano lo stato di sicurezza alimentare.
const Color lightStatusSafeText = Color(0xFF0D631B);
const Color lightStatusSafeContainer = Color(0xFF2E7D32);
const Color darkStatusSafeText = Color(0xFF51CF66);
const Color darkStatusSafeContainer = Color(0xFF065314);

// Backward-compatible alias
const Color darkStatusPrimaryText = darkStatusSafeText;

// ─── Lactose Status Tokens (Scollegati da secondaryContainer / Navigation) ──
// Fonte di verità autonoma per l'allerta Lattosio: modifiche alla Bottom Navigation
// (secondaryContainer) non impattano il badge e gli indicatori del lattosio.
const Color lightLactoseText = Color(0xFF003567);
const Color lightLactoseContainer = Color(0xFF54A0FE);
const Color darkLactoseText = Color(0xFFD0E4FF);
const Color darkLactoseContainer = Color(0xFF004886);

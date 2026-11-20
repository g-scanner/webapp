// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — See LICENSE file in root for terms.

import 'package:flutter/material.dart';

// ─── Neutral & Base Colors ──────────────────────────────────────────────────
const Color colorWhite = Color(0xFFFFFFFF);
const Color colorBlack = Color(0xFF000000);
const Color colorTransparent = Color(0x00000000);

// ─── Light Palette — Cobalt Mist (Material 3) ─────────────────────────────────
// Superfici e sfondi
const Color lightSurface = Color(0xFFF4F7FC); // Sfondo pagina
const Color lightCardBackground = Color(0xFFFFFFFF); // Card principale
const Color lightCardSecondaryBg = Color(0xFFECEFF4); // Container secondario / Legenda / Box note / Footer
const Color lightSurfaceContainerLow = Color(0xFFECEFF4); // surfaceContainerLow
const Color lightSurfaceVariant = Color(0xFFE2E9F4); // Input / Pillole ricerca / Campi form / Chip barcode
const Color lightBottomNavBg = Color(0xFFECF1F9); // Bottom Navigation Bar sfondo
const Color lightBottomSheetBg = Color(0xFFF5F8FD); // Bottom Sheet modalBackgroundColor
const Color lightScannerLegendBg = Color(0xFFECEFF4); // Legenda scanner

// Testi e icone neutre
const Color lightOnSurface = Color(0xFF141923); // Testo primario
const Color lightOnSurfaceVariant = Color(0xFF465061); // Testo secondario
const Color lightTextTertiary = Color(0xFF6E798B); // Hint / Placeholder / Terziario

// Bordi e outline
const Color lightOutline = Color(0xFF6C798E); // Switch off, divider forti
const Color lightCardPrimaryBorder = Color(0xFFDEE1E6); // Bordo opaco Card Principali
const Color lightCardSecondaryBorder = Color(0xFFE2E5EA); // Bordo opaco Card Secondarie / CTA bar
const Color lightButtonTertiaryBorder = Color(0x6B1E5FA8); // Bordo Bottoni Outlined rgba(30, 95, 168, 0.42)

// Brand Primary & Bottoni
const Color lightPrimary = Color(0xFF1E5FA8); // Blu brand principale
const Color lightOnPrimary = Color(0xFFFFFFFF); // Testo su bottone primario
const Color lightPrimaryContainer = Color(0xFFD3E4FF); // Cerchi icona brand, tile selezionate, invio barcode
const Color lightOnPrimaryContainer = Color(0xFF072347); // Testo su primary container

// Navigazione attiva (Bottom Nav pill)
const Color lightSecondaryContainer = Color(0xFFDAE6F7); // navSelectedBg
const Color lightOnSecondaryContainer = Color(0xFF153257); // navSelectedFg

// Stati Cibo — Sicuro (Safe / Adatto) — Indipendente dal brand blu
const Color lightStatusSafeText = Color(0xFF14632F);
const Color lightStatusSafeBg = Color(0xFFDFF0E4); // Sfondo pastello già pronto (100% opacity)
const Color lightStatusSafeContainer = Color(0xFFDFF0E4);
const Color lightStatusSafeLegendDot = Color(0xFF1E733B); // Pallino legenda pieno

// Stati Cibo — Incerto / Warning
const Color lightStatusUncertainText = Color(0xFFA35300);
const Color lightStatusUncertainBg = Color(0xFFF8ECDE); // Sfondo pastello già pronto (100% opacity)
const Color lightTertiaryContainer = Color(0xFFF8ECDE);
const Color lightOnTertiaryContainer = Color(0xFFA35300);
const Color lightStatusUncertainLegendDot = Color(0xFFB35C00); // Pallino legenda pieno

// Stati Cibo — Vietato / Errore
const Color lightError = Color(0xFFB0251E);
const Color lightErrorContainer = Color(0xFFFCE6E6); // Sfondo pastello già pronto (100% opacity)
const Color lightOnErrorContainer = Color(0xFFB0251E);
const Color lightStatusUnsafeText = Color(0xFFB0251E);
const Color lightStatusUnsafeBg = Color(0xFFFCE6E6);
const Color lightStatusUnsafeDestructiveBorder = Color(0x73B0251E); // rgba(176, 37, 30, 0.45)
const Color lightStatusUnsafeLegendDot = Color(0xFFB3261E); // Pallino legenda pieno

// Stati Cibo — Ignoto / Neutro
const Color lightStatusUnknownText = Color(0xFF495058);
const Color lightStatusUnknownBg = Color(0xFFE8ECF1); // Sfondo pastello già pronto (100% opacity)
const Color lightStatusUnknownLegendDot = Color(0xFF565B62); // Pallino legenda pieno

// Stati Cibo — Lattosio (Scollegato da Bottom Nav)
const Color lightLactoseText = Color(0xFF0E5A7A);
const Color lightLactoseBg = Color(0xFFDCF3FA); // Sfondo pastello già pronto (100% opacity)
const Color lightLactoseContainer = Color(0xFFDCF3FA);

// Scrim e Shadow
const Color lightScrim = Color(0x730E1622); // rgba(14, 22, 34, 0.45)
const Color lightShadow = Color(0x1A0A1E3C);


// ─── Dark Palette — Cobalt Mist Neutro Anti-Abbagliamento ─────────────────────
// Superfici e sfondi
const Color darkSurface = Color(0xFF0E1014); // Sfondo pagina antracite neutro
const Color darkCardBackground = Color(0xFF16191F); // Card principale grigio neutro
const Color darkCardSecondaryBg = Color(0xFF121419); // Container secondario / Legenda / Box note / Footer
const Color darkSurfaceContainerLow = Color(0xFF121419); // surfaceContainerLow
const Color darkSurfaceVariant = Color(0xFF21252E); // Input / Pillole ricerca / Campi form / Chip barcode
const Color darkBottomNavBg = Color(0xFF12151A); // Bottom Navigation Bar sfondo
const Color darkBottomSheetBg = Color(0xFF15181E); // Bottom Sheet modalBackgroundColor
const Color darkScannerLegendBg = Color(0xFF121419); // Legenda scanner

// Testi e icone neutre
const Color darkOnSurface = Color(0xFFDCE1E8); // Testo primario bianco morbido
const Color darkOnSurfaceVariant = Color(0xFF9BA3B0); // Testo secondario
const Color darkTextTertiary = Color(0xFF6E7685); // Hint / Placeholder / Terziario

// Bordi e outline
const Color darkOutline = Color(0xFF6C7482); // Switch off, divider forti
const Color darkCardPrimaryBorder = Color(0xFF32353A); // Bordo opaco Card Principali
const Color darkCardSecondaryBorder = Color(0xFF282B30); // Bordo opaco Card Secondarie / CTA bar
const Color darkButtonTertiaryBorder = Color(0x5C86B4EB); // Bordo Bottoni Outlined rgba(134, 180, 235, 0.36)

// Brand Primary & Bottoni
const Color darkPrimary = Color(0xFF86B4EB); // Per testi, link, switch, icone sezione
const Color darkOnPrimary = Color(0xFF0B2442);
const Color darkButtonPrimaryBg = Color(0xFF255C99); // Sfondo bottone primario pieno anti-abbagliamento
const Color darkButtonPrimaryFg = Color(0xFFEDF4FC); // Testo bottone primario pieno
const Color darkPrimaryContainer = Color(0xFF1C2C42); // Cerchi icona, card licenza, tile selezionate, invio barcode
const Color darkOnPrimaryContainer = Color(0xFFC7DCF7);

// Navigazione attiva (Bottom Nav pill)
const Color darkSecondaryContainer = Color(0xFF202836); // navSelectedBg
const Color darkOnSecondaryContainer = Color(0xFFCEDBF0); // navSelectedFg

// Stati Cibo — Sicuro (Safe / Adatto)
const Color darkStatusSafeText = Color(0xFF75CF94);
const Color darkStatusSafeBg = Color(0xFF152B1E); // Sfondo pastello già pronto (100% opacity)
const Color darkStatusSafeContainer = Color(0xFF152B1E);
const Color darkStatusPrimaryText = darkStatusSafeText; // Alias retrocompatibile

// Stati Cibo — Incerto / Warning
const Color darkStatusUncertainText = Color(0xFFEBA85E);
const Color darkStatusUncertainBg = Color(0xFF2E2214); // Sfondo pastello già pronto (100% opacity)
const Color darkTertiaryContainer = Color(0xFF2E2214);
const Color darkOnTertiaryContainer = Color(0xFFEBA85E);

// Stati Cibo — Vietato / Errore
const Color darkError = Color(0xFFEB827D);
const Color darkErrorContainer = Color(0xFF331A1C); // Sfondo pastello già pronto (100% opacity)
const Color darkOnErrorContainer = Color(0xFFEB827D);
const Color darkOnError = Color(0xFF1A0002); // Per bottone distruttivo pieno
const Color darkStatusUnsafeText = Color(0xFFEB827D);
const Color darkStatusUnsafeBg = Color(0xFF331A1C);
const Color darkStatusUnsafeDestructiveBorder = Color(0x6BEB827D); // rgba(235, 130, 125, 0.42)

// Stati Cibo — Ignoto / Neutro
const Color darkStatusUnknownText = Color(0xFFAEB6C2);
const Color darkStatusUnknownBg = Color(0xFF20242C); // Sfondo pastello già pronto (100% opacity)

// Stati Cibo — Lattosio (Scollegato da Bottom Nav)
const Color darkLactoseText = Color(0xFF75C4DE);
const Color darkLactoseBg = Color(0xFF142C38); // Sfondo pastello già pronto (100% opacity)
const Color darkLactoseContainer = Color(0xFF142C38);

// Scrim e Shadow
const Color darkScrim = Color(0xBD04060A); // rgba(4, 6, 10, 0.74)
const Color darkShadow = Color(0x47000000);

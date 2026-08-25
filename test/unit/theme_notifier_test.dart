// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Pure Unit Tests: Theme Notifier & App Theme

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gscanner/theme/theme_notifier.dart';
import 'package:gscanner/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1 – themeNotifier Reactive State
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 1 – themeNotifier Reactive State', () {
    tearDown(() {
      themeNotifier.value = ThemeMode.system;
    });

    test('initializes with ThemeMode.system default', () {
      expect(themeNotifier.value, ThemeMode.system);
    });

    test('notifies listeners when themeMode changes', () {
      int notifyCount = 0;
      void listener() => notifyCount++;

      themeNotifier.addListener(listener);

      themeNotifier.value = ThemeMode.dark;
      expect(themeNotifier.value, ThemeMode.dark);
      expect(notifyCount, 1);

      themeNotifier.value = ThemeMode.light;
      expect(themeNotifier.value, ThemeMode.light);
      expect(notifyCount, 2);

      themeNotifier.removeListener(listener);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2 – themeModeFromString & themeModeToString Conversions
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 2 – themeModeFromString & themeModeToString Conversions', () {
    test('themeModeFromString maps string values accurately', () {
      expect(themeModeFromString('light'), ThemeMode.light);
      expect(themeModeFromString('dark'), ThemeMode.dark);
      expect(themeModeFromString('system'), ThemeMode.system);
      expect(themeModeFromString('invalid_string'), ThemeMode.system);
      expect(themeModeFromString(''), ThemeMode.system);
    });

    test('themeModeToString maps ThemeMode enum accurately', () {
      expect(themeModeToString(ThemeMode.light), 'light');
      expect(themeModeToString(ThemeMode.dark), 'dark');
      expect(themeModeToString(ThemeMode.system), 'system');
    });

    test('round-trip conversion produces identical values', () {
      for (final mode in ThemeMode.values) {
        final stringVal = themeModeToString(mode);
        final convertedMode = themeModeFromString(stringVal);
        expect(convertedMode, mode);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3 – ThemeData Definitions & Palettes
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 3 – ThemeData Definitions & Palettes', () {
    test('lightTheme has Material3 enabled, light brightness, and correct primary colors', () {
      expect(lightTheme.useMaterial3, isTrue);
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.colorScheme.primary, lightPrimary);
      expect(lightTheme.scaffoldBackgroundColor, lightSurface);
      expect(lightTheme.cardColor, const Color(0xFFFFFFFF));
    });

    test('darkTheme has Material3 enabled, dark brightness, and correct primary colors', () {
      expect(darkTheme.useMaterial3, isTrue);
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.colorScheme.primary, darkPrimary);
      expect(darkTheme.scaffoldBackgroundColor, darkSurface);
      expect(darkTheme.cardColor, const Color(0xFF1E1E22));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4 – AppThemeContextExtension Methods
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 4 – AppThemeContextExtension Methods', () {
    testWidgets('provides correct colors and isDarkMode in light theme', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          themeMode: ThemeMode.light,
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedContext.isDarkMode, isFalse);
      expect(capturedContext.cardBackground, const Color(0xFFFFFFFF));
      expect(capturedContext.surfaceContainerLow, const Color(0xFFF5F3F7));
      expect(capturedContext.colorScheme.primary, lightPrimary);
    });

    testWidgets('provides correct colors and isDarkMode in dark theme', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          darkTheme: darkTheme,
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedContext.isDarkMode, isTrue);
      expect(capturedContext.cardBackground, const Color(0xFF1E1E22));
      expect(capturedContext.surfaceContainerLow, const Color(0xFF18181C));
      expect(capturedContext.colorScheme.primary, darkPrimary);
    });
  });
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/widgets.dart';

class UserSettings {
  final String? userId;
  final bool strictMode;
  final bool alertLactose;
  final bool warnAdditives;
  final bool autoSaveHistory;
  final String preferredLanguage;
  final String preferredTheme;
  final List<String> reportedBarcodes;

  static String get defaultSystemLanguage {
    try {
      const supportedLangs = ['it'];
      final sys =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      return supportedLangs.contains(sys) ? sys : 'it';
    } catch (_) {
      return 'it';
    }
  }

  UserSettings({
    this.userId,
    required this.strictMode,
    required this.alertLactose,
    required this.warnAdditives,
    required this.autoSaveHistory,
    required this.preferredLanguage,
    this.preferredTheme = 'system',
    this.reportedBarcodes = const [],
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['userId'],
      strictMode: json['strictMode'] ?? true,
      alertLactose: json['alertLactose'] ?? false,
      warnAdditives: json['warnAdditives'] ?? true,
      autoSaveHistory: json['autoSaveHistory'] ?? true,
      preferredLanguage: json['preferredLanguage'] ?? defaultSystemLanguage,
      preferredTheme: json['preferredTheme'] ?? 'system',
      reportedBarcodes: List<String>.from(json['reportedBarcodes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'strictMode': strictMode,
      'alertLactose': alertLactose,
      'warnAdditives': warnAdditives,
      'autoSaveHistory': autoSaveHistory,
      'preferredLanguage': preferredLanguage,
      'preferredTheme': preferredTheme,
      'reportedBarcodes': reportedBarcodes,
    };
  }
}

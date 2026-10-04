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
      userId: json['userId'] ?? json['user_id'],
      strictMode: json['strictMode'] ?? json['strict_mode'] ?? true,
      alertLactose: json['alertLactose'] ?? json['alert_lactose'] ?? false,
      warnAdditives: json['warnAdditives'] ?? json['warn_additives'] ?? true,
      autoSaveHistory: json['autoSaveHistory'] ?? json['auto_save_history'] ?? true,
      preferredLanguage: json['preferredLanguage'] ?? json['preferred_language'] ?? defaultSystemLanguage,
      preferredTheme: json['preferredTheme'] ?? json['preferred_theme'] ?? 'system',
      reportedBarcodes: List<String>.from(json['reportedBarcodes'] ?? json['reported_barcodes'] ?? []),
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

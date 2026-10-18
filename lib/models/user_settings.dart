// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/widgets.dart';
import 'offline_db_tier.dart';

class UserSettings {
  final String? userId;
  final bool strictMode;
  final bool alertLactose;
  final bool warnAdditives;
  final bool autoSaveHistory;
  final String preferredLanguage;
  final String preferredTheme;
  final List<String> reportedBarcodes;
  final OfflineDbTier offlineDbTier;
  final int? offlineDbLastSyncedAt;
  final int? updatedAt;

  /// Restituisce `true` se il database offline è abilitato (tier != none) e l'ultimo sync risale a oltre 30 giorni fa (o mai eseguito).
  bool get isOfflineDbStale {
    if (offlineDbTier == OfflineDbTier.none) return false;
    if (offlineDbLastSyncedAt == null || offlineDbLastSyncedAt! <= 0) return true;
    final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const thirtyDaysInSeconds = 30 * 86400;
    return (nowEpoch - offlineDbLastSyncedAt!) >= thirtyDaysInSeconds;
  }

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
    this.offlineDbTier = OfflineDbTier.none,
    this.offlineDbLastSyncedAt,
    this.updatedAt,
  });

  static const _unsetSentinel = Object();

  UserSettings copyWith({
    String? userId,
    bool? strictMode,
    bool? alertLactose,
    bool? warnAdditives,
    bool? autoSaveHistory,
    String? preferredLanguage,
    String? preferredTheme,
    List<String>? reportedBarcodes,
    OfflineDbTier? offlineDbTier,
    Object? offlineDbLastSyncedAt = _unsetSentinel,
    Object? updatedAt = _unsetSentinel,
  }) {
    final int? resolvedLastSyncedAt = identical(offlineDbLastSyncedAt, _unsetSentinel)
        ? this.offlineDbLastSyncedAt
        : (offlineDbLastSyncedAt as int?);

    final int? resolvedUpdatedAt = identical(updatedAt, _unsetSentinel)
        ? this.updatedAt
        : (updatedAt as int?);

    return UserSettings(
      userId: userId ?? this.userId,
      strictMode: strictMode ?? this.strictMode,
      alertLactose: alertLactose ?? this.alertLactose,
      warnAdditives: warnAdditives ?? this.warnAdditives,
      autoSaveHistory: autoSaveHistory ?? this.autoSaveHistory,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      preferredTheme: preferredTheme ?? this.preferredTheme,
      reportedBarcodes: reportedBarcodes ?? this.reportedBarcodes,
      offlineDbTier: offlineDbTier ?? this.offlineDbTier,
      offlineDbLastSyncedAt: resolvedLastSyncedAt,
      updatedAt: resolvedUpdatedAt,
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['userId'],
      strictMode: json['strictMode'] ?? true,
      alertLactose: json['alertLactose'] ?? false,
      warnAdditives: json['warnAdditives'] ?? true,
      autoSaveHistory: json['autoSaveHistory'] ?? true,
      preferredLanguage: json['preferredLanguage'] ?? defaultSystemLanguage,
      preferredTheme: json['preferredTheme'] ?? 'system',
      reportedBarcodes: List<String>.from(json['reportedBarcodes'] ?? const []),
      offlineDbTier: OfflineDbTierExtension.fromKey(json['offlineDbTier']),
      offlineDbLastSyncedAt: json['offlineDbLastSyncedAt'],
      updatedAt: json['updatedAt'],
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
      'offlineDbTier': offlineDbTier.key,
      'offlineDbLastSyncedAt': offlineDbLastSyncedAt,
      'updatedAt': updatedAt,
    };
  }
}

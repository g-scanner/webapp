// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/models.dart';
import '../../core/theme/theme.dart';
import '../../services/database/local_cache_service.dart';
import '../../services/database/history_db_service.dart';
import '../../services/database/daos/scan_history_dao.dart';
import 'sections/sections.dart';
import 'sheets/sheets.dart';
import 'utils/storage_utils.dart';

class SettingsPanel extends StatefulWidget {
  final UserSettings settings;
  final Future<void> Function(UserSettings, {bool isOfflineDbChange}) onSettingsChange;
  final Future<void> Function() onResetDB;
  final Future<void> Function() onClearHistory;
  final Future<void> Function()? onClearProductCache;
  final FirebaseAuth? firebaseAuth;

  const SettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChange,
    required this.onResetDB,
    required this.onClearHistory,
    this.onClearProductCache,
    this.firebaseAuth,
  });

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  FirebaseAuth get _auth => widget.firebaseAuth ?? FirebaseAuth.instance;

  int _cacheCount = 0;
  int _historyCount = 0;
  int _cacheSizeBytes = 0;
  int _historySizeBytes = 0;

  // Variabile per l'aggiornamento UI istantaneo ("Optimistic Update")
  String? _optimisticDisplayName;

  @override
  void initState() {
    super.initState();
    _loadStorageMetrics();
  }

  Future<void> _loadStorageMetrics() async {
    try {
      final userId = widget.settings.userId ?? HistoryDbService.getUserId(_auth);
      final cCount = await LocalCacheService.getProductsCount();
      final cSize = await LocalCacheService.getProductsSizeBytes();
      final hCount = await const ScanHistoryDao().getHistoryCount(userId);
      final hSize = await const ScanHistoryDao().getHistorySizeBytes(userId);
      if (mounted) {
        setState(() {
          _cacheCount = cCount;
          _cacheSizeBytes = cSize;
          _historyCount = hCount;
          _historySizeBytes = hSize;
        });
      }
    } catch (e) {
      debugPrint("Error loading storage metrics: $e");
    }
  }

  void _triggerToast(String msg) {
    if (!mounted) return;
    final colorScheme = context.colorScheme;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colorScheme.inverseSurface,
        content: Row(
          children: [
            Icon(Icons.info_outline, color: colorScheme.onInverseSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  color: colorScheme.onInverseSurface,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleToggle(bool value, String key) async {
    final updated = widget.settings.copyWith(
      strictMode: key == 'strictMode' ? value : widget.settings.strictMode,
      alertLactose: key == 'alertLactose' ? value : widget.settings.alertLactose,
      warnAdditives: key == 'warnAdditives' ? value : widget.settings.warnAdditives,
    );
    await widget.onSettingsChange(updated);
    _triggerToast("common.status.preferencesSaved".tr());
  }

  Future<void> _handleLanguageChange(String newLang) async {
    if (newLang == widget.settings.preferredLanguage) {
      return;
    }

    final updated = widget.settings.copyWith(
      preferredLanguage: newLang,
    );
    await widget.onSettingsChange(updated);
    if (mounted) context.setLocale(Locale(newLang));
    _triggerToast("common.status.preferencesSaved".tr());
  }

  Future<void> _handleThemeChange(String newTheme) async {
    if (newTheme == widget.settings.preferredTheme) {
      return;
    }

    final updated = widget.settings.copyWith(
      preferredTheme: newTheme,
    );
    await widget.onSettingsChange(updated);
    _triggerToast("common.status.preferencesSaved".tr());
  }

  Future<void> _handleClearHistory() async {
    try {
      await widget.onClearHistory();
      await _loadStorageMetrics();
      _triggerToast("common.status.historyClearedSuccess".tr());
    } catch (_) {
      // Errore già notificato con SnackBar
    }
  }

  Future<void> _handleClearProductCache() async {
    try {
      await widget.onClearProductCache?.call();
      await _loadStorageMetrics();
      _triggerToast("common.status.productsClearedSuccess".tr());
    } catch (_) {
      // Errore già gestito
    }
  }

  String _getOfflineDbSubtitle() {
    if (widget.settings.offlineDbTier == OfflineDbTier.none) {
      return "settings.offlineDb.disabledStatus".tr();
    }
    final key = widget.settings.offlineDbTier.key;
    final packName = "settings.offlineDb.packages.$key.title".tr();
    final packSize = "settings.offlineDb.packages.$key.downloadSize".tr();
    final installedStatus = "settings.offlineDb.installedStatus".tr();
    return "$packName • $packSize ($installedStatus)";
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "settings.title".tr(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: kIsWeb ? FontWeight.w600 : FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "settings.subtitle".tr(),
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // 0. Account Utente Unificato M3
          SectionHeader(
            icon: Icons.attribution_rounded,
            title: "settings.sectionTitles.account".tr(),
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          AccountSection(
            auth: _auth,
            optimisticDisplayName: _optimisticDisplayName,
            onTriggerToast: _triggerToast,
            onUpdateOptimisticDisplayName: (newName) {
              setState(() => _optimisticDisplayName = newName);
            },
          ),

          const SizedBox(height: 40),

          // 1. Regole di Analisi
          SectionHeader(
            icon: Icons.tune,
            title: "settings.sectionTitles.analysisRules".tr(),
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),

          AnalysisRulesSection(
            warnAdditives: widget.settings.warnAdditives,
            strictMode: widget.settings.strictMode,
            alertLactose: widget.settings.alertLactose,
            onToggle: _handleToggle,
          ),

          const SizedBox(height: 40),

          // 2. Opzioni di Visualizzazione: Tema
          SectionHeader(
            icon: Icons.palette_outlined,
            title: "settings.sectionTitles.appearance".tr(),
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: AppearanceSection(
              preferredTheme: widget.settings.preferredTheme,
              onThemeChange: _handleThemeChange,
            ),
          ),

          const SizedBox(height: 40),

          // 3. Opzioni di Visualizzazione: Lingua
          SectionHeader(
            icon: Icons.translate_outlined,
            title: "settings.sectionTitles.language".tr(),
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: LanguageSection(
              preferredLanguage: widget.settings.preferredLanguage,
              onLanguageChange: _handleLanguageChange,
            ),
          ),

          const SizedBox(height: 40),

          // 4. Sezione Principale: Archiviazione & Dati
          SectionHeader(
            icon: Icons.data_usage,
            title: "settings.sectionTitles.storageAndData".tr(),
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),

          Material(
            color: cardBg,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                SettingsNavigationItem(
                  title: "settings.offlineDb.title".tr(),
                  subtitle: Text(
                    _getOfflineDbSubtitle(),
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  isFirst: true,
                  isLast: false,
                  onTap: () {
                    showOfflineDatabaseSheet(
                      context: context,
                      settings: widget.settings,
                      onSettingsChange: widget.onSettingsChange,
                      onDatabaseUpdated: () {
                        setState(() {});
                      },
                    );
                  },
                ),
                SettingsNavigationItem(
                  title: "settings.localData.title".tr(),
                  subtitle: Text(
                    "settings.localData.used".tr(
                      args: [formatBytes(_cacheSizeBytes + _historySizeBytes)],
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  isFirst: false,
                  isLast: true,
                  onTap: () {
                    showStorageHistorySheet(
                      context: context,
                      onClearHistory: _handleClearHistory,
                      onClearProductCache: widget.onClearProductCache != null
                          ? _handleClearProductCache
                          : null,
                      historyCount: _historyCount,
                      cacheCount: _cacheCount,
                      historySizeBytes: _historySizeBytes,
                      cacheSizeBytes: _cacheSizeBytes,
                      onStorageUpdated: _loadStorageMetrics,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // 5. Sezione Legale
          SectionHeader(
            icon: Icons.info_outline_rounded,
            title: "settings.sectionTitles.legalInfo".tr(),
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),

          const LegalSection(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

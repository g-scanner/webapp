// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/models.dart';
import '../../core/theme/theme.dart';
import 'sections/sections.dart';
import 'dialogs/dialogs.dart';

class SettingsPanel extends StatefulWidget {
  final UserSettings settings;
  final Future<void> Function(UserSettings) onSettingsChange;
  final Future<void> Function() onResetDB;
  final Future<void> Function() onClearHistory;
  final FirebaseAuth? firebaseAuth;

  const SettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChange,
    required this.onResetDB,
    required this.onClearHistory,
    this.firebaseAuth,
  });

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  FirebaseAuth get _auth => widget.firebaseAuth ?? FirebaseAuth.instance;
  bool _clearing = false;

  // Variabile per l'aggiornamento UI istantaneo ("Optimistic Update")
  String? _optimisticDisplayName;

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
    final updated = UserSettings(
      userId: widget.settings.userId,
      strictMode: key == 'strictMode' ? value : widget.settings.strictMode,
      alertLactose: key == 'alertLactose' ? value : widget.settings.alertLactose,
      warnAdditives: key == 'warnAdditives' ? value : widget.settings.warnAdditives,
      autoSaveHistory: widget.settings.autoSaveHistory,
      preferredLanguage: widget.settings.preferredLanguage,
      preferredTheme: widget.settings.preferredTheme,
      reportedBarcodes: widget.settings.reportedBarcodes,
    );
    await widget.onSettingsChange(updated);
    _triggerToast("common.status.preferencesSaved".tr());
  }

  Future<void> _handleLanguageChange(String newLang) async {
    if (newLang == widget.settings.preferredLanguage) {
      return;
    }

    final updated = UserSettings(
      userId: widget.settings.userId,
      strictMode: widget.settings.strictMode,
      alertLactose: widget.settings.alertLactose,
      warnAdditives: widget.settings.warnAdditives,
      autoSaveHistory: widget.settings.autoSaveHistory,
      preferredLanguage: newLang,
      preferredTheme: widget.settings.preferredTheme,
      reportedBarcodes: widget.settings.reportedBarcodes,
    );
    await widget.onSettingsChange(updated);
    // Aggiorna la locale UI in sync con la preferenza
    if (mounted) context.setLocale(Locale(newLang));
    _triggerToast("Preferenze salvate ed applicate!");
  }

  Future<void> _handleThemeChange(String newTheme) async {
    if (newTheme == widget.settings.preferredTheme) {
      return;
    }

    final updated = UserSettings(
      userId: widget.settings.userId,
      strictMode: widget.settings.strictMode,
      alertLactose: widget.settings.alertLactose,
      warnAdditives: widget.settings.warnAdditives,
      autoSaveHistory: widget.settings.autoSaveHistory,
      preferredLanguage: widget.settings.preferredLanguage,
      preferredTheme: newTheme,
      reportedBarcodes: widget.settings.reportedBarcodes,
    );
    await widget.onSettingsChange(updated);
    _triggerToast("Preferenze salvate ed applicate!");
  }

  Future<void> _handleClearHistory() async {
    final confirm = await showClearHistoryDialog(context);

    if (confirm == true) {
      setState(() => _clearing = true);
      try {
        await widget.onClearHistory();
        _triggerToast("common.status.historyClearedSuccess".tr());
      } finally {
        if (mounted) setState(() => _clearing = false);
      }
    }
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

          // 4. Sezione Dati & Cronologia
          SectionHeader(
            icon: Icons.data_usage,
            title: "settings.sectionTitles.dataAndHistory".tr(),
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),

          DataHistorySection(
            isClearing: _clearing,
            onClearHistoryTap: _handleClearHistory,
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

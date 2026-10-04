// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/utils.dart';
import '../../models/models.dart';

/// Dati anonimi rilevati, suddivisi per categoria.
class AnonymousDataSummary {
  final List<ScanHistoryItem> history;
  final List<ProductReport> reports;
  final bool hasSettings;

  const AnonymousDataSummary({
    this.history = const [],
    this.reports = const [],
    this.hasSettings = false,
  });

  bool get hasHistory => history.isNotEmpty;
  bool get hasReports => reports.isNotEmpty;
  int get categoryCount =>
      (hasHistory ? 1 : 0) + (hasReports ? 1 : 0) + (hasSettings ? 1 : 0);
}

/// Rappresenta le categorie scelte dall'utente per la sincronizzazione.
class SyncChoices {
  final bool syncHistory;
  final bool syncReports;
  final bool syncSettings;

  const SyncChoices({
    this.syncHistory = true,
    this.syncReports = true,
    this.syncSettings = true,
  });

  bool get hasAny => syncHistory || syncReports || syncSettings;
}

typedef SyncDecisionCallback = void Function(
  bool wantToSync, [
  SyncChoices choices,
]);

/// Schermata di sincronizzazione dati locali anonimi → profilo cloud.
///
/// Mostra solo le categorie per cui esistono effettivamente dati e
/// consente all'utente di scegliere quali sincronizzare o scartare tutto.
class SyncDataScreen extends StatefulWidget {
  final SyncDecisionCallback onDecision;
  final AnonymousDataSummary dataSummary;
  final bool useResponsiveWrapper;

  const SyncDataScreen({
    super.key,
    required this.onDecision,
    required this.dataSummary,
    this.useResponsiveWrapper = true,
  });

  @override
  State<SyncDataScreen> createState() => _SyncDataScreenState();
}

class _SyncDataScreenState extends State<SyncDataScreen> {
  late bool _syncHistory;
  late bool _syncReports;
  late bool _syncSettings;

  @override
  void initState() {
    super.initState();
    _syncHistory = widget.dataSummary.hasHistory;
    _syncReports = widget.dataSummary.hasReports;
    _syncSettings = widget.dataSummary.hasSettings;
  }

  int get _selectedCount =>
      (_syncHistory ? 1 : 0) + (_syncReports ? 1 : 0) + (_syncSettings ? 1 : 0);

  int get _totalCount => widget.dataSummary.categoryCount;

  bool get _allSelected => _selectedCount == _totalCount;

  void _toggleAll() {
    setState(() {
      final newVal = !_allSelected;
      if (widget.dataSummary.hasHistory) _syncHistory = newVal;
      if (widget.dataSummary.hasReports) _syncReports = newVal;
      if (widget.dataSummary.hasSettings) _syncSettings = newVal;
    });
  }

  Future<void> _showDiscardConfirmation() async {
    final colorScheme = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_rounded,
            color: colorScheme.onErrorContainer,
            size: 28,
          ),
        ),
        title: Text(
          "sync.localDataFound.discardConfirmTitle".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        content: Text(
          "sync.localDataFound.discardConfirmBody".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  "sync.localDataFound.discardConfirmAction".tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  "common.actions.cancel".tr(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result == true) {
      widget.onDecision(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final summary = widget.dataSummary;

    final scaffold = Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "common.appName".tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // ── Hero Icon — cerchi concentrici ──
                      _buildHeroIcon(colorScheme),
                      const SizedBox(height: 24),

                      // ── Titolo e descrizione ──
                      Text(
                        "sync.localDataFound.title".tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "sync.localDataFound.body".tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Card contenitore categorie ──
                      _buildCategoryCard(colorScheme, summary),
                      const SizedBox(height: 24),

                      const Spacer(),

                      // ── Azioni in basso ──
                      _buildActions(colorScheme),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    if (widget.useResponsiveWrapper) {
      return ResponsiveMaxCardWidth(maxWidth: 500, child: scaffold);
    }
    return scaffold;
  }

  Widget _buildHeroIcon(ColorScheme colorScheme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.cloud_sync_rounded,
        size: 36,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildCategoryCard(ColorScheme colorScheme, AnonymousDataSummary summary) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header stile SectionCard ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
            child: Row(
              children: [
                Icon(
                  Icons.sync_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "sync.localDataFound.toSync".tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_totalCount > 1)
                  TextButton(
                    onPressed: _toggleAll,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      _allSelected
                          ? "sync.localDataFound.deselectAll".tr()
                          : "sync.localDataFound.selectAll".tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Tile list ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              children: [
                if (summary.hasHistory)
                  _buildTile(
                    icon: Icons.history_rounded,
                    title: "common.navigation.history".tr(),
                    subtitle: summary.history.length == 1
                        ? "sync.localDataFound.historySubtitleOne".tr(
                            namedArgs: {'count': '${summary.history.length}'},
                          )
                        : "sync.localDataFound.historySubtitleOther".tr(
                            namedArgs: {'count': '${summary.history.length}'},
                          ),
                    checked: _syncHistory,
                    onChanged: (v) => setState(() => _syncHistory = v),
                    colorScheme: colorScheme,
                  ),
                if (summary.hasReports)
                  _buildTile(
                    icon: Icons.flag_rounded,
                    title: "common.navigation.reports".tr(),
                    subtitle: summary.reports.length == 1
                        ? "sync.localDataFound.reportsSubtitleOne".tr(
                            namedArgs: {'count': '${summary.reports.length}'},
                          )
                        : "sync.localDataFound.reportsSubtitleOther".tr(
                            namedArgs: {'count': '${summary.reports.length}'},
                          ),
                    checked: _syncReports,
                    onChanged: (v) => setState(() => _syncReports = v),
                    colorScheme: colorScheme,
                  ),
                if (summary.hasSettings)
                  _buildTile(
                    icon: Icons.tune_rounded,
                    title: "common.navigation.settings".tr(),
                    subtitle: "sync.localDataFound.settingsSubtitle".tr(),
                    checked: _syncSettings,
                    onChanged: (v) => setState(() => _syncSettings = v),
                    colorScheme: colorScheme,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool checked,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: checked
              ? colorScheme.primaryContainer.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: checked
                ? colorScheme.primary.withValues(alpha: 0.25)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Avatar circolare
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: checked
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: checked ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),

            // Testi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Checkbox circolare
            _buildCircularCheckbox(checked, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularCheckbox(bool checked, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? colorScheme.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: checked
            ? null
            : Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                width: 1.5,
              ),
      ),
      child: checked
          ? Icon(Icons.check, size: 14, color: colorScheme.onPrimary)
          : null,
    );
  }

  Widget _buildActions(ColorScheme colorScheme) {
    final bool hasSelection = _selectedCount > 0;

    return Column(
      children: [
        // Pulsante primario — Sincronizza
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: hasSelection
                ? () => widget.onDecision(
                      true,
                      SyncChoices(
                        syncHistory: _syncHistory,
                        syncReports: _syncReports,
                        syncSettings: _syncSettings,
                      ),
                    )
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.3),
              disabledForegroundColor: colorScheme.onPrimary.withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            icon: Icon(
              hasSelection ? Icons.cloud_upload_outlined : Icons.block,
              size: 20,
            ),
            label: Text(
              hasSelection
                  ? "sync.localDataFound.merge".tr()
                  : "sync.localDataFound.noneSelected".tr(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Pulsante secondario — Elimina
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton.icon(
            onPressed: _showDiscardConfirmation,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            label: Text(
              "sync.localDataFound.discard".tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

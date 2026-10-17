// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/models.dart';
import '../../../services/database/offline_db_service.dart';
import '../../../services/database/offline_db_sync_service.dart';

/// Sezione impostazioni per la configurazione e sincronizzazione del Database Offline.
class OfflineDatabaseSection extends StatefulWidget {
  final UserSettings settings;
  final Future<void> Function(UserSettings) onSettingsChange;

  const OfflineDatabaseSection({
    super.key,
    required this.settings,
    required this.onSettingsChange,
  });

  @override
  State<OfflineDatabaseSection> createState() => _OfflineDatabaseSectionState();
}

class _OfflineDatabaseSectionState extends State<OfflineDatabaseSection> {
  OfflineSyncProgress _syncProgress = const OfflineSyncProgress.idle();
  StreamSubscription<OfflineSyncProgress>? _syncSubscription;
  int _dbSizeBytes = 0;
  bool _isLoadingSize = true;
  bool _isDbInstalled = false;
  OfflineDbTier? _downloadingTier;

  @override
  void initState() {
    super.initState();
    _loadDatabaseSize();
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDatabaseSize() async {
    final size = await OfflineDbService.getDatabaseSizeBytes();
    final installed = await OfflineDbService.isDatabaseInstalled();
    if (mounted) {
      setState(() {
        _dbSizeBytes = size;
        _isDbInstalled = installed;
        _isLoadingSize = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String _formatLastSync(int? epochSeconds) {
    if (epochSeconds == null || epochSeconds <= 0) {
      return 'settings.offlineDatabase.neverSynced'.tr();
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  Future<void> _handleTierChange(OfflineDbTier newTier) async {
    if (_syncProgress.isInProgress) return;
    if (newTier == widget.settings.offlineDbTier) return;

    if (newTier == OfflineDbTier.none) {
      final confirm = await _showDeleteConfirmDialog();
      if (confirm == true) {
        await _deleteDatabase();
      }
      return;
    }

    _startSync(newTier);
  }

  void _startSync(OfflineDbTier tier) {
    _syncSubscription?.cancel();
    setState(() {
      _downloadingTier = tier;
      _syncProgress = const OfflineSyncProgress(
        step: OfflineSyncStep.checkingVersion,
        progress: 0.05,
      );
    });

    _syncSubscription = OfflineDbSyncService.syncDatabase(
      tier: tier,
      currentLastSyncedAt: widget.settings.offlineDbLastSyncedAt,
    ).listen(
      (progress) async {
        if (!mounted) return;
        setState(() {
          _syncProgress = progress;
        });

        if (progress.step == OfflineSyncStep.completed) {
          final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final updated = widget.settings.copyWith(
            offlineDbTier: tier,
            offlineDbLastSyncedAt: nowEpoch,
          );
          await widget.onSettingsChange(updated);
          if (mounted) {
            setState(() {
              _downloadingTier = null;
            });
          }
          await _loadDatabaseSize();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('settings.offlineDatabase.syncSuccess'.tr()),
                backgroundColor: context.colorScheme.primary,
              ),
            );
          }
        } else if (progress.step == OfflineSyncStep.error) {
          debugPrint("OfflineDatabaseSection download error: ${progress.errorMessage}");
          if (mounted) {
            setState(() {
              _downloadingTier = null;
            });
          }
          await _loadDatabaseSize();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('settings.offlineDatabase.downloadError'.tr()),
                backgroundColor: context.colorScheme.error,
              ),
            );
          }
        }
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _downloadingTier = null;
          _syncProgress = OfflineSyncProgress.error(err.toString());
        });
        _loadDatabaseSize();
      },
    );
  }

  Future<void> _deleteDatabase() async {
    await OfflineDbService.deleteDatabaseFile();
    final updated = widget.settings.copyWith(
      offlineDbTier: OfflineDbTier.none,
      offlineDbLastSyncedAt: null,
    );
    await widget.onSettingsChange(updated);
    await _loadDatabaseSize();
  }

  Future<bool?> _showDeleteConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('settings.offlineDatabase.deleteConfirmTitle'.tr()),
        content: Text('settings.offlineDatabase.deleteConfirmBody'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.actions.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: ctx.colorScheme.error,
            ),
            child: Text('common.actions.delete'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;
    final selectedTier = _downloadingTier ?? widget.settings.offlineDbTier;
    final isPanelVisible = _isDbInstalled || _syncProgress.isInProgress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'settings.offlineDatabase.subtitle'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Dropdown Tier
          SettingsDropdownTile<OfflineDbTier>(
            title: 'settings.offlineDatabase.tierSelectionTitle'.tr(),
            subtitle: _getTierLabel(selectedTier),
            tooltip: 'settings.offlineDatabase.tierSelectionTitle'.tr(),
            selectedValue: selectedTier,
            options: [
              SettingsDropdownOption(
                value: OfflineDbTier.none,
                label: 'settings.offlineDatabase.tierNone'.tr(),
              ),
              SettingsDropdownOption(
                value: OfflineDbTier.tier1,
                label: 'settings.offlineDatabase.tier1'.tr(),
              ),
              SettingsDropdownOption(
                value: OfflineDbTier.tier2,
                label: 'settings.offlineDatabase.tier2'.tr(),
              ),
              SettingsDropdownOption(
                value: OfflineDbTier.tier3,
                label: 'settings.offlineDatabase.tier3'.tr(),
              ),
            ],
            onSelected: _syncProgress.isInProgress ? (_) {} : _handleTierChange,
          ),

          if (isPanelVisible) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Metadati: Ultimo Sync e Spazio Disco
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'settings.offlineDatabase.lastSyncLabel'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatLastSync(widget.settings.offlineDbLastSyncedAt),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'settings.offlineDatabase.sizeOnDiskLabel'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _isLoadingSize ? '...' : _formatBytes(_dbSizeBytes),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Barra di progresso sync (se attivo)
            if (_syncProgress.isInProgress) ...[
              LinearProgressIndicator(
                value: _syncProgress.progress > 0 ? _syncProgress.progress : null,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'settings.offlineDatabase.syncing'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Azioni: Aggiorna Ora & Elimina
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _syncProgress.isInProgress ||
                            widget.settings.offlineDbTier == OfflineDbTier.none
                        ? null
                        : () => _startSync(widget.settings.offlineDbTier),
                    icon: const Icon(Icons.sync, size: 18),
                    label: Text('settings.offlineDatabase.syncNow'.tr()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _syncProgress.isInProgress
                      ? null
                      : () async {
                          final confirm = await _showDeleteConfirmDialog();
                          if (confirm == true) {
                            await _deleteDatabase();
                          }
                        },
                  tooltip: 'settings.offlineDatabase.deleteDatabase'.tr(),
                  icon: Icon(
                    Icons.delete_outline,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getTierLabel(OfflineDbTier tier) => tier.label;
}

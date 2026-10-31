// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../models/models.dart';
import '../../../services/database/offline_db_service.dart';
import '../../../services/database/settings_db_service.dart';
import '../../../services/database/offline_db_sync_service.dart';
import '../../../core/network/connectivity_helper.dart';
import '../../../core/widgets/widgets.dart';

/// Mostra il Modal Bottom Sheet "Database Offline" in puro stile M3.
void showOfflineDatabaseSheet({
  required BuildContext context,
  required UserSettings settings,
  required Future<void> Function(UserSettings, {bool isOfflineDbChange})
  onSettingsChange,
  VoidCallback? onDatabaseUpdated,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: false,
    constraints: const BoxConstraints(maxWidth: 500),
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final double sheetHeight = MediaQuery.of(ctx).size.height * 0.85;
      return Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: ctx.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: _OfflineDatabaseSheetContent(
          settings: settings,
          onSettingsChange: onSettingsChange,
          onDatabaseUpdated: onDatabaseUpdated,
        ),
      );
    },
  );
}

class _OfflineDatabaseSheetContent extends StatefulWidget {
  final UserSettings settings;
  final Future<void> Function(UserSettings, {bool isOfflineDbChange})
  onSettingsChange;
  final VoidCallback? onDatabaseUpdated;

  const _OfflineDatabaseSheetContent({
    required this.settings,
    required this.onSettingsChange,
    this.onDatabaseUpdated,
  });

  @override
  State<_OfflineDatabaseSheetContent> createState() =>
      _OfflineDatabaseSheetContentState();
}

class _OfflineDatabaseSheetContentState
    extends State<_OfflineDatabaseSheetContent> {
  late UserSettings _currentSettings;
  late OfflineDbTier _installedTier;
  late String _previewPack;

  OfflineDbTier _rollbackTier = OfflineDbTier.none;
  int? _rollbackLastSyncedAt;
  OfflineDbTier? _downloadingTier;

  StreamSubscription<OfflineSyncProgress>? _syncSubscription;
  StreamSubscription<UserSettings>? _settingsSubscription;
  OfflineSyncProgress _syncProgress = const OfflineSyncProgress(
    step: OfflineSyncStep.idle,
    progress: 0.0,
  );

  static const List<String> _packageKeys = [
    'gluten_free',
    'euro_core',
    'america_core',
    'global_top',
  ];

  void _initStateInternal() {
    _currentSettings = widget.settings;
    _installedTier = _currentSettings.offlineDbTier;
    _previewPack = _installedTier != OfflineDbTier.none
        ? _installedTier.key
        : _getDefaultTierKey();
  }

  @override
  void initState() {
    super.initState();
    _initStateInternal();

    _settingsSubscription = SettingsDbService.settingsStream.listen((newSettings) {
      if (!mounted) return;
      setState(() {
        _currentSettings = newSettings;
        _installedTier = newSettings.offlineDbTier;
        if (_previewPack.isEmpty || _previewPack == 'euro_core') {
          _previewPack = _installedTier != OfflineDbTier.none
              ? _installedTier.key
              : _getDefaultTierKey();
        }
      });
      widget.onDatabaseUpdated?.call();
    });

    OfflineDbSyncService.syncProgressNotifier.addListener(_onGlobalSyncProgress);
    final currentProgress = OfflineDbSyncService.syncProgressNotifier.value;
    if (currentProgress.isInProgress && _syncSubscription == null) {
      _syncProgress = currentProgress;
      _downloadingTier = OfflineDbSyncService.currentSyncingTier;
    }
  }

  @override
  void dispose() {
    OfflineDbSyncService.syncProgressNotifier.removeListener(_onGlobalSyncProgress);
    _settingsSubscription?.cancel();
    _syncSubscription?.cancel();
    super.dispose();
  }

  void _onGlobalSyncProgress() {
    if (!mounted) return;
    final progress = OfflineDbSyncService.syncProgressNotifier.value;
    if (_syncSubscription != null) return;

    setState(() {
      _syncProgress = progress;
      if (progress.isInProgress) {
        _downloadingTier = OfflineDbSyncService.currentSyncingTier;
      } else {
        _downloadingTier = null;
      }
    });

    if (progress.step == OfflineSyncStep.completed) {
      _reloadStateFromStorage();
    }
  }

  Future<void> _reloadStateFromStorage() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final latest = await SettingsDbService.getLocalSettings();
    final installed = await OfflineDbService.getInstalledTier() ?? OfflineDbTier.none;
    if (!mounted) return;
    setState(() {
      _currentSettings = latest;
      _installedTier = installed;
      if (_installedTier != OfflineDbTier.none) {
        _previewPack = _installedTier.key;
      }
    });
    widget.onDatabaseUpdated?.call();
  }

  OfflineDbTier _keyToTier(String key) {
    return OfflineDbTierExtension.fromKey(key);
  }

  String _getDefaultTierKey() {
    try {
      final locale = View.of(context).platformDispatcher.locale;
      final country = (locale.countryCode ?? '').toUpperCase();
      const americanCountries = [
        'US',
        'CA',
        'MX',
        'BR',
        'AR',
        'CL',
        'CO',
        'PE',
        'UY',
        'PY',
        'BO',
        'EC',
        'VE',
      ];
      if (americanCountries.contains(country)) {
        return 'america_core';
      }
    } catch (_) {}
    return 'euro_core';
  }

  void _triggerSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    showAppSnackBar(context, message, isError: isError);
  }

  void _startSync(OfflineDbTier tier, {int? explicitLastSyncedAt}) {
    _syncSubscription?.cancel();
    _rollbackTier = _installedTier;
    _rollbackLastSyncedAt = _currentSettings.offlineDbLastSyncedAt;
    _downloadingTier = tier;

    setState(() {
      _syncProgress = const OfflineSyncProgress(
        step: OfflineSyncStep.checkingVersion,
        progress: 0.05,
      );
    });

    final effectiveLastSyncedAt =
        explicitLastSyncedAt ?? _currentSettings.offlineDbLastSyncedAt;

    _syncSubscription =
        OfflineDbSyncService.syncDatabase(
          tier: tier,
          currentLastSyncedAt: effectiveLastSyncedAt,
        ).listen(
          (progress) async {
            if (!mounted) return;
            setState(() {
              _syncProgress = progress;
            });

            if (progress.step == OfflineSyncStep.completed) {
              await OfflineDbService.setInstalledTier(tier);
              final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
              final updated = _currentSettings.copyWith(
                offlineDbTier: tier,
                offlineDbLastSyncedAt: nowEpoch,
              );
              _currentSettings = updated;
              await widget.onSettingsChange(updated, isOfflineDbChange: true);

              if (mounted) {
                setState(() {
                  _installedTier = tier;
                  _previewPack = tier.key;
                  _downloadingTier = null;
                  _syncSubscription?.cancel();
                  _syncSubscription = null;
                });
                widget.onDatabaseUpdated?.call();
                _triggerSnackbar("settings.offlineDb.syncSuccess".tr());
              }
            } else if (progress.step == OfflineSyncStep.error) {
              if (mounted) {
                await _performRollback();
                _triggerSnackbar(
                  "settings.offlineDb.downloadError".tr(),
                  isError: true,
                );
              }
            }
          },
          onError: (err) async {
            if (!mounted) return;
            await _performRollback();
            _triggerSnackbar(
              "settings.offlineDb.downloadError".tr(),
              isError: true,
            );
          },
        );
  }

  Future<void> _performRollback() async {
    _syncSubscription?.cancel();
    _syncSubscription = null;
    OfflineDbSyncService.cancelSync();

    if (_rollbackTier == OfflineDbTier.none) {
      await OfflineDbService.deleteDatabaseFile();
      await OfflineDbService.setInstalledTier(OfflineDbTier.none);
      if (_currentSettings.offlineDbTier != OfflineDbTier.none ||
          _currentSettings.offlineDbLastSyncedAt != null) {
        final updated = _currentSettings.copyWith(
          offlineDbTier: OfflineDbTier.none,
          offlineDbLastSyncedAt: null,
        );
        _currentSettings = updated;
        await widget.onSettingsChange(updated, isOfflineDbChange: true);
      }

      if (mounted) {
        setState(() {
          _installedTier = OfflineDbTier.none;
          _downloadingTier = null;
          _syncProgress = const OfflineSyncProgress.idle();
        });
        widget.onDatabaseUpdated?.call();
      }
    } else {
      await OfflineDbService.setInstalledTier(_rollbackTier);
      if (_currentSettings.offlineDbTier != _rollbackTier ||
          _currentSettings.offlineDbLastSyncedAt != _rollbackLastSyncedAt) {
        final updated = _currentSettings.copyWith(
          offlineDbTier: _rollbackTier,
          offlineDbLastSyncedAt: _rollbackLastSyncedAt,
        );
        _currentSettings = updated;
        await widget.onSettingsChange(updated, isOfflineDbChange: true);
      }

      if (mounted) {
        setState(() {
          _installedTier = _rollbackTier;
          _downloadingTier = null;
          _syncProgress = const OfflineSyncProgress.idle();
        });
        widget.onDatabaseUpdated?.call();
      }
    }
  }

  Future<void> _cancelSync() async {
    await _performRollback();
  }

  Future<void> _handleUninstallPackage() async {
    if (_syncProgress.isInProgress) return;

    final packTitle = "settings.offlineDb.packages.${_installedTier.key}.title"
        .tr();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ctx.colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: ctx.colorScheme.onErrorContainer,
              size: 28,
            ),
          ),
        ),
        title: Text(
          "settings.offlineDb.uninstallPackage".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ctx.colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "settings.offlineDb.uninstallConfirmBody".tr(
            namedArgs: {'name': packTitle},
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ctx.colorScheme.onSurfaceVariant,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: ctx.colorScheme.error,
                  foregroundColor: ctx.colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  "settings.offlineDb.uninstallPackage".tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ctx.colorScheme.onSurface,
                  side: BorderSide(
                    color: ctx.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  "common.actions.cancel".tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await OfflineDbService.deleteDatabaseFile();
        await OfflineDbService.setInstalledTier(OfflineDbTier.none);
        final updated = _currentSettings.copyWith(
          offlineDbTier: OfflineDbTier.none,
          offlineDbLastSyncedAt: null,
        );
        _currentSettings = updated;
        await widget.onSettingsChange(updated, isOfflineDbChange: true);

        if (mounted) {
          setState(() {
            _installedTier = OfflineDbTier.none;
          });
          widget.onDatabaseUpdated?.call();
        }
      } catch (e) {
        debugPrint("Error uninstalling offline database: $e");
      }
    }
  }

  Future<void> _handleSwitchPackage(
    String targetKey, {
    bool isInitialInstall = false,
  }) async {
    if (_syncProgress.isInProgress) return;

    final packTitle = "settings.offlineDb.packages.$targetKey.title".tr();
    final packDl = "settings.offlineDb.packages.$targetKey.downloadSize".tr();
    final packDisk = "settings.offlineDb.packages.$targetKey.diskSize".tr();

    final String dialogTitle = isInitialInstall
        ? "settings.offlineDb.downloadConfirmTitle".tr(
            namedArgs: {'name': packTitle},
          )
        : "settings.offlineDb.switchConfirmTitle".tr(
            namedArgs: {'name': packTitle},
          );

    final String baseBody = isInitialInstall
        ? "settings.offlineDb.downloadConfirmBody".tr(
            namedArgs: {'dl': packDl, 'disk': packDisk},
          )
        : "settings.offlineDb.switchConfirmBody".tr(
            namedArgs: {'dl': packDl, 'disk': packDisk},
          );

    final showWarning = await _shouldShowMobileDataWarning();
    final String dialogBody = showWarning
        ? "$baseBody\n\n${"settings.offlineDb.networkUsageNotice".tr()}"
        : baseBody;

    final String confirmBtnText = isInitialInstall
        ? "settings.offlineDb.downloadConfirmTitle".tr(
            namedArgs: {'name': packTitle},
          )
        : "settings.offlineDb.switchConfirmTitle".tr(
            namedArgs: {'name': packTitle},
          );

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ctx.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isInitialInstall
                  ? Icons.cloud_download_rounded
                  : Icons.swap_horiz_rounded,
              color: ctx.colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
        ),
        title: Text(
          dialogTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ctx.colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          dialogBody,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ctx.colorScheme.onSurfaceVariant,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: ctx.colorScheme.primary,
                  foregroundColor: ctx.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  confirmBtnText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ctx.colorScheme.onSurface,
                  side: BorderSide(
                    color: ctx.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  "common.actions.cancel".tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      final targetTier = _keyToTier(targetKey);
      _startSync(targetTier, explicitLastSyncedAt: null);
    }
  }

  /// Restituisce `true` se l'utente ha attiva l'opzione "Solo Wi-Fi" (o "Protezione reti mobili" su Web)
  /// e si trova attualmente su rete mobile (o su Web dove il tipo di rete non è rilevabile).
  Future<bool> _shouldShowMobileDataWarning() async {
    if (!_currentSettings.offlineDbWifiOnly) return false;
    if (OfflineDbSyncService.isWeb) return true;
    final isWifi = await ConnectivityHelper.isWifiConnection();
    return !isWifi;
  }

  Future<void> _handleManualUpdate() async {
    final showWarning = await _shouldShowMobileDataWarning();
    if (showWarning) {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ctx.cardBackground,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          icon: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ctx.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: ctx.colorScheme.onPrimaryContainer,
                size: 28,
              ),
            ),
          ),
          title: Text(
            "settings.offlineDb.manualUpdateConfirmTitle".tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ctx.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "settings.offlineDb.manualUpdateConfirmBody".tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ctx.colorScheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: ctx.colorScheme.primary,
                    foregroundColor: ctx.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    "settings.offlineDb.updateBtn".tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ctx.colorScheme.onSurface,
                    side: BorderSide(
                      color: ctx.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    "common.actions.cancel".tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    _startSync(_installedTier);
  }

  Widget _buildStatusPill(ColorScheme colorScheme) {
    AppStatusPillVariant variant;
    String label;

    if (_syncProgress.isInProgress) {
      variant = AppStatusPillVariant.neutral;
      label = "settings.offlineDb.statusDownloading".tr();
    } else if (_installedTier == OfflineDbTier.none) {
      variant = AppStatusPillVariant.neutral;
      label = "settings.offlineDb.statusDisabled".tr();
    } else {
      final lastSync = _currentSettings.offlineDbLastSyncedAt;
      if (lastSync == null || lastSync <= 0) {
        variant = AppStatusPillVariant.error;
        label = "settings.offlineDb.statusHardStale".tr();
      } else {
        final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final diffDays = (nowSec - lastSync) ~/ 86400;

        if (diffDays <= 7) {
          variant = AppStatusPillVariant.primary;
          label = "settings.offlineDb.statusSynchronized".tr();
        } else if (diffDays <= 30) {
          variant = AppStatusPillVariant.tertiary;
          label = "settings.offlineDb.statusSoftStale".tr();
        } else {
          variant = AppStatusPillVariant.error;
          label = "settings.offlineDb.statusHardStale".tr();
        }
      }
    }

    return AppStatusPill.preset(variant: variant, label: label);
  }

  String _formatAlignmentDate() {
    if (_syncProgress.isInProgress &&
        _downloadingTier != null &&
        _downloadingTier != _installedTier) {
      return "settings.offlineDb.neverSynced".tr();
    }
    if (_installedTier == OfflineDbTier.none) {
      return "settings.offlineDb.disabledHint".tr();
    }
    final lastSync = _currentSettings.offlineDbLastSyncedAt;
    if (lastSync == null || lastSync <= 0) {
      return "settings.offlineDb.neverSynced".tr();
    }
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diffDays = (nowSec - lastSync) ~/ 86400;

    String daysAgo;
    if (diffDays == 0) {
      daysAgo = "common.time.today".tr().toLowerCase();
    } else if (diffDays == 1) {
      daysAgo = "common.time.yesterday".tr().toLowerCase();
    } else {
      daysAgo = "settings.offlineDb.daysAgo".tr(args: [diffDays.toString()]);
    }
    return "settings.offlineDb.lastSyncFormat".tr(args: [daysAgo]);
  }

  Widget _buildToggleRow({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: isFirst ? 24.0 : 16.0,
        bottom: isLast ? 24.0 : 16.0,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colorScheme.onPrimary,
            activeTrackColor: colorScheme.primary,
            inactiveThumbColor: colorScheme.onSurfaceVariant.withValues(
              alpha: 0.7,
            ),
            inactiveTrackColor: colorScheme.surfaceContainerHigh,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageChip(String key) {
    final isSelected = _previewPack == key;
    final title = "settings.offlineDb.packages.$key.title".tr();
    final dl = "settings.offlineDb.packages.$key.downloadSize".tr();
    final colorScheme = Theme.of(context).colorScheme;
    final cardBg = context.cardBackground;

    return InkWell(
      onTap: () {
        setState(() => _previewPack = key);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.selectedItemBg
              : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              dl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;
    final isSyncing = _syncProgress.isInProgress;

    final displayTier = (isSyncing && _downloadingTier != null)
        ? _downloadingTier!
        : _installedTier;

    final String activePackTitle = displayTier != OfflineDbTier.none
        ? "settings.offlineDb.packages.${displayTier.key}.title".tr()
        : "settings.offlineDb.noDbInstalled".tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Drag Handle
        Center(
          child: Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.only(top: 16, bottom: 24),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),

        // 2. Titolo (Centrato, con spaziature allineate al ToS bottom sheet)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: Text(
              "settings.offlineDb.sheetTitle".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 3. Hero Status Card (Centrata, Pura e Simmetrica)
                Container(
                  padding: const EdgeInsets.only(
                    top: 22,
                    bottom: 18,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Pillola di Stato M3 (SOPRA il nome, solo testo)
                      _buildStatusPill(colorScheme),
                      const SizedBox(height: 10),

                      // Nome Pacchetto Installato
                      Text(
                        activePackTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Data Ultimo Aggiornamento
                      Text(
                        _formatAlignmentDate(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),

                      // Pulsante "Aggiorna" Compatto (mostrato solo se non è in corso una sincronizzazione)
                      if (_installedTier != OfflineDbTier.none &&
                          !isSyncing) ...[
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () {
                            _handleManualUpdate();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                            side: BorderSide(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(
                            "settings.offlineDb.updateBtn".tr(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],

                      // Barra di avanzamento con percentuale e cancellazione (X)
                      if (isSyncing) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: _syncProgress.progress > 0
                                      ? _syncProgress.progress
                                      : null,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHigh,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "${(_syncProgress.progress.clamp(0.0, 1.0) * 100).toInt()}%",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              key: const ValueKey('cancelSyncButton'),
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: _cancelSync,
                              color: colorScheme.onSurfaceVariant,
                              tooltip: "common.actions.cancel".tr(),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 4. Selettore Pacchetti
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "settings.offlineDb.selectPackageLabel".tr(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildPackageChip(_packageKeys[0])),
                        const SizedBox(width: 14),
                        Expanded(child: _buildPackageChip(_packageKeys[1])),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _buildPackageChip(_packageKeys[2])),
                        const SizedBox(width: 14),
                        Expanded(child: _buildPackageChip(_packageKeys[3])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 5. Scheda Spiegazione (grigia senza bordo)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Riga Intestazione
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              "settings.offlineDb.packages.$_previewPack.title"
                                  .tr(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (_previewPack == _installedTier.key)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.statusPrimaryBg,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                "settings.offlineDb.inUseBadge".tr(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Descrizione estesa
                      Text(
                        "settings.offlineDb.packages.$_previewPack.description"
                            .tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.55,
                        ),
                      ),

                      // Divisore simmetrico con padding
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),

                      // In una sola riga: download a sinistra e spazio su disco a destra
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              "${"settings.offlineDb.downloadLabel".tr()} ${"settings.offlineDb.packages.$_previewPack.downloadSize".tr()}",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Text(
                              "${"settings.offlineDb.diskLabel".tr()} ${"settings.offlineDb.packages.$_previewPack.diskSize".tr()}",
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Pulsante di Azione
                      if (_previewPack == _installedTier.key)
                        OutlinedButton.icon(
                          onPressed: isSyncing ? null : _handleUninstallPackage,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                          ),
                          label: Text(
                            "settings.offlineDb.uninstallPackage".tr(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            backgroundColor: colorScheme.errorContainer
                                .withValues(alpha: 0.3),
                            side: BorderSide(color: colorScheme.errorContainer),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        )
                      else if (_installedTier == OfflineDbTier.none)
                        FilledButton(
                          onPressed: isSyncing
                              ? null
                              : () => _handleSwitchPackage(
                                  _previewPack,
                                  isInitialInstall: true,
                                ),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            "settings.offlineDb.downloadAndActivate".tr(
                              args: [
                                "settings.offlineDb.packages.$_previewPack.title"
                                    .tr(),
                              ],
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        )
                      else
                        FilledButton(
                          onPressed: isSyncing
                              ? null
                              : () => _handleSwitchPackage(
                                  _previewPack,
                                  isInitialInstall: false,
                                ),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            "settings.offlineDb.switchConfirmTitle".tr(
                              namedArgs: {
                                'name':
                                    "settings.offlineDb.packages.$_previewPack.title"
                                        .tr(),
                              },
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 6. Card Automazione e Rete
                Row(
                  children: [
                    Icon(
                      Icons.wifi_tethering,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "settings.offlineDb.automationAndNetworkLabel".tr(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
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
                      _buildToggleRow(
                        context: context,
                        title: OfflineDbSyncService.isWeb
                            ? "settings.offlineDb.mobileProtectionTitle".tr()
                            : "settings.offlineDb.wifiOnlyTitle".tr(),
                        subtitle: OfflineDbSyncService.isWeb
                            ? "settings.offlineDb.mobileProtectionSubtitle".tr()
                            : "settings.offlineDb.wifiOnlySubtitle".tr(),
                        value: _currentSettings.offlineDbWifiOnly,
                        onChanged: (v) async {
                          final updated = _currentSettings.copyWith(
                            offlineDbWifiOnly: v,
                          );
                          setState(() => _currentSettings = updated);
                          await widget.onSettingsChange(
                            updated,
                            isOfflineDbChange: true,
                          );
                        },
                        isFirst: true,
                      ),
                      _buildToggleRow(
                        context: context,
                        title: "settings.offlineDb.autoUpdateTitle".tr(),
                        subtitle: "settings.offlineDb.autoUpdateSubtitle".tr(),
                        value: _currentSettings.offlineDbAutoSync,
                        onChanged: (v) async {
                          final updated = _currentSettings.copyWith(
                            offlineDbAutoSync: v,
                          );
                          setState(() => _currentSettings = updated);
                          await widget.onSettingsChange(
                            updated,
                            isOfflineDbChange: true,
                          );
                        },
                      ),
                      _buildToggleRow(
                        context: context,
                        title: "settings.offlineDb.cloudSyncTitle".tr(),
                        subtitle: "settings.offlineDb.cloudSyncSubtitle".tr(),
                        value: _currentSettings.offlineDbCloudSync,
                        isLast: true,
                        onChanged: (v) async {
                          final updated = _currentSettings.copyWith(
                            offlineDbCloudSync: v,
                          );
                          setState(() => _currentSettings = updated);
                          await widget.onSettingsChange(updated);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

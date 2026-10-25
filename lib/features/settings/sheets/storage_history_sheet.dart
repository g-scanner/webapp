// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../dialogs/clear_history_dialog.dart';
import '../dialogs/clear_product_cache_dialog.dart';
import '../utils/storage_utils.dart';

/// Mostra il Modal Bottom Sheet "Memoria e Cronologia" in puro stile M3.
void showStorageHistorySheet({
  required BuildContext context,
  required Future<void> Function() onClearHistory,
  required Future<void> Function()? onClearProductCache,
  int historyCount = 0,
  int cacheCount = 0,
  int historySizeBytes = 0,
  int cacheSizeBytes = 0,
  Future<StorageMetrics> Function()? onLoadMetrics,
  VoidCallback? onStorageUpdated,
}) {
  int currentHistoryCount = historyCount;
  int currentCacheCount = cacheCount;
  int currentHistoryBytes = historySizeBytes;
  int currentCacheBytes = cacheSizeBytes;
  bool didInitialLoad = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: false,
    constraints: const BoxConstraints(maxWidth: 500),
    backgroundColor: context.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) {
      final colorScheme = ctx.colorScheme;
      final cardBg = ctx.cardBackground;

      return StatefulBuilder(
        builder: (BuildContext sheetContext, StateSetter setModalState) {
          if (!didInitialLoad && onLoadMetrics != null) {
            didInitialLoad = true;
            onLoadMetrics().then((metrics) {
              if (sheetContext.mounted) {
                setModalState(() {
                  currentHistoryCount = metrics.historyCount;
                  currentCacheCount = metrics.cacheCount;
                  currentHistoryBytes = metrics.historySizeBytes;
                  currentCacheBytes = metrics.cacheSizeBytes;
                });
              }
            });
          }

          final int totalBytes = currentCacheBytes + currentHistoryBytes;

          return Column(
            mainAxisSize: MainAxisSize.min,
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

              // 2. Titolo (Centrato, con spaziature allineate al ToS e Database Offline)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Center(
                  child: Text(
                    "settings.dataHistory.sheetTitle".tr(),
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
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 3. Hero Card Totale (Sfondo grigio, SENZA bordi, SENZA pillole)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 22,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              formatBytes(totalBytes),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "settings.dataHistory.totalStorageLabel".tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                // 4. Card Cache Prodotti
                Builder(
                  builder: (context) {
                    final cacheUnit = currentCacheCount == 1
                        ? "settings.dataHistory.cacheItemSingle".tr()
                        : "settings.dataHistory.cacheItemPlural".tr();
                    final cacheDataText = "settings.dataHistory.statsFormat".tr(
                      namedArgs: {
                        'size': formatBytes(currentCacheBytes),
                        'count': currentCacheCount.toString(),
                        'unit': cacheUnit,
                      },
                    );

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  "settings.dataHistory.cacheTitle".tr(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  cacheDataText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "settings.dataHistory.cacheDesc".tr(),
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: onClearProductCache == null
                                  ? null
                                  : () async {
                                      final confirm =
                                          await showClearProductCacheDialog(
                                        sheetContext,
                                      );
                                      if (confirm == true) {
                                        await onClearProductCache();
                                        setModalState(() {
                                          currentCacheCount = 0;
                                          currentCacheBytes = 0;
                                        });
                                        onStorageUpdated?.call();
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                foregroundColor: colorScheme.onSurface,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              icon: const Icon(Icons.cached_rounded, size: 20),
                              label: Text(
                                "settings.dataHistory.clearCacheAction".tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 5. Card Cronologia Scansioni
                Builder(
                  builder: (context) {
                    final historyUnit = currentHistoryCount == 1
                        ? "settings.dataHistory.historyItemSingle".tr()
                        : "settings.dataHistory.historyItemPlural".tr();
                    final historyDataText =
                        "settings.dataHistory.statsFormat".tr(
                      namedArgs: {
                        'size': formatBytes(currentHistoryBytes),
                        'count': currentHistoryCount.toString(),
                        'unit': historyUnit,
                      },
                    );

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  "settings.dataHistory.historyTitle".tr(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  historyDataText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "settings.dataHistory.historyDesc".tr(),
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final confirm =
                                    await showClearHistoryDialog(sheetContext);
                                if (confirm == true) {
                                  await onClearHistory();
                                  setModalState(() {
                                    currentHistoryCount = 0;
                                    currentHistoryBytes = 0;
                                  });
                                  onStorageUpdated?.call();
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.error,
                                backgroundColor: colorScheme.errorContainer
                                    .withValues(alpha: 0.3),
                                side: BorderSide(
                                  color: colorScheme.errorContainer,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                              ),
                              label: Text(
                                "settings.dataHistory.clearHistoryAction".tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
        },
      );
    },
  ).then((_) {
    onStorageUpdated?.call();
  });
}

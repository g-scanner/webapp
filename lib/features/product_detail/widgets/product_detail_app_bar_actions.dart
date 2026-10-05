// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:gscanner/core/theme/app_theme.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:easy_localization/easy_localization.dart';

/// Widget dedicato per gestire le azioni dell'AppBar in ProductDetailCard:
/// - Skeleton durante il caricamento
/// - Menu Popup a 3 puntini con opzioni Elimina Cronologia ed Elimina Segnalazione
/// - Dialoghi di conferma dedicati
class ProductDetailAppBarActions extends StatelessWidget {
  final bool showActionsSkeleton;
  final bool canDeleteHistory;
  final bool canDeleteReport;
  final String barcode;
  final String? effectiveUserReportId;
  final Future<void> Function(String barcode)? onDeleteHistoryByBarcode;
  final Future<void> Function(String reportId)? onDeleteReport;
  final VoidCallback onBack;
  final Color cardBg;
  final ColorScheme colorScheme;

  const ProductDetailAppBarActions({
    super.key,
    required this.showActionsSkeleton,
    required this.canDeleteHistory,
    required this.canDeleteReport,
    required this.barcode,
    required this.effectiveUserReportId,
    required this.onDeleteHistoryByBarcode,
    required this.onDeleteReport,
    required this.onBack,
    required this.cardBg,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (showActionsSkeleton) {
      return Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: Skeletonizer(
          enabled: true,
          child: IconButton(
            color: cardBg,
            onPressed: () {},
            icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    if (canDeleteHistory || canDeleteReport) {
      return PopupMenuButton<String>(
        tooltip: "common.actions.moreOptions".tr(),
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.12),

        // ── Offset calcolato: 40 (altezza del bottone) + 8 (spazio vuoto) = 48dp di stacco! ──
        offset: const Offset(0, 48),

        color: context.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        onSelected: (value) => _handleMenuSelection(context, value),
        itemBuilder: (BuildContext context) {
          final colorScheme = context.colorScheme;
          final items = <PopupMenuEntry<String>>[];

          // 1. Elimina cronologia
          if (canDeleteHistory) {
            items.add(
              _buildDestructiveMenuItem(
                value: 'delete_history',
                title: "common.actions.deleteHistoryConfirmTitle".tr(),
                icon: Icons.delete_outline_rounded,
                colorScheme: colorScheme,
              ),
            );
          }

          // Divisore: distanziato dai bordi e con lo stesso colore e spessore del bordo del popup
          if (canDeleteHistory && canDeleteReport) {
            items.add(
              PopupMenuItem<String>(
                enabled: false,
                height: 9, // Altezza compatta
                padding: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                  ), // Rientro dai bordi
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ), // Identico al bordo del popup
                  ),
                ),
              ),
            );
          }

          // 2. Elimina segnalazione
          if (canDeleteReport) {
            items.add(
              _buildDestructiveMenuItem(
                value: 'delete_report',
                title: "common.actions.deleteReportConfirmTitle".tr(),
                icon: Icons.report_gmailerrorred_rounded,
                colorScheme: colorScheme,
              ),
            );
          }

          return items;
        },
        // Trigger dei 3 puntini da 40dp
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.more_vert_rounded,
            color: context.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _handleMenuSelection(BuildContext context, String value) {
    if (value == 'delete_history') {
      _showDeleteHistoryDialog(context);
    } else if (value == 'delete_report') {
      _showDeleteReportDialog(context);
    }
  }

  void _showDeleteHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: colorScheme.onErrorContainer,
              size: 28,
            ),
          ),
        ),
        title: Text(
          "common.actions.deleteHistoryConfirmTitle".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "common.actions.deleteHistoryConfirmBody".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Azione 1: Elimina elemento per barcode (Filled distruttivo a pillola)
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onDeleteHistoryByBarcode?.call(barcode);
                  onBack();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  "common.actions.delete".tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Azione 2: Annulla (Outlined neutro a pillola)
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
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
  }

  void _showDeleteReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.report_gmailerrorred_rounded,
              color: colorScheme.onErrorContainer,
              size: 28,
            ),
          ),
        ),
        title: Text(
          "common.actions.deleteReportConfirmTitle".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "common.actions.deleteReportConfirmBody".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Azione 1: Elimina report (Filled distruttivo a pillola)
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final reportId = effectiveUserReportId;
                  if (reportId != null) {
                    await onDeleteReport?.call(reportId);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  "common.actions.delete".tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Azione 2: Annulla (Outlined neutro a pillola)
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
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
  }
}

PopupMenuItem<String> _buildDestructiveMenuItem({
  required String value,
  required String title,
  required IconData icon,
  required ColorScheme colorScheme,
}) {
  return PopupMenuItem<String>(
    value: value,
    padding: EdgeInsets.zero,
    height: 48,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.error, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

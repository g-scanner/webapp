// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
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
            icon: Icon(
              Icons.more_vert,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    if (canDeleteHistory || canDeleteReport) {
      return PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
        color: cardBg,
        onSelected: (value) => _handleMenuSelection(context, value),
        itemBuilder: (BuildContext context) => [
          if (canDeleteHistory)
            PopupMenuItem(
              value: 'delete_history',
              child: Row(
                children: [
                  Icon(Icons.delete, color: colorScheme.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "common.actions.deleteHistoryConfirmTitle".tr(),
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          if (canDeleteReport)
            PopupMenuItem(
              value: 'delete_report',
              child: Row(
                children: [
                  Icon(Icons.warning, color: colorScheme.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "common.actions.deleteReportConfirmTitle".tr(),
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
        ],
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
        title: Text(
          "common.actions.deleteHistoryConfirmTitle".tr(),
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          "common.actions.deleteHistoryConfirmBody".tr(),
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
            ),
            child: Text("common.actions.cancel".tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDeleteHistoryByBarcode?.call(barcode);
              onBack();
            },
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            child: Text("common.actions.delete".tr()),
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
        title: Text(
          "common.actions.deleteReportConfirmTitle".tr(),
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          "common.actions.deleteReportConfirmBody".tr(),
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
            ),
            child: Text("common.actions.cancel".tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final reportId = effectiveUserReportId;
              if (reportId != null) {
                await onDeleteReport?.call(reportId);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            child: Text("common.actions.delete".tr()),
          ),
        ],
      ),
    );
  }
}

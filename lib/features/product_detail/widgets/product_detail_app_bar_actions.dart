// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

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
              Icons.more_vert_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    if (canDeleteHistory || canDeleteReport) {
      return AppCircleMoreMenu<String>(
        tooltip: "common.actions.moreOptions".tr(),
        onSelected: (value) => _handleMenuSelection(context, value),
        itemBuilder: (BuildContext context) {
          final colorScheme = context.colorScheme;
          final items = <PopupMenuEntry<String>>[];

          // 1. Elimina cronologia
          if (canDeleteHistory) {
            items.add(
              AppDestructivePopupMenuItem<String>(
                value: 'delete_history',
                title: "common.actions.deleteHistoryConfirmTitle".tr(),
                icon: Icons.delete_outline_rounded,
                colorScheme: colorScheme,
              ),
            );
          }

          // Divisore
          if (canDeleteHistory && canDeleteReport) {
            items.add(
              PopupMenuItem<String>(
                enabled: false,
                height: 9,
                padding: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
            );
          }

          // 2. Elimina segnalazione
          if (canDeleteReport) {
            items.add(
              AppDestructivePopupMenuItem<String>(
                value: 'delete_report',
                title: "common.actions.deleteReportConfirmTitle".tr(),
                icon: Icons.report_gmailerrorred_rounded,
                colorScheme: colorScheme,
              ),
            );
          }

          return items;
        },
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
    showDeleteHistoryConfirmDialog(
      context: context,
      onConfirm: () async {
        if (onDeleteHistoryByBarcode != null) {
          await onDeleteHistoryByBarcode!(barcode);
        }
        onBack();
      },
    );
  }

  void _showDeleteReportDialog(BuildContext context) {
    showDeleteReportConfirmDialog(
      context: context,
      onConfirm: () async {
        if (effectiveUserReportId != null && onDeleteReport != null) {
          await onDeleteReport!(effectiveUserReportId!);
        }
        onBack();
      },
    );
  }
}

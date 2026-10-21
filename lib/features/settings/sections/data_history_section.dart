// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';

/// Sezione dati e cronologia con pulsanti distruttivi per svuotare cronologia e cache prodotti.
class DataHistorySection extends StatelessWidget {
  final bool isClearing;
  final VoidCallback onClearHistoryTap;
  final bool isClearingProducts;
  final VoidCallback? onClearProductsTap;

  const DataHistorySection({
    super.key,
    required this.isClearing,
    required this.onClearHistoryTap,
    this.isClearingProducts = false,
    this.onClearProductsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionCard(
          context: context,
          isBusy: isClearing,
          onTap: onClearHistoryTap,
          icon: Icons.delete_outline,
          title: "settings.dataAndHistory.clearHistoryTitle".tr(),
          subtitle: "settings.dataAndHistory.clearHistorySubtitle".tr(),
        ),
        if (onClearProductsTap != null) ...[
          const SizedBox(height: 12),
          _buildActionCard(
            context: context,
            isBusy: isClearingProducts,
            onTap: onClearProductsTap!,
            icon: Icons.inventory_2_outlined,
            title: "settings.dataAndHistory.clearProductsTitle".tr(),
            subtitle: "settings.dataAndHistory.clearProductsSubtitle".tr(),
          ),
        ],
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required bool isBusy,
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colorScheme = context.colorScheme;
    return InkWell(
      onTap: isBusy ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      splashColor: colorScheme.error.withValues(alpha: 0.12),
      highlightColor: colorScheme.error.withValues(alpha: 0.08),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.errorContainer),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: isBusy
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: colorScheme.error,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      icon,
                      color: colorScheme.error,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: colorScheme.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

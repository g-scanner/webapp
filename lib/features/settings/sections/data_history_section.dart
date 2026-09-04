// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';

/// Sezione dati e cronologia con pulsante distruttivo svuota cronologia.
class DataHistorySection extends StatelessWidget {
  final bool isClearing;
  final VoidCallback onClearHistoryTap;

  const DataHistorySection({
    super.key,
    required this.isClearing,
    required this.onClearHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return InkWell(
      onTap: isClearing ? null : onClearHistoryTap,
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
              child: isClearing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: colorScheme.error,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.delete_outline,
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
                    "settings.destructive.clearHistoryTitle".tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "settings.destructive.clearHistorySubtitle".tr(),
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

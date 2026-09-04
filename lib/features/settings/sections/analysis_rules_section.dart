// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';

/// Sezione "Regole di Analisi" con i tre toggle principali.
class AnalysisRulesSection extends StatelessWidget {
  final bool warnAdditives;
  final bool strictMode;
  final bool alertLactose;
  final void Function(bool value, String key) onToggle;

  const AnalysisRulesSection({
    super.key,
    required this.warnAdditives,
    required this.strictMode,
    required this.alertLactose,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Material(
      color: context.cardBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildToggleItem(
            context: context,
            title: "settings.toggles.warnAdditivesTitle".tr(),
            subtitle: "settings.toggles.warnAdditivesSubtitle".tr(),
            value: warnAdditives,
            onChanged: (v) => onToggle(v, 'warnAdditives'),
            isFirst: true,
          ),
          _buildToggleItem(
            context: context,
            title: "settings.toggles.strictFilterTitle".tr(),
            subtitle: "settings.toggles.strictFilterSubtitle".tr(),
            value: strictMode,
            onChanged: (v) => onToggle(v, 'strictMode'),
          ),
          _buildToggleItem(
            context: context,
            title: "settings.toggles.lactoseIntoleranceTitle".tr(),
            subtitle: "settings.toggles.lactoseIntoleranceSubtitle".tr(),
            value: alertLactose,
            onChanged: (v) => onToggle(v, 'alertLactose'),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
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
            inactiveThumbColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            inactiveTrackColor: colorScheme.surfaceContainerHigh,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';

/// Pulsante circolare 40dp con tre puntini verticali per menu opzioni,
/// coordinato con il design system di G-Scanner.
class AppCircleMoreMenu<T> extends StatelessWidget {
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T>? onSelected;
  final String? tooltip;
  final Offset offset;

  const AppCircleMoreMenu({
    super.key,
    required this.itemBuilder,
    this.onSelected,
    this.tooltip,
    this.offset = const Offset(0, 48),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    return ClipOval(
      child: PopupMenuButton<T>(
        tooltip: tooltip ?? "common.actions.moreOptions".tr(),
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        offset: offset,
        color: cardBg,
        surfaceTintColor: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        onSelected: onSelected,
        itemBuilder: itemBuilder,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.more_vert_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
      ),
    );
  }
}

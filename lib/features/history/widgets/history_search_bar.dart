// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';

class HistorySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const HistorySearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final bool showClearIcon = isFocused && searchQuery.isNotEmpty;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 14,
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: "common.actions.search".tr(),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(
            alpha: 0.6,
          ),
          fontSize: 14,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          maxWidth: 48,
          minHeight: 48,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
            child: showClearIcon
                ? IconButton(
                    key: const ValueKey('clearIcon'),
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onClear,
                  )
                : Icon(
                    key: const ValueKey('searchIcon'),
                    Icons.search,
                    color: searchQuery.isNotEmpty
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                  ),
          ),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 0,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

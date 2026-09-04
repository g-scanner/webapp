// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';

class ManualBarcodeField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool scanningProgress;
  final VoidCallback onSearch;

  const ManualBarcodeField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.scanningProgress,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final bool hasText = value.text.trim().isNotEmpty;
        final bool showClearIcon = isFocused && hasText;

        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSearch(),
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                ),
                decoration: InputDecoration(
                  hintText: "scanner.manualInput.hint".tr(),
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    maxWidth: 48,
                    minHeight: 48,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
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
                                size: 22,
                              ),
                              onPressed: () {
                                controller.clear();
                                focusNode.requestFocus();
                              },
                            )
                          : Icon(
                              Icons.qr_code_scanner_rounded,
                              key: const ValueKey('barcodeIcon'),
                              color: hasText
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    ),
                              size: 22,
                            ),
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasText
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                boxShadow: hasText
                    ? [
                        BoxShadow(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [const BoxShadow(color: Colors.transparent)],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: (hasText && !scanningProgress) ? onSearch : null,
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0.5, 0),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: hasText
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Alias for architecture plan compliance
typedef ManualBarcodeSheet = ManualBarcodeField;

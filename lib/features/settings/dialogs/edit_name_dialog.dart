// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Costruisce la vista secondaria (Edit Nome) dentro il bottom sheet di gestione account.
Widget buildEditNameView({
  required BuildContext context,
  required ColorScheme colorScheme,
  required TextEditingController nameController,
  required FocusNode nameFocusNode,
  required String currentDisplayName,
  required VoidCallback onGoBack,
  required Future<void> Function(String newName) onSaveName,
}) {
  return Column(
    key: const ValueKey("EditNameView"),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: Container(
          width: 36,
          height: 5,
          margin: const EdgeInsets.only(top: 16, bottom: 16),
          decoration: BoxDecoration(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),

      // Header con Back Button
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: colorScheme.onSurfaceVariant,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHigh,
              ),
              onPressed: onGoBack,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "settings.account.editName".tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),

      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "settings.account.editNameSubtitle".tr(),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // ── TEXTFIELD AGGIORNATO (Stile SearchBar) ──
            TextField(
              controller: nameController,
              focusNode: nameFocusNode,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(
                fontSize: 14, // Uniformato alla grandezza della search bar
                color: colorScheme.onSurface,
              ),
              cursorColor: colorScheme.primary,
              decoration: InputDecoration(
                hintText: "settings.account.editNameHint".tr(),
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  maxWidth: 48,
                  minHeight: 48,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.badge_outlined,
                    color: colorScheme.onSurfaceVariant,
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
            ),
            const SizedBox(height: 24),

            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: onGoBack,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    "common.actions.cancel".tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: nameController,
                  builder: (context, value, child) {
                    final bool isValid = value.text.trim().isNotEmpty;
                    return FilledButton(
                      onPressed: isValid
                          ? () async {
                              final newName = value.text.trim();
                              await onSaveName(newName);
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        "common.actions.save".tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

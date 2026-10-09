// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'app_popup_menu_item.dart';

/// Voce di menu popup con spunta circolare animata sul lato destro,
/// coerente con il design system di G-Scanner.
class AppRadioPopupMenuItem<T> extends AppPopupMenuItem<T> {
  AppRadioPopupMenuItem({
    super.key,
    required super.value,
    required String label,
    required bool isSelected,
    required ColorScheme colorScheme,
    Color? activeColor,
    Color? activeTextColor,
    Color? activeBgColor,
    super.onTap,
  }) : super(
         mouseCursor: isSelected ? SystemMouseCursors.basic : SystemMouseCursors.click,
         customSplashColor: isSelected
             ? Colors.transparent
             : (activeTextColor ?? colorScheme.primary).withValues(alpha: 0.12),
         customHighlightColor: isSelected
             ? Colors.transparent
             : (activeTextColor ?? colorScheme.primary).withValues(alpha: 0.08),
         customHoverColor: isSelected
             ? Colors.transparent
             : (activeTextColor ?? colorScheme.primary).withValues(alpha: 0.06),
         child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
           decoration: BoxDecoration(
             color: isSelected
                 ? (activeBgColor ??
                     colorScheme.primary.withValues(alpha: 0.12))
                 : Colors.transparent,
             borderRadius: BorderRadius.circular(999),
           ),
           child: Row(
             children: [
               Expanded(
                 child: Text(
                   label,
                   style: TextStyle(
                     fontSize: 14,
                     fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                     color: isSelected
                         ? (activeTextColor ?? colorScheme.primary)
                         : colorScheme.onSurface,
                   ),
                 ),
               ),
               const SizedBox(width: 12),
               AnimatedContainer(
                 duration: const Duration(milliseconds: 200),
                 width: 20,
                 height: 20,
                 decoration: BoxDecoration(
                   color: isSelected
                       ? (activeColor ?? colorScheme.primary)
                       : Colors.transparent,
                   shape: BoxShape.circle,
                   border: isSelected
                       ? null
                       : Border.all(
                           color: colorScheme.outlineVariant.withValues(
                             alpha: 0.6,
                           ),
                           width: 1.5,
                         ),
                 ),
                 child: isSelected
                     ? Icon(Icons.check, size: 14, color: colorScheme.surface)
                     : null,
               ),
             ],
           ),
         ),
       );
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'app_popup_menu_item.dart';

/// Voce di menu popup distruttiva (es. elimina) con icona evidenziata
/// in un bollino circolare e stile coordinato a colorScheme.error.
class AppDestructivePopupMenuItem<T> extends AppPopupMenuItem<T> {
  AppDestructivePopupMenuItem({
    super.key,
    required super.value,
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
    super.onTap,
  }) : super(
         customSplashColor: colorScheme.error.withValues(alpha: 0.12),
         customHighlightColor: colorScheme.error.withValues(alpha: 0.08),
         customHoverColor: colorScheme.error.withValues(alpha: 0.06),
         child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
           decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
           child: Row(
             children: [
               Container(
                 width: 32,
                 height: 32,
                 decoration: BoxDecoration(
                   color: colorScheme.error.withValues(alpha: 0.10),
                   shape: BoxShape.circle,
                 ),
                 child: Icon(icon, color: colorScheme.error, size: 18),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Text(
                   title,
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                   style: TextStyle(
                     color: colorScheme.error,
                     fontSize: 14,
                     fontWeight: FontWeight.w600,
                   ),
                 ),
               ),
             ],
           ),
         ),
       );
}

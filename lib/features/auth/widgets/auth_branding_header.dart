// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';

class AuthBrandingHeader extends StatelessWidget {
  const AuthBrandingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.colorScheme.primaryContainer.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: const Image(
            image: AssetImage(
              'assets/logo/app_icon_foreground.png',
            ),
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "G-Scanner",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: context.colorScheme.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "auth.branding.tagline".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

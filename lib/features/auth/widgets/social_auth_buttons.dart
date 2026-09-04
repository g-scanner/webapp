// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';

class SocialAuthButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onFacebookSignIn;
  final VoidCallback onAnonymousSignIn;

  const SocialAuthButtons({
    super.key,
    required this.isLoading,
    required this.onGoogleSignIn,
    required this.onFacebookSignIn,
    required this.onAnonymousSignIn,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: CircularProgressIndicator(color: context.colorScheme.primary),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSocialBtn(
          context: context,
          text: "auth.social.continueWithGoogle".tr(),
          iconWidget: Image.asset(
            'assets/icons/google.png',
            width: 20,
            height: 20,
          ),
          bgColor: context.colorScheme.primary,
          textColor: context.colorScheme.onPrimary,
          onTap: onGoogleSignIn,
        ),
        const SizedBox(height: 12),
        _buildSocialBtn(
          context: context,
          text: "auth.social.continueWithFacebook".tr(),
          iconWidget: Image.asset(
            'assets/icons/facebook.png',
            width: 20,
            height: 20,
          ),
          bgColor: context.cardBackground,
          textColor: context.colorScheme.onSurface,
          borderColor: context.colorScheme.outlineVariant,
          onTap: onFacebookSignIn,
        ),
        const SizedBox(height: 24),

        // --- GUEST ENTRY ---
        Row(
          children: [
            Expanded(
              child: Divider(
                color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
                thickness: 1.5,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "auth.social.or".tr(),
                style: TextStyle(
                  fontSize: 14,
                  color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
                thickness: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: onAnonymousSignIn,
          icon: const Icon(Icons.person_off, size: 18),
          label: Text(
            "auth.social.enterAnonymously".tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: context.colorScheme.primary,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "auth.social.anonymousDisclaimer".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialBtn({
    required BuildContext context,
    required String text,
    required Widget iconWidget,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
    Color? borderColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: borderColor == null
              ? [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: borderColor == null
                  ? const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: iconWidget,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

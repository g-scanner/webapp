// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../licenses/licenses_screen.dart';
import '../dialogs/legal_content_dialog.dart';
import '../dialogs/native_legal_texts.dart';
import 'legal_item.dart';

/// Sezione informativa legale M3 (Termini, Privacy Policy, Licenze).
class LegalSection extends StatelessWidget {
  const LegalSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    return Material(
      color: cardBg,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          buildLegalItem(
            title: "settings.legalMenu.termsAndConditionsTitle".tr(),
            subtitle: Text(
              "settings.legalMenu.termsAndConditionsSubtitle".tr(),
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
            onTap: () {
              showLegalBottomSheet(
                context,
                "settings.legalMenu.termsAndConditionsTitle".tr(),
                buildNativeTos(colorScheme.onSurfaceVariant),
              );
            },
            showTrailingArrow: true,
            isFirst: true,
          ),
          buildLegalItem(
            title: "settings.legalMenu.privacyPolicyTitle".tr(),
            subtitle: Text(
              "settings.legalMenu.privacyPolicySubtitle".tr(),
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
            onTap: () {
              showLegalBottomSheet(
                context,
                "settings.legalMenu.privacyPolicyTitle".tr(),
                buildNativePrivacyPolicy(colorScheme.onSurfaceVariant),
              );
            },
            showTrailingArrow: true,
          ),
          buildLegalItem(
            title: "settings.legalMenu.licensesTitle".tr(),
            subtitle: Text(
              "settings.legalMenu.licensesSubtitle".tr(),
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomLicensesPage(),
                ),
              );
            },
            showTrailingArrow: true,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

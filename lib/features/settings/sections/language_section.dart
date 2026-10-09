// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/widgets/widgets.dart';

/// Sezione "Lingua" con selettore lingua a popup.
class LanguageSection extends StatelessWidget {
  final String preferredLanguage;
  final void Function(String) onLanguageChange;

  const LanguageSection({
    super.key,
    required this.preferredLanguage,
    required this.onLanguageChange,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsDropdownTile<String>(
      title: "settings.uiOptions.preferredLanguageTitle".tr(),
      subtitle: "settings.uiOptions.preferredLanguageSubtitle".tr(),
      tooltip: "Scegli lingua",
      selectedValue: preferredLanguage,
      options: [
        SettingsDropdownOption(
          value: 'it',
          label: "common.languages.it".tr(),
        ),
        SettingsDropdownOption(
          value: 'en',
          label: "common.languages.en".tr(),
        ),
        SettingsDropdownOption(
          value: 'es',
          label: "common.languages.es".tr(),
        ),
        SettingsDropdownOption(
          value: 'de',
          label: "common.languages.de".tr(),
        ),
        SettingsDropdownOption(
          value: 'fr',
          label: "common.languages.fr".tr(),
        ),
      ],
      onSelected: onLanguageChange,
    );
  }
}

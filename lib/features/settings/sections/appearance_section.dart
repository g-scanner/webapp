// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/widgets/widgets.dart';

/// Sezione "Aspetto" con selettore tema a popup.
class AppearanceSection extends StatelessWidget {
  final String preferredTheme;
  final void Function(String) onThemeChange;

  const AppearanceSection({
    super.key,
    required this.preferredTheme,
    required this.onThemeChange,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsDropdownTile<String>(
      title: "settings.uiOptions.appThemeTitle".tr(),
      subtitle: "settings.uiOptions.appThemeSubtitle".tr(),
      tooltip: "settings.uiOptions.tooltips.theme".tr(),
      selectedValue: preferredTheme,
      options: [
        SettingsDropdownOption(
          value: 'system',
          label: "common.themes.system".tr(),
        ),
        SettingsDropdownOption(
          value: 'light',
          label: "common.themes.light".tr(),
        ),
        SettingsDropdownOption(
          value: 'dark',
          label: "common.themes.dark".tr(),
        ),
      ],
      onSelected: onThemeChange,
    );
  }
}

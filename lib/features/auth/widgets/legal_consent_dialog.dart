// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';

class LegalConsentDialog extends StatefulWidget {
  final String lang;
  const LegalConsentDialog({super.key, required this.lang});

  @override
  State<LegalConsentDialog> createState() => _LegalConsentDialogState();
}

class _LegalConsentDialogState extends State<LegalConsentDialog> {
  bool _isChecked = false;

  late final TapGestureRecognizer _tosRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  String get tosUrl {
    switch (widget.lang) {
      case 'it':
        return 'https://g-scanner.github.io/it/TerminiDiServizio.html';
      case 'es':
        return 'https://g-scanner.github.io/es/TerminosYCondiciones.html';
      case 'de':
        return 'https://g-scanner.github.io/de/Nutzungsbedingungen.html';
      case 'fr':
        return 'https://g-scanner.github.io/fr/ConditionsDUtilisation.html';
      default:
        return 'https://g-scanner.github.io/TermsOfService.html';
    }
  }

  String get privacyUrl {
    switch (widget.lang) {
      case 'it':
        return 'https://g-scanner.github.io/it/InformativaSullaPrivacy.html';
      case 'es':
        return 'https://g-scanner.github.io/es/PoliticaDePrivacidad.html';
      case 'de':
        return 'https://g-scanner.github.io/de/Datenschutzerklaerung.html';
      case 'fr':
        return 'https://g-scanner.github.io/fr/PolitiqueDeConfidentialite.html';
      default:
        return 'https://g-scanner.github.io/PrivacyPolicy.html';
    }
  }

  @override
  void initState() {
    super.initState();
    _tosRecognizer = TapGestureRecognizer()..onTap = () => _launchURL(tosUrl);
    _privacyRecognizer = TapGestureRecognizer()..onTap = () => _launchURL(privacyUrl);
  }

  @override
  void dispose() {
    _tosRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Dialog(
        backgroundColor: context.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con Icona e Titolo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.gavel_rounded,
                      color: context.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      "auth.legal.dialogTitle".tr(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Testo introduttivo
              Text(
                "auth.legal.dialogIntro".tr(),
                style: TextStyle(
                  fontSize: 14,
                  color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // Bullets
              _buildBulletItem(
                title: "auth.legal.bullet1Title".tr(),
                description: "auth.legal.bullet1Body".tr(),
              ),
              const SizedBox(height: 10),
              _buildBulletItem(
                title: "auth.legal.bullet2Title".tr(),
                description: "auth.legal.bullet2Body".tr(),
              ),
              const SizedBox(height: 10),
              _buildBulletItem(
                title: "auth.legal.bullet3Title".tr(),
                description: "auth.legal.bullet3Body".tr(),
              ),
              const SizedBox(height: 18),

              Divider(
                color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
                height: 1,
              ),
              const SizedBox(height: 14),

              // Checkbox con link a ToS e Privacy
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _isChecked,
                      activeColor: context.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) {
                        setState(() => _isChecked = val ?? false);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isChecked = !_isChecked);
                      },
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: context.colorScheme.onSurface,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: "auth.legal.checkboxPre".tr(),
                            ),
                            TextSpan(
                              text: "auth.legal.checkboxTos".tr(),
                              style: TextStyle(
                                color: context.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: _tosRecognizer,
                            ),
                            TextSpan(text: "auth.legal.checkboxMid".tr()),
                            TextSpan(
                              text: "auth.legal.checkboxPrivacy".tr(),
                              style: TextStyle(
                                color: context.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: _privacyRecognizer,
                            ),
                            TextSpan(text: "auth.legal.checkboxPost".tr()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Pulsante INIZIA
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isChecked
                      ? () => Navigator.pop(context, true)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colorScheme.primary,
                    disabledBackgroundColor: context.colorScheme.surfaceContainerHighest,
                    disabledForegroundColor: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "auth.legal.startButton".tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletItem({
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: context.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: context.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: "$title: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

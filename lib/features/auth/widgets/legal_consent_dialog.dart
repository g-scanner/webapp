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
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _launchURL(privacyUrl);
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
          side: BorderSide(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero Icon da 80dp (Stile SyncDataScreen) ──
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: context.colorScheme.primary.withValues(
                        alpha: 0.10,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.gavel_rounded,
                      size: 36,
                      color: context.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Titolo ──
                Text(
                  "auth.legal.dialogTitle".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Introduzione ──
                Text(
                  "auth.legal.dialogIntro".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),

                // ── 3 Punti Liberi con Icona Centrata Verticalmente ──
                _buildCenteredPointRow(
                  context: context,
                  icon: Icons.volunteer_activism_outlined,
                  title: "auth.legal.bullet1Title".tr(),
                  description: "auth.legal.bullet1Body".tr(),
                ),
                const SizedBox(height: 14),
                _buildCenteredPointRow(
                  context: context,
                  icon: Icons.medical_services_outlined,
                  title: "auth.legal.bullet2Title".tr(),
                  description: "auth.legal.bullet2Body".tr(),
                ),
                const SizedBox(height: 14),
                _buildCenteredPointRow(
                  context: context,
                  icon: Icons.balance_outlined,
                  title: "auth.legal.bullet3Title".tr(),
                  description: "auth.legal.bullet3Body".tr(),
                ),
                const SizedBox(height: 22),

                // ── L'UNICA CARD: Checkbox con Allineamento Centrato ──
                GestureDetector(
                  key: const Key('legalConsentCheckbox'),
                  onTap: () => setState(() => _isChecked = !_isChecked),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _isChecked
                          ? context.colorScheme.primaryContainer.withValues(
                              alpha: 0.08,
                            )
                          : context.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isChecked
                            ? context.colorScheme.primary.withValues(
                                alpha: 0.25,
                              )
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // Centrata verticalmente rispetto al testo
                      children: [
                        // Checkbox circolare coordinata
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _isChecked
                                ? context.colorScheme.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: _isChecked
                                ? null
                                : Border.all(
                                    color: context.colorScheme.outlineVariant
                                        .withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                          ),
                          child: _isChecked
                              ? Icon(
                                  Icons.check,
                                  size: 14,
                                  color: context.colorScheme.onPrimary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // Testo legale con collegamenti preservati
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: 13,
                                color: context.colorScheme.onSurface,
                                height: 1.45,
                              ),
                              children: [
                                TextSpan(text: "auth.legal.checkboxPre".tr()),
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
                                  text: "common.legal.privacyPolicy".tr(),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Pulsante INIZIA (Altezza 56dp, radius 32px) ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isChecked
                        ? () => Navigator.pop(context, true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.colorScheme.primary,
                      foregroundColor: context.colorScheme.onPrimary,
                      disabledBackgroundColor: context.colorScheme.primary
                          .withValues(alpha: 0.3),
                      disabledForegroundColor: context.colorScheme.onPrimary
                          .withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: Text(
                      "auth.legal.startButton".tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredPointRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colorScheme = context.colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center, // Centratura verticale rispetto al testo
      children: [
        Icon(icon, size: 22, color: colorScheme.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

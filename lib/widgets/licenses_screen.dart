// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class CustomLicensesPage extends StatefulWidget {
  const CustomLicensesPage({super.key});

  @override
  State<CustomLicensesPage> createState() => _CustomLicensesPageState();
}

class _CustomLicensesPageState extends State<CustomLicensesPage> {
  Map<String, List<String>> _ossLicenses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    final Map<String, List<String>> licenses = {};

    await for (final entry in LicenseRegistry.licenses) {
      for (final package in entry.packages) {
        final text = entry.paragraphs.map((p) => p.text).join('\n\n');
        licenses.putIfAbsent(package, () => []).add(text);
      }
    }

    final sortedLicenses = Map.fromEntries(
      licenses.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    if (mounted) {
      setState(() {
        _ossLicenses = sortedLicenses;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Licenze e Note Legali",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        children: [
          // ==========================================
          // SEZIONE 1: LA TUA LICENZA PROPRIETARIA
          // ==========================================
          _buildSectionHeader(
            icon: Icons.copyright,
            title: "Licenza G-Scanner",
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text:
                        "Copyright (c) 2026 Emanuele Ciotola. Tutti i diritti riservati.\n\n",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const TextSpan(
                    text:
                        "G-Scanner è un software closed-source e proprietario. Il codice sorgente è reso pubblicamente visibile (\"Source-Available\") esclusivamente a scopo di trasparenza, verifica tecnica e portfolio personale.\n\n",
                  ),
                  const TextSpan(text: "Per qualsiasi dubbio, consulta la "),
                  TextSpan(
                    text: "Licenza Completa",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final url = Uri.parse(
                          'https://github.com/tuo-username/g-scanner/blob/main/LICENSE',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                  ),
                  const TextSpan(text: "."),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // ==========================================
          // SEZIONE 2: FONTE DATI E DISCLAIMER (OFF)
          // ==========================================
          _buildSectionHeader(
            icon: Icons.source_outlined,
            title: "Fonte Dati",
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text:
                        "I dati sui prodotti sono forniti dalla community di ",
                  ),
                  TextSpan(
                    text: "Open Food Facts",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final url = Uri.parse(
                          'https://world.openfoodfacts.org',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                  ),
                  const TextSpan(
                    text: ". I dati sono rilasciati sotto licenza ",
                  ),
                  TextSpan(
                    text: "Open Database License (ODbL)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final url = Uri.parse(
                          'https://opendatacommons.org/licenses/odbl/1-0/',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                  ),
                  const TextSpan(text: ".\n\n"),
                  const TextSpan(
                    text:
                        "Verifica SEMPRE fisicamente l'etichetta e le scritte sul prodotto prima di consumarlo. L'app non sostituisce il parere medico.",
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // ==========================================
          // SEZIONE 3: LIBRERIE OPEN SOURCE (Dinamica)
          // ==========================================
          _buildSectionHeader(
            icon: Icons.code_rounded,
            title: "Librerie Open Source",
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final Map<String, List<String>> displayLicenses = _isLoading
                  ? {
                      'Libreria Finta Molto Lunga 1': [''],
                      'Pacchetto Finto 2': [''],
                      'Altra Libreria 3': [''],
                      'Flutter Package 4': [''],
                      'Pacchetto 5': [''],
                    }
                  : _ossLicenses;

              return Skeletonizer(
                enabled: _isLoading,
                effect: ShimmerEffect(
                  baseColor: colorScheme.surfaceContainerHighest,
                  highlightColor: cardBg,
                ),
                child: Material(
                  color: cardBg,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: displayLicenses.entries.toList().asMap().entries.expand((
                      entry,
                    ) {
                      final i = entry.key;
                      final packageName = entry.value.key;
                      final licenseTexts = entry.value.value;

                      final isFirst = i == 0;
                      final isLast = i == displayLicenses.length - 1;

                      return [
                        ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          tilePadding: EdgeInsets.only(
                            left: 25,
                            right: 25,
                            top: isFirst ? 8.0 : 0.0,
                            bottom: isLast ? 8.0 : 0.0,
                          ),
                          iconColor: colorScheme.primary,
                          collapsedIconColor: colorScheme.onSurfaceVariant,
                          title: Text(
                            packageName,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          children: licenseTexts.asMap().entries.map((
                            textEntry,
                          ) {
                            final isLastText =
                                textEntry.key == licenseTexts.length - 1;
                            return Container(
                              width: double.infinity,
                              color: colorScheme.surfaceContainerHighest.withValues(
                                alpha: 0.3,
                              ),
                              padding: EdgeInsets.only(
                                left: 24,
                                right: 24,
                                top: 24,
                                bottom: (isLast && isLastText) ? 32.0 : 24.0,
                              ),
                              child: Text(
                                textEntry.value,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ];
                    }).toList(),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: color,
          ),
        ),
      ],
    );
  }
}

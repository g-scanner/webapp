// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

// Usa i colori del tuo tema
const Color bgBackground = Color(0xFFFAF9FC);
const Color surfaceLowest = Color(0xFFFFFFFF);
const Color onSurface = Color(0xFF1B1B1E);
const Color onSurfaceVariant = Color(0xFF40493D);
const Color surfaceContainerHigh = Color(0xFFE9E7EB);
const Color primary = Color(0xFF0D631B);
const Color outlineVariant = Color(0xFFBFCABA);

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
    return Scaffold(
      backgroundColor: bgBackground,
      appBar: AppBar(
        backgroundColor: bgBackground,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: onSurface),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "Licenze e Note Legali",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
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
            color: primary,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceLowest,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: onSurfaceVariant,
                  fontSize: 13,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text:
                        "Copyright (c) 2026 Emanuele Ciotola. Tutti i diritti riservati.\n\n",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const TextSpan(
                    text:
                        "G-Scanner è un software closed-source e proprietario. Il codice sorgente è reso pubblicamente visibile (\"Source-Available\") esclusivamente a scopo di trasparenza, verifica tecnica e portfolio personale.\n\n",
                  ),
                  const TextSpan(text: "Per qualsiasi dubbio, consulta la "),
                  TextSpan(
                    text: "Licenza Completa",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        // Sostituisci con il link reale alla tua repository GitHub
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
            color: primary,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceLowest,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: onSurfaceVariant,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text:
                        "I dati sui prodotti sono forniti dalla community di ",
                  ),
                  TextSpan(
                    text: "Open Food Facts",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primary,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primary,
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
            color: primary,
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
                  baseColor: surfaceContainerHigh,
                  highlightColor: surfaceLowest,
                ),
                child: Material(
                  color: surfaceLowest,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(
                      color: outlineVariant.withValues(alpha: 0.3),
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
                          // Rimuove i bordi nativi di default (sia a riposo che espansi)
                          // che occupavano fisicamente 1px e causavano il distacco
                          shape: const Border(),
                          collapsedShape: const Border(),
                          tilePadding: EdgeInsets.only(
                            left: 25,
                            right: 25,
                            top: isFirst ? 8.0 : 0.0,
                            bottom: isLast ? 8.0 : 0.0,
                          ),
                          iconColor: primary,
                          collapsedIconColor: onSurfaceVariant,
                          title: Text(
                            packageName,
                            style: const TextStyle(
                              color: onSurface,
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
                              color: surfaceContainerHigh.withValues(
                                alpha: 0.2,
                              ),
                              padding: EdgeInsets.only(
                                left: 24,
                                right: 24,
                                top: 24,
                                bottom: (isLast && isLastText) ? 32.0 : 24.0,
                              ),
                              child: Text(
                                textEntry.value,
                                style: const TextStyle(
                                  color: onSurfaceVariant,
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

  // Header IDENTICO a quello di SettingsPanel (M3 sottile ed elegante)
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

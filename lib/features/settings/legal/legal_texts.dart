// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'tos_it.dart';
import 'tos_en.dart';
import 'tos_es.dart';
import 'tos_de.dart';
import 'tos_fr.dart';
import 'pp_it.dart';
import 'pp_en.dart';
import 'pp_es.dart';
import 'pp_de.dart';
import 'pp_fr.dart';

/// Accesso istantaneo e sincrono ai testi legali (ToS e Privacy Policy)
/// suddivisi per lingua. Garantisce 0ms di caricamento e zero delay di I/O.
class LegalTexts {
  const LegalTexts._();

  static String getTos(String lang) {
    switch (lang.toLowerCase()) {
      case 'en':
        return tosEn;
      case 'es':
        return tosEs;
      case 'de':
        return tosDe;
      case 'fr':
        return tosFr;
      case 'it':
      default:
        return tosIt;
    }
  }

  static String getPrivacyPolicy(String lang) {
    switch (lang.toLowerCase()) {
      case 'en':
        return ppEn;
      case 'es':
        return ppEs;
      case 'de':
        return ppDe;
      case 'fr':
        return ppFr;
      case 'it':
      default:
        return ppIt;
    }
  }

  static String get(String type, String lang) {
    if (type == 'tos') {
      return getTos(lang);
    }
    if (type == 'pp') {
      return getPrivacyPolicy(lang);
    }
    return '';
  }
}

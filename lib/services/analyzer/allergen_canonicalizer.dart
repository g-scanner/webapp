// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'gluten_rules.dart';

class AllergenCanonicalizer {
  // ─── MAPPA CANONICALIZZAZIONE (input qualsiasi lingua → chiave canonica) ──
  static const Map<String, String> allergenCanonical = {
    // Glutine (tag compositi OFF)
    'cereals-containing-gluten': 'gluten',
    'gluten-containing-cereals': 'gluten',
    'cereals-and-products-thereof': 'gluten',
    // Latte
    'milk': 'milk',
    'lait': 'milk',
    'melk': 'milk',
    'leche': 'milk',
    'milch': 'milk',
    'latte': 'milk',
    'lattosio': 'milk',
    'milk-and-products-thereof': 'milk',
    // Frumento / Grano
    'wheat': 'wheat',
    'blé': 'wheat',
    'trigo': 'wheat',
    'weizen': 'wheat',
    'grano': 'wheat',
    'frumento': 'wheat',
    'semolina': 'wheat',
    'froment': 'wheat',
    'wheat-and-products-thereof': 'wheat',
    // Orzo
    'barley': 'barley',
    'orge': 'barley',
    'cebada': 'barley',
    'gerste': 'barley',
    'orzo': 'barley',
    // Segale
    'rye': 'rye',
    'seigle': 'rye',
    'centeno': 'rye',
    'roggen': 'rye',
    'segale': 'rye',
    // Avena
    'oat': 'oat',
    'oats': 'oat',
    'avoine': 'oat',
    'hafer': 'oat',
    'avena': 'oat',
    'oats-and-products-thereof': 'oat',
    // Farro / Spelta
    'spelt': 'spelt',
    'épeautre': 'spelt',
    'espelta': 'spelt',
    'dinkel': 'spelt',
    'farro': 'spelt',
    // Glutine (generico)
    'gluten': 'gluten',
    'glutine': 'gluten',
    // Soia
    'soy': 'soy',
    'soja': 'soy',
    'soybeans': 'soy',
    'soia': 'soy',
    'soybeans-and-products-thereof': 'soy',
    'soy-and-products-thereof': 'soy',
    // Uova
    'egg': 'egg',
    'eggs': 'egg',
    'œuf': 'egg',
    'huevo': 'egg',
    'ei': 'egg',
    'uovo': 'egg',
    'uova': 'egg',
    'eggs-and-products-thereof': 'egg',
    // Arachidi
    'peanut': 'peanut',
    'peanuts': 'peanut',
    'cacahuète': 'peanut',
    'cacahuete': 'peanut',
    'erdnuss': 'peanut',
    'arachidi': 'peanut',
    'peanuts-and-products-thereof': 'peanut',
    // Frutta a guscio (generica)
    'nut': 'nut',
    'nuts': 'nut',
    'fruits à coque': 'nut',
    'frutos de cáscara': 'nut',
    'schalenfrüchte': 'nut',
    'frutta a guscio': 'nut',
    'tree-nuts': 'nut',
    'tree-nuts-and-products-thereof': 'nut',
    // Mandorle
    'almond': 'almond',
    'almonds': 'almond',
    'amande': 'almond',
    'almendra': 'almond',
    'mandel': 'almond',
    'mandorle': 'almond',
    // Nocciole
    'hazelnut': 'hazelnut',
    'hazelnuts': 'hazelnut',
    'noisette': 'hazelnut',
    'avellana': 'hazelnut',
    'haselnuss': 'hazelnut',
    'nocciole': 'hazelnut',
    // Noci
    'walnut': 'walnut',
    'walnuts': 'walnut',
    'noix': 'walnut',
    'nuez': 'walnut',
    'walnuss': 'walnut',
    'noci': 'walnut',
    // Anacardi
    'cashew': 'cashew',
    'cashews': 'cashew',
    'noix de cajou': 'cashew',
    'anacardo': 'cashew',
    'cashewnuss': 'cashew',
    'anacardi': 'cashew',
    // Noci pecan
    'pecan': 'pecan',
    'noix de pécan': 'pecan',
    'pekannuss': 'pecan',
    'noci pecan': 'pecan',
    // Noci del Brasile
    'brazil nut': 'brazil_nut',
    'noix du brésil': 'brazil_nut',
    'paranuss': 'brazil_nut',
    'nuez de brasil': 'brazil_nut',
    'noci del brasile': 'brazil_nut',
    // Pistacchi
    'pistachio': 'pistachio',
    'pistachios': 'pistachio',
    'pistache': 'pistachio',
    'pistacho': 'pistachio',
    'pistazie': 'pistachio',
    'pistacchi': 'pistachio',
    // Macadamia
    'macadamia': 'macadamia',
    'noix de macadamia': 'macadamia',
    'nuez de macadamia': 'macadamia',
    'macadamianuss': 'macadamia',
    'noci macadamia': 'macadamia',
    // Sedano
    'celery': 'celery',
    'céleri': 'celery',
    'apio': 'celery',
    'sellerie': 'celery',
    'sedano': 'celery',
    'celery-and-products-thereof': 'celery',
    // Senape
    'mustard': 'mustard',
    'moutarde': 'mustard',
    'mostaza': 'mustard',
    'senf': 'mustard',
    'senape': 'mustard',
    'mustard-and-products-thereof': 'mustard',
    // Sesamo
    'sesame': 'sesame',
    'sésame': 'sesame',
    'sésamo': 'sesame',
    'sesam': 'sesame',
    'sesame-seeds': 'sesame',
    'sesame seeds': 'sesame',
    'sesamo': 'sesame',
    'sesame-seeds-and-products-thereof': 'sesame',
    // Solfiti
    'sulphur dioxide': 'sulphites',
    'sulfites': 'sulphites',
    'sulphites': 'sulphites',
    'anhydride sulfureux': 'sulphites',
    'dióxido de azufre': 'sulphites',
    'schwefeldioxid': 'sulphites',
    'solfiti': 'sulphites',
    'anidride solforosa': 'sulphites',
    'sulphur-dioxide-and-sulphites': 'sulphites',
    'sulfur-dioxide-and-sulfites': 'sulphites',
    'sulphur-dioxide': 'sulphites',
    // Lupini
    'lupin': 'lupin',
    'lupins': 'lupin',
    'altramuz': 'lupin',
    'lupine': 'lupin',
    'lupini': 'lupin',
    'lupin-and-products-thereof': 'lupin',
    // Molluschi
    'mollusc': 'mollusc',
    'molluscs': 'mollusc',
    'mollusques': 'mollusc',
    'moluscos': 'mollusc',
    'weichtiere': 'mollusc',
    'molluschi': 'mollusc',
    'molluscs-and-products-thereof': 'mollusc',
    // Pesce
    'fish': 'fish',
    'poisson': 'fish',
    'pescado': 'fish',
    'fisch': 'fish',
    'pesce': 'fish',
    'fish-and-products-thereof': 'fish',
    // Crostacei
    'crustacean': 'crustacean',
    'crustaceans': 'crustacean',
    'crustacés': 'crustacean',
    'crustáceos': 'crustacean',
    'krebstiere': 'crustacean',
    'crostacei': 'crustacean',
    'crustaceans-and-products-thereof': 'crustacean',
  };

  // ─── NOMI VISUALIZZATI PER LINGUA (chiave canonica → lingua → label) ──────
  static const Map<String, Map<String, String>> allergenDisplayNames = {
    'milk': {
      'it': 'Latte',
      'en': 'Milk',
      'de': 'Milch',
      'fr': 'Lait',
      'es': 'Leche',
    },
    'wheat': {
      'it': 'Frumento',
      'en': 'Wheat',
      'de': 'Weizen',
      'fr': 'Blé',
      'es': 'Trigo',
    },
    'barley': {
      'it': 'Orzo',
      'en': 'Barley',
      'de': 'Gerste',
      'fr': 'Orge',
      'es': 'Cebada',
    },
    'rye': {
      'it': 'Segale',
      'en': 'Rye',
      'de': 'Roggen',
      'fr': 'Seigle',
      'es': 'Centeno',
    },
    'oat': {
      'it': 'Avena',
      'en': 'Oats',
      'de': 'Hafer',
      'fr': 'Avoine',
      'es': 'Avena',
    },
    'spelt': {
      'it': 'Farro',
      'en': 'Spelt',
      'de': 'Dinkel',
      'fr': 'Épeautre',
      'es': 'Espelta',
    },
    'gluten': {
      'it': 'Glutine',
      'en': 'Gluten',
      'de': 'Gluten',
      'fr': 'Gluten',
      'es': 'Gluten',
    },
    'soy': {
      'it': 'Soia',
      'en': 'Soy',
      'de': 'Soja',
      'fr': 'Soja',
      'es': 'Soja',
    },
    'egg': {
      'it': 'Uova',
      'en': 'Eggs',
      'de': 'Eier',
      'fr': 'Œufs',
      'es': 'Huevos',
    },
    'peanut': {
      'it': 'Arachidi',
      'en': 'Peanuts',
      'de': 'Erdnüsse',
      'fr': 'Cacahuètes',
      'es': 'Cacahuetes',
    },
    'nut': {
      'it': 'Frutta a guscio',
      'en': 'Tree nuts',
      'de': 'Schalenfrüchte',
      'fr': 'Fruits à coque',
      'es': 'Frutos de cáscara',
    },
    'almond': {
      'it': 'Mandorle',
      'en': 'Almonds',
      'de': 'Mandeln',
      'fr': 'Amandes',
      'es': 'Almendras',
    },
    'hazelnut': {
      'it': 'Nocciole',
      'en': 'Hazelnuts',
      'de': 'Haselnüsse',
      'fr': 'Noisettes',
      'es': 'Avellanas',
    },
    'walnut': {
      'it': 'Noci',
      'en': 'Walnuts',
      'de': 'Walnüsse',
      'fr': 'Noix',
      'es': 'Nueces',
    },
    'cashew': {
      'it': 'Anacardi',
      'en': 'Cashews',
      'de': 'Cashewkerne',
      'fr': 'Noix de cajou',
      'es': 'Anacardos',
    },
    'pecan': {
      'it': 'Noci pecan',
      'en': 'Pecan nuts',
      'de': 'Pekannüsse',
      'fr': 'Noix de pécan',
      'es': 'Nueces pecán',
    },
    'brazil_nut': {
      'it': 'Noci del Brasile',
      'en': 'Brazil nuts',
      'de': 'Paranüsse',
      'fr': 'Noix du Brasile',
      'es': 'Nueces de Brasile',
    },
    'pistachio': {
      'it': 'Pistacchi',
      'en': 'Pistachios',
      'de': 'Pistazien',
      'fr': 'Pistaches',
      'es': 'Pistachos',
    },
    'macadamia': {
      'it': 'Noci macadamia',
      'en': 'Macadamia nuts',
      'de': 'Macadamianüsse',
      'fr': 'Noix de macadamia',
      'es': 'Nueces de macadamia',
    },
    'celery': {
      'it': 'Sedano',
      'en': 'Celery',
      'de': 'Sellerie',
      'fr': 'Céleri',
      'es': 'Apio',
    },
    'mustard': {
      'it': 'Senape',
      'en': 'Mustard',
      'de': 'Senf',
      'fr': 'Moutarde',
      'es': 'Mostaza',
    },
    'sesame': {
      'it': 'Sesamo',
      'en': 'Sesame',
      'de': 'Sesam',
      'fr': 'Sésame',
      'es': 'Sésamo',
    },
    'sulphites': {
      'it': 'Solfiti',
      'en': 'Sulphites',
      'de': 'Sulfite',
      'fr': 'Sulfites',
      'es': 'Sulfitos',
    },
    'lupin': {
      'it': 'Lupini',
      'en': 'Lupin',
      'de': 'Lupinen',
      'fr': 'Lupin',
      'es': 'Altramuces',
    },
    'mollusc': {
      'it': 'Molluschi',
      'en': 'Molluscs',
      'de': 'Weichtiere',
      'fr': 'Mollusques',
      'es': 'Moluscos',
    },
    'fish': {
      'it': 'Pesce',
      'en': 'Fish',
      'de': 'Fisch',
      'fr': 'Poisson',
      'es': 'Pescado',
    },
    'crustacean': {
      'it': 'Crostacei',
      'en': 'Crustaceans',
      'de': 'Krebstiere',
      'fr': 'Crustacés',
      'es': 'Crustáceos',
    },
  };

  /// Restituisce `true` se il testo o tag è una dichiarazione di sicurezza/assenza di glutine
  static bool isSafeGlutenClaim(String text) {
    if (text.trim().isEmpty) return false;
    final lowerA = text.trim().toLowerCase();
    final withoutPrefix =
        lowerA.contains(':') ? lowerA.split(':').last.trim() : lowerA;

    return GlutenRules.safeTextKeywords.any((safe) {
      final safeClean = safe.toLowerCase().trim();
      final safeHyphen = safeClean.replaceAll(' ', '-');
      final safeUnderscore = safeClean.replaceAll(' ', '_');
      return lowerA == safeClean ||
          lowerA == safeHyphen ||
          lowerA == safeUnderscore ||
          withoutPrefix == safeClean ||
          withoutPrefix == safeHyphen ||
          withoutPrefix == safeUnderscore ||
          lowerA.contains(safeClean) ||
          withoutPrefix.contains(safeHyphen) ||
          withoutPrefix.contains(safeUnderscore);
    });
  }

  static List<String> translateAllergens(
    List<String> allergensList,
    String preferredLanguage,
  ) {
    // Ordine di preferenza: lingua scelta > lingue app > prima disponibile
    final List<String> langPriority = [
      preferredLanguage,
      'it',
      'en',
      'de',
      'fr',
      'es',
    ];

    List<String> translatedAllergens = allergensList
        .where((a) => !isSafeGlutenClaim(a))
        .map((a) {
          String clean = a.trim().toLowerCase();
          // Rimuove prefissi lingua OFF (es. "en:milk" -> "milk")
          if (clean.contains(':')) {
            clean = clean.split(':').last;
          }
          final canonical = allergenCanonical[clean];
          if (canonical != null) {
            final langMap = allergenDisplayNames[canonical];
            if (langMap != null) {
              for (final lang in langPriority) {
                if (langMap.containsKey(lang)) return langMap[lang]!;
              }
              return langMap.values.first;
            }
          }
          if (clean.isEmpty) return clean;
          return clean[0].toUpperCase() + clean.substring(1);
        })
        .where((a) => !isSafeGlutenClaim(a))
        .toSet()
        .toList();

    return translatedAllergens.where((a) => a.isNotEmpty).toList();
  }
}

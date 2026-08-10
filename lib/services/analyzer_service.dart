// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

import '../models/types.dart';

class OffTags {
  final List<String> allergensTags;
  final List<String> tracesTags;
  final List<String> labelsTags;
  final List<String> ingredientsAnalysisTags;

  OffTags({
    required this.allergensTags,
    required this.tracesTags,
    required this.labelsTags,
    required this.ingredientsAnalysisTags,
  });
}

class AnalyzerResult {
  final GlutenSafetyStatus status;
  final String reason;
  final List<String> allergens;
  final List<IngredientAnalyzed> ingredientsAnalyzed;

  AnalyzerResult({
    required this.status,
    required this.reason,
    required this.allergens,
    required this.ingredientsAnalyzed,
  });
}

class AnalyzerService {
  // ─── DIZIONARI KEYWORDS ──────────────────────────────────────────────────

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
    'latte': 'milk', 'lattosio': 'milk',
    'milk-and-products-thereof': 'milk',
    // Frumento / Grano
    'wheat': 'wheat', 'blé': 'wheat', 'trigo': 'wheat', 'weizen': 'wheat',
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
    'gluten': 'gluten', 'glutine': 'gluten',
    // Soia
    'soy': 'soy', 'soja': 'soy', 'soybeans': 'soy', 'soia': 'soy',
    'soybeans-and-products-thereof': 'soy', 'soy-and-products-thereof': 'soy',
    // Uova
    'egg': 'egg', 'eggs': 'egg', 'œuf': 'egg', 'huevo': 'egg', 'ei': 'egg',
    'uovo': 'egg', 'uova': 'egg',
    'eggs-and-products-thereof': 'egg',
    // Arachidi
    'peanut': 'peanut',
    'peanuts': 'peanut',
    'cacahuète': 'peanut',
    'cacahuete': 'peanut',
    'erdnuss': 'peanut', 'arachidi': 'peanut',
    'peanuts-and-products-thereof': 'peanut',
    // Frutta a guscio (generica)
    'nut': 'nut',
    'nuts': 'nut',
    'fruits à coque': 'nut',
    'frutos de cáscara': 'nut',
    'schalenfrüchte': 'nut', 'frutta a guscio': 'nut',
    'tree-nuts': 'nut', 'tree-nuts-and-products-thereof': 'nut',
    // Mandorle
    'almond': 'almond',
    'almonds': 'almond',
    'amande': 'almond',
    'almendra': 'almond',
    'mandel': 'almond', 'mandorle': 'almond',
    // Nocciole
    'hazelnut': 'hazelnut', 'hazelnuts': 'hazelnut', 'noisette': 'hazelnut',
    'avellana': 'hazelnut', 'haselnuss': 'hazelnut', 'nocciole': 'hazelnut',
    // Noci
    'walnut': 'walnut', 'walnuts': 'walnut', 'noix': 'walnut', 'nuez': 'walnut',
    'walnuss': 'walnut', 'noci': 'walnut',
    // Anacardi
    'cashew': 'cashew', 'cashews': 'cashew', 'noix de cajou': 'cashew',
    'anacardo': 'cashew', 'cashewnuss': 'cashew', 'anacardi': 'cashew',
    // Noci pecan
    'pecan': 'pecan',
    'noix de pécan': 'pecan',
    'pekannuss': 'pecan',
    'noci pecan': 'pecan',
    // Noci del Brasile
    'brazil nut': 'brazil_nut',
    'noix du brésil': 'brazil_nut',
    'paranuss': 'brazil_nut',
    'nuez de brasil': 'brazil_nut', 'noci del brasile': 'brazil_nut',
    // Pistacchi
    'pistachio': 'pistachio',
    'pistachios': 'pistachio',
    'pistache': 'pistachio',
    'pistacho': 'pistachio', 'pistazie': 'pistachio', 'pistacchi': 'pistachio',
    // Macadamia
    'macadamia': 'macadamia', 'noix de macadamia': 'macadamia',
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
    'sesame-seeds': 'sesame', 'sesame seeds': 'sesame', 'sesamo': 'sesame',
    'sesame-seeds-and-products-thereof': 'sesame',
    // Solfiti
    'sulphur dioxide': 'sulphites',
    'sulfites': 'sulphites',
    'sulphites': 'sulphites',
    'anhydride sulfureux': 'sulphites', 'dióxido de azufre': 'sulphites',
    'schwefeldioxid': 'sulphites',
    'solfiti': 'sulphites',
    'anidride solforosa': 'sulphites',
    'sulphur-dioxide-and-sulphites': 'sulphites',
    'sulfur-dioxide-and-sulfites': 'sulphites',
    'sulphur-dioxide': 'sulphites', 'sulfur-dioxide': 'sulphites',
    // Lupini
    'lupin': 'lupin',
    'lupins': 'lupin',
    'altramuz': 'lupin',
    'lupine': 'lupin',
    'lupini': 'lupin',
    'lupin-and-products-thereof': 'lupin',
    // Molluschi
    'mollusc': 'mollusc', 'molluscs': 'mollusc', 'mollusques': 'mollusc',
    'moluscos': 'mollusc', 'weichtiere': 'mollusc', 'molluschi': 'mollusc',
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
        .map((a) {
          String clean = a.trim().toLowerCase();
          // Rimuove prefissi lingua OFF (es. "en:milk" -> "milk", "en:cereals-containing-gluten" -> "cereals-containing-gluten")
          if (clean.contains(':')) {
            clean = clean.split(':').last;
          }
          final canonical = allergenCanonical[clean];
          if (canonical != null) {
            final langMap = allergenDisplayNames[canonical];
            if (langMap != null) {
              // Segue il pattern: lingua preferita > lingue app > prima disponibile
              for (final lang in langPriority) {
                if (langMap.containsKey(lang)) return langMap[lang]!;
              }
              // Prima lingua disponibile nella mappa (fallback assoluto)
              return langMap.values.first;
            }
          }
          // Termine sconosciuto: lo restituisce title-cased
          if (clean.isEmpty) return clean;
          return clean[0].toUpperCase() + clean.substring(1);
        })
        .toSet()
        .toList();

    return translatedAllergens.where((a) => a.isNotEmpty).toList();
  }

  static const List<String> _dangerKeywords = [
    // Italiano
    "frumento", "grano", "orzo", "segale", "farro", "kamut",
    "spelta", "glutine", "tritordeum", "couscous", "bulgur", "seitan",
    // Inglese
    "wheat", "barley", "rye", "spelt", "gluten", "semolina", "triticale",
    // Francese
    "blé", "froment", "orge", "seigle", "épeautre",
    // Spagnolo
    "trigo", "cebada", "centeno", "espelta",
    // Tedesco
    "weizen", "gerste", "roggen", "dinkel",
    // Portoghese
    "cevada", "centeio",
    // Olandese
    "tarwe", "gerst", "rogge",
    // Polacco
    "pszenica", "jęczmień", "żyto", "orkisz",
    // Turco
    "buğday", "arpa", "çavdar",
    // Russo
    "пшеница", "ячмень", "рожь", "глютен",
    // Svedese
    "vete", "korn", "råg",
    // Danese/Norvegese
    "hvede", "byg", "rug", "hvete",
    // Ceco
    "pšenice", "ječmen", "žito",
    // Romeno
    "grâu", "orz", "secară",
    // Ungherese
    "búza", "árpa", "rozs",
    // Croato
    "pšenica", "ječam", "raž",
    // Greco
    "σιτάρι", "κριθάρι", "σίκαλη", "γλουτένη",
    // Arabo
    "قمح", "شعير", "غلوتين",
    // Giapponese
    "小麦", "大麦", "ライ麦", "グルテン",
  ];

  static const List<String> _maltoKeywords = [
    "malto",
    "malt",
    "maltosio",
    "maltose",
    "malz",
  ];

  static const List<String> _traceKeywords = [
    // Italiano
    "tracce di grano", "tracce di frumento", "tracce di cereali",
    "stabilimento che lavora anche frumento",
    "può contenere glutine", "può contenere frumento",
    "può contenere orzo", "può contenere farro",
    // Inglese
    "traces of wheat", "may contain wheat", "may contain gluten",
    "may contain barley", "may contain rye",
    // Francese
    "traces de blé", "peut contenir du blé", "peut contenir du gluten",
    // Spagnolo
    "trazas de trigo", "puede contener trigo", "puede contener gluten",
    // Tedesco
    "kann weizen enthalten", "kann gluten enthalten", "spuren von weizen",
    // Portoghese
    "pode conter trigo", "pode conter glúten", "traços de trigo",
    // Olandese
    "kan tarwe bevatten", "kan gluten bevatten",
    // Polacco
    "może zawierać gluten", "może zawierać pszenicę", "śladowe ilości glutenu",
    // Turco
    "buğday içerebilir", "gluten içerebilir",
  ];

  static const List<String> _safeTextKeywords = [
    // Italiano
    "senza glutine", "spiga sbarrata", "spiga barrata",
    "naturalmente privo di glutine", "adatto ai celiaci",
    // Inglese
    "gluten free", "gluten-free", "suitable for celiacs",
    // Spagnolo
    "sin gluten", "libre de gluten",
    // Francese
    "sans gluten",
    // Tedesco
    "glutenfrei",
    // Portoghese
    "sem glúten",
    // Olandese
    "glutenvrij",
    // Polacco
    "bezglutenowy", "bez glutenu",
    // Turco
    "glutensiz",
    // Russo
    "без глютена", "безглютеновый",
    // Ceco
    "bezlepkový", "bez lepku",
    // Romeno
    "fără gluten",
    // Ungherese
    "gluténmentes",
    // Greco
    "χωρίς γλουτένη",
    // Arabo
    "خالي من الغلوتين",
    // Giapponese
    "グルテンフリー",
  ];

  static const List<String> _doubtfulAdditives = [
    "amido modificato",
    "lievito",
    "aromi",
    "fibra vegetale",
    "modified starch",
    "yeast",
    "flavorings",
    "vegetable fiber",
  ];

  static const List<String> _lactoseKeywords = [
    "latte",
    "burro",
    "siero di latte",
    "lattosio",
    "panna",
    "formaggio",
    "yogurt",
    "mascarpone",
    "ricotta",
    "milk",
    "butter",
    "whey",
    "lactose",
    "cream",
    "cheese",
    "lait",
    "beurre",
    "lactosérum",
  ];

  static const List<String> _naturallySafeCategories = [
    'en:waters',
    'en:spring-waters',
    'en:mineral-waters',
    'en:milks',
    'en:fresh-milks',
    'en:fresh-fruits',
    'en:fruits',
    'en:fresh-vegetables',
    'en:vegetables',
    'en:extra-virgin-olive-oils',
    'en:olive-oils',
    'en:virgin-olive-oils',
    'en:sugars',
    'en:honeys',
    'en:salts',
    'en:coffees',
    'en:teas',
  ];

  // ─── METODI DI SANITIZZAZIONE ──────────────────────────────────────────

  // Nasconde le frasi sicure per non far scattare l'allarme sulla parola "glutine"
  static String _sanitizeForGluten(String input) {
    String text = input.toLowerCase();
    final safePhrases = [
      "senza glutine",
      "privo di glutine",
      "gluten free",
      "gluten-free",
      "sans gluten",
      "sin gluten",
      "libre de gluten",
      "deglutinato",
      "degliutinato",
      "amido di frumento deglutinato",
      "spiga barrata",
      "spiga sbarrata",
      "adatto ai celiaci",
      "zero glutine",
    ];
    for (var phrase in safePhrases) {
      text = text.replaceAll(phrase, " ");
    }
    return text;
  }

  // Nasconde le frasi sicure per non far scattare l'allarme sulla parola "lattosio"
  static String _sanitizeForLactose(String input) {
    String text = input.toLowerCase();
    final safePhrases = [
      "senza lattosio",
      "privo di lattosio",
      "lactose free",
      "lactose-free",
      "sans lactose",
      "sin lactosa",
      "delattosato",
      "senza latte",
    ];
    for (var phrase in safePhrases) {
      text = text.replaceAll(phrase, " ");
    }
    return text;
  }

  // ─── ANALISI PRINCIPALE ────────────────────────────────────────────────

  static AnalyzerResult analyzeGlutenSafety({
    required String name,
    required String brand,
    required String ingredients,
    required List<String> allergensList,
    required int reportCount,
    required List<String> categoriesTags,
    OffTags? offTags,
    bool strictMode = false, // Impostazione 1
    bool warnAdditives = true, // Impostazione 2
    bool alertLactose = false, // Impostazione 3
    String preferredLanguage = 'it', // Lingua per la traduzione degli allergeni
    bool ignoreReports = false, // Flag per calcolo stato originale
  }) {
    String safeIngredients = ingredients.trim();
    if (safeIngredients.toLowerCase() == "non disponibile") {
      safeIngredients = "";
    }

    final String lowerIng = safeIngredients.toLowerCase();
    final String lowerName = name.toLowerCase();
    final String lowerBrand = brand.toLowerCase();
    final String combinedRaw = "$lowerIng $lowerName $lowerBrand";

    // SANITIZZAZIONE (Risolve il bug "Pasta Senza Glutine")
    final String safeIng = _sanitizeForGluten(lowerIng);
    final String safeName = _sanitizeForGluten(lowerName);

    // ─── STEP 1: Controlla certificazione Gluten-Free ────────────────────────
    bool hasGlutenFreeBollino = false;
    bool hasGlutenFreeTextClaim = _safeTextKeywords.any(
      (s) => combinedRaw.contains(s),
    );

    if (offTags != null) {
      hasGlutenFreeBollino = offTags.labelsTags.any((t) {
        final lt = t.toLowerCase();
        return lt.contains('gluten-free') ||
            lt.contains('senza-glutine') ||
            lt.contains('sans-gluten') ||
            lt.contains('sin-gluten') ||
            lt.contains('crossed-grain') ||
            lt.contains('spiga-sbarrata') ||
            lt.contains('free-from-gluten') ||
            lt.contains('no-gluten') ||
            lt.contains('without-gluten') ||
            lt.contains('glutenfrei') ||
            lt.contains('glutenvrij') ||
            lt.contains('bezglutenowy') ||
            lt.contains('glutensiz') ||
            lt.contains('celiac');
      });
    }

    // ─── STEP 2: Controlla ingredienti PERICOLOSI (usando il testo pulito) ───
    List<String> foundDanger = [];
    for (String k in _dangerKeywords) {
      final regex = RegExp(
        r'\b' + RegExp.escape(k) + r'\b',
        caseSensitive: false,
      );
      if (regex.hasMatch(safeIng) || regex.hasMatch(safeName)) {
        foundDanger.add(k);
      }
    }

    bool hasMalto = false;
    for (String m in _maltoKeywords) {
      if (lowerIng.contains(m)) {
        if (!lowerIng.contains("malto di riso") &&
            !lowerIng.contains("rice malt")) {
          hasMalto = true;
        }
      }
    }

    // ─── STEP 3: Controlla allergeni e tracce ufficiali OFF ─────────────────
    bool hasOffGlutenAllergen = false;
    bool hasOffGlutenTrace = false;

    if (offTags != null) {
      bool isGlutenTag(String t) {
        final lowerT = t.toLowerCase();
        return lowerT.contains('gluten') ||
            lowerT.contains('wheat') ||
            lowerT.contains('barley') ||
            lowerT.contains('rye') ||
            lowerT.contains('spelt') ||
            lowerT.contains('kamut');
      }

      hasOffGlutenAllergen =
          offTags.allergensTags.any(isGlutenTag) ||
          offTags.ingredientsAnalysisTags.any(
            (t) => t == 'en:gluten' || t == 'en:contains-gluten',
          );
      hasOffGlutenTrace =
          offTags.tracesTags.any(isGlutenTag) ||
          offTags.ingredientsAnalysisTags.any(
            (t) =>
                t == 'en:may-contain-gluten' || t == 'en:gluten-to-be-checked',
          );
    }

    // ─── STEP 4: Controlla tracce testuali ──────────────────────────────────
    List<String> foundTraces = [];
    for (String t in _traceKeywords) {
      if (lowerIng.contains(t)) foundTraces.add(t);
    }
    for (String a in allergensList) {
      final lowerA = a.toLowerCase();
      if (_dangerKeywords.any((k) => lowerA.contains(k)) &&
          !foundDanger.contains(lowerA)) {
        foundTraces.add(lowerA);
      }
    }

    bool hasAnyTrace = hasOffGlutenTrace || foundTraces.isNotEmpty;

    // ─── STEP 5: Filtro Additivi ────────────────────────────────────────────
    List<String> foundDoubtful = [];
    if (warnAdditives) {
      for (String d in _doubtfulAdditives) {
        final regex = RegExp(
          r'\b' + RegExp.escape(d) + r'\b',
          caseSensitive: false,
        );
        if (regex.hasMatch(lowerIng)) foundDoubtful.add(d);
      }
    }

    // ─── STEP 6: Filtro Lattosio ────────────────────────────────────────────
    List<String> foundLactose = [];
    if (alertLactose) {
      final String safeLactoseIng = _sanitizeForLactose(lowerIng);
      for (String l in _lactoseKeywords) {
        final regex = RegExp(
          r'\b' + RegExp.escape(l) + r'\b',
          caseSensitive: false,
        );
        if (regex.hasMatch(safeLactoseIng)) foundLactose.add(l);
      }
      if (offTags != null) {
        bool hasMilk = offTags.allergensTags.any(
          (t) =>
              t.toLowerCase().contains('milk') ||
              t.toLowerCase().contains('lait'),
        );
        if (hasMilk && foundLactose.isEmpty) {
          foundLactose.add("Allergene Latte (OFF)");
        }
      }
    }

    // ─── STEP 7: Naturalmente Sicuro ─────────────────────────────────────────
    bool isInSafeCategory = categoriesTags.any(
      (cat) => _naturallySafeCategories.contains(cat.toLowerCase()),
    );
    List<String> ingredientList = lowerIng
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    bool isMonoIngredient =
        ingredientList.length == 1 && ingredientList[0].length > 3;
    bool isNaturallySafe =
        (isInSafeCategory || isMonoIngredient) &&
        !hasMalto &&
        foundDoubtful.isEmpty;

    // ─── STEP 8: Informazioni sufficienti? ──────────────────────────────────
    bool hasNoInfo =
        lowerIng.length < 5 &&
        !hasGlutenFreeBollino &&
        !hasOffGlutenAllergen &&
        !hasOffGlutenTrace &&
        !hasGlutenFreeTextClaim;

    // ─── STEP 9: DETERMINA LO STATUS FINALE SUL GLUTINE ─────────────────────
    GlutenSafetyStatus status;
    String reason;
    List<IngredientAnalyzed> ingredientsAnalyzed = [];

    // CASO 1: SEGNALAZIONI (Vince su tutto se non si richiede ignoreReports)
    if (!ignoreReports && reportCount > 0) {
      status = GlutenSafetyStatus.incerto;
      reason =
          "ATTENZIONE: Questo prodotto ha $reportCount segnalazione/i dagli utenti.";
      ingredientsAnalyzed.add(
        IngredientAnalyzed(
          ingredient: "Segnalazione Utenti",
          dangerLevel: "warning",
          reason: "Incongruenze segnalate dalla community.",
        ),
      );
    }
    // CASO 2: BOLLINO UFFICIALE (Se c'è bollino, è <20ppm per legge)
    else if (hasGlutenFreeBollino || hasGlutenFreeTextClaim) {
      status = GlutenSafetyStatus.adatto;
      reason =
          "ADATTO ai celiaci. Certificazione o etichetta 'Senza Glutine' rilevata.";
      ingredientsAnalyzed.add(
        IngredientAnalyzed(
          ingredient: "Etichetta Gluten-Free",
          dangerLevel: "safe",
          reason: "Prodotto certificato o dichiarato senza glutine.",
        ),
      );

      if (foundDanger.isNotEmpty) {
        // Es. "Amido di frumento deglutinato"
        ingredientsAnalyzed.add(
          IngredientAnalyzed(
            ingredient: foundDanger.join(', '),
            dangerLevel: "safe",
            reason: "Ingrediente deglutinato (Sicuro grazie al bollino).",
          ),
        );
      }
      if (hasAnyTrace) {
        ingredientsAnalyzed.add(
          IngredientAnalyzed(
            ingredient: "Tracce (<20ppm)",
            dangerLevel: "warning",
            reason: "Tracce segnalate, ma il bollino garantisce limiti sicuri.",
          ),
        );
      }
    }
    // CASO 3: ROSSO (Pericolo certo o Tracce con Filtro Rigido Attivo)
    else if (foundDanger.isNotEmpty ||
        hasOffGlutenAllergen ||
        (hasAnyTrace && strictMode)) {
      status = GlutenSafetyStatus.nonAdatto;
      if (foundDanger.isNotEmpty || hasOffGlutenAllergen) {
        reason = "NON ADATTO ai celiaci. Rilevati ingredienti vietati.";
      } else {
        reason =
            "VIETATO DAL FILTRO: Rilevate possibili tracce di contaminazione crociata (Filtro Rigido attivo).";
      }

      for (var ing in foundDanger) {
        ingredientsAnalyzed.add(
          IngredientAnalyzed(
            ingredient: ing,
            dangerLevel: "danger",
            reason: "Fonte diretta di glutine.",
          ),
        );
      }
      if (hasOffGlutenAllergen) {
        ingredientsAnalyzed.add(
          IngredientAnalyzed(
            ingredient: "Allergeni OFF",
            dangerLevel: "danger",
            reason: "Glutine tra gli allergeni ufficiali.",
          ),
        );
      }
      if (hasAnyTrace && strictMode) {
        ingredientsAnalyzed.add(
          IngredientAnalyzed(
            ingredient: "Tracce",
            dangerLevel: "danger",
            reason: "Bloccato dal Filtro Rigido Contaminazioni.",
          ),
        );
      }
    }
    // CASO 4: GRIGIO
    else if (hasNoInfo) {
      status = GlutenSafetyStatus.sconosciuto;
      reason =
          "SCONOSCIUTO. Informazioni insufficienti. Leggi l'etichetta fisica.";
      ingredientsAnalyzed.add(
        IngredientAnalyzed(
          ingredient: "Dati Assenti",
          dangerLevel: "warning",
          reason: "Nessuna specifica trovata.",
        ),
      );
    }
    // CASO 5: VERDE (Naturalmente Sicuro)
    else if (isNaturallySafe) {
      status = GlutenSafetyStatus.adatto;
      reason =
          "ADATTO ai celiaci. Prodotto di base naturalmente privo di glutine.";
      ingredientsAnalyzed.add(
        IngredientAnalyzed(
          ingredient: "Naturalmente Sicuro",
          dangerLevel: "safe",
          reason: "Categoria a bassissimo rischio (es. olio, acqua).",
        ),
      );
    }
    // CASO 6: GIALLO (Fallback)
    else {
      status = GlutenSafetyStatus.incerto;
      reason =
          "ATTENZIONE: Prodotto lavorato senza dicitura 'Senza glutine'. Verifica l'etichetta.";

      if (hasAnyTrace && !strictMode) {
        reason =
            "ATTENZIONE: Trovate diciture di contaminazione. Consumo a tuo rischio.";
        ingredientsAnalyzed.add(
          IngredientAnalyzed(
            ingredient: "Tracce",
            dangerLevel: "warning",
            reason: "Contaminazione crociata. Il filtro rigido è disattivato.",
          ),
        );
      }
      if (hasMalto) {
        ingredientsAnalyzed.add(
          IngredientAnalyzed(
            ingredient: "Malto",
            dangerLevel: "warning",
            reason: "Possibile malto d'orzo. Origine non specificata.",
          ),
        );
      }
      for (var d in foundDoubtful) {
        ingredientsAnalyzed.add(
          IngredientAnalyzed(
            ingredient: d,
            dangerLevel: "warning",
            reason: "Ingrediente ambiguo.",
          ),
        );
      }
    }

    // ─── AGGIUNTA ALLERTA LATTOSIO ALLA UI ──────────────────────────────────
    if (alertLactose && foundLactose.isNotEmpty) {
      reason += "\n\n🥛 ALLERTA LATTOSIO: Il prodotto contiene lattosio/latte.";
      for (var l in foundLactose) {
        ingredientsAnalyzed.add(
          IngredientAnalyzed(
            ingredient: l,
            dangerLevel:
                "danger", // Mostra rosso negli ingredienti per far capire all'utente
            reason: "Rilevato per le tue impostazioni sul lattosio.",
          ),
        );
      }
    }

    // Lingua target: preferita, con fallback a italiano
    final String targetLang =
        allergenDisplayNames.values.any((m) => m.containsKey(preferredLanguage))
        ? preferredLanguage
        : 'it';

    List<String> finalAllergens = translateAllergens(
      allergensList,
      preferredLanguage,
    );

    if (status == GlutenSafetyStatus.nonAdatto &&
        !finalAllergens.any((a) {
          final lower = a.toLowerCase();
          return lower == 'glutine' || lower == 'gluten';
        }) &&
        !strictMode) {
      final glutenLabel =
          allergenDisplayNames['gluten']?[targetLang] ??
          allergenDisplayNames['gluten']?['it'] ??
          'Glutine';
      finalAllergens.add(glutenLabel);
    }

    return AnalyzerResult(
      status: status,
      reason: reason,
      allergens: finalAllergens,
      ingredientsAnalyzed: ingredientsAnalyzed,
    );
  }

  static bool checkLactose(String ingredients, List<String> allergens) {
    String safeIngredients = ingredients.trim();
    if (safeIngredients.toLowerCase() == "non disponibile") {
      safeIngredients = "";
    }

    final String lowerIng = safeIngredients.toLowerCase();
    final String safeLactoseIng = _sanitizeForLactose(lowerIng);
    for (String l in _lactoseKeywords) {
      final regex = RegExp(
        r'\b' + RegExp.escape(l) + r'\b',
        caseSensitive: false,
      );
      if (regex.hasMatch(safeLactoseIng)) return true;
    }
    for (String a in allergens) {
      final lowerA = a.toLowerCase();
      if (lowerA == "latte" ||
          lowerA.contains("milk") ||
          lowerA.contains("lait") ||
          lowerA.contains("lattosio")) {
        return true;
      }
    }
    return false;
  }
}

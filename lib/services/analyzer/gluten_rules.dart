// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

class GlutenRules {
  static const List<String> dangerKeywords = [
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

  static const List<String> maltoKeywords = [
    "malto",
    "malt",
    "maltosio",
    "maltose",
    "malz",
  ];

  static const List<String> traceKeywords = [
    // Italiano
    "può contenere tracce di cereali contenenti glutine",
    "può contenere tracce di cereali con glutine",
    "può contenere tracce di frumento",
    "può contenere tracce di glutine",
    "può contenere tracce di grano",
    "può contenere tracce di cereali",
    "può contenere tracce di orzo",
    "può contenere tracce di farro",
    "può contenere tracce di segale",
    "può contenere tracce di avena",
    "può contenere cereali contenenti glutine",
    "può contenere glutine",
    "può contenere frumento",
    "può contenere grano",
    "può contenere orzo",
    "può contenere farro",
    "può contenere segale",
    "contiene tracce di glutine",
    "contiene tracce di frumento",
    "tracce di cereali contenenti glutine",
    "tracce di glutine",
    "tracce di frumento",
    "tracce di grano",
    "tracce di cereali",
    "tracce di orzo",
    "tracce di farro",
    "tracce di segale",
    "stabilimento che lavora anche frumento",
    "stabilimento che lavora anche glutine",
    "stabilimento che lavora anche cereali",
    "stabilimento che utilizza cereali contenenti glutine",
    "stabilimento che utilizza cereali con glutine",
    "lavorato in uno stabilimento che utilizza glutine",
    "lavorato in uno stabilimento che utilizza frumento",

    // Inglese
    "may contain traces of cereals containing gluten",
    "may contain traces of gluten",
    "may contain traces of wheat",
    "may contain traces of barley",
    "may contain traces of rye",
    "may contain traces of cereals",
    "may contain cereals containing gluten",
    "may contain gluten",
    "may contain wheat",
    "may contain barley",
    "may contain rye",
    "contains traces of gluten",
    "contains traces of wheat",
    "traces of cereals containing gluten",
    "traces of gluten",
    "traces of wheat",
    "traces of barley",
    "traces of rye",
    "made in a facility that also processes wheat",
    "made in a facility that also processes gluten",
    "packaged in a facility that also handles wheat",
    "packaged in a facility that also handles gluten",

    // Francese
    "peut contenir des traces de céréales contenant du gluten",
    "peut contenir des traces de gluten",
    "peut contenir des traces de blé",
    "peut contenir des traces d'orge",
    "peut contenir des traces de seigle",
    "traces de céréales contenant du gluten",
    "traces de gluten",
    "traces de blé",
    "traces d'orge",
    "traces de seigle",
    "peut contenir du gluten",
    "peut contenir du blé",
    "peut contenir de l'orge",
    "peut contenir du seigle",
    "fabriqué dans un atelier qui utilise du gluten",
    "fabriqué dans un atelier qui utilise du blé",

    // Spagnolo
    "puede contener trazas de cereales que contengan gluten",
    "puede contener trazas de gluten",
    "puede contener trazas de trigo",
    "puede contener trazas de cebada",
    "puede contener trazas de centeno",
    "trazas de cereales con gluten",
    "trazas de gluten",
    "trazas de trigo",
    "trazas de cebada",
    "trazas de centeno",
    "puede contener gluten",
    "puede contener trigo",
    "puede contener cebada",
    "puede contener centeno",
    "elaborado en una fábrica que utiliza gluten",
    "elaborado en instalaciones que procesan trigo",

    // Tedesco
    "kann spuren von glutenhaltigem getreide enthalten",
    "kann spuren von gluten enthalten",
    "kann spuren von weizen enthalten",
    "kann spuren von gerste enthalten",
    "kann spuren von roggen enthalten",
    "spuren von gluten",
    "spuren von weizen",
    "spuren von gerste",
    "spuren von roggen",
    "kann gluten enthalten",
    "kann weizen enthalten",
    "kann gerste enthalten",
    "kann roggen enthalten",
    "in einem betrieb hergestellt, der auch gluten verarbeitet",
    "in einem betrieb hergestellt, der auch weizen verarbeitet",

    // Portoghese
    "pode conter vestígios de cereais que contêm glúten",
    "pode conter vestígios de glúten",
    "pode conter vestígios de trigo",
    "pode conter vestígios de cevada",
    "pode conter traços de glúten",
    "pode conter traços de trigo",
    "pode conter traços de cevada",
    "traços de glúten",
    "traços de trigo",
    "vestígios de glúten",
    "vestígios de trigo",
    "pode conter glúten",
    "pode conter trigo",

    // Olandese
    "kan sporen van glutenbevattende granen bevatten",
    "kan sporen van gluten bevatten",
    "kan sporen van tarwe bevatten",
    "kan sporen van gerst bevatten",
    "sporen van gluten",
    "sporen van tarwe",
    "sporen van gerst",
    "kan gluten bevatten",
    "kan tarwe bevatten",

    // Polacco
    "może zawierać śladowe ilości zbóż zawierających gluten",
    "może zawierać śladowe ilości glutenu",
    "może zawierać śladowe ilości pszenicy",
    "śladowe ilości glutenu",
    "śladowe ilości pszenicy",
    "może zawierać gluten",
    "może zawierać pszenicę",

    // Turco
    "eser miktarda gluten içeren tahıllar içerebilir",
    "eser miktarda gluten içerebilir",
    "eser miktarda buğday içerebilir",
    "gluten içerebilir",
    "buğday içerebilir",
  ];

  static const List<String> safeTextKeywords = [
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

  static const List<String> doubtfulAdditives = [
    "amido modificato",
    "lievito",
    "aromi",
    "fibra vegetale",
    "modified starch",
    "yeast",
    "flavorings",
    "vegetable fiber",
  ];

  static const Set<String> agglutinativeRoots = {
    'weizen',
    'gerste',
    'roggen',
    'dinkel',
    'tarwe',
    'gerst',
    'rogge',
    'milch',
    'laktose',
    'malz',
    'hafer',
    'avoine',
  };

  static const List<String> naturallySafeCategories = [
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

  // Nasconde le frasi sicure per non far scattare l'allarme sulla parola "glutine"
  static String sanitizeForGluten(String input) {
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
    for (var phrase in traceKeywords) {
      text = text.replaceAll(phrase, " ");
    }
    return text;
  }

  // Nasconde le frasi sicure per non far scattare l'allarme sulla parola "lattosio"
  static String sanitizeForLactose(String input) {
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
}

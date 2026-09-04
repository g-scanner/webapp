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

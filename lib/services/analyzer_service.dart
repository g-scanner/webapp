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

  static const List<String> _dangerKeywords = [
    "frumento",
    "grano",
    "orzo",
    "segale",
    "farro",
    "kamut",
    "spelta",
    "glutine",
    "tritordeum",
    "couscous",
    "bulgur",
    "seitan",
    "grano saraceno",
    "wheat",
    "barley",
    "rye",
    "spelt",
    "gluten",
    "semolina",
    "triticale",
    "blé",
    "froment",
    "orge",
    "seigle",
    "épeautre",
    "trigo",
    "cebada",
    "centeno",
    "espelta",
    "weizen",
    "gerste",
    "roggen",
    "dinkel",
  ];

  static const List<String> _maltoKeywords = [
    "malto",
    "malt",
    "maltosio",
    "maltose",
    "malz",
  ];

  static const List<String> _traceKeywords = [
    "tracce di grano",
    "tracce di frumento",
    "tracce di cereali",
    "stabilimento che lavora anche frumento",
    "può contenere glutine",
    "può contenere frumento",
    "può contenere orzo",
    "può contenere farro",
    "traces of wheat",
    "may contain wheat",
    "may contain gluten",
    "trazas de trigo",
    "puede contener trigo",
    "puede contener gluten",
    "traces de blé",
    "peut contenir du blé",
    "peut contenir du gluten",
  ];

  static const List<String> _safeTextKeywords = [
    "senza glutine",
    "spiga sbarrata",
    "spiga barrata",
    "naturalmente privo di glutine",
    "adatto ai celiaci",
    "gluten free",
    "gluten-free",
    "suitable for celiacs",
    "sin gluten",
    "libre de gluten",
    "sans gluten",
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
    bool alertLactose = false, // Impostazione 3 (Nuova)
  }) {
    final String lowerIng = ingredients.toLowerCase();
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
            lt.contains('sin-gluten');
      });
    }

    // ─── STEP 2: Controlla ingredienti PERICOLOSI (usando il testo pulito) ───
    List<String> foundDanger = [];
    for (String k in _dangerKeywords) {
      final regex = RegExp(
        r'\b' + RegExp.escape(k) + r'\b',
        caseSensitive: false,
      );
      // Cerchiamo nel testo a cui abbiamo tolto "senza glutine"
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

      hasOffGlutenAllergen = offTags.allergensTags.any(isGlutenTag);
      hasOffGlutenTrace = offTags.tracesTags.any(isGlutenTag);
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

    // ─── STEP 5: Filtro Additivi (Impostazione 2) ────────────────────────────
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

    // ─── STEP 6: Filtro Lattosio (Impostazione 3) ────────────────────────────
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
        if (hasMilk && foundLactose.isEmpty)
          foundLactose.add("Allergene Latte (OFF)");
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

    // CASO 1: BOLLINO UFFICIALE (Vince su tutto. Se c'è bollino, è <20ppm per legge)
    if (hasGlutenFreeBollino || hasGlutenFreeTextClaim) {
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
    // CASO 2: ROSSO (Pericolo certo o Tracce con Filtro Rigido Attivo)
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
      if (hasOffGlutenAllergen)
        ingredientsAnalyzed.add(
          IngredientAnalyzed(
            ingredient: "Allergeni OFF",
            dangerLevel: "danger",
            reason: "Glutine tra gli allergeni ufficiali.",
          ),
        );
      if (hasAnyTrace && strictMode)
        ingredientsAnalyzed.add(
          IngredientAnalyzed(
            ingredient: "Tracce",
            dangerLevel: "danger",
            reason: "Bloccato dal Filtro Rigido Contaminazioni.",
          ),
        );
    }
    // CASO 3: GRIGIO
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
    // CASO 4: GIALLO (Segnalazioni Utenti)
    else if (reportCount > 0) {
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
      ingredientsAnalyzed.add(
        IngredientAnalyzed(
          ingredient: "Assenza Certificazione",
          dangerLevel: "warning",
          reason: "Prodotto lavorato a potenziale rischio stabilimento.",
        ),
      );

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
      if (hasMalto)
        ingredientsAnalyzed.add(
          IngredientAnalyzed(
            ingredient: "Malto",
            dangerLevel: "warning",
            reason: "Possibile malto d'orzo. Origine non specificata.",
          ),
        );
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

    List<String> detectedAllergens = allergensList.toSet().toList();
    if (status == GlutenSafetyStatus.nonAdatto &&
        !detectedAllergens.contains("glutine") &&
        !strictMode) {
      detectedAllergens.add("glutine");
    }

    return AnalyzerResult(
      status: status,
      reason: reason,
      allergens: detectedAllergens,
      ingredientsAnalyzed: ingredientsAnalyzed,
    );
  }
}

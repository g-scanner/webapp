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
  // Parole che CERTAMENTE indicano glutine (ingredienti/allergeni dichiarati)
  static const List<String> _dangerKeywords = [
    // Italian
    "frumento", "grano", "orzo", "segale", "farro", "kamut", "spelta",
    "glutine", "tritordeum", "couscous", "bulgur", "seitan", "grano saraceno",
    // English
    "wheat", "barley", "rye", "spelt", "gluten", "seitan", "semolina",
    "couscous", "bulgur", "triticale", "graham",
    // French
    "blé", "froment", "orge", "seigle", "épeautre",
    // Spanish
    "trigo", "cebada", "centeno", "espelta",
    // German
    "weizen", "gerste", "roggen", "dinkel",
  ];

  // "Malto" da solo può essere malto di riso (ok), malto d'orzo (no): trattiamolo come traccia/incerto
  static const List<String> _maltoKeywords = [
    "malto", "malt", "maltosio", "maltose", "malz",
  ];

  // Parole che indicano possibile contaminazione/tracce
  static const List<String> _traceKeywords = [
    "tracce di grano", "tracce di frumento", "tracce di cereali",
    "stabilimento che lavora anche frumento", "può contenere glutine",
    "può contenere frumento", "può contenere orzo",
    "può contenere cereali contenenti glutine", "può contenere farro",
    "traces of wheat", "may contain wheat", "may contain gluten",
    "processed in a facility that uses wheat", "may contain barley",
    "trazas de trigo", "puede contener trigo", "puede contener gluten",
    "traces de blé", "peut contenir du blé", "peut contenir du gluten",
  ];

  // Bollini / certificazioni ufficiali "senza glutine"
  static const List<String> _safeTextKeywords = [
    "senza glutine", "spiga sbarrata", "naturalmente privo di glutine",
    "adatto ai celiaci", "gluten free", "gluten-free",
    "suitable for celiacs", "sin gluten", "libre de gluten", "sans gluten",
  ];

  // Additivi ambigui (generano warning extra se warnAdditives=true)
  static const List<String> _doubtfulAdditives = [
    "amido modificato", "lievito", "aromi", "fibra vegetale",
    "modified starch", "yeast", "flavorings", "vegetable fiber",
    "almidón modificado", "levadura", "aromas", "fibra vegetal",
    "amidon modifié", "levure", "arômes", "fibre végétale",
  ];

  static AnalyzerResult analyzeGlutenSafety({
    required String name,
    required String brand,
    required String ingredients,
    required List<String> allergensList,
    required int reportCount,   // <-- nuovo parametro
    OffTags? offTags,
    bool strictMode = false,
    bool warnAdditives = true,
  }) {
    final String lowerIng = ingredients.toLowerCase();
    final String lowerName = name.toLowerCase();
    final String lowerBrand = brand.toLowerCase();
    final String combined = "$lowerIng $lowerName $lowerBrand";

    // ─── STEP 1: Controlla certificazione Gluten-Free ────────────────────────
    bool hasGlutenFreeBollino = false;  // bollino OFF ufficiale (labels_tags)
    bool hasGlutenFreeTextClaim = false; // claim testuale negli ingredienti/nome

    if (offTags != null) {
      hasGlutenFreeBollino = offTags.labelsTags.any((t) {
        final lt = t.toLowerCase();
        return lt.contains('gluten-free') || lt.contains('senza-glutine') ||
               lt.contains('sans-gluten') || lt.contains('sin-gluten');
      });
    }
    hasGlutenFreeTextClaim = _safeTextKeywords.any((s) => combined.contains(s));

    // ─── STEP 2: Controlla ingredienti PERICOLOSI ────────────────────────────
    List<String> foundDanger = [];
    for (String k in _dangerKeywords) {
      final regex = RegExp(r'\b' + RegExp.escape(k) + r'\b', caseSensitive: false);
      if (regex.hasMatch(lowerIng) || regex.hasMatch(lowerName)) {
        foundDanger.add(k);
      }
    }

    // Malto senza qualificatore "di riso" è sospetto (incerto, non pericolo certo)
    bool hasMalto = false;
    for (String m in _maltoKeywords) {
      if (lowerIng.contains(m)) {
        // se è "malto di riso" o "rice malt" non è pericoloso
        if (!lowerIng.contains("malto di riso") && !lowerIng.contains("rice malt")) {
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
        return lowerT.contains('gluten') || lowerT.contains('wheat') ||
               lowerT.contains('barley') || lowerT.contains('rye') ||
               lowerT.contains('spelt') || lowerT.contains('kamut') ||
               lowerT.contains('frumento') || lowerT.contains('orzo') ||
               lowerT.contains('farro') || lowerT.contains('segale') ||
               lowerT.contains('avena');
      }
      hasOffGlutenAllergen = offTags.allergensTags.any(isGlutenTag);
      hasOffGlutenTrace = offTags.tracesTags.any(isGlutenTag);
    }

    // ─── STEP 4: Controlla tracce testuali ──────────────────────────────────
    List<String> foundTraces = [];
    for (String t in _traceKeywords) {
      if (lowerIng.contains(t)) foundTraces.add(t);
    }
    // Allergeni dalla lista OFF che contengono parole pericolose → tracce
    for (String a in allergensList) {
      final lowerA = a.toLowerCase();
      if (_dangerKeywords.any((k) => lowerA.contains(k))) {
        if (!foundDanger.contains(lowerA)) foundTraces.add(lowerA);
      }
    }

    // ─── STEP 5: Additivi ambigui ────────────────────────────────────────────
    List<String> foundDoubtful = [];
    if (warnAdditives) {
      for (String d in _doubtfulAdditives) {
        final regex = RegExp(r'\b' + RegExp.escape(d) + r'\b', caseSensitive: false);
        if (regex.hasMatch(lowerIng)) foundDoubtful.add(d);
      }
    }

    // ─── STEP 6: Informazioni sufficienti? ──────────────────────────────────
    bool hasNoInfo = lowerIng.length < 5 &&
        !hasGlutenFreeBollino &&
        !hasOffGlutenAllergen &&
        !hasOffGlutenTrace &&
        !hasGlutenFreeTextClaim;

    // ─── STEP 7: Determina lo status finale ─────────────────────────────────
    //
    // LOGICA (priorità dall'alto):
    // 1. ROSSO  → ingrediente rischioso dichiarato (testo O allergeni OFF)
    // 2. GRIGIO → nessuna info sufficiente
    // 3. GIALLO → segnalazione utente attiva (indipendentemente dal bollino)
    //           → bollino GF assente ma nessun rischio trovato
    //           → malto ambiguo / tracce / additivi dubbi
    // 4. VERDE  → bollino GF ufficiale (OFF labels_tags) O claim testuale + zero rischi

    GlutenSafetyStatus status;
    String reason;
    List<IngredientAnalyzed> ingredientsAnalyzed = [];

    if (foundDanger.isNotEmpty || hasOffGlutenAllergen) {
      // ── ROSSO ──────────────────────────────────────────────────────────────
      status = GlutenSafetyStatus.non_adatto;
      reason = "NON ADATTO ai celiaci. Rilevati ingredienti o allergeni vietati.";
      if (hasOffGlutenAllergen) reason += " Segnalato tra gli allergeni Open Food Facts.";
      if (foundDanger.isNotEmpty) reason += " Trovati nel testo: ${foundDanger.join(', ')}.";

      if (hasOffGlutenAllergen) {
        ingredientsAnalyzed.add(IngredientAnalyzed(
          ingredient: "Allergeni OFF",
          dangerLevel: "danger",
          reason: "Il database ufficiale riporta glutine tra gli allergeni di questo prodotto.",
        ));
      }
      for (var ing in foundDanger) {
        ingredientsAnalyzed.add(IngredientAnalyzed(
          ingredient: ing,
          dangerLevel: "danger",
          reason: "Contiene una fonte diretta di glutine vietata per i celiaci.",
        ));
      }
    } else if (hasNoInfo) {
      // ── GRIGIO ─────────────────────────────────────────────────────────────
      status = GlutenSafetyStatus.sconosciuto;
      reason = "SCONOSCIUTO. Informazioni assenti o insufficienti nel database. Leggi sempre l'etichetta del prodotto fisico.";
      ingredientsAnalyzed.add(IngredientAnalyzed(
        ingredient: "Dati Assenti",
        dangerLevel: "warning",
        reason: "Nessuna specifica trovata. Prodotto non classificabile.",
      ));
    } else if (reportCount > 0) {
      // ── GIALLO per segnalazione attiva ─────────────────────────────────────
      status = GlutenSafetyStatus.incerto;
      reason = "ATTENZIONE: Questo prodotto ha $reportCount segnalazione/i da parte degli utenti. Verifica sempre la confezione fisica.";
      ingredientsAnalyzed.add(IngredientAnalyzed(
        ingredient: "Segnalazione Utenti",
        dangerLevel: "warning",
        reason: "Un utente ha segnalato incongruenze su questo prodotto.",
      ));
      // Se c'era anche il bollino, aggiungiamo nota positiva
      if (hasGlutenFreeBollino || hasGlutenFreeTextClaim) {
        ingredientsAnalyzed.add(IngredientAnalyzed(
          ingredient: "Bollino Gluten-Free presente",
          dangerLevel: "safe",
          reason: "Il prodotto dichiara assenza di glutine, ma è stato segnalato dagli utenti. Verifica la confezione.",
        ));
      }
    } else if (hasGlutenFreeBollino || hasGlutenFreeTextClaim) {
      // ── VERDE ──────────────────────────────────────────────────────────────
      status = GlutenSafetyStatus.adatto;
      if (hasGlutenFreeBollino) {
        reason = "ADATTO ai celiaci. Bollino ufficiale 'Senza Glutine' rilevato nel database Open Food Facts.";
      } else {
        reason = "ADATTO ai celiaci. Claim testuale 'Senza Glutine' / 'Gluten-Free' chiaramente rilevato negli ingredienti o nel nome.";
      }
      ingredientsAnalyzed.add(IngredientAnalyzed(
        ingredient: hasGlutenFreeBollino ? "Bollino OFF Gluten-Free" : "Etichetta Gluten-Free",
        dangerLevel: "safe",
        reason: "Certificazione o dichiarazione esplicita di assenza di glutine rilevata.",
      ));
      // Segnala comunque tracce o additivi come note aggiuntive
      if (hasOffGlutenTrace) {
        ingredientsAnalyzed.add(IngredientAnalyzed(
          ingredient: "Tracce (OFF)",
          dangerLevel: "warning",
          reason: "OFF segnala possibili tracce. Il bollino GF può indicare che sono entro i limiti di legge (<20ppm).",
        ));
      }
      for (var d in foundDoubtful) {
        ingredientsAnalyzed.add(IngredientAnalyzed(
          ingredient: d,
          dangerLevel: "warning",
          reason: "Additivo ambiguo, ma il prodotto è certificato GF.",
        ));
      }
    } else {
      // ── GIALLO — nessun bollino, nessun pericolo certo ────────────────────
      status = GlutenSafetyStatus.incerto;
      reason = "ATTENZIONE: ";
      reason += "Il prodotto non presenta l'etichetta esplicita 'Senza Glutine'. Anche se gli ingredienti sembrano sicuri, verifica SEMPRE la confezione fisica. ";
      ingredientsAnalyzed.add(IngredientAnalyzed(
        ingredient: "Assenza Certificazione",
        dangerLevel: "warning",
        reason: "Nessun bollino 'Senza Glutine' / 'Gluten-free' rilevato. Verifica la dicitura sulla confezione.",
      ));
      if (hasOffGlutenTrace || foundTraces.isNotEmpty) {
        reason += "Trovate possibili diciture di contaminazione crociata. ";
        for (var t in [...foundTraces, if (hasOffGlutenTrace) "tracce (OFF)"]) {
          ingredientsAnalyzed.add(IngredientAnalyzed(
            ingredient: t,
            dangerLevel: "warning",
            reason: "Rischio contaminazione crociata nello stabilimento.",
          ));
        }
      }
      if (hasMalto) {
        reason += "Contiene 'malto' non specificato (potrebbe essere orzo). ";
        ingredientsAnalyzed.add(IngredientAnalyzed(
          ingredient: "Malto (origine incerta)",
          dangerLevel: "warning",
          reason: "Il malto d'orzo contiene glutine. Verifica se è specificata l'origine (es. malto di riso).",
        ));
      }
      if (strictMode && foundDoubtful.isNotEmpty) {
        reason += "Trovati ingredienti ambigui (${foundDoubtful.join(', ')}). ";
        for (var d in foundDoubtful) {
          ingredientsAnalyzed.add(IngredientAnalyzed(
            ingredient: d,
            dangerLevel: "warning",
            reason: "Ingrediente ambiguo. Potrebbe derivare da cereali vietati.",
          ));
        }
      }
    }

    // Costruiamo la lista allergeni finale
    List<String> detectedAllergens = allergensList.toSet().toList();
    if (status == GlutenSafetyStatus.non_adatto && !detectedAllergens.contains("glutine")) {
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

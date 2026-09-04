// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:easy_localization/easy_localization.dart';
import '../../models/models.dart';
import 'analyzer_result.dart';
import 'gluten_rules.dart';
import 'allergen_canonicalizer.dart';
import 'additives_checker.dart';
import 'lactose_checker.dart';

class AnalyzerService {
  // Deleghe statiche a dizionari e utilità per mantenere l'API pubblica intatta
  static const Map<String, String> allergenCanonical =
      AllergenCanonicalizer.allergenCanonical;

  static const Map<String, Map<String, String>> allergenDisplayNames =
      AllergenCanonicalizer.allergenDisplayNames;

  static bool isSafeGlutenClaim(String text) =>
      AllergenCanonicalizer.isSafeGlutenClaim(text);

  static List<String> translateAllergens(
    List<String> allergensList,
    String preferredLanguage,
  ) =>
      AllergenCanonicalizer.translateAllergens(allergensList, preferredLanguage);

  static bool checkLactose(String ingredients, List<String> allergens) =>
      LactoseChecker.checkLactose(ingredients, allergens);

  // ─── ANALISI PRINCIPALE ────────────────────────────────────────────────
  static AnalyzerResult analyzeGlutenSafety({
    required String name,
    required String brand,
    required String ingredients,
    required List<String> allergensList,
    required int reportCount,
    required List<String> categoriesTags,
    OffTags? offTags,
    bool strictMode = false,
    bool warnAdditives = true,
    bool alertLactose = false,
    String preferredLanguage = 'it',
    bool ignoreReports = false,
  }) {
    String safeIngredients = ingredients.trim();
    if (safeIngredients.toLowerCase() == "non disponibile") {
      safeIngredients = "";
    }

    final String lowerIng = safeIngredients.toLowerCase();
    final String lowerName = name.toLowerCase();
    final String lowerBrand = brand.toLowerCase();
    final String allergensRaw = allergensList.join(' ').toLowerCase();
    final String combinedRaw = "$lowerIng $lowerName $lowerBrand $allergensRaw";

    // SANITIZZAZIONE (Risolve il bug "Pasta Senza Glutine")
    final String safeIng = GlutenRules.sanitizeForGluten(lowerIng);
    final String safeName = GlutenRules.sanitizeForGluten(lowerName);

    // ─── STEP 1: Controlla certificazione Gluten-Free ────────────────────────
    bool hasGlutenFreeBollino = false;
    bool hasGlutenFreeTextClaim = GlutenRules.safeTextKeywords.any(
      (s) => combinedRaw.contains(s),
    );

    if (offTags != null) {
      bool isSafeTag(String t) {
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
            lt.contains('celiac') ||
            isSafeGlutenClaim(t);
      }

      hasGlutenFreeBollino = offTags.labelsTags.any(isSafeTag) ||
          offTags.allergensTags.any(isSafeTag) ||
          offTags.tracesTags.any(isSafeTag);
    }

    // ─── STEP 2: Controlla ingredienti PERICOLOSI (usando il testo pulito) ───
    List<String> foundDanger = [];
    for (String k in GlutenRules.dangerKeywords) {
      final isAgglutinative = GlutenRules.agglutinativeRoots.contains(k);
      final regex = isAgglutinative
          ? RegExp(RegExp.escape(k), caseSensitive: false)
          : RegExp(r'\b' + RegExp.escape(k) + r'\b', caseSensitive: false);
      if (regex.hasMatch(safeIng) || regex.hasMatch(safeName)) {
        foundDanger.add(k);
      }
    }

    bool hasMalto = false;
    for (String m in GlutenRules.maltoKeywords) {
      final isAgglutinative = GlutenRules.agglutinativeRoots.contains(m);
      final regex = isAgglutinative
          ? RegExp(RegExp.escape(m), caseSensitive: false)
          : RegExp(r'\b' + RegExp.escape(m) + r'\b', caseSensitive: false);
      if (regex.hasMatch(lowerIng)) {
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
        // Ignora tag come "en:gluten-free" o "it:senza-glutine"
        if (GlutenRules.safeTextKeywords.any((safe) =>
                lowerT.contains(safe.replaceAll(' ', '-')) ||
                lowerT.contains(safe)) ||
            isSafeGlutenClaim(t)) {
          return false;
        }
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
    for (String t in GlutenRules.traceKeywords) {
      if (lowerIng.contains(t)) foundTraces.add(t);
    }
    for (String a in allergensList) {
      final lowerA = a.toLowerCase();
      if (GlutenRules.safeTextKeywords.any((safe) => lowerA.contains(safe)) ||
          isSafeGlutenClaim(a)) {
        continue;
      }
      if (GlutenRules.dangerKeywords.any((k) => lowerA.contains(k)) &&
          !foundDanger.contains(lowerA)) {
        foundTraces.add(lowerA);
      }
    }

    bool hasAnyTrace = hasOffGlutenTrace || foundTraces.isNotEmpty;

    // ─── STEP 5: Filtro Additivi ────────────────────────────────────────────
    List<String> foundDoubtful = [];
    if (warnAdditives) {
      foundDoubtful = AdditivesChecker.findDoubtfulAdditives(lowerIng);
    }

    // ─── STEP 6: Filtro Lattosio ────────────────────────────────────────────
    List<String> foundLactose = [];
    if (alertLactose) {
      final String safeLactoseIng = GlutenRules.sanitizeForLactose(lowerIng);
      for (String l in LactoseChecker.lactoseKeywords) {
        final isAgglutinative = GlutenRules.agglutinativeRoots.contains(l);
        final regex = isAgglutinative
            ? RegExp(RegExp.escape(l), caseSensitive: false)
            : RegExp(r'\b' + RegExp.escape(l) + r'\b', caseSensitive: false);
        if (regex.hasMatch(safeLactoseIng)) foundLactose.add(l);
      }
      if (offTags != null) {
        bool hasMilk = offTags.allergensTags.any(
          (t) =>
              t.toLowerCase().contains('milk') ||
              t.toLowerCase().contains('lait') ||
              t.toLowerCase().contains('milch'),
        );
        if (hasMilk && foundLactose.isEmpty) {
          foundLactose.add("Allergene Latte (OFF)");
        }
      }
    }

    // ─── STEP 7: Naturalmente Sicuro ─────────────────────────────────────────
    bool isInSafeCategory = categoriesTags.any(
      (cat) => GlutenRules.naturallySafeCategories.contains(cat.toLowerCase()),
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
      reason = "product.analysis.userReported"
          .tr(namedArgs: {"count": reportCount.toString()});
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
      reason = "product.analysis.safe".tr();
      ingredientsAnalyzed.add(
        IngredientAnalyzed(
          ingredient: "Etichetta Gluten-Free",
          dangerLevel: "safe",
          reason: "Prodotto certificato o dichiarato senza glutine.",
        ),
      );

      if (foundDanger.isNotEmpty) {
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
        reason = "product.analysis.notSuitable".tr();
      } else {
        reason = "product.analysis.strictFilterBlocked".tr();
      }

      for (var ing in foundDanger) {
        ingredientsAnalyzed.add(
          IngredientAnalyzed(
            ingredient: ing,
            dangerLevel: "danger",
            reason: "product.analysis.glutenSource".tr(),
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
            reason: "product.analysis.contaminationBlocked".tr(),
          ),
        );
      }
    }
    // CASO 4: GRIGIO
    else if (hasNoInfo) {
      status = GlutenSafetyStatus.sconosciuto;
      reason = "product.analysis.unknown".tr();
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
      reason = "product.analysis.naturallySafe".tr();
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
      reason = "product.analysis.uncertainNoLabel".tr();

      if (hasAnyTrace && !strictMode) {
        reason = "product.analysis.uncertainTraces".tr();
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
      reason += "\n\n🥛 ${'product.analysis.lactoseAlert'.tr()}";
      for (var l in foundLactose) {
        ingredientsAnalyzed.add(
          IngredientAnalyzed(
            ingredient: l,
            dangerLevel: "danger",
            reason: "product.analysis.lactoseDetected".tr(),
          ),
        );
      }
    }

    // Lingua target: preferita, con fallback a italiano
    final String targetLang = AllergenCanonicalizer.allergenDisplayNames.values
            .any((m) => m.containsKey(preferredLanguage))
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
          AllergenCanonicalizer.allergenDisplayNames['gluten']?[targetLang] ??
              AllergenCanonicalizer.allergenDisplayNames['gluten']?['it'] ??
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
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Pure Unit Tests: AnalyzerService

import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gscanner/models/types.dart';
import 'package:gscanner/services/analyzer_service.dart';
import '../mocks/shared_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupMocktailFallbacks();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1 – Allergen Canonicalization & Translation (translateAllergens)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 1 – Allergen Canonicalization & Translation', () {
    test('canonicalizes composite OFF tags (cereals-containing-gluten)', () {
      final res = AnalyzerService.translateAllergens(
        ['en:cereals-containing-gluten', 'cereals-and-products-thereof'],
        'it',
      );
      expect(res, ['Glutine']);
    });

    test('strips language prefixes and maps to Italian display names', () {
      final res = AnalyzerService.translateAllergens(
        ['en:milk', 'fr:lait', 'es:trigo', 'de:gerste', 'it:soia', 'en:egg'],
        'it',
      );
      expect(res, containsAll(['Latte', 'Frumento', 'Orzo', 'Soia', 'Uova']));
    });

    test('translates correctly to preferred languages (en, de, fr, es)', () {
      final list = ['milk', 'wheat', 'peanuts', 'sulphites'];

      expect(
        AnalyzerService.translateAllergens(list, 'en'),
        ['Milk', 'Wheat', 'Peanuts', 'Sulphites'],
      );
      expect(
        AnalyzerService.translateAllergens(list, 'de'),
        ['Milch', 'Weizen', 'Erdnüsse', 'Sulfite'],
      );
      expect(
        AnalyzerService.translateAllergens(list, 'fr'),
        ['Lait', 'Blé', 'Cacahuètes', 'Sulfites'],
      );
      expect(
        AnalyzerService.translateAllergens(list, 'es'),
        ['Leche', 'Trigo', 'Cacahuetes', 'Sulfitos'],
      );
    });

    test('translates tree nuts varieties (mandorle, noci, anacardi, pistacchi, macadamia, pecan, brasile)', () {
      final nuts = [
        'en:almonds',
        'en:walnuts',
        'en:cashews',
        'en:pistachios',
        'en:macadamia',
        'en:pecan',
        'brazil nut',
      ];
      final res = AnalyzerService.translateAllergens(nuts, 'it');
      expect(
        res,
        containsAll([
          'Mandorle',
          'Noci',
          'Anacardi',
          'Pistacchi',
          'Noci macadamia',
          'Noci pecan',
          'Noci del Brasile',
        ]),
      );
    });

    test('handles secondary allergens (celery, mustard, sesame, lupin, mollusc, fish, crustacean)', () {
      final list = [
        'en:celery',
        'en:mustard',
        'en:sesame-seeds',
        'en:lupin',
        'en:molluscs',
        'en:fish',
        'en:crustaceans',
      ];
      final res = AnalyzerService.translateAllergens(list, 'it');
      expect(
        res,
        [
          'Sedano',
          'Senape',
          'Sesamo',
          'Lupini',
          'Molluschi',
          'Pesce',
          'Crostacei',
        ],
      );
    });

    test('falls back to Title-case for unknown allergen terms and ignores empty strings', () {
      final res = AnalyzerService.translateAllergens(
        ['en:unknown_herb', '', '   ', 'cocoa'],
        'it',
      );
      expect(res, containsAll(['Unknown_herb', 'Cocoa']));
      expect(res.contains(''), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2 – Sanitization Logic (_sanitizeForGluten & _sanitizeForLactose)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 2 – Sanitization Logic', () {
    test('does not flag gluten-free safe phrases in product name or ingredients', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Pasta Senza Glutine Bio',
        brand: 'Gluten Free Brand',
        ingredients: 'Farina di mais, farina di riso, senza glutine, adatto ai celiaci',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
      );

      expect(res.status, GlutenSafetyStatus.adatto);
    });

    test('sanitizes deglutinated wheat starch correctly without triggering danger keyword', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Biscotti con Amido Deglutinato',
        brand: 'Bio',
        ingredients: 'Amido di frumento deglutinato, zucchero, uova',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
        offTags: OffTags(
          allergensTags: [],
          tracesTags: [],
          labelsTags: ['en:gluten-free'],
          ingredientsAnalysisTags: [],
        ),
      );

      expect(res.status, GlutenSafetyStatus.adatto);
    });

    test('sanitizes delactosed phrases when checking lactose', () {
      final isLactose = AnalyzerService.checkLactose(
        'Biscotti alla vaniglia (senza latte, senza lattosio, delattosato)',
        [],
      );
      expect(isLactose, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3 – Danger Keywords Detection (Red Status)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 3 – Danger Keywords Detection (Red Status)', () {
    test('detects Italian gluten cereals (frumento, grano, orzo, segale, farro, kamut, seitan, couscous, bulgur)', () {
      final italianCereals = [
        'farina di frumento',
        'chicchi di grano duro',
        'orzo perlato',
        'farina di segale',
        'farro spezzato',
        'kamut biologico',
        'seitan alla piastra',
        'couscous precotto',
        'bulgur di grano',
      ];

      for (final ing in italianCereals) {
        final res = AnalyzerService.analyzeGlutenSafety(
          name: 'Prodotto Test',
          brand: 'Brand',
          ingredients: ing,
          allergensList: [],
          reportCount: 0,
          categoriesTags: [],
        );
        expect(res.status, GlutenSafetyStatus.nonAdatto, reason: 'Failed for: $ing');
      }
    });

    test('detects International gluten cereals (EN, FR, ES, DE, NL, PL, etc.)', () {
      final intlCereals = [
        'wheat flour',
        'barley malt extract',
        'rye bread crumbs',
        'farine de froment',
        'orge perlée',
        'harina de trigo',
        'cebada tostada',
        'weizen mehl',
        'roggen brot',
        'dinkel',
        'tarwe gekookt',  // NL: tarwe \b matches here
        'gerst extract',  // NL: gerst
        'rogge brood',    // NL: rogge
        'pszenica',
        'buğday unu',
      ];

      for (final ing in intlCereals) {
        final res = AnalyzerService.analyzeGlutenSafety(
          name: 'Test',
          brand: 'Brand',
          ingredients: ing,
          allergensList: [],
          reportCount: 0,
          categoriesTags: [],
        );
        expect(res.status, GlutenSafetyStatus.nonAdatto, reason: 'Failed for: $ing');
      }
    });

    test('matches gluten keywords in product name as well as ingredients', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Pane di Frumento',
        brand: 'Panificio',
        ingredients: 'Acqua, lievito, sale',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
      );

      expect(res.status, GlutenSafetyStatus.nonAdatto);
    });

    test('appends Gluten to allergens list if not already present on nonAdatto status', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Biscotti',
        brand: 'Brand',
        ingredients: 'Farina di grano, zucchero',
        allergensList: ['en:milk'],
        reportCount: 0,
        categoriesTags: [],
        preferredLanguage: 'it',
      );

      expect(res.status, GlutenSafetyStatus.nonAdatto);
      expect(res.allergens, contains('Glutine'));
      expect(res.allergens, contains('Latte'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4 – Official OFF Labels & Bollino Certifications (Green Status)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 4 – Official OFF Labels & Bollino Certifications', () {
    test('grants safe status when official label tag is present (gluten-free, crossed-grain, spiga-sbarrata, etc.)', () {
      final labelTags = [
        'en:gluten-free',
        'en:senza-glutine',
        'en:crossed-grain',
        'en:spiga-sbarrata',
        'en:glutenfrei',
        'en:sans-gluten',
        'en:sin-gluten',
        'en:celiac',
      ];

      for (final tag in labelTags) {
        final res = AnalyzerService.analyzeGlutenSafety(
          name: 'Crackers',
          brand: 'Brand',
          ingredients: 'Farina di riso, olio, sale',
          allergensList: [],
          reportCount: 0,
          categoriesTags: [],
          offTags: OffTags(
            allergensTags: [],
            tracesTags: [],
            labelsTags: [tag],
            ingredientsAnalysisTags: [],
          ),
        );
        expect(res.status, GlutenSafetyStatus.adatto, reason: 'Failed for tag: $tag');
      }
    });

    test('text claims in ingredients or name grant safe status', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Snack',
        brand: 'Brand',
        ingredients: 'Farina di mais, olio di girasole, prodotto adatto ai celiaci',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
      );

      expect(res.status, GlutenSafetyStatus.adatto);
    });

    test('certified gluten-free product with declared traces remains adatto with warning note', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Gallette Certificate',
        brand: 'Brand',
        ingredients: 'Mais 99%, sale',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
        offTags: OffTags(
          allergensTags: [],
          tracesTags: ['en:gluten'],
          labelsTags: ['en:gluten-free'],
          ingredientsAnalysisTags: [],
        ),
      );

      expect(res.status, GlutenSafetyStatus.adatto);
      expect(
        res.ingredientsAnalyzed.any((i) => i.ingredient == 'Tracce (<20ppm)'),
        isTrue,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5 – Open Food Facts Tags & Ingredients Analysis
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 5 – Open Food Facts Tags & Ingredients Analysis', () {
    test('flags nonAdatto when offTags contains gluten allergen or contains-gluten tag', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Cibo Pronto',
        brand: 'Brand',
        ingredients: 'Ingredienti non specificati',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
        offTags: OffTags(
          allergensTags: ['en:wheat'],
          tracesTags: [],
          labelsTags: [],
          ingredientsAnalysisTags: ['en:contains-gluten'],
        ),
      );

      expect(res.status, GlutenSafetyStatus.nonAdatto);
    });

    test('detects gluten in tracesTags and ingredientsAnalysisTags (may-contain-gluten)', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Prodotto',
        brand: 'Brand',
        ingredients: 'Farina di riso, zucchero',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
        strictMode: false,
        offTags: OffTags(
          allergensTags: [],
          tracesTags: ['en:cereals-containing-gluten'],
          labelsTags: [],
          ingredientsAnalysisTags: ['en:may-contain-gluten'],
        ),
      );

      // Without strict mode, traces lead to incerto (Yellow)
      expect(res.status, GlutenSafetyStatus.incerto);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 6 – Cross-Contamination & Strict Mode (strictMode)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 6 – Cross-Contamination & Strict Mode', () {
    test('traces without strict mode result in incerto (Yellow)', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Cioccolato',
        brand: 'Choco',
        ingredients: 'Cacao, zucchero, burro di cacao',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
        strictMode: false,
        offTags: OffTags(
          allergensTags: [],
          tracesTags: ['en:gluten'],
          labelsTags: [],
          ingredientsAnalysisTags: [],
        ),
      );

      expect(res.status, GlutenSafetyStatus.incerto);
      expect(
        res.ingredientsAnalyzed.any((i) => i.ingredient == 'Tracce'),
        isTrue,
      );
    });

    test('traces with strictMode = true block product to nonAdatto (Red)', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Cioccolato',
        brand: 'Choco',
        ingredients: 'Cacao, zucchero, burro di cacao',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
        strictMode: true,
        offTags: OffTags(
          allergensTags: [],
          tracesTags: ['en:wheat'],
          labelsTags: [],
          ingredientsAnalysisTags: [],
        ),
      );

      expect(res.status, GlutenSafetyStatus.nonAdatto);
      expect(
        res.ingredientsAnalyzed.any((i) => i.dangerLevel == 'danger'),
        isTrue,
      );
    });

    // ── BUCO 2 ──────────────────────────────────────────────────────────────
    test(
        'danger keyword in allergensList with clean ingredients becomes a trace → incerto (strictMode = false) '
        '(STEP 4: allergensList loop branch)',
        () {
      // Ingredienti puliti (niente grano), ma allergensList contiene "frumento"
      // → l'algoritmo lo aggiunge a foundTraces (non a foundDanger)
      // → senza strictMode → incerto (giallo)
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Barretta Energetica',
        brand: 'SportBrand',
        ingredients: 'Avena certificata, sciroppo di glucosio, cioccolato',
        allergensList: ['frumento'],
        reportCount: 0,
        categoriesTags: [],
        strictMode: false,
      );

      expect(res.status, GlutenSafetyStatus.incerto);
    });

    test(
        'danger keyword in allergensList with clean ingredients becomes a trace → nonAdatto (strictMode = true) '
        '(STEP 4: allergensList loop branch + strictMode path)',
        () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Barretta Energetica',
        brand: 'SportBrand',
        ingredients: 'Avena certificata, sciroppo di glucosio, cioccolato',
        allergensList: ['frumento'],
        reportCount: 0,
        categoriesTags: [],
        strictMode: true,
      );

      expect(res.status, GlutenSafetyStatus.nonAdatto);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 7 – Additives, Doubtful Ingredients & Malt Checks
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 7 – Additives, Doubtful Ingredients & Malt Checks', () {
    test('detects doubtful additives (amido modificato, aromi, lievito) when warnAdditives = true', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Salsa',
        brand: 'Brand',
        ingredients: 'Pomodoro, amido modificato, aromi naturali, lievito',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
        warnAdditives: true,
      );

      expect(res.status, GlutenSafetyStatus.incerto);
      expect(
        res.ingredientsAnalyzed.any((i) => i.ingredient == 'amido modificato'),
        isTrue,
      );
      expect(
        res.ingredientsAnalyzed.any((i) => i.ingredient == 'aromi'),
        isTrue,
      );
    });

    test('ignores doubtful additives when warnAdditives = false', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Salsa',
        brand: 'Brand',
        ingredients: 'Pomodoro, aromi',
        allergensList: [],
        reportCount: 0,
        categoriesTags: ['en:vegetables'], // naturally safe category
        warnAdditives: false,
      );

      expect(res.status, GlutenSafetyStatus.adatto);
    });

    test('unspecified malt leads to incerto warning', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Bevanda',
        brand: 'Brand',
        ingredients: 'Acqua, estratto di malto, zucchero',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
      );

      expect(res.status, GlutenSafetyStatus.incerto);
      expect(
        res.ingredientsAnalyzed.any((i) => i.ingredient == 'Malto'),
        isTrue,
      );
    });

    test('rice malt (malto di riso) is excluded from malt danger', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Sciroppo',
        brand: 'Brand',
        ingredients: 'Malto di riso biologico',
        allergensList: [],
        reportCount: 0,
        categoriesTags: ['en:honeys'], // safe category
      );

      expect(res.status, GlutenSafetyStatus.adatto);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 8 – Lactose Detection (alertLactose & checkLactose)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 8 – Lactose Detection', () {
    test('checkLactose identifies all common dairy keywords and compound words', () {
      expect(AnalyzerService.checkLactose('latte scremato', []), isTrue);
      expect(AnalyzerService.checkLactose('burro chiarificato', []), isTrue);
      expect(AnalyzerService.checkLactose('siero di latte in polvere', []), isTrue);
      expect(AnalyzerService.checkLactose('mascarpone fresco', []), isTrue);
      expect(AnalyzerService.checkLactose('whey protein isolate', []), isTrue);
      expect(AnalyzerService.checkLactose('beurre de cuisine', []), isTrue);
      expect(AnalyzerService.checkLactose('vollmilchpulver', []), isTrue);
      expect(AnalyzerService.checkLactose('farina di riso, olio', []), isFalse);
    });

    test('checkLactose identifies dairy from allergen list tags', () {
      expect(AnalyzerService.checkLactose('', ['en:milk']), isTrue);
      expect(AnalyzerService.checkLactose('', ['fr:lait']), isTrue);
      expect(AnalyzerService.checkLactose('', ['lattosio']), isTrue);
      expect(AnalyzerService.checkLactose('', ['en:soy']), isFalse);
    });

    test('analyzeGlutenSafety with alertLactose = true appends lactose warning and red entry', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Yogurt Intero',
        brand: 'Dairy',
        ingredients: 'Latte intero, fermenti lattici vivi',
        allergensList: ['en:milk'],
        reportCount: 0,
        categoriesTags: ['en:milks'],
        alertLactose: true,
      );

      expect(res.status, GlutenSafetyStatus.adatto); // Gluten-wise safe
      expect(res.reason, contains('🥛'));
      expect(
        res.ingredientsAnalyzed.any((i) => i.ingredient == 'latte' && i.dangerLevel == 'danger'),
        isTrue,
      );
    });

    // ── BUCO 1 ──────────────────────────────────────────────────────────────
    test(
        'OFF tag en:milk triggers "Allergene Latte (OFF)" when ingredient text is clean '
        '(hasMilk && foundLactose.isEmpty branch)',
        () {
      // Ingredienti senza nessuna parola casearia → foundLactose.isEmpty sarà true
      // ma offTags.allergensTags contiene 'en:milk' → deve aggiungere la voce speciale
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Cracker Salati',
        brand: 'Brand',
        ingredients: 'Farina di mais, olio di girasole, sale',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
        alertLactose: true,
        offTags: OffTags(
          allergensTags: ['en:milk'], // tag ufficiale OFF, non citato negli ingredienti
          tracesTags: [],
          labelsTags: [],
          ingredientsAnalysisTags: [],
        ),
      );

      // Lo stato glutine non cambia (mais + olio + sale = safe category non attiva, ma niente glutine)
      expect(res.reason, contains('🥛'));
      expect(
        res.ingredientsAnalyzed.any((i) => i.ingredient == 'Allergene Latte (OFF)'),
        isTrue,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 9 – Naturally Safe Products & Categories
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 9 – Naturally Safe Products & Categories', () {
    test('recognizes all naturally safe categories (waters, fresh fruits, vegetables, oils, salts, sugars, teas, coffees)', () {
      final categories = [
        'en:waters',
        'en:mineral-waters',
        'en:fresh-fruits',
        'en:fresh-vegetables',
        'en:extra-virgin-olive-oils',
        'en:olive-oils',
        'en:sugars',
        'en:honeys',
        'en:salts',
        'en:coffees',
        'en:teas',
      ];

      for (final cat in categories) {
        final res = AnalyzerService.analyzeGlutenSafety(
          name: 'Prodotto Naturale',
          brand: 'Brand',
          ingredients: 'Ingredienti semplici',
          allergensList: [],
          reportCount: 0,
          categoriesTags: [cat],
        );

        expect(res.status, GlutenSafetyStatus.adatto, reason: 'Failed for cat: $cat');
        expect(
          res.ingredientsAnalyzed.any((i) => i.ingredient == 'Naturalmente Sicuro'),
          isTrue,
        );
      }
    });

    test('recognizes pure mono-ingredient product (e.g. 100% Riso)', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Riso Carnaroli',
        brand: 'Riso Bio',
        ingredients: 'Riso carnaroli 100%',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
      );

      expect(res.status, GlutenSafetyStatus.adatto);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 10 – Missing Info / Unknown Status (GlutenSafetyStatus.sconosciuto)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 10 – Missing Info / Unknown Status', () {
    test('returns sconosciuto when ingredients text is absent or shorter than 5 chars', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Prodotto Misterioso',
        brand: 'Unknown',
        ingredients: '',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
      );

      expect(res.status, GlutenSafetyStatus.sconosciuto);
      expect(
        res.ingredientsAnalyzed.any((i) => i.ingredient == 'Dati Assenti'),
        isTrue,
      );
    });

    test('treats "Non disponibile" string as empty info', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Prodotto',
        brand: 'Brand',
        ingredients: 'Non disponibile',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
      );

      expect(res.status, GlutenSafetyStatus.sconosciuto);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 11 – Community User Reports Priority (reportCount & ignoreReports)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 11 – Community User Reports Priority', () {
    test('overrides even certified gluten-free products to incerto when reportCount > 0', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Biscotti Certificati',
        brand: 'Brand',
        ingredients: 'Farina di riso, senza glutine',
        allergensList: [],
        reportCount: 3,
        categoriesTags: [],
        offTags: OffTags(
          allergensTags: [],
          tracesTags: [],
          labelsTags: ['en:gluten-free'],
          ingredientsAnalysisTags: [],
        ),
      );

      expect(res.status, GlutenSafetyStatus.incerto);
      expect(
        res.ingredientsAnalyzed.any((i) => i.ingredient == 'Segnalazione Utenti'),
        isTrue,
      );
    });

    test('calculates intrinsic status when ignoreReports = true despite reportCount > 0', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Biscotti Certificati',
        brand: 'Brand',
        ingredients: 'Farina di riso, senza glutine',
        allergensList: [],
        reportCount: 5,
        categoriesTags: [],
        ignoreReports: true,
        offTags: OffTags(
          allergensTags: [],
          tracesTags: [],
          labelsTags: ['en:gluten-free'],
          ingredientsAnalysisTags: [],
        ),
      );

      expect(res.status, GlutenSafetyStatus.adatto);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 12 – Agglutinative Languages & Compound Words Detection
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 12 – Agglutinative Languages & Compound Words Detection', () {
    test('identifies German compound wheat flour (weizenmehl) as nonAdatto (Red)', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Mehl',
        brand: 'Bio',
        ingredients: 'weizenmehl',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
      );

      expect(res.status, GlutenSafetyStatus.nonAdatto);
      expect(
        res.ingredientsAnalyzed.any((i) => i.dangerLevel == 'danger'),
        isTrue,
      );
    });

    test('identifies Dutch compound wheat flour (tarwebloem) as nonAdatto (Red)', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Bloem',
        brand: 'Bio',
        ingredients: 'tarwebloem',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
      );

      expect(res.status, GlutenSafetyStatus.nonAdatto);
      expect(
        res.ingredientsAnalyzed.any((i) => i.dangerLevel == 'danger'),
        isTrue,
      );
    });

    test('identifies German compound whole milk powder (vollmilchpulver) as adatto with lactose reason when alertLactose is true', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Milchpulver',
        brand: 'Bio',
        ingredients: 'vollmilchpulver',
        allergensList: [],
        reportCount: 0,
        categoriesTags: ['en:milks'],
        alertLactose: true,
      );

      expect(res.status, GlutenSafetyStatus.adatto);
      expect(res.reason, contains('product.analysis.lactoseAlert'));
      expect(
        res.ingredientsAnalyzed.any((i) => i.dangerLevel == 'danger'),
        isTrue,
      );
    });

    test('buckwheat flour (grano saraceno) is NOT flagged as wheat (Safe / adatto)', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Buckwheat Flour',
        brand: 'Healthy Grain',
        ingredients: 'buckwheat flour',
        allergensList: [],
        reportCount: 0,
        categoriesTags: [],
      );

      expect(res.status, GlutenSafetyStatus.adatto);
      expect(
        res.ingredientsAnalyzed.any((i) => i.dangerLevel == 'danger'),
        isFalse,
      );
    });

    test('succo di melograno (pomegranate juice) is NOT flagged as grano (Safe / adatto)', () {
      final res = AnalyzerService.analyzeGlutenSafety(
        name: 'Succo Bio',
        brand: 'Nature',
        ingredients: 'succo di melograno',
        allergensList: [],
        reportCount: 0,
        categoriesTags: ['en:fruits'],
      );

      expect(res.status, GlutenSafetyStatus.adatto);
      expect(
        res.ingredientsAnalyzed.any((i) => i.dangerLevel == 'danger'),
        isFalse,
      );
    });
  });
}

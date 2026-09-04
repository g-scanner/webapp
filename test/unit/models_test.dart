// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Pure Unit Tests: Models (models.dart)

import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:gscanner/models/models.dart';
import 'package:gscanner/services/analyzer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  EasyLocalization.logger.enableLevels = [];

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1 – IngredientAnalyzed Model
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 1 – IngredientAnalyzed Model', () {
    test('serializes and deserializes correctly via toJson and fromJson', () {
      final item = IngredientAnalyzed(
        ingredient: 'Farina di frumento',
        dangerLevel: 'danger',
        reason: 'Contiene glutine',
      );

      final jsonMap = item.toJson();
      expect(jsonMap['ingredient'], 'Farina di frumento');
      expect(jsonMap['dangerLevel'], 'danger');
      expect(jsonMap['reason'], 'Contiene glutine');

      final deserialized = IngredientAnalyzed.fromJson(jsonMap);
      expect(deserialized.ingredient, 'Farina di frumento');
      expect(deserialized.dangerLevel, 'danger');
      expect(deserialized.reason, 'Contiene glutine');
    });

    test('fromJson applies default values for missing keys', () {
      final item = IngredientAnalyzed.fromJson({});
      expect(item.ingredient, '');
      expect(item.dangerLevel, 'warning');
      expect(item.reason, '');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2 – Product Multilingual Getters & Fallbacks
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 2 – Product Multilingual Getters & Fallbacks', () {
    test('getName returns preferredLanguage if available and non-empty', () {
      final p = Product(
        barcode: '123',
        nameMap: {'it': 'Pasta', 'en': 'Pasta EN', 'de': 'Nudeln'},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: '2026-08-01T00:00:00Z',
      );

      expect(p.getName('de'), 'Nudeln');
      expect(p.getName('en'), 'Pasta EN');
      expect(p.getName('it'), 'Pasta');
    });

    test('getName falls back through standard languages order (it -> en -> es -> fr -> de) if preferred missing', () {
      final p = Product(
        barcode: '123',
        nameMap: {'fr': 'Pâtes', 'de': 'Nudeln'},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: '2026-08-01T00:00:00Z',
      );

      // 'es' is requested, not present -> searches it, en, es, fr -> finds 'fr'
      expect(p.getName('es'), 'Pâtes');
    });

    test('getName returns first non-empty value if no standard language is matched', () {
      final p = Product(
        barcode: '123',
        nameMap: {'pl': 'Makaron'},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: '2026-08-01T00:00:00Z',
      );

      expect(p.getName('it'), 'Makaron');
    });

    test('getName returns translated unknown string when nameMap is completely empty', () {
      final p = Product(
        barcode: '123',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: '2026-08-01T00:00:00Z',
      );

      expect(p.getName('it'), 'product.status.unknownProductName');
    });

    test('getBrand ignores empty strings and hyphens ("-") during fallback', () {
      final p = Product(
        barcode: '123',
        nameMap: {},
        brandMap: {'it': '-', 'en': '', 'de': 'BioMarke'},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: '2026-08-01T00:00:00Z',
      );

      // 'it' requested but is '-', falls back and finds 'de'
      expect(p.getBrand('it'), 'BioMarke');
    });

    test('getBrand returns empty string if all brands are empty or hyphens', () {
      final p = Product(
        barcode: '123',
        nameMap: {},
        brandMap: {'it': '-', 'en': ''},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: '2026-08-01T00:00:00Z',
      );

      expect(p.getBrand('it'), '');
    });

    test('getIngredients falls back properly and returns empty string if maps are empty', () {
      final p = Product(
        barcode: '123',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {'en': 'Rice flour, salt'},
        allergensMap: {},
        lastUpdated: '2026-08-01T00:00:00Z',
      );

      expect(p.getIngredients('it'), 'Rice flour, salt');

      final emptyP = Product(
        barcode: '123',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: '2026-08-01T00:00:00Z',
      );
      expect(emptyP.getIngredients('it'), '');
    });

    test('getAllergens falls back to first available non-standard language via firstWhere', () {
      // 'pl' is not in ['it', 'en', 'es', 'fr', 'de'] -> reaches allergensMap.values.firstWhere
      final p = Product(
        barcode: '123',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {'pl': ['Soja', 'Jaja']},
        lastUpdated: '2026-08-01T00:00:00Z',
      );

      expect(p.getAllergens('it'), ['Soja', 'Jaja']);
    });

    test('getAllergens returns empty list if no allergen data in any language or all empty', () {
      final p = Product(
        barcode: '123',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {'es': ['Soja']},
        lastUpdated: '2026-08-01T00:00:00Z',
      );

      expect(p.getAllergens('it'), ['Soja']);

      final emptyP = Product(
        barcode: '123',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: '2026-08-01T00:00:00Z',
      );
      expect(emptyP.getAllergens('it'), isEmpty);

      final blankListP = Product(
        barcode: '123',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {'pl': []},
        lastUpdated: '2026-08-01T00:00:00Z',
      );
      expect(blankListP.getAllergens('it'), isEmpty);
    });

    test('getAllergens preserves allergens for analysis while translateAllergens strips safe claims for UI', () {
      final p = Product(
        barcode: '123',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {
          'it': ['en:milk', 'Senza Glutine', 'it:senza-glutine', 'en:gluten-free', 'en:eggs'],
        },
        lastUpdated: '2026-08-01T00:00:00Z',
      );

      final raw = p.getAllergens('it');
      expect(raw, contains('Senza Glutine')); // Preservato per il motore di analisi

      final translated = AnalyzerService.translateAllergens(raw, 'it');
      expect(translated, ['Latte', 'Uova']);
      expect(translated.contains('Senza Glutine'), isFalse);
      expect(translated.contains('it:senza-glutine'), isFalse);
      expect(translated.contains('en:gluten-free'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3 – Product Retrocompatibility Getters & Data Flags
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 3 – Product Retrocompatibility Getters & Data Flags', () {
    test('retrocompatibility getters delegate to Italian versions and pendingReportsCount', () {
      final p = Product(
        barcode: '123',
        nameMap: {'it': 'Nome IT'},
        brandMap: {'it': 'Brand IT'},
        ingredientsMap: {'it': 'Ing IT'},
        allergensMap: {'it': ['Latte']},
        pendingReportsCount: 4,
        lastUpdated: '2026-08-01T00:00:00Z',
      );

      expect(p.name, 'Nome IT');
      expect(p.brand, 'Brand IT');
      expect(p.ingredients, 'Ing IT');
      expect(p.allergens, ['Latte']);
      expect(p.reportCount, 4);
    });

    test('hasIngredientData returns true only when at least one non-empty string exists', () {
      final pEmpty = Product(
        barcode: '1',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: '2026-08-01T00:00:00Z',
      );
      expect(pEmpty.hasIngredientData, isFalse);

      final pBlank = Product(
        barcode: '2',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {'it': '   '},
        allergensMap: {},
        lastUpdated: '2026-08-01T00:00:00Z',
      );
      expect(pBlank.hasIngredientData, isFalse);

      final pValid = Product(
        barcode: '3',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {'it': 'Mais'},
        allergensMap: {},
        lastUpdated: '2026-08-01T00:00:00Z',
      );
      expect(pValid.hasIngredientData, isTrue);
    });

    test('hasAllergenData checks declared allergens and ingredients presence', () {
      // 1. Allergens map empty -> false
      final p1 = Product(
        barcode: '1',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {'it': 'Riso'},
        allergensMap: {},
        lastUpdated: '2026-08-01T00:00:00Z',
      );
      expect(p1.hasAllergenData, isFalse);

      // 2. Declared allergen present -> true
      final p2 = Product(
        barcode: '2',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {'it': ['Uova']},
        lastUpdated: '2026-08-01T00:00:00Z',
      );
      expect(p2.hasAllergenData, isTrue);

      // 3. Declared allergens list is empty, but ingredients exist -> true (0 allergens declared)
      final p3 = Product(
        barcode: '3',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {'it': 'Riso 100%'},
        allergensMap: {'it': []},
        lastUpdated: '2026-08-01T00:00:00Z',
      );
      expect(p3.hasAllergenData, isTrue);

      // 4. Declared allergens list is empty, and NO ingredients -> false
      final p4 = Product(
        barcode: '4',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {'it': []},
        lastUpdated: '2026-08-01T00:00:00Z',
      );
      expect(p4.hasAllergenData, isFalse);

      // 5. Declared allergens only contain safe gluten claims and NO ingredients -> false (treated as empty/insufficient data)
      final p5 = Product(
        barcode: '5',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {'it': ['Senza Glutine', 'en:gluten-free']},
        lastUpdated: '2026-08-01T00:00:00Z',
      );
      expect(p5.hasAllergenData, isFalse);

      // 6. Declared allergens only contain safe gluten claims, but ingredients exist -> true (0 genuine allergens declared)
      final p6 = Product(
        barcode: '6',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {'it': 'Acqua, zucchero'},
        allergensMap: {'it': ['Senza Glutine', 'en:gluten-free']},
        lastUpdated: '2026-08-01T00:00:00Z',
      );
      expect(p6.hasAllergenData, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4 – Product Serialization & Legacy Migration
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 4 – Product Serialization & Legacy Migration', () {
    test('fromJson preserves allergens_map and allergens array for analysis engine', () {
      final jsonMap = {
        'barcode': '8000000000001',
        'name_map': {'it': 'Biscotti'},
        'brand_map': {'it': 'Mulino'},
        'ingredients_map': {'it': 'Farina di riso'},
        'allergens_map': {
          'it': ['Latte', 'Senza Glutine', 'it:senza-glutine', 'en:gluten-free'],
        },
      };

      final p = Product.fromJson(jsonMap);
      expect(p.allergensMap['it'], ['Latte', 'Senza Glutine', 'it:senza-glutine', 'en:gluten-free']);
      expect(p.getAllergens('it'), contains('Senza Glutine'));

      final legacyJson = {
        'barcode': '8000000000002',
        'allergens': ['Senza Glutine', 'en:gluten-free', 'Uova'],
      };
      final pLegacy = Product.fromJson(legacyJson);
      expect(pLegacy.allergensMap['it'], ['Senza Glutine', 'en:gluten-free', 'Uova']);
      expect(pLegacy.getAllergens('it'), contains('Senza Glutine'));
    });

    test('fromJson parses modern Map structures correctly', () {
      final jsonMap = {
        'barcode': '8000000000001',
        'name_map': {'it': 'Biscotti', 'en': 'Cookies'},
        'brand_map': {'it': 'Mulino'},
        'ingredients_map': {'it': 'Farina di riso'},
        'allergens_map': {'it': ['Latte']},
        'image_url': 'https://img.com/1.jpg',
        'pending_reports_count': 2,
        'last_updated': '2026-08-20T10:00:00Z',
        'fetched_from_off_at': '2026-08-20T10:00:00Z',
      };

      final p = Product.fromJson(jsonMap);

      expect(p.barcode, '8000000000001');
      expect(p.nameMap['en'], 'Cookies');
      expect(p.brandMap['it'], 'Mulino');
      expect(p.imageUrl, 'https://img.com/1.jpg');
      expect(p.pendingReportsCount, 2);
      expect(p.fetchedFromOffAt, '2026-08-20T10:00:00Z');

      final serialized = p.toJson();
      expect(serialized['barcode'], '8000000000001');
      expect(serialized['name_map']['it'], 'Biscotti');
      expect(serialized['pending_reports_count'], 2);
    });

    test('fromJson handles legacy flat fields (name, brand, ingredients, allergens, reportCount, imageUrl)', () {
      final legacyJson = {
        'barcode': '8000000000002',
        'name': 'Legacy Name',
        'brand': 'Legacy Brand',
        'ingredients': 'Legacy Ingredients',
        'allergens': ['Uova', 'Soia'],
        'imageUrl': 'https://img.com/legacy.jpg',
        'reportCount': 5,
        'lastUpdated': '2025-01-01T00:00:00Z',
        'fetchedFromOffAt': '2025-01-01T00:00:00Z',
      };

      final p = Product.fromJson(legacyJson);

      expect(p.barcode, '8000000000002');
      expect(p.nameMap['it'], 'Legacy Name');
      expect(p.nameMap['en'], 'Legacy Name');
      expect(p.brandMap['it'], 'Legacy Brand');
      expect(p.ingredientsMap['it'], 'Legacy Ingredients');
      expect(p.allergensMap['it'], containsAll(['Uova', 'Soia']));
      expect(p.imageUrl, 'https://img.com/legacy.jpg');
      expect(p.pendingReportsCount, 5);
      expect(p.lastUpdated, '2025-01-01T00:00:00Z');
      expect(p.fetchedFromOffAt, '2025-01-01T00:00:00Z');
    });

    test('fromJson initializes safe empty maps and default values when JSON is completely empty ({})', () {
      final p = Product.fromJson({});

      expect(p.barcode, '');
      expect(p.nameMap, isA<Map<String, String>>());
      expect(p.nameMap, isEmpty);
      expect(p.brandMap, isA<Map<String, String>>());
      expect(p.brandMap, isEmpty);
      expect(p.ingredientsMap, isA<Map<String, String>>());
      expect(p.ingredientsMap, isEmpty);
      expect(p.allergensMap, isA<Map<String, List<String>>>());
      expect(p.allergensMap, isEmpty);
      expect(p.imageUrl, isNull);
      expect(p.pendingReportsCount, 0);
      expect(p.lastUpdated, isNotEmpty);
      expect(p.fetchedFromOffAt, isNull);

      // Safe access verification: accessing any key or getter must not throw NPE
      expect(p.nameMap['it'], isNull);
      expect(p.getName('it'), 'product.status.unknownProductName');
      expect(p.getBrand('it'), '');
      expect(p.getIngredients('it'), '');
      expect(p.getAllergens('it'), isEmpty);
      expect(p.hasAllergenData, isFalse);
      expect(p.hasIngredientData, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5 – ScanHistoryItem Model
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 5 – ScanHistoryItem Model', () {
    test('serializes and deserializes correctly via toJson and fromJson', () {
      final item = ScanHistoryItem(
        id: 'hist_123',
        barcode: '8001234567890',
        scannedAt: '2026-08-20T12:00:00Z',
      );

      final jsonMap = item.toJson();
      expect(jsonMap['id'], 'hist_123');
      expect(jsonMap['barcode'], '8001234567890');
      expect(jsonMap['scannedAt'], '2026-08-20T12:00:00Z');

      final deserialized = ScanHistoryItem.fromJson(jsonMap);
      expect(deserialized.id, 'hist_123');
      expect(deserialized.barcode, '8001234567890');
      expect(deserialized.scannedAt, '2026-08-20T12:00:00Z');
    });

    test('fromJson supports snake_case scanned_at key and defaults for missing fields', () {
      final item = ScanHistoryItem.fromJson({
        'id': 'h_snake',
        'barcode': '999',
        'scanned_at': '2026-08-15T08:30:00Z',
      });

      expect(item.id, 'h_snake');
      expect(item.barcode, '999');
      expect(item.scannedAt, '2026-08-15T08:30:00Z');

      final defaultItem = ScanHistoryItem.fromJson({});
      expect(defaultItem.id, '');
      expect(defaultItem.barcode, '');
      expect(defaultItem.scannedAt, isNotEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 6 – ProductReport Model
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 6 – ProductReport Model', () {
    test('serializes and deserializes correctly via toJson and fromJson', () {
      final report = ProductReport(
        id: 'rep_001',
        userId: 'user_456',
        barcode: '8001112223334',
        productName: 'Pane Rustico',
        brand: 'Panificio',
        type: 'gluten_detected',
        comments: 'Trovata farina di frumento!',
        submittedAt: '2026-08-20T15:00:00Z',
        status: 'open',
        score: 3,
      );

      final jsonMap = report.toJson();
      expect(jsonMap['id'], 'rep_001');
      expect(jsonMap['userId'], 'user_456');
      expect(jsonMap['barcode'], '8001112223334');
      expect(jsonMap['score'], 3);

      final deserialized = ProductReport.fromJson(jsonMap);
      expect(deserialized.id, 'rep_001');
      expect(deserialized.userId, 'user_456');
      expect(deserialized.type, 'gluten_detected');
      expect(deserialized.score, 3);
    });

    test('fromJson applies defaults for missing fields', () {
      final report = ProductReport.fromJson({
        'id': 'r_empty',
        'barcode': '111',
      });

      expect(report.id, 'r_empty');
      expect(report.userId, isNull);
      expect(report.type, 'label_unclear');
      expect(report.status, 'open');
      expect(report.comments, '');
      expect(report.score, 0);
      expect(report.submittedAt, isNotEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 7 – UserSettings Model
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 7 – UserSettings Model', () {
    test('serializes and deserializes correctly via toJson and fromJson', () {
      final settings = UserSettings(
        userId: 'u_100',
        strictMode: false,
        alertLactose: true,
        warnAdditives: false,
        autoSaveHistory: false,
        preferredLanguage: 'de',
        preferredTheme: 'dark',
        reportedBarcodes: ['8001', '8002'],
      );

      final jsonMap = settings.toJson();
      expect(jsonMap['userId'], 'u_100');
      expect(jsonMap['strictMode'], isFalse);
      expect(jsonMap['alertLactose'], isTrue);
      expect(jsonMap['preferredLanguage'], 'de');
      expect(jsonMap['preferredTheme'], 'dark');
      expect(jsonMap['reportedBarcodes'], containsAll(['8001', '8002']));

      final deserialized = UserSettings.fromJson(jsonMap);
      expect(deserialized.userId, 'u_100');
      expect(deserialized.strictMode, isFalse);
      expect(deserialized.alertLactose, isTrue);
      expect(deserialized.preferredLanguage, 'de');
      expect(deserialized.preferredTheme, 'dark');
      expect(deserialized.reportedBarcodes, containsAll(['8001', '8002']));
    });

    test('fromJson applies standard defaults when JSON is empty', () {
      final settings = UserSettings.fromJson({});

      expect(settings.userId, isNull);
      expect(settings.strictMode, isTrue);
      expect(settings.alertLactose, isFalse);
      expect(settings.warnAdditives, isTrue);
      expect(settings.autoSaveHistory, isTrue);
      expect(settings.preferredTheme, 'system');
      expect(settings.reportedBarcodes, isEmpty);
      expect(settings.preferredLanguage, isNotEmpty);
    });

    test('defaultSystemLanguage returns a valid supported language code or fallback en', () {
      final lang = UserSettings.defaultSystemLanguage;
      expect(['en', 'it', 'de', 'fr', 'es'], contains(lang));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 8 – Date Formatting Utility Functions
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 8 – Date Formatting Utility Functions', () {
    test('formatRelativeDate returns today, yesterday, or Italian month formatted date', () {
      final now = DateTime.now();
      final todayIso = now.toIso8601String();
      final yesterdayIso = now.subtract(const Duration(days: 1)).toIso8601String();
      final pastIso = DateTime(2026, 8, 15, 14, 30).toIso8601String();

      // Today
      final todayFormatted = formatRelativeDate(todayIso);
      expect(todayFormatted, contains(':'));

      // Yesterday
      final yesterdayFormatted = formatRelativeDate(yesterdayIso);
      expect(yesterdayFormatted, contains(':'));

      // Past date (Month 8 -> Ago)
      final pastFormatted = formatRelativeDate(pastIso);
      expect(pastFormatted, contains('Ago 2026'));
      expect(pastFormatted, contains('14:30'));

      // Invalid ISO string returns empty string
      expect(formatRelativeDate('invalid-date'), '');
    });

    test('formatScanDate formats scan dates and handles errors with fallback', () {
      final now = DateTime.now();
      final todayIso = now.toIso8601String();
      final yesterdayIso = now.subtract(const Duration(days: 1)).toIso8601String();
      final pastIso = DateTime(2026, 12, 25, 9, 15).toIso8601String();

      expect(formatScanDate(todayIso), isNotEmpty);
      expect(formatScanDate(yesterdayIso), isNotEmpty);
      expect(formatScanDate(pastIso), isNotEmpty);

      // Invalid ISO string returns the original input
      expect(formatScanDate('corrupt_iso'), 'corrupt_iso');
    });

    test('formatReportDate formats report dates and handles errors with fallback', () {
      final now = DateTime.now();
      final todayIso = now.toIso8601String();
      final yesterdayIso = now.subtract(const Duration(days: 1)).toIso8601String();
      final pastIso = DateTime(2026, 3, 10, 18, 45).toIso8601String();

      expect(formatReportDate(todayIso), isNotEmpty);
      expect(formatReportDate(yesterdayIso), isNotEmpty);
      expect(formatReportDate(pastIso), isNotEmpty);

      // Invalid ISO string returns the original input
      expect(formatReportDate('corrupt_iso'), 'corrupt_iso');
    });
  });
}

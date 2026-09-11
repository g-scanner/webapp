// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Pure Unit Tests: OffProductParser

import 'package:flutter_test/flutter_test.dart';
import 'package:gscanner/models/models.dart';
import 'package:gscanner/services/database/off_product_parser.dart';

void main() {
  final testSettings = UserSettings(
    strictMode: true,
    alertLactose: false,
    warnAdditives: true,
    autoSaveHistory: true,
    preferredLanguage: 'it',
  );

  group('OffProductParser.cleanIngredientsText', () {
    test('returns unchanged if empty or whitespace', () {
      expect(OffProductParser.cleanIngredientsText(''), '');
      expect(OffProductParser.cleanIngredientsText('   '), '   ');
    });

    test('removes markdown underscores around emphasized words', () {
      const input = 'Farina di _frumento_, zucchero, _latte_ in polvere';
      expect(
        OffProductParser.cleanIngredientsText(input),
        'Farina di frumento, zucchero, latte in polvere',
      );
    });

    test('removes stray underscores', () {
      const input = 'Olio_vegetale_di palma';
      expect(
        OffProductParser.cleanIngredientsText(input),
        'Oliovegetaledi palma',
      );
    });

    test('extracts text from OFF language tags like {en:sugar}', () {
      const input = '{it:Farina di riso}, {en:corn starch}, {fr:sucre}';
      expect(
        OffProductParser.cleanIngredientsText(input),
        'Farina di riso, corn starch, sucre',
      );
    });

    test('strips arbitrary unknown curly brace blocks and stray braces', () {
      const input = 'Acqua, {unknown tag} sale { } e lievito';
      expect(
        OffProductParser.cleanIngredientsText(input),
        'Acqua, sale e lievito',
      );
    });

    test('removes dollar signs', () {
      const input = 'Sale, \$aromi, zucchero';
      expect(
        OffProductParser.cleanIngredientsText(input),
        'Sale, aromi, zucchero',
      );
    });

    test('normalizes nested parentheses into comma-separated list', () {
      const input = 'Cioccolato (cacao (zucchero))';
      expect(
        OffProductParser.cleanIngredientsText(input),
        'Cioccolato (cacao, zucchero)',
      );
    });

    test('cleans whitespace inside parentheses', () {
      const input = 'Biscotti (  farina di riso , olio di semi  )';
      expect(
        OffProductParser.cleanIngredientsText(input),
        'Biscotti (farina di riso, olio di semi)',
      );
    });

    test('removes empty or punctuation-only parentheses', () {
      const input = 'Pomodoro () origano (-) sale';
      expect(
        OffProductParser.cleanIngredientsText(input),
        'Pomodoro origano sale',
      );
    });

    test('removes double closing parentheses and space before punctuation', () {
      const input = 'Zucchero , cacao )) . Olio ; sale';
      expect(
        OffProductParser.cleanIngredientsText(input),
        'Zucchero, cacao). Olio; sale',
      );
    });

    test('compresses multiple consecutive spaces into a single space', () {
      const input = 'Farina     di     riso      100%';
      expect(
        OffProductParser.cleanIngredientsText(input),
        'Farina di riso 100%',
      );
    });
  });

  group('OffProductParser.getFirstNonEmptyString', () {
    test('returns first non-empty string among candidate keys', () {
      final map = {
        'k1': '',
        'k2': '  val2  ',
        'k3': 'val3',
      };
      expect(OffProductParser.getFirstNonEmptyString(map, ['k1', 'k2', 'k3'], 'def'), 'val2');
    });

    test('extracts first item when value is a List of strings', () {
      final map = {
        'tags': ['FirstTag', 'SecondTag'],
      };
      expect(OffProductParser.getFirstNonEmptyString(map, ['tags'], 'def'), 'FirstTag');
    });

    test('handles non-string types safely by calling toString()', () {
      final map = {
        'code': 12345,
      };
      expect(OffProductParser.getFirstNonEmptyString(map, ['code'], 'def'), '12345');
    });

    test('returns default value if all keys are missing, null, or blank', () {
      final map = {
        'emptyList': [],
        'blank': '   ',
        'nullKey': null,
      };
      expect(
        OffProductParser.getFirstNonEmptyString(map, ['emptyList', 'blank', 'nullKey', 'missing'], 'fallback'),
        'fallback',
      );
    });
  });

  group('OffProductParser.parseProduct', () {
    test('parses full multilingual payload with names, brands, ingredients, allergen tags and image', () {
      final payload = {
        'product_name_it': 'Biscotti al Cioccolato',
        'product_name_en': 'Chocolate Cookies',
        'brands': 'Mulino Test',
        'ingredients_text_it': 'Farina di _frumento_, gocce di cioccolato',
        'ingredients_text_en': '_Wheat_ flour, chocolate chips',
        'allergens_tags': ['en:gluten', 'en:milk'],
        'image_url': 'https://images.openfoodfacts.org/1.jpg',
      };

      final product = OffProductParser.parseProduct('8001234567890', payload, testSettings);

      expect(product.barcode, '8001234567890');
      expect(product.nameMap['it'], 'Biscotti al Cioccolato');
      expect(product.nameMap['en'], 'Chocolate Cookies');
      expect(product.brandMap['it'], 'Mulino Test');
      expect(product.brandMap['en'], 'Mulino Test');
      expect(product.ingredientsMap['it'], 'Farina di frumento, gocce di cioccolato');
      expect(product.ingredientsMap['en'], 'Wheat flour, chocolate chips');
      expect(product.allergensMap['it'], contains('Glutine'));
      expect(product.allergensMap['it'], contains('Latte'));
      expect(product.imageUrl, 'https://images.openfoodfacts.org/1.jpg');
      expect(product.isGhostProduct, isFalse);
      expect(product.isStale, isFalse);
    });

    test('ignores brands if value is empty or "-"', () {
      final payload = {
        'product_name': 'Prodotto Generico',
        'brands': '-',
      };

      final product = OffProductParser.parseProduct('1111', payload, testSettings);
      expect(product.brandMap, isEmpty);
    });

    test('uses fallback image keys (image_front_url, image_thumb_url)', () {
      final p1 = OffProductParser.parseProduct('1', {'image_front_url': 'https://front.jpg'}, testSettings);
      expect(p1.imageUrl, 'https://front.jpg');

      final p2 = OffProductParser.parseProduct('2', {'image_thumb_url': 'https://thumb.jpg'}, testSettings);
      expect(p2.imageUrl, 'https://thumb.jpg');
    });

    test('extreme fallback for ingredients: uses any ingredients_text_* if supported langs missing', () {
      final payload = {
        'product_name': 'Biscotti Polacchi',
        'ingredients_text_pl': 'Mąka pszenna, cukier',
      };

      final product = OffProductParser.parseProduct('2222', payload, testSettings);
      expect(product.ingredientsMap['en'], 'Mąka pszenna, cukier');
      expect(product.hasIngredientData, isTrue);
    });

    test('fallback for product name: uses any product_name* if supported langs missing', () {
      final payload = {
        'product_name_cs': 'Sušenky',
        'ingredients_text_it': 'Riso',
      };

      final product = OffProductParser.parseProduct('3333', payload, testSettings);
      expect(product.nameMap['en'], 'Sušenky');
    });

    test('allergens extracted from allergens_from_ingredients comma string', () {
      final payload = {
        'product_name': 'Pane',
        'ingredients_text_it': 'Farina, sale',
        'allergens_from_ingredients': 'en:gluten, en:soybeans',
      };

      final product = OffProductParser.parseProduct('4444', payload, testSettings);
      expect(product.allergensMap['it'], isNotEmpty);
      expect(product.allergensMap['it'], contains('Glutine'));
      expect(product.allergensMap['it'], contains('Soia'));
    });

    test('allergens extracted from allergens comma string', () {
      final payload = {
        'product_name': 'Pasta',
        'ingredients_text_it': 'Semola',
        'allergens': 'en:gluten',
      };

      final product = OffProductParser.parseProduct('5555', payload, testSettings);
      expect(product.allergensMap['it'], contains('Glutine'));
    });

    test('empty allergens list when ingredients exist but no allergens specified', () {
      final payload = {
        'product_name': 'Mela',
        'ingredients_text_it': '100% mela',
      };

      final product = OffProductParser.parseProduct('6666', payload, testSettings);
      expect(product.allergensMap['it'], isEmpty);
      expect(product.allergensMap['en'], isEmpty);
    });

    test('appends (Senza glutine) when safe claim tag is present', () {
      final payload = {
        'product_name': 'Biscotti Certificati',
        'ingredients_text_it': 'Farina di riso',
        'allergens_tags': ['en:gluten-free'],
      };

      final product = OffProductParser.parseProduct('7777', payload, testSettings);
      expect(product.ingredientsMap['it'], contains('Senza glutine'));
    });
  });
}

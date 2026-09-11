// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Pure Unit Tests: 3-Window Freshness Architecture (GOAT)

import 'package:flutter_test/flutter_test.dart';
import 'package:gscanner/models/models.dart';

void main() {
  group('ProductFreshnessWindow – Level A: Super Fresco (0 - 7 days)', () {
    test('Product fetched just now (0 days) is superFresh', () {
      final p = Product(
        barcode: 'fresh_0',
        nameMap: {'it': 'Pasta Fresca'},
        brandMap: {'it': 'Barilla'},
        ingredientsMap: {'it': 'Semola di grano duro'},
        allergensMap: {},
        lastUpdated: DateTime.now().toIso8601String(),
        fetchedFromOffAt: DateTime.now().toIso8601String(),
      );

      expect(p.freshnessWindow, equals(ProductFreshnessWindow.superFresh));
      expect(p.isSuperFresh, isTrue);
      expect(p.isInTolerance, isFalse);
      expect(p.isStale, isFalse);
    });

    test('Product fetched 3 days ago is superFresh', () {
      final date = DateTime.now().subtract(const Duration(days: 3)).toIso8601String();
      final p = Product(
        barcode: 'fresh_3',
        nameMap: {'it': 'Biscotti'},
        brandMap: {},
        ingredientsMap: {'it': 'Farina di riso'},
        allergensMap: {},
        lastUpdated: date,
        fetchedFromOffAt: date,
      );

      expect(p.freshnessWindow, equals(ProductFreshnessWindow.superFresh));
      expect(p.isSuperFresh, isTrue);
      expect(p.isInTolerance, isFalse);
      expect(p.isStale, isFalse);
    });

    test('Boundary: Product fetched exactly 7 days ago is superFresh', () {
      final date = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      final p = Product(
        barcode: 'fresh_7',
        nameMap: {'it': 'Crackers'},
        brandMap: {},
        ingredientsMap: {'it': 'Farina di mais'},
        allergensMap: {},
        lastUpdated: date,
        fetchedFromOffAt: date,
      );

      expect(p.freshnessWindow, equals(ProductFreshnessWindow.superFresh));
      expect(p.isSuperFresh, isTrue);
      expect(p.isInTolerance, isFalse);
      expect(p.isStale, isFalse);
    });

    test('Boundary: Product fetched 7 days and 23 hours ago is still superFresh (diff.inDays == 7)', () {
      final date = DateTime.now().subtract(const Duration(days: 7, hours: 23)).toIso8601String();
      final p = Product(
        barcode: 'fresh_7_23h',
        nameMap: {'it': 'Fette biscottate'},
        brandMap: {},
        ingredientsMap: {'it': 'Farina di riso'},
        allergensMap: {},
        lastUpdated: date,
        fetchedFromOffAt: date,
      );

      expect(p.freshnessWindow, equals(ProductFreshnessWindow.superFresh));
      expect(p.isSuperFresh, isTrue);
      expect(p.isInTolerance, isFalse);
      expect(p.isStale, isFalse);
    });
  });

  group('ProductFreshnessWindow – Level B: Zona di Tolleranza (8 - 30 days)', () {
    test('Boundary: Product fetched 8 days and 1 hour ago enters tolerance window', () {
      final date = DateTime.now().subtract(const Duration(days: 8, hours: 1)).toIso8601String();
      final p = Product(
        barcode: 'tol_8',
        nameMap: {'it': 'Cereali'},
        brandMap: {},
        ingredientsMap: {'it': 'Avena'},
        allergensMap: {},
        lastUpdated: date,
        fetchedFromOffAt: date,
      );

      expect(p.freshnessWindow, equals(ProductFreshnessWindow.tolerance));
      expect(p.isInTolerance, isTrue);
      expect(p.isSuperFresh, isFalse);
      expect(p.isStale, isFalse);
    });

    test('Product fetched 15 days ago is in tolerance window', () {
      final date = DateTime.now().subtract(const Duration(days: 15)).toIso8601String();
      final p = Product(
        barcode: 'tol_15',
        nameMap: {'it': 'Snack'},
        brandMap: {},
        ingredientsMap: {'it': 'Mais'},
        allergensMap: {},
        lastUpdated: date,
        fetchedFromOffAt: date,
      );

      expect(p.freshnessWindow, equals(ProductFreshnessWindow.tolerance));
      expect(p.isInTolerance, isTrue);
      expect(p.isSuperFresh, isFalse);
      expect(p.isStale, isFalse);
    });

    test('Boundary: Product fetched 29 days and 23 hours ago is still in tolerance window (diff.inDays == 29)', () {
      final date = DateTime.now().subtract(const Duration(days: 29, hours: 23)).toIso8601String();
      final p = Product(
        barcode: 'tol_29_23h',
        nameMap: {'it': 'Grissini'},
        brandMap: {},
        ingredientsMap: {'it': 'Farina di riso'},
        allergensMap: {},
        lastUpdated: date,
        fetchedFromOffAt: date,
      );

      expect(p.freshnessWindow, equals(ProductFreshnessWindow.tolerance));
      expect(p.isInTolerance, isTrue);
      expect(p.isSuperFresh, isFalse);
      expect(p.isStale, isFalse);
    });
  });

  group('ProductFreshnessWindow – Level C: Hard Stale (> 30 days or Incomplete)', () {
    test('Boundary: Product fetched 30 days and 1 hour ago is hardStale', () {
      final date = DateTime.now().subtract(const Duration(days: 30, hours: 1)).toIso8601String();
      final p = Product(
        barcode: 'stale_30',
        nameMap: {'it': 'Pasta Vecchia'},
        brandMap: {},
        ingredientsMap: {'it': 'Semola'},
        allergensMap: {},
        lastUpdated: date,
        fetchedFromOffAt: date,
      );

      expect(p.freshnessWindow, equals(ProductFreshnessWindow.hardStale));
      expect(p.isStale, isTrue);
      expect(p.isSuperFresh, isFalse);
      expect(p.isInTolerance, isFalse);
    });

    test('Product fetched 60 days ago is hardStale', () {
      final date = DateTime.now().subtract(const Duration(days: 60)).toIso8601String();
      final p = Product(
        barcode: 'stale_60',
        nameMap: {'it': 'Prodotto Molto Vecchio'},
        brandMap: {},
        ingredientsMap: {'it': 'Ingredienti'},
        allergensMap: {},
        lastUpdated: date,
        fetchedFromOffAt: date,
      );

      expect(p.freshnessWindow, equals(ProductFreshnessWindow.hardStale));
      expect(p.isStale, isTrue);
    });

    test('Incomplete product (empty ingredientsMap) is ALWAYS hardStale even if fetched just now', () {
      final p = Product(
        barcode: 'inc_empty',
        nameMap: {'it': 'Nome Solo'},
        brandMap: {},
        ingredientsMap: {}, // Incompleto!
        allergensMap: {},
        lastUpdated: DateTime.now().toIso8601String(),
        fetchedFromOffAt: DateTime.now().toIso8601String(),
      );

      expect(p.freshnessWindow, equals(ProductFreshnessWindow.hardStale));
      expect(p.isStale, isTrue);
      expect(p.isSuperFresh, isFalse);
    });

    test('Incomplete product (whitespace-only ingredients) is ALWAYS hardStale', () {
      final p = Product(
        barcode: 'inc_whitespace',
        nameMap: {'it': 'Nome Solo'},
        brandMap: {},
        ingredientsMap: {'it': '   \n\t  '},
        allergensMap: {},
        lastUpdated: DateTime.now().toIso8601String(),
        fetchedFromOffAt: DateTime.now().toIso8601String(),
      );

      expect(p.freshnessWindow, equals(ProductFreshnessWindow.hardStale));
      expect(p.isStale, isTrue);
    });

    test('Product with null or malformed fetchedFromOffAt is ALWAYS hardStale', () {
      final pNull = Product(
        barcode: 'null_date',
        nameMap: {'it': 'Test'},
        brandMap: {},
        ingredientsMap: {'it': 'Riso'},
        allergensMap: {},
        lastUpdated: '',
        fetchedFromOffAt: null,
      );
      expect(pNull.freshnessWindow, equals(ProductFreshnessWindow.hardStale));
      expect(pNull.isStale, isTrue);

      final pMalformed = Product(
        barcode: 'malformed_date',
        nameMap: {'it': 'Test'},
        brandMap: {},
        ingredientsMap: {'it': 'Riso'},
        allergensMap: {},
        lastUpdated: '',
        fetchedFromOffAt: 'invalid-iso-date',
      );
      expect(pMalformed.freshnessWindow, equals(ProductFreshnessWindow.hardStale));
      expect(pMalformed.isStale, isTrue);
    });

    test('Product with null fetchedFromOffAt falls back to lastUpdated for freshness calculation', () {
      final dateFresh = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
      final pFresh = Product(
        barcode: 'fallback_fresh',
        nameMap: {'it': 'Pasta'},
        brandMap: {},
        ingredientsMap: {'it': 'Semola'},
        allergensMap: {},
        lastUpdated: dateFresh,
        fetchedFromOffAt: null,
      );
      expect(pFresh.freshnessWindow, equals(ProductFreshnessWindow.superFresh));

      final dateStale = DateTime.now().subtract(const Duration(days: 45)).toIso8601String();
      final pStale = Product(
        barcode: 'fallback_stale',
        nameMap: {'it': 'Pasta'},
        brandMap: {},
        ingredientsMap: {'it': 'Semola'},
        allergensMap: {},
        lastUpdated: dateStale,
        fetchedFromOffAt: null,
      );
      expect(pStale.freshnessWindow, equals(ProductFreshnessWindow.hardStale));
      expect(pStale.isStale, isTrue);
    });
  });

  group('ProductFreshnessWindow – Ghost Product 24-Hour Aureola Rule', () {
    test('Ghost Product fetched 2 hours ago is superFresh (< 24h)', () {
      final date = DateTime.now().subtract(const Duration(hours: 2)).toIso8601String();
      final ghost = Product(
        barcode: 'ghost_2h',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: date,
        fetchedFromOffAt: date,
      );

      expect(ghost.isGhostProduct, isTrue);
      expect(ghost.freshnessWindow, equals(ProductFreshnessWindow.superFresh));
      expect(ghost.isSuperFresh, isTrue);
      expect(ghost.isStale, isFalse);
    });

    test('Ghost Product boundary: 23 hours 59 minutes is superFresh (< 24h)', () {
      final date = DateTime.now().subtract(const Duration(hours: 23, minutes: 59)).toIso8601String();
      final ghost = Product(
        barcode: 'ghost_23h59m',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: date,
        fetchedFromOffAt: date,
      );

      expect(ghost.isGhostProduct, isTrue);
      expect(ghost.freshnessWindow, equals(ProductFreshnessWindow.superFresh));
      expect(ghost.isSuperFresh, isTrue);
      expect(ghost.isStale, isFalse);
    });

    test('Ghost Product boundary: 24 hours 1 minute is hardStale (>= 24h triggers sync refresh)', () {
      final date = DateTime.now().subtract(const Duration(hours: 24, minutes: 1)).toIso8601String();
      final ghost = Product(
        barcode: 'ghost_24h1m',
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        lastUpdated: date,
        fetchedFromOffAt: date,
      );

      expect(ghost.isGhostProduct, isTrue);
      expect(ghost.freshnessWindow, equals(ProductFreshnessWindow.hardStale));
      expect(ghost.isStale, isTrue);
      expect(ghost.isSuperFresh, isFalse);
    });
  });
}

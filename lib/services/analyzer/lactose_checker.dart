// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'gluten_rules.dart';

class LactoseChecker {
  static const List<String> lactoseKeywords = [
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
    "milch",
    "molke",
    "melk",
    "leche",
    "laktose",
  ];

  static List<String> findLactoseIngredients(
    String ingredients,
    List<String> allergens,
  ) {
    String safeIngredients = ingredients.trim();
    if (safeIngredients.toLowerCase() == "non disponibile") {
      safeIngredients = "";
    }

    final String lowerIng = safeIngredients.toLowerCase();
    final String safeLactoseIng = GlutenRules.sanitizeForLactose(lowerIng);
    final List<String> found = [];

    final sortedKeywords = List<String>.from(lactoseKeywords)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (String l in sortedKeywords) {
      final isAgglutinative = GlutenRules.agglutinativeRoots.contains(l);
      final regex = isAgglutinative
          ? RegExp(RegExp.escape(l), caseSensitive: false)
          : RegExp(r'\b' + RegExp.escape(l) + r'\b', caseSensitive: false);
      if (regex.hasMatch(safeLactoseIng)) {
        if (!found.any((existing) => existing.contains(l))) {
          found.add(l);
        }
      }
    }

    for (String a in allergens) {
      final lowerA = a.toLowerCase();
      if (lowerA == "latte" ||
          lowerA.contains("milk") ||
          lowerA.contains("lait") ||
          lowerA.contains("milch") ||
          lowerA.contains("lattosio") ||
          lowerA.contains("laktose")) {
        final cleanAllergen = lowerA.replaceFirst(RegExp(r'^[a-z]{2}:'), '');
        if (!found.any((f) => f == cleanAllergen || f == 'latte' || f == 'lattosio')) {
          found.add(cleanAllergen.isNotEmpty ? cleanAllergen : 'latte');
        }
      }
    }

    found.sort((a, b) {
      final posA = lowerIng.indexOf(a);
      final posB = lowerIng.indexOf(b);
      if (posA != -1 && posB != -1) return posA.compareTo(posB);
      if (posA != -1) return -1;
      if (posB != -1) return 1;
      return 0;
    });

    return found;
  }

  static bool checkLactose(String ingredients, List<String> allergens) =>
      findLactoseIngredients(ingredients, allergens).isNotEmpty;
}

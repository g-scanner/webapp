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

  static bool checkLactose(String ingredients, List<String> allergens) {
    String safeIngredients = ingredients.trim();
    if (safeIngredients.toLowerCase() == "non disponibile") {
      safeIngredients = "";
    }

    final String lowerIng = safeIngredients.toLowerCase();
    final String safeLactoseIng = GlutenRules.sanitizeForLactose(lowerIng);
    for (String l in lactoseKeywords) {
      final isAgglutinative = GlutenRules.agglutinativeRoots.contains(l);
      final regex = isAgglutinative
          ? RegExp(RegExp.escape(l), caseSensitive: false)
          : RegExp(r'\b' + RegExp.escape(l) + r'\b', caseSensitive: false);
      if (regex.hasMatch(safeLactoseIng)) return true;
    }
    for (String a in allergens) {
      final lowerA = a.toLowerCase();
      if (lowerA == "latte" ||
          lowerA.contains("milk") ||
          lowerA.contains("lait") ||
          lowerA.contains("milch") ||
          lowerA.contains("lattosio") ||
          lowerA.contains("laktose")) {
        return true;
      }
    }
    return false;
  }
}

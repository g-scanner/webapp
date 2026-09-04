// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'gluten_rules.dart';

class AdditivesChecker {
  static List<String> findDoubtfulAdditives(String lowerIngredients) {
    final List<String> found = [];
    for (final d in GlutenRules.doubtfulAdditives) {
      final isAgglutinative = GlutenRules.agglutinativeRoots.contains(d);
      final regex = isAgglutinative
          ? RegExp(RegExp.escape(d), caseSensitive: false)
          : RegExp(r'\b' + RegExp.escape(d) + r'\b', caseSensitive: false);
      if (regex.hasMatch(lowerIngredients)) {
        found.add(d);
      }
    }
    return found;
  }
}

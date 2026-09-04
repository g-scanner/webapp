// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

class IngredientAnalyzed {
  final String ingredient;
  final String dangerLevel; // "safe" | "warning" | "danger"
  final String reason;

  IngredientAnalyzed({
    required this.ingredient,
    required this.dangerLevel,
    required this.reason,
  });

  factory IngredientAnalyzed.fromJson(Map<String, dynamic> json) {
    return IngredientAnalyzed(
      ingredient: json['ingredient'] ?? '',
      dangerLevel: json['dangerLevel'] ?? 'warning',
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredient': ingredient,
      'dangerLevel': dangerLevel,
      'reason': reason,
    };
  }
}

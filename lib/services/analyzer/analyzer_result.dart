// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import '../../models/models.dart';

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

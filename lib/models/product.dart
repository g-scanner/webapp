// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:easy_localization/easy_localization.dart';
import '../services/analyzer_service.dart';

class Product {
  final String barcode;
  final Map<String, String> nameMap;
  final Map<String, String> brandMap;
  final Map<String, String> ingredientsMap;
  final Map<String, List<String>> allergensMap;
  final String? imageUrl;
  final int pendingReportsCount;
  final String lastUpdated;
  final String? fetchedFromOffAt;

  Product({
    required this.barcode,
    required this.nameMap,
    required this.brandMap,
    required this.ingredientsMap,
    required this.allergensMap,
    this.imageUrl,
    this.pendingReportsCount = 0,
    required this.lastUpdated,
    this.fetchedFromOffAt,
  });

  // Helper getters per estrarre la lingua corrente con fallback intelligente
  String getName(String preferredLanguage) {
    if (nameMap.containsKey(preferredLanguage) &&
        nameMap[preferredLanguage]!.trim().isNotEmpty) {
      return nameMap[preferredLanguage]!;
    }
    for (final lang in ['it', 'en', 'es', 'fr', 'de']) {
      if (nameMap.containsKey(lang) && nameMap[lang]!.trim().isNotEmpty) {
        return nameMap[lang]!;
      }
    }
    final firstNonEmpty = nameMap.values.firstWhere(
      (v) => v.trim().isNotEmpty,
      orElse: () => '',
    );
    if (firstNonEmpty.isNotEmpty) return firstNonEmpty;
    return 'product.status.unknownProductName'.tr();
  }

  String getBrand(String preferredLanguage) {
    if (brandMap.containsKey(preferredLanguage) &&
        brandMap[preferredLanguage]!.trim().isNotEmpty &&
        brandMap[preferredLanguage] != '-') {
      return brandMap[preferredLanguage]!;
    }
    for (final lang in ['it', 'en', 'es', 'fr', 'de']) {
      if (brandMap.containsKey(lang) &&
          brandMap[lang]!.trim().isNotEmpty &&
          brandMap[lang] != '-') {
        return brandMap[lang]!;
      }
    }
    final firstNonEmpty = brandMap.values.firstWhere(
      (v) => v.trim().isNotEmpty && v != '-',
      orElse: () => '',
    );
    return firstNonEmpty;
  }

  String getIngredients(String preferredLanguage) {
    if (ingredientsMap.containsKey(preferredLanguage) &&
        ingredientsMap[preferredLanguage]!.trim().isNotEmpty) {
      return ingredientsMap[preferredLanguage]!;
    }
    for (final lang in ['it', 'en', 'es', 'fr', 'de']) {
      if (ingredientsMap.containsKey(lang) &&
          ingredientsMap[lang]!.trim().isNotEmpty) {
        return ingredientsMap[lang]!;
      }
    }
    return ingredientsMap.values.firstWhere(
      (v) => v.trim().isNotEmpty,
      orElse: () => '',
    );
  }

  List<String> getAllergens(String preferredLanguage) {
    if (allergensMap.containsKey(preferredLanguage) &&
        allergensMap[preferredLanguage]!.isNotEmpty) {
      return allergensMap[preferredLanguage]!;
    }
    for (final lang in ['it', 'en', 'es', 'fr', 'de']) {
      if (allergensMap.containsKey(lang) &&
          allergensMap[lang]!.isNotEmpty) {
        return allergensMap[lang]!;
      }
    }
    return allergensMap.values.firstWhere(
      (v) => v.isNotEmpty,
      orElse: () => const [],
    );
  }

  // Getters di retrocompatibilità
  String get name => getName('it');
  String get brand => getBrand('it');
  String get ingredients => getIngredients('it');
  List<String> get allergens => getAllergens('it');
  int get reportCount => pendingReportsCount;

  /// `true` se abbiamo dati certi sugli allergeni:
  /// - se ci sono allergeni dichiarati nella lista (> 0) escluse le diciture safe "Senza Glutine"
  /// - OPPURE se abbiamo la lista degli ingredienti da cui è stato accertato che non ci sono allergeni
  /// Se non abbiamo né ingredienti né allergeni dichiarati (es. prodotto incompleto su OFF), restituisce `false`.
  bool get hasAllergenData {
    if (allergensMap.isEmpty) return false;
    final bool hasAnyDeclaredAllergen = allergensMap.values.any(
      (list) => list.any(
        (a) =>
            a.trim().isNotEmpty && !AnalyzerService.isSafeGlutenClaim(a),
      ),
    );
    if (hasAnyDeclaredAllergen) return true;
    return hasIngredientData;
  }

  /// `true` se abbiamo dati sugli ingredienti (almeno un testo ingredienti non vuoto).
  /// `false` se la mappa è completamente assente o vuota (Ghost Product o prodotto incompleto).
  bool get hasIngredientData {
    if (ingredientsMap.isEmpty) return false;
    return ingredientsMap.values.any((ing) => ing.trim().isNotEmpty);
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Gestione nameMap
    Map<String, String> nMap = {};
    if (json['name_map'] != null) {
      nMap = Map<String, String>.from(json['name_map']);
    } else if (json['name'] != null) {
      final String singleName = json['name'].toString();
      nMap = {'it': singleName, 'en': singleName};
    }

    // Gestione brandMap
    Map<String, String> bMap = {};
    if (json['brand_map'] != null) {
      bMap = Map<String, String>.from(json['brand_map']);
    } else if (json['brand'] != null) {
      final String singleBrand = json['brand'].toString();
      bMap = {'it': singleBrand, 'en': singleBrand};
    }

    // Gestione ingredientsMap
    Map<String, String> iMap = {};
    if (json['ingredients_map'] != null) {
      iMap = Map<String, String>.from(json['ingredients_map']);
    } else if (json['ingredients'] != null) {
      final String singleIng = json['ingredients'].toString();
      iMap = {'it': singleIng, 'en': singleIng};
    }

    // Gestione allergensMap
    Map<String, List<String>> aMap = {};
    if (json['allergens_map'] != null) {
      aMap = (json['allergens_map'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, List<String>.from(v)),
      );
    } else if (json['allergens'] != null) {
      final List<String> singleAlg = List<String>.from(json['allergens']);
      aMap = {'it': singleAlg, 'en': singleAlg};
    }

    return Product(
      barcode: json['barcode'] ?? '',
      nameMap: nMap,
      brandMap: bMap,
      ingredientsMap: iMap,
      allergensMap: aMap,
      imageUrl: json['image_url'] ?? json['imageUrl'],
      pendingReportsCount:
          json['pending_reports_count'] ?? json['reportCount'] ?? 0,
      lastUpdated: json['last_updated'] ??
          json['lastUpdated'] ??
          DateTime.now().toIso8601String(),
      fetchedFromOffAt: json['fetched_from_off_at'] ?? json['fetchedFromOffAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name_map': nameMap,
      'brand_map': brandMap,
      'ingredients_map': ingredientsMap,
      'allergens_map': allergensMap,
      'image_url': imageUrl,
      'pending_reports_count': pendingReportsCount,
      'last_updated': lastUpdated,
      'fetched_from_off_at': fetchedFromOffAt,
    };
  }
}

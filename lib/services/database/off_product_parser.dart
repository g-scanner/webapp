// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import '../../models/models.dart';
import '../analyzer/analyzer.dart';

/// Servizio di parsing e sanitizzazione dedicato ai payload Open Food Facts.
/// Estrae nomi, marchi, ingredienti e allergeni multilingua con normalizzazione del testo.
class OffProductParser {
  static const List<String> supportedLangs = ['it', 'en', 'es', 'fr', 'de'];

  /// Esegue il parsing completo di una mappa prodotto OFF in un'istanza [Product].
  static Product parseProduct(
    String barcode,
    Map<String, dynamic> pData,
    UserSettings settings,
  ) {
    final Map<String, String> nameMap = {};
    final Map<String, String> brandMap = {};
    final Map<String, String> ingredientsMap = {};
    final Map<String, List<String>> allergensMap = {};

    // 1. Estrazione Multilingua NOMI
    for (final lang in supportedLangs) {
      final n = getFirstNonEmptyString(pData, [
        'product_name_$lang',
        'product_name',
      ], '');
      if (n.isNotEmpty) nameMap[lang] = n;
    }

    // 2. Estrazione Multilingua BRANDS (solo se presente su OFF)
    final brandStr = getFirstNonEmptyString(pData, [
      'brands',
      'brand_tags',
    ], '');
    if (brandStr.isNotEmpty && brandStr != '-') {
      for (final lang in supportedLangs) {
        brandMap[lang] = brandStr;
      }
    }

    // 3. Estrazione Multilingua INGREDIENTI
    for (final lang in supportedLangs) {
      final String ing = getFirstNonEmptyString(pData, [
        'ingredients_text_$lang',
      ], '');
      if (ing.isNotEmpty) {
        ingredientsMap[lang] = cleanIngredientsText(ing);
      }
    }

    // 4. Fallback Lingua Estremo: se mancano IT, EN, ES, FR, DE, cerca la prima disponibile
    if (ingredientsMap.isEmpty) {
      String fallbackIng = '';
      for (final key in pData.keys) {
        if (key.startsWith('ingredients_text_') &&
            key != 'ingredients_text_with_allergens') {
          final val = pData[key];
          if (val is String && val.trim().isNotEmpty) {
            fallbackIng = cleanIngredientsText(val.trim());
            break;
          }
        }
      }
      if (fallbackIng.isNotEmpty) {
        ingredientsMap['en'] = fallbackIng;
      }
    }

    // 5. Se nameMap è vuoto, cerca prima qualunque chiave di nome su OFF
    if (nameMap.isEmpty) {
      String fallbackName = '';
      for (final key in pData.keys) {
        if (key.startsWith('product_name')) {
          final val = pData[key];
          if (val is String && val.trim().isNotEmpty) {
            fallbackName = val.trim();
            break;
          }
        }
      }
      if (fallbackName.isNotEmpty) {
        nameMap['en'] = fallbackName;
      }
    }

    // 6. Estrazione Allergeni con rilevamento accurato dei dati mancanti:
    List<String>? rawAllergens;
    if (pData['allergens_tags'] != null &&
        (pData['allergens_tags'] as List).isNotEmpty) {
      rawAllergens = List<String>.from(pData['allergens_tags']);
    } else if (pData['allergens_from_ingredients'] != null &&
        pData['allergens_from_ingredients'].toString().trim().isNotEmpty) {
      rawAllergens = pData['allergens_from_ingredients']
          .toString()
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (pData['allergens'] != null &&
        pData['allergens'].toString().trim().isNotEmpty) {
      rawAllergens = pData['allergens']
          .toString()
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (ingredientsMap.isNotEmpty) {
      rawAllergens = [];
    } else if (pData['allergens_tags'] is List &&
        (pData['allergens_tags'] as List).isEmpty) {
      rawAllergens = [];
    }

    if (rawAllergens != null) {
      for (final lang in supportedLangs) {
        allergensMap[lang] = AllergenCanonicalizer.translateAllergens(
          rawAllergens,
          lang,
        );
      }

      final safeClaims = rawAllergens
          .where(AllergenCanonicalizer.isSafeGlutenClaim)
          .toList();
      if (safeClaims.isNotEmpty) {
        for (final lang in supportedLangs) {
          final currentIng = ingredientsMap[lang] ?? '';
          if (!AllergenCanonicalizer.isSafeGlutenClaim(currentIng)) {
            ingredientsMap[lang] = currentIng.isEmpty
                ? 'Senza glutine'
                : '$currentIng (Senza glutine)';
          }
        }
      }
    }

    final imageUrl = pData['image_url'] ??
        pData['image_front_url'] ??
        pData['image_thumb_url'] ??
        "";

    final nowIso = DateTime.now().toIso8601String();

    return Product(
      barcode: barcode,
      nameMap: nameMap,
      brandMap: brandMap,
      ingredientsMap: ingredientsMap,
      allergensMap: allergensMap,
      imageUrl: imageUrl,
      pendingReportsCount: 0,
      lastUpdated: nowIso,
      fetchedFromOffAt: nowIso,
    );
  }

  /// Pulisce il testo degli ingredienti rimuovendo formattazione markdown, tag interni e parentesi duplicate.
  static String cleanIngredientsText(String text) {
    if (text.trim().isEmpty) return text;
    return text
        .replaceAllMapped(RegExp(r'_([^_]+)_'), (m) => m[1]!)
        .replaceAll('_', '')
        .replaceAllMapped(RegExp(r'\{[a-z]{2}:([^}]+)\}'), (m) => m[1]!)
        .replaceAll(RegExp(r'\{[^}]*\}'), '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll('\$', '')
        .replaceAllMapped(RegExp(r'\(([^()]+)\(([^()]+)\)\)'), (m) {
          return '(${m[1]!.trim()}, ${m[2]!.trim()})';
        })
        .replaceAllMapped(RegExp(r'\(\s*([^()]+)\s*\(\s*([^()]+)\s*\)\s*\)'), (m) {
          return '(${m[1]!.trim()}, ${m[2]!.trim()})';
        })
        .replaceAll(RegExp(r'\(\s+'), '(')
        .replaceAll(RegExp(r'\s+\)'), ')')
        .replaceAll(RegExp(r'\([^a-zA-Z0-9À-ÿ]*\)'), '')
        .replaceAll('))', ')')
        .replaceAllMapped(RegExp(r'\s+([,.;])'), (m) => m[1]!)
        .replaceAll(RegExp(r'  +'), ' ')
        .trim();
  }

  /// Restituisce la prima stringa non vuota tra le chiavi specificate in [keys].
  static String getFirstNonEmptyString(
    Map<String, dynamic> data,
    List<String> keys,
    String defaultValue,
  ) {
    for (final key in keys) {
      final val = data[key];
      if (val == null) continue;
      if (val is List && val.isNotEmpty) {
        final firstVal = val[0].toString().trim();
        if (firstVal.isNotEmpty) return firstVal;
      } else if (val is String && val.trim().isNotEmpty) {
        return val.trim();
      } else if (val is! List && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return defaultValue;
  }
}

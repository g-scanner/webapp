// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner -- See LICENSE file in root for terms.

import '../../models/models.dart';

/// Utility pulita per il calcolo dell'impronta digitale (content hash) dei dati critici di un prodotto.
///
/// Utilizzata per confrontare i dati ricevuti da Open Food Facts con quelli gia presenti
/// in cache/Firestore: se il content hash non e variato, si evitano inutili scritture su Firebase.
class ProductContentHasher {
  /// Calcola una stringa hash a 64-bit FNV-1a (veloce, deterministica, a zero dipendenze esterne)
  /// basata sui dati che impattano la sicurezza alimentare e la presentazione:
  /// - Mappa degli ingredienti in tutte le lingue
  /// - Mappa degli allergeni in tutte le lingue
  /// - Nomi e marche
  static String computeContentHash(Product product) {
    final buffer = StringBuffer();

    // Normalizzazione deterministica delle chiavi per ordinamento alfabetico
    final sortedIngLangs = product.ingredientsMap.keys.toList()..sort();
    for (final lang in sortedIngLangs) {
      buffer.write('ing:$lang=${product.ingredientsMap[lang]?.trim()};');
    }

    final sortedAllergenLangs = product.allergensMap.keys.toList()..sort();
    for (final lang in sortedAllergenLangs) {
      final list = List<String>.from(product.allergensMap[lang] ?? [])..sort();
      buffer.write('alg:$lang=${list.join(',')};');
    }

    final sortedNameLangs = product.nameMap.keys.toList()..sort();
    for (final lang in sortedNameLangs) {
      buffer.write('name:$lang=${product.nameMap[lang]?.trim()};');
    }

    final sortedBrandLangs = product.brandMap.keys.toList()..sort();
    for (final lang in sortedBrandLangs) {
      buffer.write('brand:$lang=${product.brandMap[lang]?.trim()};');
    }

    return _fnv1a64(buffer.toString());
  }

  /// Verifica se due prodotti presentano differenze sostanziali nel loro contenuto alimentare.
  static bool hasContentChanged(Product current, Product updated) {
    return computeContentHash(current) != computeContentHash(updated);
  }

  /// Algoritmo di hashing FNV-1a a 64 bit (non crittografico, deterministico, ultra rapido).
  static String _fnv1a64(String input) {
    final BigInt fnvPrime = BigInt.from(0x100000001b3);
    final BigInt fnvOffsetBasis = BigInt.parse('0xcbf29ce484222325');
    final BigInt mask64 = (BigInt.one << 64) - BigInt.one;

    BigInt hash = fnvOffsetBasis;
    final codeUnits = input.codeUnits;

    for (final byte in codeUnits) {
      hash = (hash ^ BigInt.from(byte)) & mask64;
      hash = (hash * fnvPrime) & mask64;
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }
}
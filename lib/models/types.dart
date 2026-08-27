import 'package:flutter/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/analyzer_service.dart';

enum GlutenSafetyStatus { adatto, nonAdatto, incerto, sconosciuto }

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
    if (nameMap.containsKey(preferredLanguage) && nameMap[preferredLanguage]!.trim().isNotEmpty) {
      return nameMap[preferredLanguage]!;
    }
    for (final lang in ['it', 'en', 'es', 'fr', 'de']) {
      if (nameMap.containsKey(lang) && nameMap[lang]!.trim().isNotEmpty) {
        return nameMap[lang]!;
      }
    }
    final firstNonEmpty = nameMap.values.firstWhere((v) => v.trim().isNotEmpty, orElse: () => '');
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
    if (ingredientsMap.containsKey(preferredLanguage) && ingredientsMap[preferredLanguage]!.trim().isNotEmpty) {
      return ingredientsMap[preferredLanguage]!;
    }
    for (final lang in ['it', 'en', 'es', 'fr', 'de']) {
      if (ingredientsMap.containsKey(lang) && ingredientsMap[lang]!.trim().isNotEmpty) {
        return ingredientsMap[lang]!;
      }
    }
    return ingredientsMap.values.firstWhere((v) => v.trim().isNotEmpty, orElse: () => '');
  }

  List<String> getAllergens(String preferredLanguage) {
    if (allergensMap.containsKey(preferredLanguage) && allergensMap[preferredLanguage]!.isNotEmpty) {
      return allergensMap[preferredLanguage]!;
    }
    for (final lang in ['it', 'en', 'es', 'fr', 'de']) {
      if (allergensMap.containsKey(lang) && allergensMap[lang]!.isNotEmpty) {
        return allergensMap[lang]!;
      }
    }
    return allergensMap.values.firstWhere((v) => v.isNotEmpty, orElse: () => const []);
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
      (list) => list.any((a) => a.trim().isNotEmpty && !AnalyzerService.isSafeGlutenClaim(a)),
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
      pendingReportsCount: json['pending_reports_count'] ?? json['reportCount'] ?? 0,
      lastUpdated: json['last_updated'] ?? json['lastUpdated'] ?? DateTime.now().toIso8601String(),
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

class ScanHistoryItem {
  final String id;
  final String barcode;
  final String scannedAt;

  ScanHistoryItem({
    required this.id,
    required this.barcode,
    required this.scannedAt,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      id: json['id'] ?? '',
      barcode: json['barcode'] ?? '',
      scannedAt: json['scannedAt'] ?? json['scanned_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'scannedAt': scannedAt,
    };
  }
}

class ProductReport {
  final String id;
  final String? userId;
  final String barcode;
  final String productName;
  final String brand;
  final String type;
  final String comments;
  final String submittedAt;
  final String status;
  final int score;

  ProductReport({
    required this.id,
    this.userId,
    required this.barcode,
    required this.productName,
    required this.brand,
    required this.type,
    required this.comments,
    required this.submittedAt,
    required this.status,
    this.score = 0,
  });

  factory ProductReport.fromJson(Map<String, dynamic> json) {
    return ProductReport(
      id: json['id'] ?? '',
      userId: json['userId'],
      barcode: json['barcode'] ?? '',
      productName: json['productName'] ?? '',
      brand: json['brand'] ?? '',
      type: json['type'] ?? 'label_unclear',
      comments: json['comments'] ?? '',
      submittedAt: json['submittedAt'] ?? DateTime.now().toIso8601String(),
      status: json['status'] ?? 'open',
      score: json['score'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'barcode': barcode,
      'productName': productName,
      'brand': brand,
      'type': type,
      'comments': comments,
      'submittedAt': submittedAt,
      'status': status,
      'score': score,
    };
  }
}

class UserSettings {
  final String? userId;
  final bool strictMode;
  final bool alertLactose;
  final bool warnAdditives;
  final bool autoSaveHistory;
  final String preferredLanguage;
  final String preferredTheme;
  final List<String> reportedBarcodes;

  static String get defaultSystemLanguage {
    try {
      const supportedLangs = ['it'];
      final sys = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      return supportedLangs.contains(sys) ? sys : 'it';
    } catch (_) {
      return 'it';
    }
  }

  UserSettings({
    this.userId,
    required this.strictMode,
    required this.alertLactose,
    required this.warnAdditives,
    required this.autoSaveHistory,
    required this.preferredLanguage,
    this.preferredTheme = 'system',
    this.reportedBarcodes = const [],
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['userId'],
      strictMode: json['strictMode'] ?? true,
      alertLactose: json['alertLactose'] ?? false,
      warnAdditives: json['warnAdditives'] ?? true,
      autoSaveHistory: json['autoSaveHistory'] ?? true,
      preferredLanguage: json['preferredLanguage'] ?? defaultSystemLanguage,
      preferredTheme: json['preferredTheme'] ?? 'system',
      reportedBarcodes: List<String>.from(json['reportedBarcodes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'strictMode': strictMode,
      'alertLactose': alertLactose,
      'warnAdditives': warnAdditives,
      'autoSaveHistory': autoSaveHistory,
      'preferredLanguage': preferredLanguage,
      'preferredTheme': preferredTheme,
      'reportedBarcodes': reportedBarcodes,
    };
  }
}

String formatRelativeDate(String isoDate) {
  try {
    final parsed = DateTime.parse(isoDate).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(parsed.year, parsed.month, parsed.day);

    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');

    if (targetDate == today) {
      return "${'common.time.today'.tr()}, $hour:$minute";
    } else if (targetDate == yesterday) {
      return "${'common.time.yesterday'.tr()}, $hour:$minute";
    } else {
      const months = [
        'Gen',
        'Feb',
        'Mar',
        'Apr',
        'Mag',
        'Giu',
        'Lug',
        'Ago',
        'Set',
        'Ott',
        'Nov',
        'Dic',
      ];
      return "${parsed.day} ${months[parsed.month - 1]} ${parsed.year}, $hour:$minute";
    }
  } catch (e) {
    return "";
  }
}

String formatScanDate(String isoDate) {
  try {
    final parsed = DateTime.parse(isoDate).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(parsed.year, parsed.month, parsed.day);

    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    final timeStr = "$hour:$minute";

    if (targetDate == today) {
      return "product.scanDate.today".tr(namedArgs: {"time": timeStr});
    } else if (targetDate == yesterday) {
      return "product.scanDate.yesterday".tr(namedArgs: {"time": timeStr});
    } else {
      const months = [
        'Gen',
        'Feb',
        'Mar',
        'Apr',
        'Mag',
        'Giu',
        'Lug',
        'Ago',
        'Set',
        'Ott',
        'Nov',
        'Dic',
      ];
      final dateStr = "${parsed.day} ${months[parsed.month - 1]} ${parsed.year}";
      return "product.scanDate.default".tr(namedArgs: {"date": dateStr, "time": timeStr});
    }
  } catch (e) {
    return isoDate;
  }
}

String formatReportDate(String isoDate) {
  try {
    final parsed = DateTime.parse(isoDate).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(parsed.year, parsed.month, parsed.day);

    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    final timeStr = "$hour:$minute";

    if (targetDate == today) {
      return "report.ui.reportDate.today".tr(namedArgs: {"time": timeStr});
    } else if (targetDate == yesterday) {
      return "report.ui.reportDate.yesterday".tr(namedArgs: {"time": timeStr});
    } else {
      const months = [
        'Gen',
        'Feb',
        'Mar',
        'Apr',
        'Mag',
        'Giu',
        'Lug',
        'Ago',
        'Set',
        'Ott',
        'Nov',
        'Dic',
      ];
      final dateStr = "${parsed.day} ${months[parsed.month - 1]} ${parsed.year}";
      return "report.ui.reportDate.default".tr(namedArgs: {"date": dateStr, "time": timeStr});
    }
  } catch (e) {
    return isoDate;
  }
}

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
  final String name;
  final String brand;
  final String ingredients;
  final List<String> allergens;
  final GlutenSafetyStatus status;
  final String reason;
  final List<IngredientAnalyzed>? ingredientsAnalyzed;
  final String? imageUrl;
  final bool? isManual;
  final String lastUpdated;
  final int? reportCount;
  final GlutenSafetyStatus? originalStatus;
  final Map<String, String>? ingredientsMap;
  final Map<String, List<String>>? allergensMap;
  final Map<String, String>? reasonsMap;
  final Map<String, List<IngredientAnalyzed>>? ingredientsAnalyzedMap;

  Product({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.ingredients,
    required this.allergens,
    required this.status,
    required this.reason,
    this.ingredientsAnalyzed,
    this.imageUrl,
    this.isManual,
    required this.lastUpdated,
    this.reportCount,
    this.originalStatus,
    this.ingredientsMap,
    this.allergensMap,
    this.reasonsMap,
    this.ingredientsAnalyzedMap,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      barcode: json['barcode'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      ingredients: json['ingredients'] ?? '',
      allergens: List<String>.from(json['allergens'] ?? []),
      status: GlutenSafetyStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GlutenSafetyStatus.sconosciuto,
      ),
      reason: json['reason'] ?? '',
      ingredientsAnalyzed: (json['ingredients_analyzed'] as List?)
          ?.map((e) => IngredientAnalyzed.fromJson(e))
          .toList(),
      imageUrl: json['image_url'],
      isManual: json['isManual'],
      lastUpdated: json['lastUpdated'] ?? DateTime.now().toIso8601String(),
      reportCount: json['reportCount'],
      originalStatus: json['originalStatus'] != null
          ? GlutenSafetyStatus.values.firstWhere(
              (e) => e.name == json['originalStatus'],
              orElse: () => GlutenSafetyStatus.sconosciuto,
            )
          : null,
      ingredientsMap: json['ingredients_map'] != null
          ? Map<String, String>.from(json['ingredients_map'])
          : null,
      allergensMap: json['allergens_map'] != null
          ? (json['allergens_map'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<String>.from(v)),
            )
          : null,
      reasonsMap: json['reasons_map'] != null
          ? Map<String, String>.from(json['reasons_map'])
          : null,
      ingredientsAnalyzedMap: json['ingredients_analyzed_map'] != null
          ? (json['ingredients_analyzed_map'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(
                k,
                (v as List)
                    .map((e) => IngredientAnalyzed.fromJson(e))
                    .toList(),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'ingredients': ingredients,
      'allergens': allergens,
      'status': status.name,
      'reason': reason,
      'ingredients_analyzed': ingredientsAnalyzed
          ?.map((e) => e.toJson())
          .toList(),
      'image_url': imageUrl,
      'isManual': isManual,
      'lastUpdated': lastUpdated,
      'reportCount': reportCount,
      'originalStatus': originalStatus?.name,
      'ingredients_map': ingredientsMap,
      'allergens_map': allergensMap,
      'reasons_map': reasonsMap,
      'ingredients_analyzed_map': ingredientsAnalyzedMap?.map(
        (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
      ),
    };
  }
}

class ScanHistoryItem {
  final String id;
  final String? userId;
  final String barcode;
  final String productName;
  final String brand;
  final GlutenSafetyStatus status;
  final String scannedAt;
  final bool hasLactose;

  ScanHistoryItem({
    required this.id,
    this.userId,
    required this.barcode,
    required this.productName,
    required this.brand,
    required this.status,
    required this.scannedAt,
    this.hasLactose = false,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      id: json['id'] ?? '',
      userId: json['userId'],
      barcode: json['barcode'] ?? '',
      productName: json['productName'] ?? '',
      brand: json['brand'] ?? '',
      status: GlutenSafetyStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GlutenSafetyStatus.sconosciuto,
      ),
      scannedAt: json['scannedAt'] ?? DateTime.now().toIso8601String(),
      hasLactose: json['hasLactose'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'barcode': barcode,
      'productName': productName,
      'brand': brand,
      'status': status.name,
      'scannedAt': scannedAt,
      'hasLactose': hasLactose,
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
  final GlutenSafetyStatus?
  originalStatus; // Lo stato del prodotto al momento della segnalazione
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
    this.originalStatus,
    this.score = 0,
  });

  factory ProductReport.fromJson(Map<String, dynamic> json) {
    return ProductReport(
      id: json['id'] ?? '',
      userId: json['userId'],
      barcode: json['barcode'] ?? '',
      productName: json['productName'] ?? '',
      brand: json['brand'] ?? '',
      type: json['type'] ?? 'other',
      comments: json['comments'] ?? '',
      submittedAt: json['submittedAt'] ?? DateTime.now().toIso8601String(),
      status: json['status'] ?? 'open',
      originalStatus: json['originalStatus'] != null
          ? GlutenSafetyStatus.values.firstWhere(
              (e) => e.name == json['originalStatus'],
              orElse: () => GlutenSafetyStatus.sconosciuto,
            )
          : null,
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
      'originalStatus': originalStatus?.name,
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
  final List<String> reportedBarcodes;

  UserSettings({
    this.userId,
    required this.strictMode,
    required this.alertLactose,
    required this.warnAdditives,
    required this.autoSaveHistory,
    required this.preferredLanguage,
    this.reportedBarcodes = const [],
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['userId'],
      strictMode: json['strictMode'] ?? true,
      alertLactose: json['alertLactose'] ?? false,
      warnAdditives: json['warnAdditives'] ?? true,
      autoSaveHistory: json['autoSaveHistory'] ?? true,
      preferredLanguage: json['preferredLanguage'] ?? 'it',
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
      return "Oggi, $hour:$minute";
    } else if (targetDate == yesterday) {
      return "Ieri, $hour:$minute";
    } else {
      const months = [
        'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
        'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
      ];
      return "${parsed.day} ${months[parsed.month - 1]} ${parsed.year}, $hour:$minute";
    }
  } catch (e) {
    return "";
  }
}

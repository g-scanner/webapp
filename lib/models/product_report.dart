// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

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

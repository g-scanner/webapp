// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

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
      scannedAt: json['scannedAt'] ??
          json['scanned_at'] ??
          DateTime.now().toIso8601String(),
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

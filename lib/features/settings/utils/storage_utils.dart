// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/foundation.dart';
import '../../../services/database/local_cache_service.dart';
import '../../../services/database/daos/scan_history_dao.dart';

/// Rappresenta le metriche di storage (cronologia e cache prodotti) su disco.
class StorageMetrics {
  final int historyCount;
  final int historySizeBytes;
  final int cacheCount;
  final int cacheSizeBytes;

  const StorageMetrics({
    this.historyCount = 0,
    this.historySizeBytes = 0,
    this.cacheCount = 0,
    this.cacheSizeBytes = 0,
  });

  int get totalBytes => historySizeBytes + cacheSizeBytes;
}

/// Recupera in modo leggero e asincrono le metriche di storage attuali da SQLite.
Future<StorageMetrics> fetchStorageMetrics(String? userId) async {
  try {
    final cCount = await LocalCacheService.getProductsCount();
    final cSize = await LocalCacheService.getProductsSizeBytes();
    final hCount = await const ScanHistoryDao().getHistoryCount(userId);
    final hSize = await const ScanHistoryDao().getHistorySizeBytes(userId);
    return StorageMetrics(
      historyCount: hCount,
      historySizeBytes: hSize,
      cacheCount: cCount,
      cacheSizeBytes: cSize,
    );
  } catch (e) {
    debugPrint("Error loading storage metrics: $e");
    return const StorageMetrics();
  }
}

/// Converte una dimensione in byte in una stringa leggibile (B, KB, MB, GB).
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const kb = 1024;
  const mb = 1024 * 1024;
  const gb = 1024 * 1024 * 1024;

  if (bytes < kb) {
    return '$bytes B';
  } else if (bytes < mb) {
    final value = bytes / kb;
    return '${value >= 10 ? value.toStringAsFixed(0) : value.toStringAsFixed(1).replaceAll('.0', '')} KB';
  } else if (bytes < gb) {
    final value = bytes / mb;
    return '${value >= 10 ? value.toStringAsFixed(0) : value.toStringAsFixed(1).replaceAll('.0', '')} MB';
  } else {
    final value = bytes / gb;
    return '${value.toStringAsFixed(1).replaceAll('.0', '')} GB';
  }
}

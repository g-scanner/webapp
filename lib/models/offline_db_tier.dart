// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

/// Livello di database SQLite scaricabile per la consultazione offline.
enum OfflineDbTier {
  none,
  tier1, // Ultra-Light: Solo Celiachia (~20 MB)
  tier2, // Standard: Celiachia + Cibi mercato (~90 MB)
  tier3, // Completo: Full Catalog OFF (~350 MB)
}

extension OfflineDbTierExtension on OfflineDbTier {
  String get key {
    switch (this) {
      case OfflineDbTier.none:
        return 'none';
      case OfflineDbTier.tier1:
        return 'tier1';
      case OfflineDbTier.tier2:
        return 'tier2';
      case OfflineDbTier.tier3:
        return 'tier3';
    }
  }

  static OfflineDbTier fromKey(String? key) {
    switch (key) {
      case 'tier1':
        return OfflineDbTier.tier1;
      case 'tier2':
        return OfflineDbTier.tier2;
      case 'tier3':
        return OfflineDbTier.tier3;
      case 'none':
      default:
        return OfflineDbTier.none;
    }
  }
}

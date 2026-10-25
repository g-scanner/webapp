// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:easy_localization/easy_localization.dart';

/// Pacchetto di database SQLite scaricabile per la consultazione offline.
enum OfflineDbTier {
  none,
  glutenFree,  // Tutti i prodotti Gluten-Free del MONDO (~10-15 MB)
  euroCore,    // gluten_free + Consumi quotidiani IT, FR, DE, ES, UK (~60-70 MB)
  americaCore, // gluten_free + Consumi quotidiani USA, CA, MX, AR, BR (~50-60 MB)
  globalTop,   // gluten_free + Top 800.000 prodotti più scansionati al mondo (~120-140 MB)
}

extension OfflineDbTierExtension on OfflineDbTier {
  String get key {
    switch (this) {
      case OfflineDbTier.none:
        return 'none';
      case OfflineDbTier.glutenFree:
        return 'gluten_free';
      case OfflineDbTier.euroCore:
        return 'euro_core';
      case OfflineDbTier.americaCore:
        return 'america_core';
      case OfflineDbTier.globalTop:
        return 'global_top';
    }
  }

  String get label {
    switch (this) {
      case OfflineDbTier.none:
        return 'settings.offlineDb.disabledStatus'.tr();
      case OfflineDbTier.glutenFree:
        return 'settings.offlineDb.packages.gluten_free.title'.tr();
      case OfflineDbTier.euroCore:
        return 'settings.offlineDb.packages.euro_core.title'.tr();
      case OfflineDbTier.americaCore:
        return 'settings.offlineDb.packages.america_core.title'.tr();
      case OfflineDbTier.globalTop:
        return 'settings.offlineDb.packages.global_top.title'.tr();
    }
  }

  static OfflineDbTier fromKey(String? key) {
    switch (key) {
      case 'gluten_free':
        return OfflineDbTier.glutenFree;
      case 'euro_core':
        return OfflineDbTier.euroCore;
      case 'america_core':
        return OfflineDbTier.americaCore;
      case 'global_top':
        return OfflineDbTier.globalTop;
      case 'none':
      default:
        return OfflineDbTier.none;
    }
  }
}

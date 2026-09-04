// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

class AppConstants {
  // ─── Local Storage Keys ──────────────────────────────────────────────────
  static const String productsKey = 'celiac_products_cache';
  static const String lastSyncKey = 'celiac_app_last_sync_time';
  static const String historyKey = 'celiac_history';
  static const String reportsKey = 'celiac_reports';
  static const String reportedBarcodesKey = 'celiac_reported_barcodes';
  static const String settingsKey = 'celiac_settings';
  static const String termsAcceptedKey = 'celiac_terms_accepted_v1';

  // ─── Firestore Collections ───────────────────────────────────────────────
  static const String productsCollection = 'products';
  static const String reportsCollection = 'reports';
  static const String usersCollection = 'users';

  // ─── Routing & Limits ────────────────────────────────────────────────────
  static const double wideScreenThreshold = 960.0;
  static const double maxCardWidth = 500.0;
  static const double maxCardHeight = 900.0;
  static const int defaultPageSize = 20;
}

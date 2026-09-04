// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/models.dart';
import 'local_cache_service.dart';
import 'history_db_service.dart';
import 'reports_db_service.dart';
import 'settings_db_service.dart';
import 'off_ingestion_service.dart';
import 'account_data_service.dart';

class DbService {
  static FirebaseFirestore db = FirebaseFirestore.instance;
  static FirebaseAuth auth = FirebaseAuth.instance;

  // ─── LOCAL PRODUCT CACHE & DELTA SYNC ──────────────────────────────────────

  static Future<List<Product>> getLocalProducts() =>
      LocalCacheService.getLocalProducts();

  static Future<Product?> getLocalProductByBarcode(String barcode) =>
      LocalCacheService.getLocalProductByBarcode(barcode);

  static Future<void> saveLocalProducts(List<Product> products) =>
      LocalCacheService.saveLocalProducts(products);

  static Future<void> upsertLocalProduct(Product product) =>
      LocalCacheService.upsertLocalProduct(product);

  static Future<String?> getLastSyncTime() =>
      LocalCacheService.getLastSyncTime();

  static Future<void> saveLastSyncTime(String timeIso) =>
      LocalCacheService.saveLastSyncTime(timeIso);

  static Future<List<Product>> performDeltaSync() =>
      LocalCacheService.performDeltaSync(db);

  static Future<Product?> getProductByBarcode(String barcode) =>
      LocalCacheService.getProductByBarcode(db, barcode);

  // ─── PIPELINE DI SCANSIONE ────────────────────────────────────────────────

  static Future<Product> scanBarcodeClientSide(
    String barcode,
    UserSettings settings,
  ) =>
      OffIngestionService.scanBarcodeClientSide(
        db: db,
        auth: auth,
        barcode: barcode,
        settings: settings,
      );

  // ─── CRONOLOGIA SCANSIONI ──────────────────────────────────────────────────

  static Future<List<ScanHistoryItem>> getHistory() =>
      HistoryDbService.getHistory(auth);

  static Future<List<ScanHistoryItem>> getHistoryPaged({
    int offset = 0,
    int limit = 20,
  }) =>
      HistoryDbService.getHistoryPaged(auth, offset: offset, limit: limit);

  static Future<List<ScanHistoryItem>> syncHistoryWithFirestore() =>
      HistoryDbService.syncHistoryWithFirestore(db, auth);

  static Future<void> wipeHistoryLocal() =>
      HistoryDbService.wipeHistoryLocal(db, auth);

  static Future<void> deleteHistoryByBarcodeLocal(String barcode) =>
      HistoryDbService.deleteHistoryByBarcodeLocal(db, auth, barcode);

  static Future<void> deleteHistoryItemLocal(String id) =>
      HistoryDbService.deleteHistoryItemLocal(db, auth, id);

  // ─── GESTIONE DELLE SEGNALAZIONI ──────────────────────────────────────────

  static Future<List<ProductReport>> fetchUserReports() =>
      ReportsDbService.fetchUserReports(auth);

  static Future<List<ProductReport>> syncReportsWithFirestore() =>
      ReportsDbService.syncReportsWithFirestore(db, auth);

  static Future<ProductReport> submitProductReportClientSide(
    String barcode,
    String productName,
    String brand,
    Map<String, dynamic> reportData,
  ) =>
      ReportsDbService.submitProductReportClientSide(
        db,
        auth,
        barcode,
        productName,
        brand,
        reportData,
      );

  static Future<void> deleteReportFromDb(String reportId) =>
      ReportsDbService.deleteReportFromDb(db, auth, reportId);

  static Future<void> deleteLocalReport(String reportId) =>
      ReportsDbService.deleteLocalReport(auth, reportId);

  static Future<void> voteOnReportByBarcode(String barcode, int newVote) =>
      ReportsDbService.voteOnReportByBarcode(db, auth, barcode, newVote);

  static Future<Map<String, int>> getReportVoteDataByBarcode(String barcode) =>
      ReportsDbService.getReportVoteDataByBarcode(db, auth, barcode);

  // ─── IMPOSTAZIONI UTENTE ───────────────────────────────────────────────────

  static Future<UserSettings> getLocalSettings() =>
      SettingsDbService.getLocalSettings();

  static Future<void> saveLocalSettings(UserSettings settings) =>
      SettingsDbService.saveLocalSettings(settings);

  static Future<void> saveSettings(UserSettings settings) =>
      SettingsDbService.saveSettings(db, auth, settings);

  static Future<UserSettings> syncSettingsWithFirestore(
    UserSettings localSettings,
  ) =>
      SettingsDbService.syncSettingsWithFirestore(db, auth, localSettings);

  static Future<bool> hasAcceptedTerms() =>
      SettingsDbService.hasAcceptedTerms();

  static Future<void> saveTermsAccepted() =>
      SettingsDbService.saveTermsAccepted();

  // ─── MIGRAZIONE E WIPE ─────────────────────────────────────────────────────

  static Future<List<ScanHistoryItem>> getLocalUnsyncedHistory() =>
      AccountDataService.getLocalUnsyncedHistory();

  static Future<List<ProductReport>> getLocalUnsyncedReports() =>
      AccountDataService.getLocalUnsyncedReports();

  static Future<void> migrateLocalDataToFirestore(String newUid) =>
      AccountDataService.migrateLocalDataToFirestore(db, newUid);

  static Future<void> wipeAllLocalData() =>
      AccountDataService.wipeAllLocalData(auth);

  static Future<void> wipeCurrentUserLocalData() =>
      AccountDataService.wipeCurrentUserLocalData(auth);

  // ─── ACCOUNT DELETION HELPERS ──────────────────────────────────────────────

  static Future<void> deleteUserSettings(String uid) =>
      AccountDataService.deleteUserSettings(db, uid);

  static Future<void> deleteUserHistory(String uid) =>
      AccountDataService.deleteUserHistory(db, uid);

  static Future<void> anonymizeUserReports(String uid) =>
      AccountDataService.anonymizeUserReports(db, uid);
}

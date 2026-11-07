// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gscanner/models/models.dart';
import 'package:gscanner/services/database/background_sync_manager.dart';
import 'package:gscanner/services/database/reports_db_service.dart';
import 'package:gscanner/services/database/history_db_service.dart';
import 'package:gscanner/core/network/connectivity_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ConnectivityHelper.mockIsConnected = true;
    ConnectivityHelper.mockIsWifi = true;
  });

  tearDown(() {
    ConnectivityHelper.mockIsConnected = null;
    ConnectivityHelper.mockIsWifi = null;
  });

  UserSettings createSettings({
    String userId = 'test_user',
    bool offlineDbWifiOnly = true,
  }) {
    return UserSettings(
      userId: userId,
      strictMode: true,
      alertLactose: false,
      warnAdditives: true,
      autoSaveHistory: true,
      preferredLanguage: 'it',
      offlineDbWifiOnly: offlineDbWifiOnly,
    );
  }

  group('BackgroundSyncManager - calculateInitialDelayToNextSundayNight', () {
    test('returns correct delay when now is Monday 10:00', () {
      final monday = DateTime(2026, 11, 2, 10, 0); // Monday
      final delay = BackgroundSyncManager.calculateInitialDelayToNextSundayNight(now: monday);

      // Next Sunday is 2026-11-08 04:30
      final expectedSunday = DateTime(2026, 11, 8, 4, 30);
      expect(delay, expectedSunday.difference(monday));
    });

    test('returns delay for today when now is Sunday 02:00 (before 04:30)', () {
      final sundayEarly = DateTime(2026, 11, 8, 2, 0); // Sunday 02:00
      final delay = BackgroundSyncManager.calculateInitialDelayToNextSundayNight(now: sundayEarly);

      expect(delay, const Duration(hours: 2, minutes: 30));
    });

    test('returns delay for next Sunday when now is Sunday 06:00 (after 04:30)', () {
      final sundayLate = DateTime(2026, 11, 8, 6, 0); // Sunday 06:00
      final delay = BackgroundSyncManager.calculateInitialDelayToNextSundayNight(now: sundayLate);

      final nextSunday = DateTime(2026, 11, 15, 4, 30);
      expect(delay, nextSunday.difference(sundayLate));
    });
  });

  group('BackgroundSyncManager - hasPendingUserData', () {
    test('returns false when SharedPreferences is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final result = await BackgroundSyncManager.hasPendingUserData('test_user');
      expect(result, isFalse);
    });

    test('returns true when pending votes exist', () async {
      SharedPreferences.setMockInitialValues({
        ReportsDbService.getPendingVotesKey('test_user'): json.encode({'800111': 1}),
      });
      final result = await BackgroundSyncManager.hasPendingUserData('test_user');
      expect(result, isTrue);
    });

    test('returns false when pending votes map is empty JSON object', () async {
      SharedPreferences.setMockInitialValues({
        ReportsDbService.getPendingVotesKey('test_user'): '{}',
      });
      final result = await BackgroundSyncManager.hasPendingUserData('test_user');
      expect(result, isFalse);
    });

    test('returns true when pending reports exist', () async {
      SharedPreferences.setMockInitialValues({
        ReportsDbService.getPendingReportsKey('test_user'): ['rep_123'],
      });
      final result = await BackgroundSyncManager.hasPendingUserData('test_user');
      expect(result, isTrue);
    });

    test('returns true when report tombstones exist', () async {
      SharedPreferences.setMockInitialValues({
        'deleted_reports_sync_filter': ['rep_del_1'],
      });
      final result = await BackgroundSyncManager.hasPendingUserData('test_user');
      expect(result, isTrue);
    });

    test('returns true when pending history exists', () async {
      SharedPreferences.setMockInitialValues({
        HistoryDbService.getPendingHistoryKey('test_user'): ['hist_1'],
      });
      final result = await BackgroundSyncManager.hasPendingUserData('test_user');
      expect(result, isTrue);
    });

    test('returns true when history barcode tombstones exist', () async {
      SharedPreferences.setMockInitialValues({
        'deleted_barcodes_sync_filter': ['800222'],
      });
      final result = await BackgroundSyncManager.hasPendingUserData('test_user');
      expect(result, isTrue);
    });

    test('returns true when history id tombstones exist', () async {
      SharedPreferences.setMockInitialValues({
        'deleted_history_ids_sync_filter': ['hist_del_99'],
      });
      final result = await BackgroundSyncManager.hasPendingUserData('test_user');
      expect(result, isTrue);
    });
  });

  group('BackgroundSyncManager - performPendingDataSync pre-flight checks', () {
    test('aborts with true when offlineDbWifiOnly is true but device is not on Wi-Fi', () async {
      SharedPreferences.setMockInitialValues({
        ReportsDbService.getPendingVotesKey('test_user'): json.encode({'800111': 1}),
      });
      ConnectivityHelper.mockIsWifi = false;
      ConnectivityHelper.mockIsConnected = true;

      final settings = createSettings(
        userId: 'test_user',
        offlineDbWifiOnly: true,
      );

      final result = await performPendingDataSync(settings);
      expect(result, isTrue);
    });

    test('aborts with true when device has no internet connection', () async {
      SharedPreferences.setMockInitialValues({
        ReportsDbService.getPendingVotesKey('test_user'): json.encode({'800111': 1}),
      });
      ConnectivityHelper.mockIsConnected = false;

      final settings = createSettings(
        userId: 'test_user',
        offlineDbWifiOnly: false,
      );

      final result = await performPendingDataSync(settings);
      expect(result, isTrue);
    });

    test('aborts with true when there is internet and Wi-Fi but no pending data', () async {
      SharedPreferences.setMockInitialValues({});
      ConnectivityHelper.mockIsConnected = true;
      ConnectivityHelper.mockIsWifi = true;

      final settings = createSettings(
        userId: 'test_user',
        offlineDbWifiOnly: false,
      );

      final result = await performPendingDataSync(settings);
      expect(result, isTrue);
    });
  });

  group('BackgroundSyncManager - schedulePendingDataSyncIfNeeded', () {
    test('completes safely when no pending data exists (cancels task)', () async {
      SharedPreferences.setMockInitialValues({});

      await expectLater(
        BackgroundSyncManager.schedulePendingDataSyncIfNeeded(),
        completes,
      );
    });

    test('completes safely when pending data exists', () async {
      SharedPreferences.setMockInitialValues({
        'deleted_reports_sync_filter': ['tomb_1'],
      });

      await expectLater(
        BackgroundSyncManager.schedulePendingDataSyncIfNeeded(
          settings: createSettings(userId: 'test_user', offlineDbWifiOnly: true),
        ),
        completes,
      );
    });
  });
}

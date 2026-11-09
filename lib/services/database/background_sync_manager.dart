import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:background_downloader/background_downloader.dart' as bg;
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../../models/models.dart';
import 'offline_db_service.dart';
import 'offline_db_sync_service.dart';
import 'settings_db_service.dart';
import 'reports_db_service.dart';
import 'history_db_service.dart';
import '../../core/network/connectivity_helper.dart';

/// Identificativo del task di sincronizzazione periodica in background (Trigger 1).
const String offlineDbPeriodicTask = 'com.emanueleciotola.gscanner.offlineDbPeriodicSync';

/// Identificativo del task one-shot per la sincronizzazione dei dati utente pendenti (Trigger 2).
const String pendingDataOneShotTask = 'com.emanueleciotola.gscanner.pendingDataOneShotSync';

/// Esegue il download del delta su iOS delegandolo nativamente a Background URLSession.
/// Rispetta il limite rigido dei 30 secondi: l'OS gestisce il download HTTP in background
/// e sveglia il processo unicamente per la query atomica SQLite ATTACH (~300ms).
Future<bool> performIosBackgroundDownloadAndMerge(UserSettings settings) async {
  try {
    debugPrint('BackgroundSyncManager [iOS]: Starting Background URLSession download...');

    // 1. Fetch rapido del manifest (pochi byte, < 200ms)
    final manifest = await OfflineDbSyncService.fetchVersionManifest();
    if (manifest == null) return false;

    final publishedAt = manifest['published_at'] as int? ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final delta7dSince = manifest['delta_7d_since'] as int? ?? (publishedAt - 7 * 86400);
    final delta30dSince = manifest['delta_30d_since'] as int? ?? (publishedAt - 30 * 86400);

    final packagesMap = manifest['packages'] as Map<String, dynamic>? ?? {};
    final packageData = packagesMap[settings.offlineDbTier.key] as Map<String, dynamic>?;
    if (packageData == null) return false;

    final isInstalled = await OfflineDbService.isDatabaseInstalled();
    final action = OfflineDbSyncService.determineSyncAction(
      isDbInstalled: isInstalled,
      lastSyncedAt: settings.offlineDbLastSyncedAt,
      delta7dSince: delta7dSince,
      delta30dSince: delta30dSince,
      publishedAt: publishedAt,
    );

    if (action == OfflineSyncAction.upToDate) {
      debugPrint('BackgroundSyncManager [iOS]: Already up-to-date.');
      return true;
    }

    String fileName;
    String? expectedSha256;
    switch (action) {
      case OfflineSyncAction.fastDelta7d:
        fileName = packageData['delta_7d']?['file'] ?? '${settings.offlineDbTier.key}_delta_7d.db.gz';
        expectedSha256 = packageData['delta_7d']?['sha256'] as String?;
        break;
      case OfflineSyncAction.extendedDelta30d:
        fileName = packageData['delta_30d']?['file'] ?? '${settings.offlineDbTier.key}_delta_30d.db.gz';
        expectedSha256 = packageData['delta_30d']?['sha256'] as String?;
        break;
      case OfflineSyncAction.fullDownload:
        fileName = packageData['full']?['file'] ?? '${settings.offlineDbTier.key}_full.db.gz';
        expectedSha256 = packageData['full']?['sha256'] as String?;
        break;
      case OfflineSyncAction.upToDate:
        return true;
    }

    final downloadUrl = '${OfflineDbSyncService.getEffectiveBaseUrl()}/$fileName';
    final targetDbPath = await OfflineDbService.getDatabasePath();
    final dir = Directory(p.dirname(targetDbPath));
    final tempGzFile = File(p.join(dir.path, 'ios_bg_download.db.gz'));
    final tempExtractedDb = File(p.join(dir.path, 'ios_temp_extracted.db'));

    if (tempGzFile.existsSync()) tempGzFile.deleteSync();
    if (tempExtractedDb.existsSync()) tempExtractedDb.deleteSync();

    // 2. Crea il DownloadTask delegato a Background URLSession
    final task = bg.DownloadTask(
      url: downloadUrl,
      baseDirectory: bg.BaseDirectory.applicationSupport,
      directory: 'offline_db',
      filename: 'ios_bg_download.db.gz',
      requiresWiFi: settings.offlineDbWifiOnly,
      retries: 2,
      allowPause: false,
    );

    // 3. Esegui il download tramite demone nativo iOS
    final result = await bg.FileDownloader().download(task);
    if (result.status != bg.TaskStatus.complete) {
      debugPrint('BackgroundSyncManager [iOS]: Download failed with status: ${result.status}');
      return false;
    }

    // 4. Verifica checksum SHA-256
    if (expectedSha256 != null && expectedSha256.isNotEmpty) {
      final bytes = await tempGzFile.readAsBytes();
      final actualSha = sha256.convert(bytes).toString();
      if (actualSha.toLowerCase() != expectedSha256.toLowerCase()) {
        debugPrint('BackgroundSyncManager [iOS]: SHA-256 mismatch');
        if (tempGzFile.existsSync()) tempGzFile.deleteSync();
        return false;
      }
    }

    // 5. Decompressione gzip
    await OfflineDbSyncService.decompressGzipFile(tempGzFile, tempExtractedDb);
    if (tempGzFile.existsSync()) tempGzFile.deleteSync();

    // 6. Fusione atomica veloce (< 400ms)
    if (action == OfflineSyncAction.fullDownload) {
      await OfflineDbService.close();
      final finalDbFile = File(targetDbPath);
      if (finalDbFile.existsSync()) finalDbFile.deleteSync();
      await tempExtractedDb.rename(finalDbFile.path);
    } else {
      await OfflineDbSyncService.applyPatchDatabase(
        targetDbPath: targetDbPath,
        patchFile: tempExtractedDb,
      );
    }

    // 7. Salva la versione aggiornata
    final updated = settings.copyWith(
      offlineDbTier: settings.offlineDbTier,
      offlineDbLastSyncedAt: publishedAt,
    );
    await SettingsDbService.saveLocalSettings(updated);
    debugPrint('BackgroundSyncManager [iOS]: Background URLSession sync SUCCESS ($publishedAt)');
    return true;
  } catch (e) {
    debugPrint('BackgroundSyncManager [iOS]: Error in Background URLSession sync: $e');
    return false;
  }
}

/// Esegue la sincronizzazione verso Firestore dei dati utente pendenti generati offline.
/// Controlla i vincoli di rete (Wi-Fi, connettività Internet) e la presenza effettiva di dati.
Future<bool> performPendingDataSync(UserSettings settings) async {
  try {
    debugPrint('BackgroundSyncManager [PendingSync]: Starting pending data sync...');

    if (settings.offlineDbWifiOnly) {
      final isWifi = await ConnectivityHelper.isWifiConnection();
      if (!isWifi) {
        debugPrint(
          'BackgroundSyncManager [PendingSync]: Aborted: offlineDbWifiOnly is active and device is not on Wi-Fi.',
        );
        return true;
      }
    }

    final hasInternet = await ConnectivityHelper.hasInternetConnection();
    if (!hasInternet) {
      debugPrint('BackgroundSyncManager [PendingSync]: Aborted: no internet connection.');
      return true;
    }

    final hasData = await BackgroundSyncManager.hasPendingUserData();
    if (!hasData) {
      debugPrint('BackgroundSyncManager [PendingSync]: Aborted: no pending user data found.');
      return true;
    }

    // Inizializza Firebase se non ancora disponibile nell'isolate di background
    if (Firebase.apps.isEmpty) {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final db = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    // 1. Sincronizza i voti sulle segnalazioni in attesa
    await ReportsDbService.syncPendingVotesWithFirestore(db, auth);

    // 2. Sincronizza le segnalazioni (upload pendenti e cancellazione tombstones)
    await ReportsDbService.syncReportsWithFirestore(db, auth);

    // 3. Sincronizza la cronologia scansioni (upload pendenti e cancellazione tombstones)
    await HistoryDbService.syncHistoryWithFirestore(db, auth);

    debugPrint('BackgroundSyncManager [PendingSync]: Completed successfully.');
    return true;
  } catch (e) {
    debugPrint('BackgroundSyncManager [PendingSync]: Error: $e');
    return false;
  }
}

/// Callback dispatcher di WorkManager (eseguita in un isolate Dart separato quando l'app è chiusa).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('BackgroundSyncManager: WorkManager task started: $taskName');

    if (taskName == pendingDataOneShotTask) {
      final settings = await SettingsDbService.getLocalSettings();
      return performPendingDataSync(settings);
    }

    if (taskName == offlineDbPeriodicTask) {
      try {
        final settings = await SettingsDbService.getLocalSettings();
        if (settings.offlineDbTier == OfflineDbTier.none || !settings.offlineDbAutoSync) {
          debugPrint('BackgroundSyncManager: Offline DB disabled or autoSync off, cancelling periodic background task.');
          try {
            await Workmanager().cancelByUniqueName(offlineDbPeriodicTask);
          } catch (_) {}
          return Future.value(true);
        }

        if (settings.offlineDbWifiOnly) {
          final isWifi = await ConnectivityHelper.isWifiConnection();
          if (!isWifi) {
            debugPrint('BackgroundSyncManager: Not on Wi-Fi, skipping background sync.');
            return Future.value(true);
          }
        }

        // Su iOS: delega nativa a Background URLSession tramite FileDownloader
        // per azzerare il rischio di timeout dei 30 secondi imposto da BGTaskScheduler
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          final success = await performIosBackgroundDownloadAndMerge(settings);
          return success;
        }

        // Su Android e altre piattaforme: esecuzione standard via OfflineDbSyncService
        final completer = Completer<bool>();
        final subscription = OfflineDbSyncService.syncDatabase(
          tier: settings.offlineDbTier,
          currentLastSyncedAt: settings.offlineDbLastSyncedAt,
        ).listen(
          (progress) async {
            if (progress.step == OfflineSyncStep.completed) {
              final manifest = await OfflineDbSyncService.fetchVersionManifest();
              final publishedAt = manifest?['published_at'] as int? ??
                  (DateTime.now().millisecondsSinceEpoch ~/ 1000);

              if (settings.offlineDbLastSyncedAt != publishedAt) {
                final updated = settings.copyWith(
                  offlineDbTier: settings.offlineDbTier,
                  offlineDbLastSyncedAt: publishedAt,
                );
                await SettingsDbService.saveLocalSettings(updated);
                debugPrint(
                  'BackgroundSyncManager: Background sync completed. Version: $publishedAt',
                );
              }
              if (!completer.isCompleted) completer.complete(true);
            } else if (progress.step == OfflineSyncStep.error) {
              debugPrint(
                'BackgroundSyncManager: Background sync error: ${progress.errorMessage}',
              );
              if (!completer.isCompleted) completer.complete(false);
            }
          },
          onError: (err) {
            debugPrint('BackgroundSyncManager: Stream error: $err');
            if (!completer.isCompleted) completer.complete(false);
          },
        );

        final result = await completer.future.timeout(
          const Duration(minutes: 5),
          onTimeout: () {
            subscription.cancel();
            return false;
          },
        );
        await subscription.cancel();
        return result;
      } catch (e) {
        debugPrint('BackgroundSyncManager: Failed executing task: $e');
        return Future.value(false);
      }
    }

    return Future.value(true);
  });
}

/// Gestore del ciclo di vita dei task di background di sistema per l'aggiornamento dei DB offline.
class BackgroundSyncManager {
  static bool _isInitialized = false;

  /// Calcola il Duration dal momento attuale alla prossima Domenica alle 04:30 locali.
  /// Utilizzato come `initialDelay` per allineare il task periodico al rilascio
  /// settimanale dei DB (GitHub Action: Domenica 03:00 → task: Domenica 04:30).
  @visibleForTesting
  static Duration calculateInitialDelayToNextSundayNight({DateTime? now}) {
    final localNow = now ?? DateTime.now();
    // weekday: 1=Mon ... 7=Sun
    int daysUntilSunday = (DateTime.sunday - localNow.weekday) % 7;
    if (daysUntilSunday == 0) {
      // Oggi è Domenica: controlla se le 04:30 sono già passate
      final todaySunday = DateTime(
        localNow.year,
        localNow.month,
        localNow.day,
        4,
        30,
      );
      if (localNow.isBefore(todaySunday)) {
        return todaySunday.difference(localNow);
      }
      // Già passate le 04:30 di Domenica → prossima Domenica
      daysUntilSunday = 7;
    }
    final nextSunday = DateTime(
      localNow.year,
      localNow.month,
      localNow.day + daysUntilSunday,
      4,
      30,
    );
    return nextSunday.difference(localNow);
  }

  /// Inizializza il worker nativo (Android WorkManager / iOS Background Tasks).
  /// Su Web e piattaforme desktop non supportate dal demone di background, è una no-op sicura.
  static Future<void> initialize() async {
    if (kIsWeb) return;

    if (_isInitialized) return;

    try {
      await Workmanager().initialize(callbackDispatcher);
      _isInitialized = true;
      debugPrint('BackgroundSyncManager: WorkManager initialized.');
    } catch (e) {
      debugPrint('BackgroundSyncManager: Initialization failed: $e');
    }
  }

  /// Verifica se sono presenti dati utente in attesa di sincronizzazione
  /// (voti, segnalazioni, tombstones segnalazioni, cronologia, tombstones cronologia).
  static Future<bool> hasPendingUserData([String? userId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = userId ??
          (Firebase.apps.isNotEmpty
              ? FirebaseAuth.instance.currentUser?.uid
              : null) ??
          'anonymous_voter';

      // 1. Voti pendenti
      final pendingVotesStr =
          prefs.getString(ReportsDbService.getPendingVotesKey(uid));
      if (pendingVotesStr != null &&
          pendingVotesStr.isNotEmpty &&
          pendingVotesStr != '{}') {
        return true;
      }

      // 2. Segnalazioni pendenti
      final pendingReports =
          prefs.getStringList(ReportsDbService.getPendingReportsKey(uid));
      if (pendingReports != null && pendingReports.isNotEmpty) {
        return true;
      }

      // 3. Tombstone segnalazioni
      final deletedReports = prefs.getStringList('deleted_reports_sync_filter');
      if (deletedReports != null && deletedReports.isNotEmpty) {
        return true;
      }

      // 4. Cronologia scansioni pendenti
      final pendingHistory =
          prefs.getStringList(HistoryDbService.getPendingHistoryKey(uid));
      if (pendingHistory != null && pendingHistory.isNotEmpty) {
        return true;
      }

      // 5. Tombstone cronologia
      final deletedBarcodes =
          prefs.getStringList('deleted_barcodes_sync_filter');
      if (deletedBarcodes != null && deletedBarcodes.isNotEmpty) {
        return true;
      }
      final deletedHistoryIds =
          prefs.getStringList('deleted_history_ids_sync_filter');
      if (deletedHistoryIds != null && deletedHistoryIds.isNotEmpty) {
        return true;
      }
    } catch (e) {
      debugPrint('BackgroundSyncManager.hasPendingUserData error: $e');
    }

    return false;
  }

  /// Schedula il task One-Shot per i dati utente pendenti solo se necessario.
  /// Su Web o se non vi sono dati pendenti, è una no-op sicura.
  static Future<void> schedulePendingDataSyncIfNeeded({
    UserSettings? settings,
    ExistingWorkPolicy existingWorkPolicy = ExistingWorkPolicy.keep,
  }) async {
    if (kIsWeb) return;

    final hasData = await hasPendingUserData();
    if (!hasData) {
      await cancelPendingDataSync();
      return;
    }

    if (!_isInitialized) {
      await initialize();
    }

    try {
      final effectiveSettings =
          settings ?? await SettingsDbService.getLocalSettings();

      await Workmanager().registerOneOffTask(
        pendingDataOneShotTask,
        pendingDataOneShotTask,
        constraints: Constraints(
          networkType: effectiveSettings.offlineDbWifiOnly
              ? NetworkType.unmetered
              : NetworkType.connected,
          requiresBatteryNotLow: false,
        ),
        existingWorkPolicy: existingWorkPolicy,
      );
      debugPrint(
        'BackgroundSyncManager: Scheduled One-Shot pending data sync (wifiOnly: ${effectiveSettings.offlineDbWifiOnly}).',
      );
    } catch (e) {
      debugPrint(
        'BackgroundSyncManager: Failed scheduling One-Shot pending data sync: $e',
      );
    }
  }

  /// Cancella esplicitamente il task periodico nativo per il database offline.
  static Future<void> cancelOfflineDbPeriodicTask() async {
    if (kIsWeb) return;
    try {
      await Workmanager().cancelByUniqueName(offlineDbPeriodicTask);
      debugPrint('BackgroundSyncManager: Periodic task cancelled.');
    } catch (e) {
      debugPrint('BackgroundSyncManager: Failed cancelling periodic task: $e');
    }
  }

  /// Cancella il task One-Shot se le code sono state svuotate (es. in foreground).
  static Future<void> cancelPendingDataSync() async {
    if (kIsWeb) return;
    try {
      await Workmanager().cancelByUniqueName(pendingDataOneShotTask);
      debugPrint('BackgroundSyncManager: Cancelled One-Shot pending data sync.');
    } catch (e) {
      debugPrint('BackgroundSyncManager: Failed cancelling One-Shot task: $e');
    }
  }

  /// Registra o annulla il task periodico di 7 giorni in base alle preferenze dell'utente.
  static Future<void> updatePeriodicTaskRegistration(UserSettings settings) async {
    if (kIsWeb) return;

    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Se ci sono dati pendenti, aggiorna anche il task One-Shot con le nuove impostazioni (es. cambio wifiOnly)
      await schedulePendingDataSyncIfNeeded(
        settings: settings,
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      final shouldSchedule = settings.offlineDbTier != OfflineDbTier.none &&
          settings.offlineDbAutoSync;

      if (!shouldSchedule) {
        await Workmanager().cancelByUniqueName(offlineDbPeriodicTask);
        debugPrint('BackgroundSyncManager: Periodic task cancelled.');
        return;
      }

      // Registra task periodico (eseguito ogni 7 giorni dal sistema operativo)
      // initialDelay allinea la prima esecuzione alla prossima Domenica 04:30 locale.
      final initialDelay = calculateInitialDelayToNextSundayNight();

      await Workmanager().registerPeriodicTask(
        offlineDbPeriodicTask,
        offlineDbPeriodicTask,
        frequency: const Duration(days: 7),
        initialDelay: initialDelay,
        constraints: Constraints(
          networkType: settings.offlineDbWifiOnly
              ? NetworkType.unmetered
              : NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
      debugPrint(
        'BackgroundSyncManager: Registered periodic task (frequency: 7d, initialDelay: ${initialDelay.inHours}h, wifiOnly: ${settings.offlineDbWifiOnly}).',
      );
    } catch (e) {
      debugPrint('BackgroundSyncManager: Failed scheduling periodic task: $e');
    }
  }
}

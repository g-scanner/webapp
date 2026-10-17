// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/models.dart';
import 'offline_db_service.dart';

/// Tipo di sincronizzazione calcolato dal decision engine a 3 stati.
enum OfflineSyncAction {
  fastDelta7d,
  extendedDelta30d,
  fullDownload,
}

/// Servizio che gestisce il download, la decompressione gzip e la fusione atomica
/// dei database offline tramite GitHub Releases.
class OfflineDbSyncService {
  static const String _defaultReleaseBaseUrl =
      'https://github.com/g-scanner/webapp/releases/download/offline-data';

  static const String _webProxyBaseUrl = String.fromEnvironment(
    'OFF_PROXY_BASE_URL',
    defaultValue: 'https://gscanner-off-proxy.g-scanner.workers.dev',
  );

  static String _baseUrl = _defaultReleaseBaseUrl;
  static http.Client? _mockClient;

  /// Notifier globale dello stato e avanzamento della sincronizzazione offline.
  static final ValueNotifier<OfflineSyncProgress> syncProgressNotifier =
      ValueNotifier<OfflineSyncProgress>(const OfflineSyncProgress.idle());

  /// Tier attualmente in fase di sincronizzazione o download.
  static OfflineDbTier? currentSyncingTier;
  static StreamSubscription<OfflineSyncProgress>? _autoDownloadSubscription;

  /// Indica se una sincronizzazione del database offline è attualmente in corso.
  static bool get isSyncing =>
      currentSyncingTier != null && syncProgressNotifier.value.isInProgress;

  /// Annulla eventuali sincronizzazioni automatiche o manuali in corso.
  static void cancelSync() {
    _autoDownloadSubscription?.cancel();
    _autoDownloadSubscription = null;
    currentSyncingTier = null;
    syncProgressNotifier.value = const OfflineSyncProgress.idle();
  }

  @visibleForTesting
  static void setMockBaseUrl(String url) {
    _baseUrl = url;
  }

  @visibleForTesting
  static void setMockClient(http.Client? client) {
    _mockClient = client;
  }

  @visibleForTesting
  static void resetState() {
    _baseUrl = _defaultReleaseBaseUrl;
    _mockClient = null;
    cancelSync();
  }

  @visibleForTesting
  static void resetBaseUrl() => resetState();

  /// Restituisce l'URL base effettivo, instradando tramite proxy CORS se eseguito su Web.
  static String getEffectiveBaseUrl() {
    if (_baseUrl != _defaultReleaseBaseUrl) {
      return _baseUrl;
    }
    if (kIsWeb) {
      final proxy = _webProxyBaseUrl.trim();
      if (proxy.isNotEmpty) {
        final cleanProxy = proxy.endsWith('/')
            ? proxy.substring(0, proxy.length - 1)
            : proxy;
        return '$cleanProxy/offline-data';
      }
    }
    return _baseUrl;
  }

  /// Scarica e analizza il manifest version.json da GitHub Releases.
  static Future<Map<String, dynamic>?> fetchVersionManifest({
    http.Client? client,
  }) async {
    final httpClient = client ?? _mockClient ?? http.Client();
    try {
      final currentBaseUrl = getEffectiveBaseUrl();
      final response = await httpClient.get(
        Uri.parse('$currentBaseUrl/version.json'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint("OfflineDbSyncService.fetchVersionManifest error: $e");
      return null;
    } finally {
      if (client == null && _mockClient == null) httpClient.close();
    }
  }

  /// Determina l'azione di sincronizzazione ottimale in base ai timestamp.
  static OfflineSyncAction determineSyncAction({
    required bool isDbInstalled,
    required int? lastSyncedAt,
    required int delta7dSince,
    required int delta30dSince,
  }) {
    if (!isDbInstalled || lastSyncedAt == null) {
      return OfflineSyncAction.fullDownload;
    }

    if (lastSyncedAt >= delta7dSince) {
      return OfflineSyncAction.fastDelta7d;
    } else if (lastSyncedAt >= delta30dSince) {
      return OfflineSyncAction.extendedDelta30d;
    } else {
      return OfflineSyncAction.fullDownload;
    }
  }

  /// Se l'utente ha configurato un Tier diverso da [OfflineDbTier.none], ma il file fisico
  /// non è ancora installato su questo dispositivo (es. nuovo dispositivo o web cache pulita),
  /// avvia automaticamente il download in background senza bloccare la UI.
  static Future<void> autoDownloadIfNeeded({
    required UserSettings settings,
    required Future<void> Function(UserSettings) onSettingsChange,
    http.Client? client,
  }) async {
    if (settings.offlineDbTier == OfflineDbTier.none) {
      final isInstalled = await OfflineDbService.isDatabaseInstalled();
      if (isInstalled) {
        debugPrint(
          'OfflineDbSyncService: Tier is none in settings. Physically deleting offline DB from device...',
        );
        await OfflineDbService.deleteDatabaseFile();
      }
      return;
    }
    if (isSyncing) return;

    final isInstalled = await OfflineDbService.isDatabaseInstalled();
    final installedTier = await OfflineDbService.getInstalledTier();

    // Se un database è installato ma appartiene a un Tier diverso da quello richiesto:
    // cancelliamo fisicamente il vecchio DB per scaricare ed installare quello corretto!
    if (isInstalled && installedTier != null && installedTier != settings.offlineDbTier) {
      debugPrint(
        'OfflineDbSyncService: Tier mismatch (installed: ${installedTier.key}, desired: ${settings.offlineDbTier.key}). Deleting old DB...',
      );
      await OfflineDbService.deleteDatabaseFile();
    } else if (isInstalled) {
      return;
    }

    debugPrint(
      'OfflineDbSyncService: Auto-downloading ${settings.offlineDbTier.key} in background...',
    );

    _autoDownloadSubscription?.cancel();
    _autoDownloadSubscription = syncDatabase(
      tier: settings.offlineDbTier,
      currentLastSyncedAt: settings.offlineDbLastSyncedAt,
      client: client,
    ).listen((progress) async {
      if (progress.step == OfflineSyncStep.completed) {
        _autoDownloadSubscription = null;
        final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final updated = settings.copyWith(
          offlineDbTier: settings.offlineDbTier,
          offlineDbLastSyncedAt: nowEpoch,
        );
        await onSettingsChange(updated);
        debugPrint(
          'OfflineDbSyncService: Auto-download completed successfully for ${settings.offlineDbTier.key}',
        );
      } else if (progress.step == OfflineSyncStep.error) {
        _autoDownloadSubscription = null;
        debugPrint(
          'OfflineDbSyncService: Auto-download error: ${progress.errorMessage}',
        );
      }
    });
  }

  /// Esegue la sincronizzazione completa con emissione dello stato nello stream progressivo.
  /// Aggiorna automaticamente [syncProgressNotifier] e [currentSyncingTier] per i listener UI.
  static Stream<OfflineSyncProgress> syncDatabase({
    required OfflineDbTier tier,
    required int? currentLastSyncedAt,
    http.Client? client,
  }) async* {
    if (tier == OfflineDbTier.none) {
      currentSyncingTier = null;
      syncProgressNotifier.value = const OfflineSyncProgress.idle();
      yield const OfflineSyncProgress.idle();
      return;
    }

    currentSyncingTier = tier;
    await for (final progress in _syncDatabaseInternal(
      tier: tier,
      currentLastSyncedAt: currentLastSyncedAt,
      client: client,
    )) {
      syncProgressNotifier.value = progress;
      if (!progress.isInProgress) {
        currentSyncingTier = null;
      }
      yield progress;
    }
  }

  static Stream<OfflineSyncProgress> _syncDatabaseInternal({
    required OfflineDbTier tier,
    required int? currentLastSyncedAt,
    http.Client? client,
  }) async* {
    if (tier == OfflineDbTier.none) {
      yield const OfflineSyncProgress.idle();
      return;
    }

    yield const OfflineSyncProgress(
      step: OfflineSyncStep.checkingVersion,
      progress: 0.05,
    );

    final manifest = await fetchVersionManifest(client: client);
    if (manifest == null) {
      yield const OfflineSyncProgress.error("manifest_fetch_failed");
      return;
    }

    final publishedAt = manifest['published_at'] as int? ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final delta7dSince = manifest['delta_7d_since'] as int? ?? (publishedAt - 7 * 86400);
    final delta30dSince = manifest['delta_30d_since'] as int? ?? (publishedAt - 30 * 86400);

    final tiersMap = manifest['tiers'] as Map<String, dynamic>? ?? {};
    final tierData = tiersMap[tier.key] as Map<String, dynamic>?;
    if (tierData == null) {
      yield const OfflineSyncProgress.error("tier_not_found_in_manifest");
      return;
    }

    final bool isInstalled = await OfflineDbService.isDatabaseInstalled();

    // Se il database è già installato ed è allineato all'ultima versione del server (non stale),
    // evitiamo download ridondanti dello stesso database.
    if (isInstalled &&
        currentLastSyncedAt != null &&
        currentLastSyncedAt >= publishedAt) {
      debugPrint(
        "OfflineDbSyncService: Database ${tier.key} già installato e aggiornato ($currentLastSyncedAt >= $publishedAt). Download saltato.",
      );
      yield const OfflineSyncProgress.completed();
      return;
    }

    final action = kIsWeb
        ? OfflineSyncAction.fullDownload
        : determineSyncAction(
            isDbInstalled: isInstalled,
            lastSyncedAt: currentLastSyncedAt,
            delta7dSince: delta7dSince,
            delta30dSince: delta30dSince,
          );

    String fileName;
    switch (action) {
      case OfflineSyncAction.fastDelta7d:
        fileName = tierData['delta_7d']?['file'] ?? '${tier.key}_delta_7d.db.gz';
        break;
      case OfflineSyncAction.extendedDelta30d:
        fileName = tierData['delta_30d']?['file'] ?? '${tier.key}_delta_30d.db.gz';
        break;
      case OfflineSyncAction.fullDownload:
        fileName = tierData['full']?['file'] ?? '${tier.key}_full.db.gz';
        break;
    }

    final currentBaseUrl = getEffectiveBaseUrl();
    final downloadUrl = '$currentBaseUrl/$fileName';
    final targetDbPath = await OfflineDbService.getDatabasePath();

    if (kIsWeb) {
      http.Client? internalClient;
      try {
        // 1. DOWNLOAD STREAMING / BYTES (WEB)
        yield const OfflineSyncProgress(
          step: OfflineSyncStep.downloading,
          progress: 0.1,
        );

        final httpClient = client ?? _mockClient ?? (internalClient = http.Client());
        final request = http.Request('GET', Uri.parse(downloadUrl));
        final response = await httpClient.send(request);

        if (response.statusCode != 200) {
          yield OfflineSyncProgress.error("http_error_${response.statusCode}");
          return;
        }

        final totalBytes = response.contentLength ?? 0;
        var receivedBytes = 0;
        final bytesBuilder = BytesBuilder();

        await for (final chunk in response.stream) {
          bytesBuilder.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            final downloadProgress = 0.1 + (receivedBytes / totalBytes) * 0.6; // 0.1 -> 0.7
            yield OfflineSyncProgress(
              step: OfflineSyncStep.downloading,
              progress: downloadProgress.clamp(0.1, 0.7),
            );
          }
        }

        // 2. EXTRACTION (DECOMPRESSIONE GZIP IN MEMORIA)
        yield const OfflineSyncProgress(
          step: OfflineSyncStep.extracting,
          progress: 0.75,
        );

        final compressedBytes = bytesBuilder.takeBytes();
        final decompressedBytes = decompressGzipBytes(compressedBytes);

        // 3. SOSTITUZIONE ATOMICA IN INDEXEDDB
        yield const OfflineSyncProgress(
          step: OfflineSyncStep.merging,
          progress: 0.85,
        );

        await OfflineDbService.close();
        await databaseFactory.writeDatabaseBytes(
          targetDbPath,
          Uint8List.fromList(decompressedBytes),
        );
        await OfflineDbService.setInstalledTier(tier);

        yield const OfflineSyncProgress.completed();
      } catch (e) {
        debugPrint("OfflineDbSyncService web sync error: $e");
        yield OfflineSyncProgress.error(e.toString());
      } finally {
        internalClient?.close();
      }
      return;
    }

    final dir = Directory(p.dirname(targetDbPath));
    final tempGzFile = File(p.join(dir.path, 'download_temp.db.gz'));
    final tempExtractedDb = File(p.join(dir.path, 'temp_extracted.db'));
    http.Client? internalClient;

    try {
      // 1. DOWNLOAD STREAMING (NATIVE)
      yield const OfflineSyncProgress(
        step: OfflineSyncStep.downloading,
        progress: 0.1,
      );

      final httpClient = client ?? _mockClient ?? (internalClient = http.Client());
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await httpClient.send(request);

      if (response.statusCode != 200) {
        yield OfflineSyncProgress.error("http_error_${response.statusCode}");
        return;
      }

      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;
      final sink = tempGzFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          final downloadProgress = 0.1 + (receivedBytes / totalBytes) * 0.6; // 0.1 -> 0.7
          yield OfflineSyncProgress(
            step: OfflineSyncStep.downloading,
            progress: downloadProgress.clamp(0.1, 0.7),
          );
        }
      }
      await sink.flush();
      await sink.close();

      // 2. EXTRACTION (DECOMPRESSIONE GZIP)
      yield const OfflineSyncProgress(
        step: OfflineSyncStep.extracting,
        progress: 0.75,
      );

      if (tempExtractedDb.existsSync()) {
        tempExtractedDb.deleteSync();
      }

      await decompressGzipFile(tempGzFile, tempExtractedDb);

      if (tempGzFile.existsSync()) {
        tempGzFile.deleteSync();
      }

      // 3. MERGING O SOSTITUZIONE ATOMICA
      yield const OfflineSyncProgress(
        step: OfflineSyncStep.merging,
        progress: 0.85,
      );

      if (action == OfflineSyncAction.fullDownload) {
        // Sostituzione atomica del file
        await OfflineDbService.close();
        final finalDbFile = File(targetDbPath);
        if (finalDbFile.existsSync()) {
          finalDbFile.deleteSync();
        }
        await tempExtractedDb.rename(finalDbFile.path);
      } else {
        // Fusione atomica via SQLite ATTACH
        await applyPatchDatabase(
          targetDbPath: targetDbPath,
          patchFile: tempExtractedDb,
        );
      }

      await OfflineDbService.setInstalledTier(tier);

      yield const OfflineSyncProgress.completed();
    } catch (e) {
      debugPrint("OfflineDbSyncService sync error: $e");
      yield OfflineSyncProgress.error(e.toString());
    } finally {
      internalClient?.close();
      if (tempGzFile.existsSync()) {
        try {
          tempGzFile.deleteSync();
        } catch (_) {}
      }
      if (tempExtractedDb.existsSync()) {
        try {
          tempExtractedDb.deleteSync();
        } catch (_) {}
      }
    }
  }

  /// Decomprime bytes gzip in memoria (utilizzato su Web e per test).
  static List<int> decompressGzipBytes(List<int> compressedBytes) {
    return GZipDecoder().decodeBytes(compressedBytes);
  }

  /// Decomprime un file gzip in streaming su un file di destinazione.
  static Future<void> decompressGzipFile(File gzFile, File targetFile) async {
    final inputStream = gzFile.openRead();
    final outputSink = targetFile.openWrite();
    await inputStream.transform(gzip.decoder).pipe(outputSink);
  }

  /// Applica una patch SQLite montando il database secondario con ATTACH ed
  /// eseguendo un UPSERT atomico a livello di motore SQLite in C.
  static Future<void> applyPatchDatabase({
    required String targetDbPath,
    required File patchFile,
  }) async {
    final Database db = await openDatabase(targetDbPath);

    try {
      // 1. Collega il database temporaneo patch (al di fuori del blocco transaction)
      await db.execute("ATTACH DATABASE '${patchFile.path}' AS patch;");

      // 2. Upsert atomico all'interno della transazione
      try {
        await db.transaction((txn) async {
          await txn.execute("""
            INSERT OR REPLACE INTO products (
              code, product_name, brands, ingredients_text, 
              allergens_tags, labels_tags, traces_tags, last_modified_t
            )
            SELECT 
              code, product_name, brands, ingredients_text, 
              allergens_tags, labels_tags, traces_tags, last_modified_t 
            FROM patch.products;
          """);
        });
      } finally {
        // 3. Scollega sempre il database patch a fine operazione
        await db.execute("DETACH DATABASE patch;");
      }
    } finally {
      await db.close();
      if (patchFile.existsSync()) {
        patchFile.deleteSync();
      }
    }
  }
}

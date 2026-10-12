// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
      'https://github.com/manuxdev/gscanner/releases/download/offline-data';

  static String _baseUrl = _defaultReleaseBaseUrl;

  @visibleForTesting
  static void setMockBaseUrl(String url) {
    _baseUrl = url;
  }

  @visibleForTesting
  static void resetBaseUrl() {
    _baseUrl = _defaultReleaseBaseUrl;
  }

  /// Scarica e analizza il manifest version.json da GitHub Releases.
  static Future<Map<String, dynamic>?> fetchVersionManifest({
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.get(
        Uri.parse('$_baseUrl/version.json'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint("OfflineDbSyncService.fetchVersionManifest error: $e");
      return null;
    } finally {
      if (client == null) httpClient.close();
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

  /// Esegue la sincronizzazione completa con emissione dello stato nello stream progressivo.
  static Stream<OfflineSyncProgress> syncDatabase({
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
    final action = determineSyncAction(
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

    final downloadUrl = '$_baseUrl/$fileName';
    final targetDbPath = await OfflineDbService.getDatabasePath();
    final dir = Directory(p.dirname(targetDbPath));
    final tempGzFile = File(p.join(dir.path, 'download_temp.db.gz'));
    final tempExtractedDb = File(p.join(dir.path, 'temp_extracted.db'));

    try {
      // 1. DOWNLOAD STREAMING
      yield const OfflineSyncProgress(
        step: OfflineSyncStep.downloading,
        progress: 0.1,
      );

      final httpClient = client ?? http.Client();
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

      yield const OfflineSyncProgress.completed();
    } catch (e) {
      debugPrint("OfflineDbSyncService sync error: $e");
      yield OfflineSyncProgress.error(e.toString());
    } finally {
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

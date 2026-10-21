// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/models.dart';
import '../../core/core.dart';
import 'local_cache_service.dart';
import 'history_db_service.dart';
import 'offline_db_service.dart';
import 'off_product_parser.dart';

class OffIngestionService {
  static Future<ScanResult> scanBarcodeClientSide({
    required FirebaseFirestore db,
    required dynamic auth,
    required String barcode,
    required UserSettings settings,
  }) async {
    // 1. CACHE LOCALE: Cerca in locale.
    final localProduct =
        await LocalCacheService.getLocalProductByBarcode(barcode);
    if (localProduct != null) {
      // 1a. LIVELLO A: SUPER FRESCO (0 - 7 giorni)
      // Dati freschissimi: restituisce subito dalla cache locale con ZERO chiamate di rete.
      if (localProduct.isSuperFresh) {
        if (settings.autoSaveHistory) {
          await HistoryDbService.saveHistoryItem(db, auth, localProduct);
        }
        return ScanResult.fresh(localProduct);
      }

      // 1b. LIVELLO B: ZONA DI TOLLERANZA (8 - 30 giorni)
      // Dati affidabili: restituisce subito all'utente (0ms) e lancia check background fire-and-forget.
      if (localProduct.isInTolerance) {
        if (settings.autoSaveHistory) {
          await HistoryDbService.saveHistoryItem(db, auth, localProduct);
        }
        checkAndRefreshOffStaleCache(
          db: db,
          product: localProduct,
          settings: settings,
        );
        return ScanResult.fresh(localProduct);
      }

      // 1c. LIVELLO C: HARD STALE (>30 giorni) O INCOMPLETO
      // Se il DB offline è installato e contiene il barcode, lo prediligiamo subito
      // evitando lentezze da rete debole:
      final bool hasOfflineDb = await OfflineDbService.isDatabaseInstalled();
      if (hasOfflineDb) {
        final offlineProduct = await OfflineDbService.searchProduct(barcode);
        if (offlineProduct != null) {
          await LocalCacheService.upsertLocalProduct(offlineProduct);
          if (settings.autoSaveHistory) {
            await HistoryDbService.saveHistoryItem(db, auth, offlineProduct);
          }
          return ScanResult.offline(offlineProduct);
        }
      }

      // Se non è nel DB offline (o nessun DB offline), tentiamo un refresh SINCRONO da OFF se c'è connessione:
      final bool isConnected = await ConnectivityHelper.hasInternetConnection();
      if (isConnected) {
        final freshResult = await fetchOffProduct(barcode, settings);
        if (freshResult.status == OffFetchStatus.found &&
            freshResult.product != null) {
          return await _persistAndEmitResult(
            db: db,
            auth: auth,
            product: freshResult.product!,
            settings: settings,
            saveToFirestore: true,
          );
        }
      }

      // Fallback finale: il prodotto non è presente nel DB offline (o nessun DB installato),
      // e la rete è assente o ha fallito.
      // Restituiamo ScanResult.stale con i dati di cache locale e banner di avviso.
      if (settings.autoSaveHistory) {
        await HistoryDbService.saveHistoryItem(db, auth, localProduct);
      }
      return ScanResult.stale(localProduct);
    }

    // 2. VERIFICA DB OFFLINE (Priorità Assoluta per Responsività su Rete Debole / Offline):
    final bool hasOfflineDb = await OfflineDbService.isDatabaseInstalled();
    if (hasOfflineDb) {
      final offlineProduct = await OfflineDbService.searchProduct(barcode);
      if (offlineProduct != null) {
        await LocalCacheService.upsertLocalProduct(offlineProduct);
        if (settings.autoSaveHistory) {
          await HistoryDbService.saveHistoryItem(db, auth, offlineProduct);
        }
        return ScanResult.offline(offlineProduct);
      }
    }

    // 3. CONTROLLO PREVENTIVO CONNETTIVITÀ (Fail-Fast):
    // Se non c'è rete:
    // a) Se il DB offline è installato, il barcode non era presente -> ScanResult.offlineNotFound
    // b) Se il DB non è installato -> solleva OfflineWithoutDbException (0 ms)
    final bool isConnected =
        await ConnectivityHelper.hasInternetConnection();
    if (!isConnected) {
      if (hasOfflineDb) {
        final notFoundProduct =
            OfflineDbService.createOfflineNotFoundProduct(barcode);
        await LocalCacheService.upsertLocalProduct(notFoundProduct);
        if (settings.autoSaveHistory) {
          await HistoryDbService.saveHistoryItem(db, auth, notFoundProduct);
        }
        return ScanResult.offlineNotFound(notFoundProduct);
      }
      throw const OfflineWithoutDbException();
    }

    // 4. FIRESTORE (`products/{barcode}`): Cerca su Firestore se manca in locale
    Product? remoteProduct;
    try {
      remoteProduct = await LocalCacheService.getProductByBarcode(db, barcode);
      if (remoteProduct != null) {
        // Se il prodotto su Firestore è Hard Stale (>30gg o incompleto), applichiamo
        // la massima sicurezza alimentare con refresh sincrono da OFF:
        if (remoteProduct.isStale) {
          final freshResult = await fetchOffProduct(barcode, settings);
          if (freshResult.status == OffFetchStatus.found &&
              freshResult.product != null) {
            return await _persistAndEmitResult(
              db: db,
              auth: auth,
              product: freshResult.product!,
              settings: settings,
              saveToFirestore: true,
            );
          }
          // Se OFF non risponde, restituisce il dato remoto salvandolo localmente come stale
          return await _persistAndEmitResult(
            db: db,
            auth: auth,
            product: remoteProduct,
            settings: settings,
            saveToFirestore: false,
            forceStale: true,
          );
        }

        // Livello B (Zona di Tolleranza 8 - 30 giorni): avvia check background fire-and-forget
        if (remoteProduct.isInTolerance) {
          checkAndRefreshOffStaleCache(
            db: db,
            product: remoteProduct,
            settings: settings,
          );
        }
        // Livello A (Super Fresco 0 - 7 giorni): NESSUN check in background!

        return await _persistAndEmitResult(
          db: db,
          auth: auth,
          product: remoteProduct,
          settings: settings,
          saveToFirestore: false,
        );
      }
    } catch (e) {
      debugPrint("Firestore product lookup failed: $e");
    }

    // 5. PRODOTTO NUOVO (OFF API): Se manca sia in locale che in Firestore, chiama OFF
    final offResult = await fetchOffProduct(barcode, settings);

    if (offResult.status == OffFetchStatus.found && offResult.product != null) {
      return await _persistAndEmitResult(
        db: db,
        auth: auth,
        product: offResult.product!,
        settings: settings,
        saveToFirestore: true,
      );
    }

    if (offResult.status == OffFetchStatus.notFound) {
      // GHOST PRODUCT LEGITTIMO: OFF ha risposto confermando che il prodotto NON esiste.
      final nowIso = DateTime.now().toIso8601String();
      final ghostProduct = Product(
        barcode: barcode,
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        pendingReportsCount: 0,
        lastUpdated: nowIso,
        fetchedFromOffAt: nowIso,
      );

      return await _persistAndEmitResult(
        db: db,
        auth: auth,
        product: ghostProduct,
        settings: settings,
        saveToFirestore: true,
      );
    }

    // 6. ERRORE DI RETE / TIMEOUT (OFF non risponde / Rete debole):
    if (hasOfflineDb) {
      final notFoundProduct =
          OfflineDbService.createOfflineNotFoundProduct(barcode);
      await LocalCacheService.upsertLocalProduct(notFoundProduct);
      if (settings.autoSaveHistory) {
        await HistoryDbService.saveHistoryItem(db, auth, notFoundProduct);
      }
      return ScanResult.offlineNotFound(notFoundProduct);
    }

    // Nessun DB locale e chiamata fallita: non salvare ghost e rilancia eccezione
    throw const OffNetworkException();
  }

  /// Helper privato di Clean Architecture: salva atomicamente il prodotto in cache locale,
  /// su Firestore (se richiesto), in cronologia scansioni, e ritorna ScanResult.fresh.
  static Future<ScanResult> _persistAndEmitResult({
    required FirebaseFirestore db,
    required dynamic auth,
    required Product product,
    required UserSettings settings,
    required bool saveToFirestore,
    bool forceStale = false,
  }) async {
    if (saveToFirestore) {
      try {
        await db
            .collection(productsCollection)
            .doc(product.barcode)
            .set(product.toJson(), SetOptions(merge: true))
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint("Error saving product to Firestore: $e");
      }
    }

    await LocalCacheService.upsertLocalProduct(product);

    if (settings.autoSaveHistory) {
      await HistoryDbService.saveHistoryItem(db, auth, product);
    }

    return forceStale ? ScanResult.stale(product) : ScanResult.fresh(product);
  }

  static void checkAndRefreshOffStaleCache({
    required FirebaseFirestore db,
    required Product product,
    required UserSettings settings,
    void Function(Product freshProduct)? onRefreshed,
  }) async {
    // Se il prodotto è Super Fresco (0 - 7 giorni), nessun refresh in background è necessario!
    if (product.isSuperFresh) return;

    try {
      // Innesca ricalcolo asincrono silenzioso in background solo se online
      fetchOffProduct(product.barcode, settings).then((offResult) async {
        if (offResult.status == OffFetchStatus.found &&
            offResult.product != null) {
          final newOffProduct = offResult.product!;

          // OTTIMIZZAZIONE ANTI-EMORRAGIA SCRITTURE (HASHING):
          // Scrive su Firestore SOLO SE il contenuto del prodotto (ingredienti, allergeni, nomi)
          // è effettivamente cambiato rispetto alla versione già memorizzata.
          if (ProductContentHasher.hasContentChanged(product, newOffProduct)) {
            await db
                .collection(productsCollection)
                .doc(product.barcode)
                .set(newOffProduct.toJson(), SetOptions(merge: true));
            await LocalCacheService.upsertLocalProduct(newOffProduct);
          } else {
            // Contenuto invariato: aggiorna solo la data locale per prolungare la validità senza scritture Firestore
            await LocalCacheService.upsertLocalProduct(newOffProduct);
          }
          // Notifica chi ne ha bisogno (es. main_screen per aggiornare productNotifier)
          // che il prodotto è stato rinfrescato con successo.
          onRefreshed?.call(newOffProduct);
        }
      }).catchError((e) {
        debugPrint("Background OFF stale refresh error: $e");
      });
    } catch (e) {
      debugPrint("Stale check error: $e");
    }
  }

  /// Risolve online un prodotto (es. scansionato offline o in attesa di verifica)
  /// applicando rigorosamente l'architettura a 3 livelli:
  /// 1. Controlla prima Firestore (`products/{barcode}`)
  ///    - Se Super Fresco (0 - 7 giorni): usa Firestore senza contattare OFF (zero chiamate di rete a OFF!)
  ///    - Se in Zona di Tolleranza (8 - 30 giorni): usa Firestore e avvia check background fire-and-forget
  ///    - Se Hard Stale (> 30 giorni o incompleto): aggiorna da OFF
  /// 2. Se manca su Firestore: contatta OFF
  ///    - Se trovato: salva su Firestore e in SQLite
  ///    - Se notFound su OFF: crea e salva ghost product su Firestore e SQLite
  /// MAI invoca saveHistoryItem per non duplicare la cronologia.
  static Future<Product?> resolveProductOnline({
    required FirebaseFirestore db,
    required String barcode,
    required UserSettings settings,
    void Function(Product freshProduct)? onBackgroundRefreshed,
  }) async {
    // 1. FIRESTORE (`products/{barcode}`): verifica se il prodotto esiste già nel DB cloud
    Product? remoteProduct;
    try {
      remoteProduct = await LocalCacheService.getProductByBarcode(db, barcode);
      if (remoteProduct != null) {
        // Se il prodotto su Firestore è Hard Stale (>30gg o incompleto), refresh sincrono da OFF:
        if (remoteProduct.isStale) {
          final freshResult = await fetchOffProduct(barcode, settings);
          if (freshResult.status == OffFetchStatus.found &&
              freshResult.product != null) {
            final freshProduct = freshResult.product!;
            await LocalCacheService.saveProductToFirestore(db, freshProduct);
            await LocalCacheService.upsertLocalProduct(freshProduct);
            return freshProduct;
          }
          // Se OFF non risponde o errore, restituisce il dato Firestore salvato localmente
          await LocalCacheService.upsertLocalProduct(remoteProduct);
          return remoteProduct;
        }

        // Zona di Tolleranza (8 - 30 giorni): restituisce Firestore e lancia refresh in background
        if (remoteProduct.isInTolerance) {
          checkAndRefreshOffStaleCache(
            db: db,
            product: remoteProduct,
            settings: settings,
            onRefreshed: onBackgroundRefreshed,
          );
        }

        // Super Fresco (0 - 7 giorni) o Tolleranza: usa Firestore senza attendere OFF
        await LocalCacheService.upsertLocalProduct(remoteProduct);
        return remoteProduct;
      }
    } catch (e) {
      debugPrint("Firestore lookup in resolveProductOnline fallito: $e");
    }

    // 2. Se manca su Firestore, contatta Open Food Facts (Tier 3)
    try {
      final offResult = await fetchOffProduct(barcode, settings);
      if (offResult.status == OffFetchStatus.found &&
          offResult.product != null) {
        final offProduct = offResult.product!;
        await LocalCacheService.saveProductToFirestore(db, offProduct);
        await LocalCacheService.upsertLocalProduct(offProduct);
        return offProduct;
      }

      if (offResult.status == OffFetchStatus.notFound) {
        final nowIso = DateTime.now().toIso8601String();
        final ghostProduct = Product(
          barcode: barcode,
          nameMap: const {},
          brandMap: const {},
          ingredientsMap: const {},
          allergensMap: const {},
          pendingReportsCount: 0,
          lastUpdated: nowIso,
          fetchedFromOffAt: nowIso,
        );
        await LocalCacheService.saveProductToFirestore(db, ghostProduct);
        await LocalCacheService.upsertLocalProduct(ghostProduct);
        return ghostProduct;
      }
    } catch (e) {
      debugPrint("OFF fetch in resolveProductOnline fallito: $e");
    }

    return null;
  }

  static Future<OffFetchResult> fetchOffProduct(
    String barcode,
    UserSettings settings,
  ) async {
    try {
      final response = await OffApiClient.getProduct(barcode);
      if (response.statusCode == 200) {
        final offData = json.decode(response.body);
        if (offData != null && offData['status'] == 1) {
          final pData = offData['product'] as Map<String, dynamic>;
          final product = OffProductParser.parseProduct(
            barcode,
            pData,
            settings,
          );
          return OffFetchResult.found(product);
        }

        // status != 1: Prodotto esplicitamente assente su OFF
        return const OffFetchResult.notFound();
      }

      if (response.statusCode == 404) {
        return const OffFetchResult.notFound();
      }

      if (response.statusCode >= 500) {
        debugPrint(
          "OFF server error status: ${response.statusCode} for barcode $barcode",
        );
        return const OffFetchResult.networkError();
      }
    } catch (e) {
      debugPrint("OFF fetch and parse error: $e");
      return const OffFetchResult.networkError();
    }

    return const OffFetchResult.networkError();
  }

}

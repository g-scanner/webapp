// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/models.dart';
import '../../core/core.dart';
import 'local_cache_service.dart';
import 'history_db_service.dart';
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
      // 1a. PRODOTTO FRESCO E COMPLETO: Ha ingredienti e meno di 30 giorni.
      // Sicuro da servire immediatamente all'utente con zero latenza.
      if (!localProduct.isStale && localProduct.hasIngredientData) {
        if (settings.autoSaveHistory) {
          await HistoryDbService.saveHistoryItem(db, auth, localProduct);
        }
        // In background verifica/prepara l'aggiornamento silenzioso senza bloccare
        checkAndRefreshOffStaleCache(
          db: db,
          product: localProduct,
          settings: settings,
        );
        return ScanResult.fresh(localProduct);
      }

      // 1b. PRODOTTO STALE O INCOMPLETO: Ha più di 30 giorni oppure mancano gli ingredienti.
      // Per sicurezza alimentare, se c'è connessione tentiamo un refresh SINCRONO da OFF
      // prima di restituire il dato potenzialmente obsoleto all'utente.
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
        // Se OFF ha risposto con networkError (es. server down momentaneo):
        // fallback sul dato in cache locale piuttosto che bloccare l'utente.
      }

      // Fallback finale: siamo offline oppure OFF non era raggiungibile.
      // Restituiamo ScanResult.stale così la UI può mostrare un avviso appropriato.
      if (settings.autoSaveHistory) {
        await HistoryDbService.saveHistoryItem(db, auth, localProduct);
      }
      return ScanResult.stale(localProduct);
    }

    // 2. CONTROLLO PREVENTIVO CONNETTIVITÀ (Fail-Fast):
    // Se non c'è rete e non abbiamo il DB offline, blocca subito senza far attendere timeout all'utente.
    final bool isConnected =
        await ConnectivityHelper.hasInternetConnection();
    if (!isConnected) {
      throw const OfflineWithoutDbException();
    }

    // 3. FIRESTORE (`products/{barcode}`): Cerca su Firestore se manca in locale
    Product? remoteProduct;
    try {
      remoteProduct = await LocalCacheService.getProductByBarcode(db, barcode);
      if (remoteProduct != null) {
        // Se il prodotto su Firestore è stale (>30gg) o incompleto, applichiamo
        // la stessa massima sicurezza alimentare con refresh sincrono da OFF:
        if (remoteProduct.isStale || !remoteProduct.hasIngredientData) {
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

        // Prodotto fresco da Firestore: avvia eventuale controllo asincrono e restituisce
        checkAndRefreshOffStaleCache(
          db: db,
          product: remoteProduct,
          settings: settings,
        );
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

    // 4. PRODOTTO NUOVO (OFF API): Se manca sia in locale che in Firestore, chiama OFF
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

    // ⚠️ ERRORE DI RETE / TIMEOUT / SERVER OFF OVERLOADED:
    // NON creare alcun Ghost Product per non inquinare il DB con falsi sconosciuti per 30 giorni!
    // Registra comunque l'evento di scansione in cronologia locale se richiesto.
    if (settings.autoSaveHistory) {
      final nowIso = DateTime.now().toIso8601String();
      final placeholder = Product(
        barcode: barcode,
        nameMap: {},
        brandMap: {},
        ingredientsMap: {},
        allergensMap: {},
        pendingReportsCount: 0,
        lastUpdated: nowIso,
      );
      await HistoryDbService.saveHistoryItem(db, auth, placeholder);
    }

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
  }) async {
    if (saveToFirestore) {
      try {
        await db
            .collection(productsCollection)
            .doc(product.barcode)
            .set(product.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error saving product to Firestore: $e");
      }
    }

    await LocalCacheService.upsertLocalProduct(product);

    if (settings.autoSaveHistory) {
      await HistoryDbService.saveHistoryItem(db, auth, product);
    }

    return ScanResult.fresh(product);
  }

  static void checkAndRefreshOffStaleCache({
    required FirebaseFirestore db,
    required Product product,
    required UserSettings settings,
  }) async {
    // Se il prodotto non è obsoleto (stale), nessun refresh in background è necessario
    if (!product.isStale) return;

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
        }
      }).catchError((e) {
        debugPrint("Background OFF stale refresh error: $e");
      });
    } catch (e) {
      debugPrint("Stale check error: $e");
    }
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

  /// Metodo legacy mantenuto per piena retrocompatibilità.
  static Future<Product?> fetchAndParseOffProduct(
    String barcode,
    UserSettings settings,
  ) async {
    final result = await fetchOffProduct(barcode, settings);
    return result.product;
  }

  /// Delega a [OffProductParser.cleanIngredientsText] per retrocompatibilità.
  static String cleanIngredientsText(String text) =>
      OffProductParser.cleanIngredientsText(text);

  /// Delega a [OffProductParser.getFirstNonEmptyString] per retrocompatibilità.
  static String getFirstNonEmptyString(
    Map<String, dynamic> data,
    List<String> keys,
    String defaultValue,
  ) => OffProductParser.getFirstNonEmptyString(data, keys, defaultValue);
}

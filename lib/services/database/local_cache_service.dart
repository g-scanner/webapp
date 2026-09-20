// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';
import 'daos/product_dao.dart';
import 'daos/sync_metadata_dao.dart';

const String productsCollection = "products";

/// Servizio per la gestione della cache locale dei prodotti alimentari e delta-sync.
/// I dati sono memorizzati su SQLite (sqflite) per evitare saturazione della memoria RAM.
class LocalCacheService {
  static const String productsKey = 'celiac_products_cache';
  static const String lastSyncKey = 'celiac_app_last_sync_time';

  static const ProductDao _productDao = ProductDao();
  static const SyncMetadataDao _syncMetadataDao = SyncMetadataDao();

  /// Recupera tutti i prodotti salvati nella cache locale SQLite.
  static Future<List<Product>> getLocalProducts() async {
    try {
      final fromDb = await _productDao.getAllProducts();
      if (fromDb.isNotEmpty) return fromDb;

      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(productsKey) ?? [];
      final List<Product> result = [];
      for (final e in list) {
        try {
          final decoded = json.decode(e);
          if (decoded is Map<String, dynamic>) {
            result.add(Product.fromJson(decoded));
          }
        } catch (_) {}
      }
      return result;
    } catch (e) {
      debugPrint("Error loading local products from SQLite: $e");
      return [];
    }
  }

  /// Recupera un singolo prodotto per barcode direttamente con query SQL indicizzata.
  static Future<Product?> getLocalProductByBarcode(String barcode) async {
    try {
      return await _productDao.getProductByBarcode(barcode);
    } catch (e) {
      debugPrint("Error fetching product by barcode from SQLite: $e");
      return null;
    }
  }

  /// Salva o aggiorna un elenco di prodotti nel database SQLite.
  static Future<void> saveLocalProducts(List<Product> products) async {
    try {
      await _productDao.upsertProducts(products);
    } catch (e) {
      debugPrint("Error saving local products to SQLite: $e");
    }
  }

  /// Inserisce o aggiorna un singolo prodotto nel database SQLite.
  static Future<void> upsertLocalProduct(Product product) async {
    try {
      await _productDao.upsertProduct(product);
    } catch (e) {
      debugPrint("Error upserting local product into SQLite: $e");
    }
  }

  /// Recupera il timestamp dell'ultima sincronizzazione delta.
  static Future<String?> getLastSyncTime() async {
    try {
      return await _syncMetadataDao.getMetadata(lastSyncKey);
    } catch (e) {
      debugPrint("Error getting last sync time: $e");
      return null;
    }
  }

  /// Salva il timestamp dell'ultima sincronizzazione delta.
  static Future<void> saveLastSyncTime(String timeIso) async {
    try {
      await _syncMetadataDao.setMetadata(lastSyncKey, timeIso);
    } catch (e) {
      debugPrint("Error saving last sync time: $e");
    }
  }

  /// Delta Sync (Pilastro 2, Punto 3 & 4)
  /// Fa una singola query a Firestore per scaricare SOLO i prodotti modificati:
  /// `db.collection('products').where('last_updated', '>', app_last_sync_time)`
  static Future<List<Product>> performDeltaSync(FirebaseFirestore db) async {
    try {
      final lastSync = await getLastSyncTime();
      Query<Map<String, dynamic>> query = db.collection(productsCollection);

      if (lastSync != null && lastSync.isNotEmpty) {
        query = query.where('last_updated', isGreaterThan: lastSync);
      } else {
        // Primo avvio: limita a 100 per non saturare le letture
        query = query.orderBy('last_updated', descending: true).limit(100);
      }

      final snap = await query.get();
      if (snap.docs.isEmpty) {
        return getLocalProducts();
      }

      final updatedProducts = snap.docs
          .map((d) => Product.fromJson(d.data()))
          .toList();

      // Upsert batch in SQLite (massima efficienza, zero saturazione RAM)
      await _productDao.upsertProducts(updatedProducts);
      await saveLastSyncTime(DateTime.now().toIso8601String());

      return await _productDao.getAllProducts();
    } catch (e) {
      debugPrint("Error performing delta sync: $e");
      return getLocalProducts();
    }
  }

  /// Recupera un prodotto puntuale da Firestore e lo inserisce nella cache SQLite.
  static Future<Product?> getProductByBarcode(
    FirebaseFirestore db,
    String barcode,
  ) async {
    try {
      final docSnap = await db
          .collection(productsCollection)
          .doc(barcode)
          .get()
          .timeout(const Duration(seconds: 5));
      if (docSnap.exists && docSnap.data() != null) {
        final prod = Product.fromJson(docSnap.data()!);
        await upsertLocalProduct(prod);
        return prod;
      }
      return null;
    } catch (e) {
      debugPrint("Error getting product from Firestore: $e");
      return null;
    }
  }
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';

const String productsCollection = "products";

class LocalCacheService {
  static const String productsKey = 'celiac_products_cache';
  static const String lastSyncKey = 'celiac_app_last_sync_time';

  static Future<List<Product>> getLocalProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(productsKey) ?? [];
      final List<Product> result = [];
      for (final e in list) {
        try {
          final decoded = json.decode(e);
          if (decoded is Map<String, dynamic>) {
            result.add(Product.fromJson(decoded));
          }
        } catch (err) {
          debugPrint("Error decoding single local product: $err");
        }
      }
      return result;
    } catch (e) {
      debugPrint("Error loading local products: $e");
      return [];
    }
  }

  static Future<Product?> getLocalProductByBarcode(String barcode) async {
    final list = await getLocalProducts();
    try {
      return list.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveLocalProducts(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        productsKey,
        products.map((p) => json.encode(p.toJson())).toList(),
      );
    } catch (e) {
      debugPrint("Error saving local products: $e");
    }
  }

  static Future<void> upsertLocalProduct(Product product) async {
    try {
      final products = await getLocalProducts();
      final index = products.indexWhere((p) => p.barcode == product.barcode);
      if (index != -1) {
        products[index] = product;
      } else {
        products.insert(0, product);
      }
      await saveLocalProducts(products);
    } catch (e) {
      debugPrint("Error upserting local product: $e");
    }
  }

  static Future<String?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastSyncKey);
  }

  static Future<void> saveLastSyncTime(String timeIso) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastSyncKey, timeIso);
  }

  /// Delta Sync (Pilastro 2, Punto 3 & 4)
  /// Fa una singola query a Firestore per scaricare SOLO i prodotti modificati dai mod:
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

      final localProducts = await getLocalProducts();
      final Map<String, Product> productMap = {
        for (var p in localProducts) p.barcode: p,
      };

      for (var p in updatedProducts) {
        productMap[p.barcode] = p;
      }

      final newList = productMap.values.toList();
      await saveLocalProducts(newList);
      await saveLastSyncTime(DateTime.now().toIso8601String());

      return newList;
    } catch (e) {
      debugPrint("Error performing delta sync: $e");
      return getLocalProducts();
    }
  }

  static Future<Product?> getProductByBarcode(
    FirebaseFirestore db,
    String barcode,
  ) async {
    try {
      final docSnap = await db.collection(productsCollection).doc(barcode).get();
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

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner -- See LICENSE file in root for terms.

import '../../models/models.dart';

/// Risultato tipizzato della pipeline di scansione barcode.
///
/// Distingue tra un dato certo/aggiornato ([ScanResult.fresh]) e un dato
/// restituito dalla cache locale come fallback quando l'aggiornamento non era
/// possibile ([ScanResult.stale]), permettendo alla UI di mostrare avvisi
/// appropriati senza inquinare il modello [Product] con flag di presentazione.
sealed class ScanResult {
  const ScanResult();

  /// Dato aggiornato o certamente valido: proveniente da cache fresca,
  /// da un refresh riuscito, da Firestore o da OFF API live.
  const factory ScanResult.fresh(Product product) = _ScanResultFresh;

  /// Dato obsoleto restituito come fallback: il prodotto era in cache ma
  /// stale (>30gg) o incompleto, e non e stato possibile aggiornarlo
  /// (offline o OFF irraggiungibile).
  const factory ScanResult.stale(Product product) = _ScanResultStale;

  /// Dato proveniente dal database SQLite offline locale.
  const factory ScanResult.offline(Product product) = _ScanResultOffline;

  /// Prodotto non presente nel catalogo del database offline locale (risultato volatile).
  const factory ScanResult.offlineNotFound(Product product) = _ScanResultOfflineNotFound;

  /// Il prodotto associato al risultato.
  Product get product;

  /// `true` se il dato e aggiornato e attendibile.
  bool get isFresh => this is _ScanResultFresh;

  /// `true` se il dato e potenzialmente obsoleto (fallback dalla cache locale).
  bool get isStaleResult => this is _ScanResultStale;

  /// `true` se il dato proviene dal database SQLite offline.
  bool get isOfflineResult => this is _ScanResultOffline;

  /// `true` se il prodotto non è stato trovato nel database offline.
  bool get isOfflineNotFoundResult => this is _ScanResultOfflineNotFound;
}

final class _ScanResultFresh extends ScanResult {
  const _ScanResultFresh(this.product);

  @override
  final Product product;
}

final class _ScanResultStale extends ScanResult {
  const _ScanResultStale(this.product);

  @override
  final Product product;
}

final class _ScanResultOffline extends ScanResult {
  const _ScanResultOffline(this.product);

  @override
  final Product product;
}

final class _ScanResultOfflineNotFound extends ScanResult {
  const _ScanResultOfflineNotFound(this.product);

  @override
  final Product product;
}
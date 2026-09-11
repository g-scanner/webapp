// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import '../../models/models.dart';

/// Rappresenta i possibili esiti della richiesta a Open Food Facts.
enum OffFetchStatus {
  /// Prodotto trovato con successo (HTTP 200, status == 1).
  found,

  /// Il prodotto non esiste a catalogo (HTTP 200 con status == 0 o HTTP 404).
  notFound,

  /// Errore temporaneo di rete o server non raggiungibile (timeout, 5xx, socket error).
  networkError,
}

/// Incapsula il risultato dettagliato dell'interrogazione OFF.
class OffFetchResult {
  final OffFetchStatus status;
  final Product? product;
  final String? errorMessageKey;

  const OffFetchResult.found(Product this.product)
      : status = OffFetchStatus.found,
        errorMessageKey = null;

  const OffFetchResult.notFound()
      : status = OffFetchStatus.notFound,
        product = null,
        errorMessageKey = null;

  const OffFetchResult.networkError([this.errorMessageKey])
      : status = OffFetchStatus.networkError,
        product = null;

  bool get isFound => status == OffFetchStatus.found;
  bool get isNotFound => status == OffFetchStatus.notFound;
  bool get isNetworkError => status == OffFetchStatus.networkError;
}

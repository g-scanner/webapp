// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

/// Eccezione sollevata quando Open Food Facts o la connessione di rete falliscono.
class OffNetworkException implements Exception {
  final String localizationKey;

  const OffNetworkException([
    this.localizationKey = 'scanner.result.networkError',
  ]);

  @override
  String toString() => 'OffNetworkException(localizationKey: $localizationKey)';
}

/// Eccezione sollevata quando l'utente è offline e non ha scaricato il database locale.
class OfflineWithoutDbException implements Exception {
  final String localizationKey;

  const OfflineWithoutDbException([
    this.localizationKey = 'scanner.result.offlineNoDbPrompt',
  ]);

  @override
  String toString() =>
      'OfflineWithoutDbException(localizationKey: $localizationKey)';
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:web/web.dart' as web;

/// Controlla navigator.onLine del browser.
/// Ritorna false solo quando il browser è CERTO di essere offline.
/// Ritorna true in tutti gli altri casi (online, o stato incerto).
bool isWebNavigatorOnline() {
  try {
    return web.window.navigator.onLine;
  } catch (_) {
    // Fallback sicuro: assume connesso se non riusciamo a leggere lo stato.
    return true;
  }
}

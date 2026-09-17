// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:js_interop';

/// Binding JS → isLastPopupClosed() in web/index.html.
/// Controlla se l'ultimo popup auth è stato chiuso dall'utente.
@JS('isLastPopupClosed')
external bool _jsIsLastPopupClosed();

bool jsIsLastPopupClosed() {
  try {
    return _jsIsLastPopupClosed();
  } catch (_) {
    return false;
  }
}


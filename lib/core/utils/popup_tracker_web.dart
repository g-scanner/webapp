// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:js_interop';

/// Binding JS alla funzione isLastPopupClosed() definita in web/index.html.
/// Controlla se l'ultimo popup aperto da window.open è stato chiuso.
@JS('isLastPopupClosed')
external bool _jsIsLastPopupClosed();

bool jsIsLastPopupClosed() {
  try {
    return _jsIsLastPopupClosed();
  } catch (_) {
    return false;
  }
}

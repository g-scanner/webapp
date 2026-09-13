// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:js_interop';

@JS('hasWebTorch')
external JSBoolean _jsHasWebTorch();

@JS('toggleWebTorch')
external JSPromise<JSBoolean> _jsToggleWebTorch(JSBoolean on);

/// Controlla se la fotocamera attualmente attiva sul browser supporta la torcia/flash.
Future<bool> jsHasWebTorch() async {
  try {
    return _jsHasWebTorch().toDart;
  } catch (_) {
    return false;
  }
}

/// Accende o spegne la torcia della fotocamera su browser Web compatibili (es. Chrome su Android).
Future<bool> jsToggleWebTorch(bool on) async {
  try {
    final promise = _jsToggleWebTorch(on.toJS);
    final jsBool = await promise.toDart;
    return jsBool.toDart;
  } catch (_) {
    return false;
  }
}

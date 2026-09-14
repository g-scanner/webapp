// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

/// Stub per piattaforme non-web (Android, iOS nativo, ecc.)
/// Restituisce sempre false perché il popup tracking è solo per Web.
bool jsIsLastPopupClosed() => false;

/// Stub: non web, quindi mai in modalità iOS PWA standalone via browser.
bool jsIsIosPwaStandalone() => false;

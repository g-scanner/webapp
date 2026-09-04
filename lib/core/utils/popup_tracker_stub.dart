// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

/// Stub per piattaforme non-web (Android, iOS, ecc.)
/// Restituisce sempre false perché il popup tracking è solo per Web.
bool jsIsLastPopupClosed() => false;

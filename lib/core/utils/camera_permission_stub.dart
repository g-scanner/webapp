// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

/// Stub per piattaforme non-web (Android, iOS, ecc.)
/// Restituisce sempre 'granted' perché il controllo permessi su
/// queste piattaforme viene fatto tramite permission_handler.
Future<String> queryWebCameraPermission() async => 'granted';

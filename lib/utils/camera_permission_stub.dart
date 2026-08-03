/// Stub per piattaforme non-web (Android, iOS, ecc.)
/// Restituisce sempre 'granted' perché il controllo permessi su
/// queste piattaforme viene fatto tramite permission_handler.
Future<String> queryWebCameraPermission() async => 'granted';

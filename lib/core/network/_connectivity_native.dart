// Stub per piattaforme native (Android, iOS, desktop).
// Su queste piattaforme ConnectivityHelper usa InternetAddress.lookup di dart:io.
bool isWebNavigatorOnline() => true;
Future<bool> requestWebStoragePersistence() async => true;

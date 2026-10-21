import 'dart:js_interop';
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

/// Richiede la persistenza dello storage (IndexedDB) per prevenire l'eviction automatica di Safari/WebKit.
Future<bool> requestWebStoragePersistence() async {
  try {
    final storage = web.window.navigator.storage;
    final isPersisted = await storage.persist().toDart;
    return isPersisted.toDart;
  } catch (_) {
    return false;
  }
}

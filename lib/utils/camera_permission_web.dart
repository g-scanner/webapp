import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Usa la Web Permissions API per verificare lo stato del permesso camera
/// senza avviare la fotocamera (evita il blind try-catch).
/// Restituisce: 'granted', 'denied', 'prompt' o 'unknown'.
Future<String> queryWebCameraPermission() async {
  try {
    final permissions = web.window.navigator.permissions;
    // Crea il descriptor come JSObject con la chiave 'name'
    final JSObject descriptor = <String, JSAny?>{'name': 'camera'.toJS}.jsify() as JSObject;
    final result = await permissions.query(descriptor).toDart;
    return result.state;
  } catch (e) {
    // Browser non supporta la Permissions API → unknown (useremo try/catch)
    return 'unknown';
  }
}

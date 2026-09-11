// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'dart:io' show InternetAddress, SocketException;
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;

/// Helper leggero e testabile per la verifica rapida della connettività Internet.
class ConnectivityHelper {
  @visibleForTesting
  static bool? mockIsConnected;

  /// Verifica se il dispositivo ha accesso alla rete Internet.
  /// Su Web fa affidamento alla disponibilità del browser navigator.onLine o assume connesso.
  /// Su mobile/desktop effettua un lookup DNS rapido e a basso overhead.
  static Future<bool> hasInternetConnection({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (mockIsConnected != null) {
      return mockIsConnected!;
    }

    if (kIsWeb) {
      return true;
    }

    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(timeout);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}

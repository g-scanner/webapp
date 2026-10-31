// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'dart:io' show InternetAddress, SocketException;
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:connectivity_plus/connectivity_plus.dart';

export 'package:connectivity_plus/connectivity_plus.dart' show ConnectivityResult;

// Import condizionale: su web usa navigator.onLine, su native ritorna sempre true
// (il check nativo avviene tramite InternetAddress.lookup di dart:io più in basso).
import '_connectivity_native.dart'
    if (dart.library.js_interop) '_connectivity_web.dart';

/// Helper leggero e testabile per la verifica rapida della connettività Internet.
class ConnectivityHelper {
  @visibleForTesting
  static bool? mockIsConnected;

  @visibleForTesting
  static bool? mockIsWifi;

  @visibleForTesting
  static Stream<List<ConnectivityResult>>? mockConnectivityStream;

  /// Stream che notifica le variazioni dello stato di connettività di rete.
  static Stream<List<ConnectivityResult>> get onConnectivityChanged {
    if (mockConnectivityStream != null) {
      return mockConnectivityStream!;
    }
    return Connectivity().onConnectivityChanged;
  }

  /// Verifica se il dispositivo ha accesso alla rete Internet.
  ///
  /// - **Web**: controlla [navigator.onLine]. Se `false`, siamo certamente offline
  ///   e ritorniamo subito `false` (fail-fast). Se `true`, il browser ritiene di
  ///   essere online ma potrebbe comunque avere una connessione debole: in quel
  ///   caso le chiamate HTTP/Firestore successive gestiranno i timeout.
  /// - **Mobile/Desktop**: effettua un lookup DNS rapido con timeout di 3s.
  static Future<bool> hasInternetConnection({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (mockIsConnected != null) {
      return mockIsConnected!;
    }

    if (kIsWeb) {
      // navigator.onLine = false → offline certo → fail-fast (come mobile).
      // navigator.onLine = true → online o connessione debole → i timeout HTTP
      //                          e Firestore gestiranno il caso debole.
      return isWebNavigatorOnline();
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

  /// Verifica se il dispositivo è connesso a una rete non a consumo (Wi-Fi / Ethernet).
  /// Su Web ritorna sempre true (il browser non espone il tipo di connessione fisica in modo affidabile).
  static Future<bool> isWifiConnection() async {
    if (mockIsWifi != null) {
      return mockIsWifi!;
    }
    if (kIsWeb) {
      return true;
    }
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);
    } catch (_) {
      return true;
    }
  }

  /// Richiede la persistenza dello storage nel browser (IndexedDB) per evitare l'eviction automatica di Safari.
  static Future<bool> requestStoragePersistence() async {
    if (!kIsWeb) return true;
    return requestWebStoragePersistence();
  }
}


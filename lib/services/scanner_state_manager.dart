// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gscanner/utils/camera_permission_stub.dart'
    if (dart.library.js_interop) 'package:gscanner/utils/camera_permission_web.dart';

/// Stati in cui può trovarsi il motore dello scanner e dei permessi.
enum ScannerStatus {
  /// Stato iniziale prima del controllo permessi / avvio
  uninitialized,

  /// Verificando lo stato dei permessi
  checkingPermissions,

  /// In attesa che l'utente conceda il permesso nel dialog di sistema (Mobile)
  permissionWaiting,

  /// Permesso fotocamera negato su Mobile (richiede openAppSettings)
  permissionDeniedMobile,

  /// Permesso fotocamera negato nel browser su Web
  permissionDeniedWeb,

  /// Tentativo di avvio del MobileScannerController in corso
  starting,

  /// Fotocamera attiva e pronta a scansionare
  running,

  /// Errore generico di avvio
  error,
}

/// Oggetto immutabile che racchiude lo stato corrente dello scanner.
@immutable
class ScannerState {
  final ScannerStatus status;
  final String? errorMessage;

  const ScannerState({
    required this.status,
    this.errorMessage,
  });

  bool get isRunning => status == ScannerStatus.running;
  bool get isStarting => status == ScannerStatus.starting;
  bool get isChecking =>
      status == ScannerStatus.checkingPermissions ||
      status == ScannerStatus.permissionWaiting;
  bool get isPermissionDenied =>
      status == ScannerStatus.permissionDeniedMobile ||
      status == ScannerStatus.permissionDeniedWeb;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannerState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => status.hashCode ^ errorMessage.hashCode;
}

/// State Manager dedicato che gestisce in modo deterministico il ciclo di vita
/// del [MobileScannerController] e la logica dei permessi bifurcata per Mobile e Web.
class ScannerStateManager extends ValueNotifier<ScannerState> {
  final MobileScannerController controller;
  bool _isDisposed = false;

  ScannerStateManager({required this.controller})
      : super(const ScannerState(status: ScannerStatus.uninitialized));

  /// Indica se lo state manager e' stato dismesso
  bool get isDisposed => _isDisposed;

  /// Aggiorna il valore in sicurezza solo se l'oggetto non e' stato disposed
  void _safeSetState(ScannerState newState) {
    if (!_isDisposed) {
      value = newState;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Avvia la procedura deterministica di verifica permessi e avvio fotocamera.
  /// Rispetta il flag [isActive] (es. tab visibile, nessuna modale aperta).
  Future<void> initializeAndStart({required bool isActive}) async {
    if (_isDisposed || !isActive) return;

    // Evita avvii multipli se già in esecuzione o in fase di avvio
    if (value.status == ScannerStatus.running ||
        value.status == ScannerStatus.starting) {
      return;
    }

    _safeSetState(const ScannerState(status: ScannerStatus.checkingPermissions));

    if (kIsWeb) {
      // --- LOGICA PERMESSI WEB ---
      final permState = await queryWebCameraPermission();
      if (_isDisposed) return;

      if (permState == 'denied') {
        _safeSetState(const ScannerState(status: ScannerStatus.permissionDeniedWeb));
        return;
      }
      // Se 'granted', 'prompt' o 'unknown', proviamo ad avviare lo stream
      await _startControllerDirectly();
    } else {
      // --- LOGICA PERMESSI MOBILE (Android / iOS) ---
      final status = await Permission.camera.status;
      if (_isDisposed) return;

      if (status.isGranted) {
        await _startControllerDirectly();
      } else if (status.isPermanentlyDenied || status.isRestricted) {
        _safeSetState(const ScannerState(status: ScannerStatus.permissionDeniedMobile));
      } else {
        // Permesso non ancora richiesto o negato ma richiedibile
        _safeSetState(const ScannerState(status: ScannerStatus.permissionWaiting));
        final reqStatus = await Permission.camera.request();
        if (_isDisposed) return;

        if (reqStatus.isGranted) {
          await _startControllerDirectly();
        } else if (reqStatus.isPermanentlyDenied) {
          _safeSetState(const ScannerState(status: ScannerStatus.permissionDeniedMobile));
        } else {
          _safeSetState(const ScannerState(status: ScannerStatus.permissionDeniedMobile));
        }
      }
    }
  }

  /// Esegue controller.start() racchiudendolo in try-catch specifici per
  /// prevenire deadlock e silenziare eccezioni non-fatali di inizializzazione.
  Future<void> _startControllerDirectly() async {
    if (_isDisposed) return;

    _safeSetState(const ScannerState(status: ScannerStatus.starting));
    try {
      await controller.start();
      if (_isDisposed) return;
      _safeSetState(const ScannerState(status: ScannerStatus.running));
    } on MobileScannerException catch (e) {
      if (_isDisposed) return;
      final errStr = e.toString();
      final errDetailsMsg = e.errorDetails?.message ?? "";
      debugPrint("MobileScannerException durante start: ${e.errorCode} - $errStr - $errDetailsMsg");

      // 1. Eccezioni di inizializzazione/già attivo: non sono veri errori
      final isAlreadyWorking = e.errorCode ==
              MobileScannerErrorCode.controllerInitializing ||
          e.errorCode == MobileScannerErrorCode.controllerAlreadyInitialized ||
          errStr.contains("already running") ||
          errStr.contains("initializing") ||
          errDetailsMsg.contains("already running") ||
          errDetailsMsg.contains("initializing");

      if (isAlreadyWorking) {
        _safeSetState(const ScannerState(status: ScannerStatus.running));
        return;
      }

      // 2. Eccezioni relative ai permessi negati a livello driver/browser
      final isPermissionError =
          e.errorCode == MobileScannerErrorCode.permissionDenied ||
              errStr.contains("permission") ||
              errStr.contains("NotAllowedError") ||
              errStr.contains("Permission denied") ||
              errDetailsMsg.contains("permission") ||
              errDetailsMsg.contains("NotAllowedError") ||
              errDetailsMsg.contains("Permission denied");

      if (isPermissionError) {
        _safeSetState(ScannerState(
          status: kIsWeb
              ? ScannerStatus.permissionDeniedWeb
              : ScannerStatus.permissionDeniedMobile,
        ));
        return;
      }

      // 3. Altri errori generici del controller
      _safeSetState(ScannerState(
        status: ScannerStatus.error,
        errorMessage: errDetailsMsg.isNotEmpty ? errDetailsMsg : errStr,
      ));
    } catch (e) {
      if (_isDisposed) return;
      debugPrint("Eccezione generica durante l'avvio della fotocamera: $e");
      final errStr = e.toString();

      if (errStr.contains("already running") || errStr.contains("initializing")) {
        _safeSetState(const ScannerState(status: ScannerStatus.running));
        return;
      }

      if (kIsWeb &&
          (errStr.contains("NotAllowedError") ||
              errStr.contains("Permission denied") ||
              errStr.contains("permission"))) {
        _safeSetState(const ScannerState(status: ScannerStatus.permissionDeniedWeb));
        return;
      }

      _safeSetState(ScannerState(
        status: ScannerStatus.error,
        errorMessage: errStr,
      ));
    }
  }

  /// Ferma il controller e imposta lo stato su [ScannerStatus.uninitialized].
  Future<void> stop() async {
    if (_isDisposed) return;

    try {
      await controller.stop();
    } catch (e) {
      debugPrint("Errore durante l'arresto del controller scanner: $e");
    } finally {
      if (!_isDisposed) {
        _safeSetState(const ScannerState(status: ScannerStatus.uninitialized));
      }
    }
  }

  /// Richiesta manuale di permessi su Mobile (es. click sul pulsante fallback)
  Future<void> requestMobilePermission() async {
    if (_isDisposed) return;

    final status = await Permission.camera.status;
    if (_isDisposed) return;

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      _safeSetState(const ScannerState(status: ScannerStatus.permissionWaiting));
      final reqStatus = await Permission.camera.request();
      if (_isDisposed) return;

      if (reqStatus.isGranted) {
        await _startControllerDirectly();
      } else {
        _safeSetState(const ScannerState(status: ScannerStatus.permissionDeniedMobile));
      }
    }
  }

  /// Riprova l'avvio su Web (es. dopo che l'utente ha modificato le impostazioni nel browser)
  Future<void> retryWebStart() async {
    if (_isDisposed) return;

    if (kIsWeb) {
      await initializeAndStart(isActive: true);
    }
  }
}

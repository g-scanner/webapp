// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gscanner/utils/camera_permission_stub.dart'
    if (dart.library.js_interop) 'package:gscanner/utils/camera_permission_web.dart';

// --- Material 3 Design Colors ---
const Color primaryContainer = Color(0xFF2E7D32);
const Color surfaceContainerLowest = Color(0xFFFFFFFF);
const Color surfaceContainer = Color(0xFFEFEDF1);
const Color surfaceContainerLow = Color(0xFFF5F3F7);
const Color surfaceContainerHighest = Color(0xFFE3E2E6);
const Color outlineVariant = Color(0xFFBFCABA);
const Color onSurface = Color(0xFF1B1B1E);
const Color onSurfaceVariant = Color(0xFF40493D);
const Color errorColor = Color(0xFFBA1A1A);
const Color tertiaryContainer = Color(0xFFAD5600);

class CameraModule extends StatefulWidget {
  final MobileScannerController controller;
  final Future<void> Function(String barcode) onScanSuccess;
  final bool scanningProgress;
  final String? scanError;
  final bool isActive;

  const CameraModule({
    super.key,
    required this.controller,
    required this.onScanSuccess,
    required this.scanningProgress,
    this.scanError,
    this.isActive = true,
  });

  @override
  State<CameraModule> createState() => _CameraModuleState();
}

class _CameraModuleState extends State<CameraModule>
    with WidgetsBindingObserver {
  final TextEditingController _manualCodeController = TextEditingController();
  late FocusNode _manualFocusNode; // 1. Aggiunto il FocusNode

  bool _isProcessing = false;
  bool _isManualFocused = false; // 2. Stato per tracciare il focus
  bool _webPermissionDenied = false;
  bool _isCameraStarting = false;
  bool _browserPermissionDeniedPermanently = false;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  PermissionStatus _permissionStatus = PermissionStatus.provisional;
  bool _hasCheckedPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Inizializzo il focus e l'ascoltatore (identico alla cronologia)
    _manualFocusNode = FocusNode();
    _manualFocusNode.addListener(_onManualFocusChange);

    // Aspettiamo il primo frame: il widget MobileScanner deve essere
    // già montato nell'albero prima di chiamare controller.start().
    // Senza questo, su web si ottiene controllerNotAttached.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkPermission();
    });
  }

  Future<void> _safeStartCamera() async {
    if (!mounted || !widget.isActive) return;
    if (_isCameraStarting) {
      debugPrint("Camera start already in progress, skipping.");
      return;
    }
    _isCameraStarting = true;
    try {
      await widget.controller.start();
      if (mounted) {
        setState(() {
          _webPermissionDenied = false;
          _browserPermissionDeniedPermanently = false;
          _permissionStatus = PermissionStatus.granted;
        });
      }
    } catch (e) {
      debugPrint("Web camera start exception: $e");
      final errStr = e.toString();
      if (errStr.contains("already running")) {
        if (mounted) {
          setState(() {
            _webPermissionDenied = false;
            _browserPermissionDeniedPermanently = false;
            _permissionStatus = PermissionStatus.granted;
          });
        }
      } else {
        final permState = await queryWebCameraPermission();
        if (mounted) {
          setState(() {
            _webPermissionDenied = true;
            _browserPermissionDeniedPermanently = (permState == 'denied');
            _permissionStatus = PermissionStatus.denied;
          });
        }
      }
    } finally {
      _isCameraStarting = false;
    }
  }

  Future<void> _checkPermission() async {
    if (kIsWeb) {
      // --- WEB ---
      final permState = await queryWebCameraPermission();

      if (permState == 'denied') {
        // Permanentemente negato: mostriamo subito la UI con MobileScanner
        // in albero (necessario per il controller attachment)
        if (mounted) {
          setState(() {
            _webPermissionDenied = true;
            _browserPermissionDeniedPermanently = true;
            _permissionStatus = PermissionStatus.denied;
            _hasCheckedPermission = true; // MobileScanner entra nell'albero
          });
        }
        return;
      }

      // 'granted' o 'prompt': impostiamo hasCheckedPermission = true PRIMA
      // di chiamare start(), così MobileScanner viene renderizzato e il
      // controller risulta attached quando start() viene eseguito.
      if (mounted) {
        setState(() {
          _webPermissionDenied = false;
          _browserPermissionDeniedPermanently = false;
          _hasCheckedPermission = true; // ← MobileScanner entra nell'albero
        });
      }

      if (widget.isActive) {
        // Aspettiamo il frame successivo (MobileScanner è ora nell'albero)
        // poi chiamiamo start(). Qui il controller è garantito attached.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _safeStartCamera();
        });
      }
      return;
    }

    // --- NATIVE (Android / iOS) ---
    final status = await Permission.camera.status;
    if (status.isGranted) {
      if (mounted) {
        setState(() {
          _permissionStatus = status;
          _hasCheckedPermission = true;
        });
      }
      if (widget.isActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.controller.start().catchError((_) {});
        });
      }
    } else if (status.isDenied || status.isProvisional) {
      final reqStatus = await Permission.camera.request();
      if (mounted) {
        setState(() {
          _permissionStatus = reqStatus;
          _hasCheckedPermission = true;
        });
        if (reqStatus.isGranted && widget.isActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            widget.controller.start().catchError((_) {});
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _permissionStatus = status;
          _hasCheckedPermission = true;
        });
      }
    }
  }

  Future<void> _checkPermissionOnResume() async {
    if (kIsWeb) {
      // Su web, l'utente potrebbe aver concesso il permesso dal lucchetto
      // del browser mentre era su un'altra tab. Al resume ricontrolliamo.
      final permState = await queryWebCameraPermission();
      if (!mounted) return;
      if (permState == 'granted' && widget.isActive) {
        setState(() {
          _webPermissionDenied = false;
          _browserPermissionDeniedPermanently = false;
          _permissionStatus = PermissionStatus.granted;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _safeStartCamera();
        });
      } else if (permState == 'denied') {
        setState(() {
          _webPermissionDenied = true;
          _browserPermissionDeniedPermanently = true;
          _permissionStatus = PermissionStatus.denied;
        });
      }
      return;
    }
    // --- NATIVE ---
    final status = await Permission.camera.status;
    if (mounted) {
      setState(() {
        _permissionStatus = status;
        _hasCheckedPermission = true;
      });
      if (status.isGranted && widget.isActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.controller.start().catchError((_) {});
        });
      }
    }
  }

  void _onManualFocusChange() {
    setState(() {
      _isManualFocused = _manualFocusNode.hasFocus;
    });
  }

  @override
  void didUpdateWidget(CameraModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        if (kIsWeb) {
          // Su Web NON resettiamo _hasCheckedPermission: MobileScanner deve
          // restare nell'albero. Tentiamo semplicemente di riavviare lo stream.
          if (!_webPermissionDenied) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _safeStartCamera();
            });
          }
        } else {
          if (_permissionStatus.isGranted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              widget.controller.start().catchError((_) {});
            });
          }
        }
      } else {
        unawaited(widget.controller.stop().catchError((_) {}));
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionOnResume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manualFocusNode.removeListener(_onManualFocusChange);
    _manualFocusNode.dispose();
    _manualCodeController.dispose();
    if (kIsWeb) {
      // Spegniamo esplicitamente lo stream per rilasciare la camera
      unawaited(widget.controller.stop().catchError((_) {}));
    }
    super.dispose();
  }

  void _handleManualSearch() {
    if (_manualCodeController.text.trim().isEmpty) return;
    widget.onScanSuccess(_manualCodeController.text.trim());
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!widget.isActive) return;
    if (_isProcessing || widget.scanningProgress) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      _isProcessing = true;
      await widget.onScanSuccess(barcodes.first.rawValue!);
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surfaceContainerLowest,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 16.0,
          bottom: 40.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIntegratedCard(),

            if (widget.scanError != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: errorColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: errorColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.scanError!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: errorColor,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            _buildSafetyGuide(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegratedCard() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: outlineVariant.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: onSurface.withValues(alpha: 0.04),
            blurRadius: 28,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Scan Product",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: onSurface,
                fontFamily: 'Inter',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Align barcode within frame to check celiac safety.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildCameraArea(),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 24.0,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Divider(
                      color: surfaceContainerHighest,
                      thickness: 1.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "Oppure",
                      style: TextStyle(
                        fontSize: 14,
                        color: onSurfaceVariant.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(
                      color: surfaceContainerHighest,
                      thickness: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Inserimento Manuale Totalmente Ricostruito
            _buildManualInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraArea() {
    // Fase di caricamento: controlliamo ancora il permesso, mostriamo spinner.
    // MobileScanner NON è ancora nell'albero — ok perché non chiamiamo start().
    if (!_hasCheckedPermission) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.0),
          color: Colors.black,
        ),
        clipBehavior: Clip.antiAlias,
        child: const AspectRatio(
          aspectRatio: 16 / 10,
          child: Center(
            child: CircularProgressIndicator(color: primaryContainer),
          ),
        ),
      );
    }

    // Una volta che _hasCheckedPermission = true, MobileScanner entra
    // nell'albero e rimane SEMPRE lì — anche quando il permesso è negato.
    // La UI di errore è un overlay che copre il widget camera, non un
    // sostituto: questo garantisce che il controller sia sempre attached
    // e che start() possa essere chiamato dal bottone senza controllerNotAttached.
    final bool isPermissionDenied = kIsWeb
        ? _webPermissionDenied
        : (_permissionStatus.isDenied ||
              _permissionStatus.isPermanentlyDenied ||
              _permissionStatus.isRestricted);

    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: widget.controller,
      builder: (context, state, child) {
        final bool hasTorch = _isMobile;
        final double buttonOverflow = hasTorch ? 28.0 : 0.0;

        return Stack(
          children: [
            // ── Camera container (SEMPRE nell'albero) ──────────────────────
            Padding(
              padding: EdgeInsets.only(bottom: buttonOverflow),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28.0),
                  color: Colors.black,
                ),
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      final double frameW = w * 0.85;
                      final double frameH = h * 0.65;

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(
                            controller: widget.controller,
                            onDetect: _onDetect,
                          ),
                          // Overlay UI scanner (solo se permesso concesso)
                          if (!isPermissionDenied) ...[
                            CustomPaint(
                              size: Size(w, h),
                              painter: _VignetteBorderPainter(
                                frameWidth: frameW,
                                frameHeight: frameH,
                              ),
                            ),
                            Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 2,
                                      height: 24,
                                      color: primaryContainer,
                                    ),
                                    Container(
                                      width: 24,
                                      height: 2,
                                      color: primaryContainer,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: SizedBox(
                                width: frameW,
                                height: frameH,
                                child: _buildCorners(),
                              ),
                            ),
                            if (widget.scanningProgress)
                              Container(
                                color: Colors.black.withValues(alpha: 0.6),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: primaryContainer,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Analisi in corso...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            // ── Torch button ───────────────────────────────────────────────
            if (hasTorch && !isPermissionDenied)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Material(
                    color: state.torchState == TorchState.on
                        ? primaryContainer
                        : surfaceContainerLowest,
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.4),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => widget.controller.toggleTorch(),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Center(
                          child: Icon(
                            state.torchState == TorchState.on
                                ? Icons.flashlight_on
                                : Icons.flashlight_off,
                            size: 24,
                            color: state.torchState == TorchState.on
                                ? surfaceContainerLowest
                                : onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // ── Overlay permesso negato (copre la camera, non la sostituisce) ──
            if (isPermissionDenied)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28.0),
                    color: Colors.black,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        _browserPermissionDeniedPermanently
                            ? 'Accesso Fotocamera Bloccato'
                            : 'Fotocamera non disponibile',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _browserPermissionDeniedPermanently
                            ? 'Abilita la fotocamera dall\'icona del lucchetto nella barra degli indirizzi del browser, consenti l\'accesso e ricarica la pagina.'
                            : 'Concedi l\'accesso alla fotocamera per\nscansionare i codici a barre.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!_browserPermissionDeniedPermanently) ...[
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () async {
                            if (kIsWeb) {
                              // Se clicca per richiedere l'accesso, prima chiamiamo stop()
                              // per ripulire lo stato, poi proviamo ad avviare.
                              try {
                                await widget.controller.stop();
                              } catch (_) {}
                              await _safeStartCamera();
                              return;
                            }
                            // --- NATIVE ---
                            final status = await Permission.camera.status;
                            if (status.isPermanentlyDenied) {
                              await openAppSettings();
                            } else {
                              final reqStatus = await Permission.camera
                                  .request();
                              if (mounted) {
                                setState(() {
                                  _permissionStatus = reqStatus;
                                });
                                if (reqStatus.isGranted && widget.isActive) {
                                  Future.microtask(() async {
                                    if (!mounted) return;
                                    try {
                                      await widget.controller.start();
                                    } catch (_) {}
                                  });
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.security, size: 16),
                          label: const Text(
                            'Richiedi Accesso',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryContainer,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 👇 LA NUOVA BARRA DI RICERCA 1:1 CON LA CRONOLOGIA 👇
  Widget _buildManualInput() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _manualCodeController,
      builder: (context, value, child) {
        final bool hasText = value.text.trim().isNotEmpty;

        // Identico a cronologia: mostra l'icona X solo se c'è testo ED è in focus
        final bool showClearIcon = _isManualFocused && hasText;

        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _manualCodeController,
                focusNode: _manualFocusNode, // Assegnato il nuovo FocusNode
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 15,
                  color: onSurface,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                ),
                decoration: InputDecoration(
                  hintText: "Manual Barcode...",
                  hintStyle: TextStyle(
                    color: onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    maxWidth: 48,
                    minHeight: 48,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                      child: showClearIcon
                          ? IconButton(
                              key: const ValueKey('clearIcon'),
                              icon: const Icon(
                                Icons.close,
                                color: onSurfaceVariant,
                                size: 22,
                              ),
                              onPressed: () {
                                _manualCodeController.clear();
                                _manualFocusNode.requestFocus();
                              },
                            )
                          : Icon(
                              Icons
                                  .qr_code_scanner_rounded, // Icona barcode invece della lente
                              key: ValueKey('barcodeIcon'),
                              color: hasText
                                  ? onSurfaceVariant
                                  : onSurfaceVariant.withValues(alpha: 0.6),
                              size: 22,
                            ),
                    ),
                  ),
                  filled: true,
                  fillColor:
                      surfaceContainer, // Stesso background della cronologia
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Bottone Rotondo Dinamico
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // IL SEGRETO È QUI: Usa il verde (primaryContainer) al 12% di opacità.
                // Resta un blocco solido, ma chiaramente "spento".
                color: hasText ? primaryContainer : surfaceContainer,
                boxShadow: hasText
                    ? [
                        BoxShadow(
                          color: primaryContainer.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [BoxShadow(color: Colors.transparent)],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: (hasText && !widget.scanningProgress)
                      ? _handleManualSearch
                      : null,
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0.5, 0),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        // Anche l'icona usa il verde (al 35-40%) per restare in tema
                        // e staccarsi leggermente dal fondo chiaro.
                        color: hasText
                            ? surfaceContainerLowest
                            : onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSafetyGuide() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          const Text(
            "Safety Indicators",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: _buildIndicatorItem(
                  Icons.check_circle_rounded,
                  "Safe",
                  "Gluten-free",
                  primaryContainer,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: _buildIndicatorItem(
                  Icons.warning_rounded,
                  "Uncertain",
                  "Check label",
                  tertiaryContainer,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: _buildIndicatorItem(
                  Icons.cancel_rounded,
                  "Unsafe",
                  "Has gluten",
                  errorColor,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: _buildIndicatorItem(
                  Icons.help_rounded,
                  "Unknown",
                  "Not found",
                  onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: surfaceContainerLowest,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: onSurface,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: onSurfaceVariant,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCorners() {
    const double cornerLen = 28;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: CustomPaint(
            size: const Size(cornerLen, cornerLen),
            painter: _CornerPainter(
              color: primaryContainer,
              alignment: Alignment.topLeft,
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(cornerLen, cornerLen),
            painter: _CornerPainter(
              color: primaryContainer,
              alignment: Alignment.topRight,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: CustomPaint(
            size: const Size(cornerLen, cornerLen),
            painter: _CornerPainter(
              color: primaryContainer,
              alignment: Alignment.bottomLeft,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(cornerLen, cornerLen),
            painter: _CornerPainter(
              color: primaryContainer,
              alignment: Alignment.bottomRight,
            ),
          ),
        ),
      ],
    );
  }
}

// ── CUSTOM PAINTER ──────────────────────────────────────────────────────────

class _CornerPainter extends CustomPainter {
  final Color color;
  final Alignment alignment;

  static const double strokeWidth = 4.0;
  static const double radius = 12.0;

  _CornerPainter({required this.color, required this.alignment});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final d = strokeWidth / 2;

    if (alignment == Alignment.topLeft) {
      path.moveTo(d, size.height);
      path.lineTo(d, radius);
      path.quadraticBezierTo(d, d, radius, d);
      path.lineTo(size.width, d);
    } else if (alignment == Alignment.topRight) {
      path.moveTo(0, d);
      path.lineTo(size.width - radius, d);
      path.quadraticBezierTo(size.width - d, d, size.width - d, radius);
      path.lineTo(size.width - d, size.height);
    } else if (alignment == Alignment.bottomLeft) {
      path.moveTo(d, 0);
      path.lineTo(d, size.height - radius);
      path.quadraticBezierTo(d, size.height - d, radius, size.height - d);
      path.lineTo(size.width, size.height - d);
    } else if (alignment == Alignment.bottomRight) {
      path.moveTo(size.width - d, 0);
      path.lineTo(size.width - d, size.height - radius);
      path.quadraticBezierTo(
        size.width - d,
        size.height - d,
        size.width - radius,
        size.height - d,
      );
      path.lineTo(0, size.height - d);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}

/// Disegna un gradiente infallibile calcolando matematicamente l'Alpha Blending.
/// Utilizza una curva (Curves.easeInOut) per garantire che l'opacità al bordo del
/// riquadro parta ESATTAMENTE da 0.0 e salga in modo morbidissimo verso l'esterno.
class _VignetteBorderPainter extends CustomPainter {
  final double frameWidth;
  final double frameHeight;

  _VignetteBorderPainter({required this.frameWidth, required this.frameHeight});

  // L'oscurità massima raggiunta ai bordi estremi dello schermo
  static const double _targetMaxOpacity = 0.75;

  // Alzato a 45 per garantire che la curva matematica non mostri mai "scalini"
  static const int _steps = 45;

  // Calcola l'opacità totale che il gradiente deve avere ad un determinato step.
  // k=0 è il bordo esterno (più scuro), k=_steps-1 è il riquadro centrale (0.0).
  double _getTargetOpacity(int k) {
    if (k >= _steps - 1) return 0.0;

    // t va da 0.0 (interno) a 1.0 (esterno)
    final double t = 1.0 - (k / (_steps - 1));

    // Curves.easeInOut garantisce che il gradiente parta piatto da 0 e acceleri dolcemente
    final double curveT = Curves.easeInOut.transform(t);
    return _targetMaxOpacity * curveT;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final screenRect = Rect.fromLTRB(
      -100,
      -100,
      size.width + 100,
      size.height + 100,
    );

    // Partiamo da fuori lo schermo per coprire bene anche gli angoli del dispositivo
    final double startWidth = size.width * 1.3;
    final double startHeight = size.height * 1.3;

    for (int i = 0; i < _steps; i++) {
      final double currentTarget = _getTargetOpacity(i);
      final double innerTarget = _getTargetOpacity(i + 1);

      // --- LA MAGIA DELL'ALPHA BLENDING ---
      // Calcoliamo esattamente quale opacità (layerAlpha) deve avere questo strato
      // per raggiungere il 'currentTarget', sapendo che sotto di esso ci sono strati
      // che arrivano a 'innerTarget'.
      double layerAlpha = 0.0;
      if (innerTarget < 1.0) {
        layerAlpha = (currentTarget - innerTarget) / (1.0 - innerTarget);
      }
      // Sicurezza contro approssimazioni in virgola mobile
      layerAlpha = layerAlpha.clamp(0.0, 1.0);

      final Paint paint = Paint()
        ..color = Colors.black.withValues(alpha: layerAlpha)
        ..style = PaintingStyle.fill;

      // Interpola la dimensione geometrica del livello
      final double t = i / (_steps - 1);
      final double currentWidth = startWidth + (frameWidth - startWidth) * t;
      final double currentHeight =
          startHeight + (frameHeight - startHeight) * t;

      // Curvatura dinamica: più ampia all'esterno, aderente a 24 al centro
      final double currentRadius = 60.0 + (24.0 - 60.0) * t;

      final RRect hole = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: currentWidth,
          height: currentHeight,
        ),
        Radius.circular(currentRadius),
      );

      final Path path = Path()
        ..addRect(screenRect)
        ..addRRect(hole)
        ..fillType = PathFillType.evenOdd;

      // Lo strato più vicino al centro avrà letteralmente opacità 0.0!
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VignetteBorderPainter oldDelegate) =>
      oldDelegate.frameWidth != frameWidth ||
      oldDelegate.frameHeight != frameHeight;
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';

class CameraModule extends StatefulWidget {
  final MobileScannerController? controller;
  final Future<void> Function(String barcode) onScanSuccess;
  final bool scanningProgress;
  final String? scanError;
  final bool isActive;

  const CameraModule({
    super.key,
    this.controller,
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
  late final MobileScannerController _controller;

  final TextEditingController _manualCodeController = TextEditingController();
  late FocusNode _manualFocusNode;

  bool _isProcessing = false;
  bool _isManualFocused = false;
  bool _isStarting = false;
  Object? _cameraError;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller =
        widget.controller ??
        MobileScannerController(
          autoStart: false,
          detectionSpeed: DetectionSpeed.noDuplicates,
          formats: const [
            BarcodeFormat.ean13,
            BarcodeFormat.ean8,
            BarcodeFormat.qrCode,
          ],
          cameraResolution: const Size(480, 640),
        );

    _manualFocusNode = FocusNode();
    _manualFocusNode.addListener(_onManualFocusChange);

    // Avvio deterministico della fotocamera dopo il primo frame (widget montato)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isActive) {
        _startCamera();
      }
    });
  }

  @override
  void didUpdateWidget(CameraModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startCamera();
      } else {
        _controller.stop();
        if (mounted) {
          setState(() => _cameraError = null); // Reset errore al cambio tab
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Su Web, la minimizzazione/cambio scheda emette `inactive` o `hidden` invece di `paused`.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (widget.isActive) {
        _startCamera();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manualFocusNode.removeListener(_onManualFocusChange);
    _manualFocusNode.dispose();
    _manualCodeController.dispose();

    _controller.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    if (_isStarting || _controller.value.isRunning) return;
    _isStarting = true;

    if (mounted) {
      setState(() {
        _cameraError = null;
      });
    }

    try {
      await _controller.start();
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      // Su Web, il browser potrebbe tenere il video appeso. Ignoriamo questo "falso errore".
      if (errorString.contains('already running') ||
          errorString.contains('already playing')) {
        debugPrint('Web Camera already running, ignoring exception.');
      } else {
        if (mounted) {
          setState(() {
            _cameraError = e;
          });
        }
      }
    } finally {
      _isStarting = false;
    }
  }

  void _onManualFocusChange() {
    setState(() {
      _isManualFocused = _manualFocusNode.hasFocus;
    });
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
    final colorScheme = context.colorScheme;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
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
                  color: colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.scanError!,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.error,
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
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.04),
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
            Text(
              "scanner.ui.scanProduct".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                fontFamily: 'Inter',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "scanner.ui.alignBarcodeHint".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurfaceVariant,
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
                  Expanded(
                    child: Divider(
                      color: colorScheme.surfaceContainerHighest,
                      thickness: 1.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "common.actions.or".tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: colorScheme.surfaceContainerHighest,
                      thickness: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            _buildManualInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraArea() {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;
    final bool hasTorch = _isMobile;
    final double buttonOverflow = hasTorch ? 28.0 : 0.0;

    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: _controller,
      builder: (context, state, child) {
        final hasError = state.error != null || _cameraError != null;
        final currentError = state.error ?? _cameraError;

        return Stack(
          children: [
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
                  child: hasError
                      ? _buildInPageErrorOverlay(currentError)
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;
                            final double frameW = w * 0.85;
                            final double frameH = h * 0.65;

                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                // 1. Livello inferiore (Camera) con placeholder nero
                                MobileScanner(
                                  controller: _controller,
                                  onDetect: _onDetect,
                                  placeholderBuilder: (context) =>
                                      Container(color: Colors.black),
                                ),

                                // 2. Overlay Statico (visibile solo quando NON ci sono errori)
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
                                          color: colorScheme.primaryContainer,
                                        ),
                                        Container(
                                          width: 24,
                                          height: 2,
                                          color: colorScheme.primaryContainer,
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
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(
                                            color: colorScheme.primaryContainer,
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
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
                            );
                          },
                        ),
                ),
              ),
            ),

            // Pulsante Flashlight per dispositivi Mobile (attivo solo se non ci sono errori)
            if (hasTorch && !hasError)
              ValueListenableBuilder<MobileScannerState>(
                valueListenable: _controller,
                builder: (context, controllerState, _) {
                  final isTorchOn = controllerState.torchState == TorchState.on;
                  return Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Material(
                        color: isTorchOn
                            ? colorScheme.primaryContainer
                            : cardBg,
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.4),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _controller.toggleTorch(),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: Icon(
                                isTorchOn
                                    ? Icons.flashlight_on
                                    : Icons.flashlight_off,
                                size: 24,
                                color: isTorchOn
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildInPageErrorOverlay(Object? error) {
    final colorScheme = context.colorScheme;
    // Su Web i browser restituiscono stringhe d'errore incoerenti: evitiamo il parsing.
    final String cleanMessage;
    if (kIsWeb) {
      cleanMessage = "scanner.camera.permissionDeniedWeb".tr();
    } else {
      cleanMessage = "scanner.camera.permissionDeniedMobile".tr();
    }

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              cleanMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            // Su Web nessun bottone: l'utente deve agire sul browser (lucchetto URL)
            if (!kIsWeb) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  if (_isMobile) await openAppSettings();
                  await _startCamera();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('scanner.camera.openSettings'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManualInput() {
    final colorScheme = context.colorScheme;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _manualCodeController,
      builder: (context, value, child) {
        final bool hasText = value.text.trim().isNotEmpty;
        final bool showClearIcon = _isManualFocused && hasText;

        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _manualCodeController,
                focusNode: _manualFocusNode,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                ),
                decoration: InputDecoration(
                  hintText: "scanner.manualInput.hint".tr(),
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
                              icon: Icon(
                                Icons.close,
                                color: colorScheme.onSurfaceVariant,
                                size: 22,
                              ),
                              onPressed: () {
                                _manualCodeController.clear();
                                _manualFocusNode.requestFocus();
                              },
                            )
                          : Icon(
                              Icons.qr_code_scanner_rounded,
                              key: const ValueKey('barcodeIcon'),
                              color: hasText
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    ),
                              size: 22,
                            ),
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasText
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                boxShadow: hasText
                    ? [
                        BoxShadow(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [const BoxShadow(color: Colors.transparent)],
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
                        color: hasText
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
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
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Text(
            "scanner.ui.safetyIndicators".tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
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
                  "scanner.states.safe".tr(),
                  "scanner.states.glutenFree".tr(),
                  colorScheme.primaryContainer,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: _buildIndicatorItem(
                  Icons.warning_rounded,
                  "scanner.states.uncertain".tr(),
                  "scanner.states.checkLabel".tr(),
                  colorScheme.tertiaryContainer,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: _buildIndicatorItem(
                  Icons.cancel_rounded,
                  "scanner.states.unsafe".tr(),
                  "scanner.states.hasGluten".tr(),
                  colorScheme.error,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: _buildIndicatorItem(
                  Icons.help_rounded,
                  "scanner.states.unknown".tr(),
                  "scanner.states.notFound".tr(),
                  colorScheme.onSurfaceVariant,
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
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: cardBg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.04),
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
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
    final colorScheme = context.colorScheme;
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
              color: colorScheme.primaryContainer,
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
              color: colorScheme.primaryContainer,
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
              color: colorScheme.primaryContainer,
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
              color: colorScheme.primaryContainer,
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

class _VignetteBorderPainter extends CustomPainter {
  final double frameWidth;
  final double frameHeight;

  _VignetteBorderPainter({required this.frameWidth, required this.frameHeight});

  static const double _targetMaxOpacity = 0.75;
  static const int _steps = 45;

  double _getTargetOpacity(int k) {
    if (k >= _steps - 1) return 0.0;
    final double t = 1.0 - (k / (_steps - 1));
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

    final double startWidth = size.width * 1.3;
    final double startHeight = size.height * 1.3;

    for (int i = 0; i < _steps; i++) {
      final double currentTarget = _getTargetOpacity(i);
      final double innerTarget = _getTargetOpacity(i + 1);

      double layerAlpha = 0.0;
      if (innerTarget < 1.0) {
        layerAlpha = (currentTarget - innerTarget) / (1.0 - innerTarget);
      }
      layerAlpha = layerAlpha.clamp(0.0, 1.0);

      final Paint paint = Paint()
        ..color = Colors.black.withValues(alpha: layerAlpha)
        ..style = PaintingStyle.fill;

      final double t = i / (_steps - 1);
      final double currentWidth = startWidth + (frameWidth - startWidth) * t;
      final double currentHeight =
          startHeight + (frameHeight - startHeight) * t;

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

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VignetteBorderPainter oldDelegate) =>
      oldDelegate.frameWidth != frameWidth ||
      oldDelegate.frameHeight != frameHeight;
}

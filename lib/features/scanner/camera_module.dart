// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/utils.dart';
import 'widgets/widgets.dart';

export 'widgets/widgets.dart';

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
  bool _isRetrying = false;
  Object? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller =
        widget.controller ??
        MobileScannerController(
          autoStart: false,
          facing: CameraFacing.back,
          detectionSpeed:
              kIsWeb ? DetectionSpeed.normal : DetectionSpeed.noDuplicates,
          detectionTimeoutMs: 250,
          formats: const [
            BarcodeFormat.ean13,
            BarcodeFormat.ean8,
            BarcodeFormat.qrCode,
            BarcodeFormat.upcA,
            BarcodeFormat.upcE,
            BarcodeFormat.code128,
            BarcodeFormat.code39,
            BarcodeFormat.dataMatrix,
          ],
          cameraResolution: kIsWeb ? null : const Size(480, 640),
        );

    _manualFocusNode = FocusNode();
    _manualFocusNode.addListener(_onManualFocusChange);

    if (kIsWeb) {
      setupWebVisibilityListener((isVisible) {
        if (!mounted) return;
        if (isVisible) {
          if (widget.isActive) {
            _startCamera();
          }
        } else {
          _stopCamera();
        }
      });
    }

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
        _stopCamera();
        if (mounted) {
          setState(() => _cameraError = null);
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      if (widget.isActive) {
        _startCamera();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (kIsWeb) {
      removeWebVisibilityListener();
      stopWebMediaTracks();
    }
    _manualFocusNode.removeListener(_onManualFocusChange);
    _manualFocusNode.dispose();
    _manualCodeController.dispose();

    _controller.dispose();
    super.dispose();
  }

  Future<void> _stopCamera() async {
    try {
      await _controller.stop();
    } catch (e) {
      debugPrint('Error stopping camera controller: $e');
    }
    if (kIsWeb) {
      stopWebMediaTracks();
    }
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

      if (errorString.contains('already running') ||
          errorString.contains('already playing')) {
        debugPrint('Web Camera already running, ignoring exception.');
        _isStarting = false;
        return;
      }

      final category = categorizeCameraError(e);

      if (category == CameraErrorCategory.permissionDenied) {
        if (mounted) {
          setState(() => _cameraError = e);
        }
        _schedulePermissionRetry();
      } else {
        if (mounted) {
          setState(() => _cameraError = e);
        }
      }
    } finally {
      _isStarting = false;
    }
  }

  void _schedulePermissionRetry() {
    if (_isRetrying) return;
    _isRetrying = true;

    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted) {
        _isRetrying = false;
        return;
      }

      if (!widget.isActive || _controller.value.isRunning) {
        _isRetrying = false;
        return;
      }

      try {
        await _controller.start();
        if (mounted) {
          setState(() => _cameraError = null);
        }
      } catch (e) {
        final retryCategory = categorizeCameraError(e);

        if (retryCategory == CameraErrorCategory.hardwareOrMemory) {
          if (mounted) {
            setState(() => _cameraError = e);
          }
        }
      } finally {
        _isRetrying = false;
      }
    });
  }

  void _onManualFocusChange() {
    setState(() {
      _isManualFocused = _manualFocusNode.hasFocus;
    });
  }

  void _handleManualSearch() {
    if (_manualCodeController.text.trim().isEmpty) return;
    final code = _manualCodeController.text.trim();
    _manualCodeController.clear();
    _manualFocusNode.unfocus();
    widget.onScanSuccess(code);
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!widget.isActive) return;
    if (_isProcessing || widget.scanningProgress) return;
    final List<Barcode> barcodes = capture.barcodes;
    final String? raw = barcodes.firstOrNull?.rawValue?.trim();
    if (raw != null && raw.isNotEmpty) {
      _isProcessing = true;
      try {
        await widget.onScanSuccess(raw);
      } finally {
        if (mounted) {
          _isProcessing = false;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              ScannerErrorBanner(scanError: widget.scanError!),
            ],

            const SizedBox(height: 32),
            const SafetyLegendChips(),
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
            const ScannerHeader(),
            const SizedBox(height: 32),
            ScannerViewport(
              controller: _controller,
              cameraError: _cameraError,
              scanningProgress: widget.scanningProgress,
              onDetect: _onDetect,
              onStartCamera: _startCamera,
            ),

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

            ManualBarcodeField(
              controller: _manualCodeController,
              focusNode: _manualFocusNode,
              isFocused: _isManualFocused,
              scanningProgress: widget.scanningProgress,
              onSearch: _handleManualSearch,
            ),
          ],
        ),
      ),
    );
  }
}

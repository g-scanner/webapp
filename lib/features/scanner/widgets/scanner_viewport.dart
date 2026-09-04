// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import 'scanner_view_painters.dart';

export 'scanner_view_painters.dart';

/// Categoria di errore della fotocamera
enum CameraErrorCategory {
  /// Permesso negato o bloccato dall'utente/OS
  permissionDenied,

  /// Memoria piena, NotReadableError, AbortError o guasto hardware
  hardwareOrMemory,
}

/// Analizza l'eccezione della fotocamera e la mappa sulla categoria corretta.
CameraErrorCategory categorizeCameraError(Object error) {
  if (error is MobileScannerException) {
    if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
      return CameraErrorCategory.permissionDenied;
    }
  }

  final errorStr = error.toString().toLowerCase();

  // Controlli per permessi negati
  if (errorStr.contains('permission') ||
      errorStr.contains('denied') ||
      errorStr.contains('notallowederror') ||
      errorStr.contains('not allowed') ||
      errorStr.contains('securityerror') ||
      errorStr.contains('restricted') ||
      errorStr.contains('unauthorized')) {
    return CameraErrorCategory.permissionDenied;
  }

  // NotReadableError, AbortError, esaurimento memoria o fallimento hardware
  return CameraErrorCategory.hardwareOrMemory;
}

class ScannerViewport extends StatelessWidget {
  final MobileScannerController controller;
  final Object? cameraError;
  final bool scanningProgress;
  final void Function(BarcodeCapture) onDetect;
  final Future<void> Function() onStartCamera;

  const ScannerViewport({
    super.key,
    required this.controller,
    required this.cameraError,
    required this.scanningProgress,
    required this.onDetect,
    required this.onStartCamera,
  });

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;
    final bool hasTorch = _isMobile;
    final double buttonOverflow = hasTorch ? 28.0 : 0.0;

    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, child) {
        final hasError = state.error != null || cameraError != null;
        final currentError = state.error ?? cameraError;

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
                      ? _buildInPageErrorOverlay(context, currentError)
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
                                  controller: controller,
                                  onDetect: onDetect,
                                  placeholderBuilder: (context) =>
                                      Container(color: Colors.black),
                                ),

                                // 2. Overlay Statico (visibile solo quando NON ci sono errori)
                                CustomPaint(
                                  size: Size(w, h),
                                  painter: VignetteBorderPainter(
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
                                    child: _buildCorners(colorScheme),
                                  ),
                                ),
                                if (scanningProgress)
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
                valueListenable: controller,
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
                          onTap: () => controller.toggleTorch(),
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

  Widget _buildInPageErrorOverlay(BuildContext context, Object? error) {
    final colorScheme = context.colorScheme;
    final category = error != null
        ? categorizeCameraError(error)
        : CameraErrorCategory.permissionDenied;

    final String cleanMessage;
    final IconData iconData;

    switch (category) {
      case CameraErrorCategory.permissionDenied:
        iconData = Icons.error_outline;
        if (kIsWeb) {
          cleanMessage = "scanner.camera.permissionDeniedWeb".tr();
        } else {
          cleanMessage = "scanner.camera.permissionDeniedMobile".tr();
        }
        break;
      case CameraErrorCategory.hardwareOrMemory:
        iconData = Icons.memory_outlined;
        cleanMessage = "scanner.camera.hardwareOrMemoryError".tr();
        break;
    }

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, color: Colors.white, size: 48),
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
            if (!kIsWeb && category == CameraErrorCategory.permissionDenied) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  if (_isMobile) await openAppSettings();
                  await onStartCamera();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('scanner.camera.openSettings'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                ),
              ),
            ] else if (category == CameraErrorCategory.hardwareOrMemory) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  await onStartCamera();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('scanner.camera.retry'.tr()),
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

  Widget _buildCorners(ColorScheme colorScheme) {
    const double cornerLen = 28;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: CustomPaint(
            size: const Size(cornerLen, cornerLen),
            painter: CornerPainter(
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
            painter: CornerPainter(
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
            painter: CornerPainter(
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
            painter: CornerPainter(
              color: colorScheme.primaryContainer,
              alignment: Alignment.bottomRight,
            ),
          ),
        ),
      ],
    );
  }
}

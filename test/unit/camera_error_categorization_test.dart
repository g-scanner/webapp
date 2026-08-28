// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Pure Unit Tests: Camera Error Categorization

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gscanner/widgets/camera_module.dart';

void main() {
  group('Camera Error Categorization Unit Tests', () {
    test('MobileScannerException with permissionDenied is mapped to permissionDenied', () {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );
      expect(categorizeCameraError(exception), CameraErrorCategory.permissionDenied);
    });

    test('MobileScannerException with genericError is mapped to hardwareOrMemory', () {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );
      expect(categorizeCameraError(exception), CameraErrorCategory.hardwareOrMemory);
    });

    test('MobileScannerException with controllerUninitialized is mapped to hardwareOrMemory', () {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerUninitialized,
      );
      expect(categorizeCameraError(exception), CameraErrorCategory.hardwareOrMemory);
    });

    test('DOMException NotAllowedError is mapped to permissionDenied', () {
      final error = Exception('DOMException: NotAllowedError: The request is not allowed by the user agent.');
      expect(categorizeCameraError(error), CameraErrorCategory.permissionDenied);
    });

    test('DOMException SecurityError is mapped to permissionDenied', () {
      final error = Exception('SecurityError: Camera permission is restricted');
      expect(categorizeCameraError(error), CameraErrorCategory.permissionDenied);
    });

    test('String error with "permission denied" is mapped to permissionDenied', () {
      final error = Exception('Camera permission denied by operating system');
      expect(categorizeCameraError(error), CameraErrorCategory.permissionDenied);
    });

    test('DOMException NotReadableError (Safari low memory / camera busy) is mapped to hardwareOrMemory', () {
      final error = Exception('DOMException: NotReadableError: Could not start video source');
      expect(categorizeCameraError(error), CameraErrorCategory.hardwareOrMemory);
    });

    test('DOMException AbortError (OS aborted video buffer) is mapped to hardwareOrMemory', () {
      final error = Exception('DOMException: AbortError: The video stream was aborted by the browser.');
      expect(categorizeCameraError(error), CameraErrorCategory.hardwareOrMemory);
    });

    test('Low memory / buffer allocation error is mapped to hardwareOrMemory', () {
      final error = Exception('Out of memory: Failed to allocate camera frame buffer');
      expect(categorizeCameraError(error), CameraErrorCategory.hardwareOrMemory);
    });

    test('Hardware busy / in use error is mapped to hardwareOrMemory', () {
      final error = Exception('Camera resource in use or device busy');
      expect(categorizeCameraError(error), CameraErrorCategory.hardwareOrMemory);
    });

    test('Generic unknown exception defaults to hardwareOrMemory', () {
      final error = Exception('Unexpected video pipeline failure');
      expect(categorizeCameraError(error), CameraErrorCategory.hardwareOrMemory);
    });
  });
}

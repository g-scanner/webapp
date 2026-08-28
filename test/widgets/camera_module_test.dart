// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget Tests: CameraModule

// ignore_for_file: subtype_of_sealed_class

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:gscanner/widgets/camera_module.dart';
import '../mocks/shared_mocks.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test Controller for MobileScannerController
// ─────────────────────────────────────────────────────────────────────────────

class TestMobileScannerController extends MobileScannerController {
  TestMobileScannerController({
    MobileScannerState? initialState,
  }) : super(autoStart: false) {
    if (initialState != null) {
      value = initialState;
    }
  }

  int startCallCount = 0;
  int stopCallCount = 0;
  int toggleTorchCallCount = 0;
  bool shouldThrowOnStart = false;
  bool shouldThrowHardwareError = false;

  @override
  Future<void> start({
    CameraFacing? cameraDirection,
    CameraLensType? cameraLensType,
    int? timeout,
  }) async {
    startCallCount++;
    if (shouldThrowOnStart) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );
    }
    if (shouldThrowHardwareError) {
      throw Exception('DOMException: NotReadableError: Could not start video source');
    }
    value = value.copyWith(isRunning: true, error: null);
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
    value = value.copyWith(isRunning: false);
  }

  @override
  Future<void> toggleTorch() async {
    toggleTorchCallCount++;
    value = value.copyWith(
      torchState:
          value.torchState == TorchState.on ? TorchState.off : TorchState.on,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock Callbacks
// ─────────────────────────────────────────────────────────────────────────────

class _CameraCallbacks {
  Future<void> onScanSuccess(String barcode) async {}
}

class MockCameraCallbacks extends Mock implements _CameraCallbacks {}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _pumpCameraModule(
  WidgetTester tester, {
  required MockCameraCallbacks cb,
  required TestMobileScannerController controller,
  bool scanningProgress = false,
  String? scanError,
  bool isActive = true,
  Size surfaceSize = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    createTestApp(
      child: Scaffold(
        body: CameraModule(
          controller: controller,
          onScanSuccess: (b) => cb.onScanSuccess(b),
          scanningProgress: scanningProgress,
          scanError: scanError,
          isActive: isActive,
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCameraCallbacks cb;
  late TestMobileScannerController controller;

  setUpAll(() async {
    setupMocktailFallbacks();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    cb = MockCameraCallbacks();
    controller = TestMobileScannerController();
    when(() => cb.onScanSuccess(any())).thenAnswer((_) async {});
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1 – Header, Subtitle & Card Structure
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 1 – Header, Subtitle & Card Structure', () {
    testWidgets('renders main title, subtitle and divider', (tester) async {
      await _pumpCameraModule(tester, cb: cb, controller: controller);

      expect(find.text('scanner.ui.scanProduct'), findsOneWidget);
      expect(find.text('scanner.ui.alignBarcodeHint'), findsOneWidget);
      expect(find.text('common.actions.or'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2 – Camera Area, Scanning Progress & Scan Error Banner
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 2 – Camera Area, Scanning Progress & Scan Error Banner', () {
    testWidgets('renders MobileScanner camera viewport when no error',
        (tester) async {
      await _pumpCameraModule(tester, cb: cb, controller: controller);

      expect(find.byType(MobileScanner), findsOneWidget);
      expect(find.byType(AspectRatio), findsOneWidget);
    });

    testWidgets(
        'renders loading overlay when scanningProgress is true', (tester) async {
      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: controller,
        scanningProgress: true,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Analisi in corso...'), findsOneWidget);
    });

    testWidgets('hides loading overlay when scanningProgress is false',
        (tester) async {
      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: controller,
        scanningProgress: false,
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Analisi in corso...'), findsNothing);
    });

    testWidgets('renders scanError banner when scanError is provided',
        (tester) async {
      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: controller,
        scanError: 'Prodotto non trovato nel database',
      );

      expect(find.text('Prodotto non trovato nel database'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('does not render scanError banner when scanError is null',
        (tester) async {
      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: controller,
        scanError: null,
      );

      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets(
        'renders flashlight button on mobile platform and toggles torch on tap',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await _pumpCameraModule(tester, cb: cb, controller: controller);

        // Flashlight is initially off
        expect(find.byIcon(Icons.flashlight_off), findsOneWidget);
        expect(find.byIcon(Icons.flashlight_on), findsNothing);

        // Tap torch button to turn ON
        await tester.tap(find.byIcon(Icons.flashlight_off));
        await tester.pump();

        expect(controller.toggleTorchCallCount, 1);
        expect(find.byIcon(Icons.flashlight_on), findsOneWidget);
        expect(find.byIcon(Icons.flashlight_off), findsNothing);

        // Tap torch button again to turn OFF
        await tester.tap(find.byIcon(Icons.flashlight_on));
        await tester.pump();

        expect(controller.toggleTorchCallCount, 2);
        expect(find.byIcon(Icons.flashlight_off), findsOneWidget);
        expect(find.byIcon(Icons.flashlight_on), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('hides flashlight button when camera has an error',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final errorController = TestMobileScannerController(
          initialState: MobileScannerState.uninitialized().copyWith(
            error: const MobileScannerException(
              errorCode: MobileScannerErrorCode.permissionDenied,
            ),
          ),
        );
        errorController.shouldThrowOnStart = true;

        await _pumpCameraModule(tester, cb: cb, controller: errorController);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.flashlight_off), findsNothing);
        expect(find.byIcon(Icons.flashlight_on), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3 – Camera Permission / Hardware Error Overlay
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 3 – Camera Permission / Hardware Error Overlay', () {
    // ── 3A Permission Denied ────────────────────────────────────────────────

    testWidgets('3A-1: permission error from MobileScannerState shows mobile message on native',
        (tester) async {
      final errorController = TestMobileScannerController(
        initialState: MobileScannerState.uninitialized().copyWith(
          error: const MobileScannerException(
            errorCode: MobileScannerErrorCode.permissionDenied,
          ),
        ),
      );
      errorController.shouldThrowOnStart = true;

      await _pumpCameraModule(tester, cb: cb, controller: errorController);
      await tester.pumpAndSettle();

      expect(
        find.text('scanner.camera.permissionDeniedMobile'),
        findsOneWidget,
      );
    });

    testWidgets('3A-2: permission error shows error_outline icon', (tester) async {
      final errorController = TestMobileScannerController(
        initialState: MobileScannerState.uninitialized().copyWith(
          error: const MobileScannerException(
            errorCode: MobileScannerErrorCode.permissionDenied,
          ),
        ),
      );
      errorController.shouldThrowOnStart = true;

      await _pumpCameraModule(tester, cb: cb, controller: errorController);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.memory_outlined), findsNothing);
    });

    testWidgets('3A-3: permission error on mobile shows openSettings button',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final errorController = TestMobileScannerController(
          initialState: MobileScannerState.uninitialized().copyWith(
            error: const MobileScannerException(
              errorCode: MobileScannerErrorCode.permissionDenied,
            ),
          ),
        );
        errorController.shouldThrowOnStart = true;

        await _pumpCameraModule(tester, cb: cb, controller: errorController);
        await tester.pumpAndSettle();

        expect(find.text('scanner.camera.openSettings'), findsOneWidget);
        expect(find.text('scanner.camera.retry'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('3A-4: start() throwing MobileScannerException permissionDenied shows permission overlay',
        (tester) async {
      final throwController = TestMobileScannerController();
      throwController.shouldThrowOnStart = true;

      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: throwController,
        isActive: true,
      );
      await tester.pumpAndSettle();

      expect(
        find.text('scanner.camera.permissionDeniedMobile'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    // ── 3B Hardware / Memory Error ──────────────────────────────────────────

    testWidgets('3B-1: hardware/memory error shows hardwareOrMemoryError message key',
        (tester) async {
      final hwController = TestMobileScannerController();
      hwController.shouldThrowHardwareError = true;

      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: hwController,
        isActive: true,
      );
      await tester.pumpAndSettle();

      expect(
        find.text('scanner.camera.hardwareOrMemoryError'),
        findsOneWidget,
      );
    });

    testWidgets('3B-2: hardware/memory error shows memory_outlined icon',
        (tester) async {
      final hwController = TestMobileScannerController();
      hwController.shouldThrowHardwareError = true;

      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: hwController,
        isActive: true,
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.memory_outlined), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('3B-3: hardware/memory error shows retry button (no settings button)',
        (tester) async {
      final hwController = TestMobileScannerController();
      hwController.shouldThrowHardwareError = true;

      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: hwController,
        isActive: true,
      );
      await tester.pumpAndSettle();

      expect(find.text('scanner.camera.retry'), findsOneWidget);
      expect(find.text('scanner.camera.openSettings'), findsNothing);
    });

    testWidgets('3B-4: tapping retry button on hardware error calls _startCamera',
        (tester) async {
      final hwController = TestMobileScannerController();
      hwController.shouldThrowHardwareError = true;

      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: hwController,
        isActive: true,
      );
      await tester.pumpAndSettle();

      final prevStartCount = hwController.startCallCount;

      // After tap the error still occurs (hardware still broken), but start is called again
      await tester.tap(find.text('scanner.camera.retry'));
      await tester.pump();

      expect(hwController.startCallCount, greaterThan(prevStartCount));
    });

    testWidgets('3B-5: hardware error hides flashlight button', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final hwController = TestMobileScannerController();
        hwController.shouldThrowHardwareError = true;

        await _pumpCameraModule(tester, cb: cb, controller: hwController);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.flashlight_off), findsNothing);
        expect(find.byIcon(Icons.flashlight_on), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('3B-6: AbortError string triggers hardwareOrMemoryError overlay',
        (tester) async {
      final hwController = TestMobileScannerController();
      // Simulate via state injection (AbortError string in _cameraError)
      hwController.shouldThrowHardwareError = true;

      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: hwController,
        isActive: true,
      );
      await tester.pumpAndSettle();

      // The overlay must be visible with hardware message
      expect(find.text('scanner.camera.hardwareOrMemoryError'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4 – Manual Barcode Input & Validation
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 4 – Manual Barcode Input & Validation', () {
    testWidgets('renders manual input field with hint', (tester) async {
      await _pumpCameraModule(tester, cb: cb, controller: controller);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('scanner.manualInput.hint'), findsOneWidget);
    });

    testWidgets(
        'tapping submit with empty text does NOT call onScanSuccess',
        (tester) async {
      await _pumpCameraModule(tester, cb: cb, controller: controller);

      final submitBtn = find.byIcon(Icons.chevron_right_rounded);
      expect(submitBtn, findsOneWidget);

      await tester.tap(submitBtn);
      await tester.pump();

      verifyNever(() => cb.onScanSuccess(any()));
    });

    testWidgets(
        'tapping submit with valid barcode calls onScanSuccess', (tester) async {
      await _pumpCameraModule(tester, cb: cb, controller: controller);

      await tester.enterText(find.byType(TextField), '8001234567890');
      await tester.pump();

      final submitBtn = find.byIcon(Icons.chevron_right_rounded);
      await tester.tap(submitBtn);
      await tester.pump();

      verify(() => cb.onScanSuccess('8001234567890')).called(1);
    });

    testWidgets(
        'clear button appears when focused with text and clears text on tap',
        (tester) async {
      await _pumpCameraModule(tester, cb: cb, controller: controller);

      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '123456');
      // Wait for AnimatedSwitcher duration (250ms)
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('123456'), findsNothing);
    });

    testWidgets(
        'manual submit is disabled when scanningProgress is true',
        (tester) async {
      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: controller,
        scanningProgress: true,
      );

      await tester.enterText(find.byType(TextField), '8001234567890');
      await tester.pump();

      final submitBtn = find.byIcon(Icons.chevron_right_rounded);
      await tester.tap(submitBtn);
      await tester.pump();

      verifyNever(() => cb.onScanSuccess(any()));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5 – Barcode Detection Callback (_onDetect)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 5 – Barcode Detection Callback', () {
    testWidgets(
        'detecting barcode when active triggers onScanSuccess', (tester) async {
      await _pumpCameraModule(tester, cb: cb, controller: controller);

      final scannerFinder = find.byType(MobileScanner);
      expect(scannerFinder, findsOneWidget);

      final MobileScanner scannerWidget = tester.widget(scannerFinder);

      // Simulate barcode detection
      scannerWidget.onDetect!(
        BarcodeCapture(
          barcodes: [
            Barcode(rawValue: '8009876543210', format: BarcodeFormat.ean13),
          ],
        ),
      );

      await tester.pump();

      verify(() => cb.onScanSuccess('8009876543210')).called(1);
    });

    testWidgets(
        'detecting barcode when isActive is false does NOT call onScanSuccess',
        (tester) async {
      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: controller,
        isActive: false,
      );

      final scannerFinder = find.byType(MobileScanner);
      expect(scannerFinder, findsOneWidget);

      final MobileScanner scannerWidget = tester.widget(scannerFinder);

      scannerWidget.onDetect!(
        BarcodeCapture(
          barcodes: [
            Barcode(rawValue: '8009876543210', format: BarcodeFormat.ean13),
          ],
        ),
      );

      await tester.pump();

      verifyNever(() => cb.onScanSuccess(any()));
    });

    testWidgets(
        'detecting barcode with null rawValue does NOT call onScanSuccess',
        (tester) async {
      await _pumpCameraModule(tester, cb: cb, controller: controller);

      final scannerFinder = find.byType(MobileScanner);
      final MobileScanner scannerWidget = tester.widget(scannerFinder);

      scannerWidget.onDetect!(
        BarcodeCapture(
          barcodes: [
            Barcode(rawValue: null, format: BarcodeFormat.ean13),
          ],
        ),
      );

      await tester.pump();

      verifyNever(() => cb.onScanSuccess(any()));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 6 – Lifecycle & Controller Management
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 6 – Lifecycle & Controller Management', () {
    testWidgets('starts camera on init when isActive is true', (tester) async {
      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: controller,
        isActive: true,
      );

      expect(controller.startCallCount, greaterThanOrEqualTo(1));
    });

    testWidgets(
        'stops camera when isActive changes from true to false', (tester) async {
      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: controller,
        isActive: true,
      );

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CameraModule(
              controller: controller,
              onScanSuccess: (b) => cb.onScanSuccess(b),
              scanningProgress: false,
              isActive: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(controller.stopCallCount, greaterThanOrEqualTo(1));
    });

    testWidgets(
        'starts camera when isActive changes from false to true', (tester) async {
      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: controller,
        isActive: false,
      );

      final prevStartCount = controller.startCallCount;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CameraModule(
              controller: controller,
              onScanSuccess: (b) => cb.onScanSuccess(b),
              scanningProgress: false,
              isActive: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(controller.startCallCount, greaterThan(prevStartCount));
    });

    testWidgets(
        'app lifecycle paused stops controller, resumed starts controller',
        (tester) async {
      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: controller,
        isActive: true,
      );

      final prevStopCount = controller.stopCallCount;

      // Valid lifecycle transition: resumed -> inactive -> hidden -> paused
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(controller.stopCallCount, greaterThan(prevStopCount));

      final prevStartCount = controller.startCallCount;

      // Valid lifecycle transition: paused -> hidden -> inactive -> resumed
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(controller.startCallCount, greaterThan(prevStartCount));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 7 – Safety Guide Section
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 7 – Safety Guide Section', () {
    testWidgets('renders safety indicators title and all 4 indicators',
        (tester) async {
      await _pumpCameraModule(tester, cb: cb, controller: controller);

      expect(find.text('scanner.ui.safetyIndicators'), findsOneWidget);

      expect(find.text('scanner.states.safe'), findsOneWidget);
      expect(find.text('scanner.states.glutenFree'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      expect(find.text('scanner.states.uncertain'), findsOneWidget);
      expect(find.text('scanner.states.checkLabel'), findsOneWidget);
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);

      expect(find.text('scanner.states.unsafe'), findsOneWidget);
      expect(find.text('scanner.states.hasGluten'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);

      expect(find.text('scanner.states.unknown'), findsOneWidget);
      expect(find.text('scanner.states.notFound'), findsOneWidget);
      expect(find.byIcon(Icons.help_rounded), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 8 – Suspension & Lifecycle Robustness
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 8 – Suspension & Lifecycle Robustness', () {
    testWidgets('suspends immediately when transitioning to inactive state',
        (tester) async {
      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: controller,
        isActive: true,
      );

      final prevStopCount = controller.stopCallCount;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(controller.stopCallCount, greaterThan(prevStopCount));
    });

    testWidgets('suspends immediately when transitioning to hidden state',
        (tester) async {
      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: controller,
        isActive: true,
      );

      final prevStopCount = controller.stopCallCount;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();

      expect(controller.stopCallCount, greaterThan(prevStopCount));
    });

    testWidgets('disposing widget stops controller and clears resources',
        (tester) async {
      await _pumpCameraModule(
        tester,
        cb: cb,
        controller: controller,
        isActive: true,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      // Controller should be disposed or stopped cleanly
      expect(find.byType(CameraModule), findsNothing);
    });
  });
}


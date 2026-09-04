// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Pure Unit Tests: Web Camera Helper Stubs & Suspension

import 'package:flutter_test/flutter_test.dart';
import 'package:gscanner/core/utils/web_camera_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Web Camera Helper Unit Tests', () {
    test('stopWebMediaTracks executes without exceptions on non-web platform', () {
      expect(() => stopWebMediaTracks(), returnsNormally);
    });

    test('setupWebVisibilityListener registers callback safely on non-web platform', () {
      bool called = false;
      expect(
        () => setupWebVisibilityListener((isVisible) {
          called = isVisible;
        }),
        returnsNormally,
      );
      expect(called, isFalse);
    });

    test('removeWebVisibilityListener unregisters callback safely on non-web platform', () {
      expect(() => removeWebVisibilityListener(), returnsNormally);
    });

    test('multiple sequential calls to stopWebMediaTracks do not throw', () {
      for (int i = 0; i < 5; i++) {
        expect(() => stopWebMediaTracks(), returnsNormally);
      }
    });
  });
}

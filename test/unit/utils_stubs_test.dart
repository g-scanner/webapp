// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Pure Unit Tests: Utils Platform Stubs

import 'package:flutter_test/flutter_test.dart';
import 'package:gscanner/utils/camera_permission_stub.dart';
import 'package:gscanner/utils/popup_tracker_stub.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Utils Platform Stubs Unit Tests', () {
    test('queryWebCameraPermission returns granted on native platforms', () async {
      final status = await queryWebCameraPermission();
      expect(status, 'granted');
    });

    test('jsIsLastPopupClosed returns false on native platforms', () {
      final isClosed = jsIsLastPopupClosed();
      expect(isClosed, isFalse);
    });
  });
}

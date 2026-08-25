// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Pure Unit Tests: ModularAssetLoader

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gscanner/utils/modular_asset_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ModularAssetLoader Unit Tests', () {
    const loader = ModularAssetLoader();

    test('loads and merges all Italian modular locale JSON files into a single map', () async {
      final result = await loader.load('assets/locales', const Locale('it'));

      expect(result, isNotEmpty);
      // Verify all 10 modular namespaces are present in the merged dictionary
      final expectedModules = [
        'auth',
        'common',
        'database',
        'history',
        'legal',
        'product',
        'report',
        'scanner',
        'settings',
        'sync',
      ];

      for (final module in expectedModules) {
        expect(result.containsKey(module), isTrue, reason: 'Missing module namespace: $module');
        expect(result[module], isA<Map<String, dynamic>>(), reason: 'Module $module is not a Map');
      }
    });

    test('retrieves nested translation keys correctly from merged map', () async {
      final result = await loader.load('assets/locales', const Locale('it'));

      final authMap = result['auth'] as Map<String, dynamic>;
      expect(authMap['social'], isNotNull);

      final productMap = result['product'] as Map<String, dynamic>;
      expect(productMap['analysis'], isNotNull);

      final commonMap = result['common'] as Map<String, dynamic>;
      expect(commonMap['appName'], isNotNull);
    });

    test('returns empty map when locale has no matching json asset files (e.g. en, xx)', () async {
      final resultEn = await loader.load('assets/locales', const Locale('en'));
      expect(resultEn, isEmpty);

      final resultXx = await loader.load('assets/locales', const Locale('xx'));
      expect(resultXx, isEmpty);
    });
  });
}

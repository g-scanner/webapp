// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Pure Unit Tests: OffApiClient

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:gscanner/services/off_api_client.dart';
import '../mocks/shared_mocks.dart';

// ─── helpers ──────────────────────────────────────────────────────────────────

http.Response _fakeOkResponse(String barcode) => http.Response(
      '''{"status":1,"product":{"_id":"$barcode","product_name":"Test Product"}}''',
      200,
    );

http.Response _fake404Response() => http.Response(
      '{"status":0,"status_verbose":"product not found"}',
      404,
    );

http.Response _fake500Response() => http.Response('Internal Server Error', 500);

http.Response _fakeMalformedJson() =>
    http.Response('{ not valid json %%', 200);

// ─── test suite ───────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHttpClient mockClient;

  setUp(() {
    mockClient = MockHttpClient();
    setupMocktailFallbacks();
  });

  tearDown(() => reset(mockClient));

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1 – URI Construction (native, no fields)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 1 – URI Construction (native platform)', () {
    test('builds correct HTTPS URI for world.openfoodfacts.org with barcode path', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _fakeOkResponse('8001234567890'));

      await OffApiClient.getProduct('8001234567890', client: mockClient);

      final capturedUri = verify(
        () => mockClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured.single as Uri;

      expect(capturedUri.host, 'world.openfoodfacts.org');
      expect(capturedUri.path, '/api/v2/product/8001234567890.json');
      expect(capturedUri.queryParameters, isEmpty);
    });

    test('appends fields as comma-separated query parameter when fields list is provided', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _fakeOkResponse('111'));

      await OffApiClient.getProduct(
        '111',
        fields: ['product_name', 'ingredients_text', 'allergens_tags'],
        client: mockClient,
      );

      final capturedUri = verify(
        () => mockClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured.single as Uri;

      expect(
        capturedUri.queryParameters['fields'],
        'product_name,ingredients_text,allergens_tags',
      );
    });

    test('sends NO fields query param when fields list is null', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _fakeOkResponse('222'));

      await OffApiClient.getProduct('222', fields: null, client: mockClient);

      final capturedUri = verify(
        () => mockClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured.single as Uri;

      expect(capturedUri.queryParameters, isEmpty);
    });

    test('sends NO fields query param when fields list is empty', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _fakeOkResponse('333'));

      await OffApiClient.getProduct('333', fields: [], client: mockClient);

      final capturedUri = verify(
        () => mockClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured.single as Uri;

      expect(capturedUri.queryParameters, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2 – Headers
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 2 – Headers', () {
    test('sends User-Agent and Accept headers on native platform (kIsWeb = false)', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _fakeOkResponse('444'));

      await OffApiClient.getProduct('444', client: mockClient);

      final capturedHeaders = verify(
        () => mockClient.get(any(), headers: captureAny(named: 'headers')),
      ).captured.single as Map<String, String>;

      // On non-web (test runner), expect User-Agent header
      expect(capturedHeaders['Accept'], 'application/json');
      // User-Agent is present only when kIsWeb == false (test host = Windows)
      expect(capturedHeaders.containsKey('User-Agent'), isTrue);
      expect(capturedHeaders['User-Agent'], contains('G-Scanner'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3 – Timeout Handling
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 3 – Timeout Handling', () {
    test('returns response directly when timeout is null (no timeout wrapper)', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _fakeOkResponse('555'));

      final res = await OffApiClient.getProduct(
        '555',
        timeout: null,
        client: mockClient,
      );

      expect(res.statusCode, 200);
    });

    test('wraps request with .timeout() when timeout Duration is provided', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _fakeOkResponse('666'));

      final res = await OffApiClient.getProduct(
        '666',
        timeout: const Duration(seconds: 10),
        client: mockClient,
      );

      expect(res.statusCode, 200);
    });

    test('throws TimeoutException when server takes longer than timeout', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 500));
          return _fakeOkResponse('777');
        },
      );

      expect(
        () => OffApiClient.getProduct(
          '777',
          timeout: const Duration(milliseconds: 10),
          client: mockClient,
        ),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4 – HTTP Response Codes
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 4 – HTTP Response Codes', () {
    test('returns 200 response body as-is for a found product', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _fakeOkResponse('8001234567890'));

      final res = await OffApiClient.getProduct(
        '8001234567890',
        client: mockClient,
      );

      expect(res.statusCode, 200);
      expect(res.body, contains('"status":1'));
      expect(res.body, contains('"product_name":"Test Product"'));
    });

    test('returns 404 response when product is not in OFF database', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _fake404Response());

      final res = await OffApiClient.getProduct('0000000000000', client: mockClient);

      expect(res.statusCode, 404);
      expect(res.body, contains('"status":0'));
    });

    test('returns 500 response on server error', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _fake500Response());

      final res = await OffApiClient.getProduct('9999', client: mockClient);

      expect(res.statusCode, 500);
    });

    test('returns 200 with malformed JSON body without throwing (parsing is caller responsibility)', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _fakeMalformedJson());

      final res = await OffApiClient.getProduct('1111', client: mockClient);

      // OffApiClient does NOT parse — it returns the raw response
      expect(res.statusCode, 200);
      expect(res.body, contains('not valid json'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5 – Network Errors
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 5 – Network Errors', () {
    test('propagates SocketException on no network / unreachable host', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(const SocketException('Network unreachable'));

      expect(
        () => OffApiClient.getProduct('2222', client: mockClient),
        throwsA(isA<SocketException>()),
      );
    });

    test('propagates generic Exception thrown by client', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(Exception('Unexpected error'));

      expect(
        () => OffApiClient.getProduct('3333', client: mockClient),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 6 – URI Construction Edge Cases
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 6 – URI Construction Edge Cases', () {
    test('handles very long numeric barcode (EAN-13)', () async {
      const barcode = '1234567890123';
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _fakeOkResponse(barcode));

      await OffApiClient.getProduct(barcode, client: mockClient);

      final capturedUri = verify(
        () => mockClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured.single as Uri;

      expect(capturedUri.path, '/api/v2/product/$barcode.json');
    });

    test('handles single-field list without trailing comma', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _fakeOkResponse('4444'));

      await OffApiClient.getProduct('4444', fields: ['product_name'], client: mockClient);

      final capturedUri = verify(
        () => mockClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured.single as Uri;

      expect(capturedUri.queryParameters['fields'], 'product_name');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 7 – Web Platform Logic (Proxy & Headers via isWebOverride)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 7 – Web Platform Logic', () {
    const testProxy = 'https://corsproxy.io/?https://world.openfoodfacts.org';

    test('Web: excludes User-Agent from headers to avoid CORS preflight issues', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _fakeOkResponse('999'));

      await OffApiClient.getProduct(
        '999',
        client: mockClient,
        isWebOverride: true,
        proxyBaseUrlOverride: testProxy,
      );

      final capturedHeaders = verify(
        () => mockClient.get(any(), headers: captureAny(named: 'headers')),
      ).captured.single as Map<String, String>;

      expect(capturedHeaders['Accept'], 'application/json');
      expect(capturedHeaders.containsKey('User-Agent'), isFalse);
    });

    test('Web: constructs URI using default CORS proxy', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _fakeOkResponse('888'));

      await OffApiClient.getProduct(
        '888',
        client: mockClient,
        isWebOverride: true,
        proxyBaseUrlOverride: testProxy,
      );

      final capturedUri = verify(
        () => mockClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured.single as Uri;

      expect(
        capturedUri.toString(),
        'https://corsproxy.io/?https://world.openfoodfacts.org/api/v2/product/888.json',
      );
    });

    test('Web: appends query parameters cleanly when using CORS proxy', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _fakeOkResponse('888'));

      await OffApiClient.getProduct(
        '888',
        fields: ['product_name', 'brands'],
        client: mockClient,
        isWebOverride: true,
        proxyBaseUrlOverride: testProxy,
      );

      final capturedUri = verify(
        () => mockClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured.single as Uri;

      expect(
        capturedUri.queryParameters['fields'],
        'product_name,brands',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 8 – Native HTTP Fallback (client == null)
  // ═══════════════════════════════════════════════════════════════════════════
  group('GROUP 8 – Native HTTP Fallback', () {
    test('uses standard http.get when no injected client is provided', () async {
      await http.runWithClient(() async {
        final res = await OffApiClient.getProduct('0000000000000');
        expect(res.statusCode, 200);
      }, () {
        final client = MockHttpClient();
        when(() => client.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => _fakeOkResponse('0000000000000'));
        return client;
      });
    });
  });
}


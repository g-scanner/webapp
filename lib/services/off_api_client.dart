// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:http/http.dart' as http;

class OffApiClient {
  static const String _userAgent =
      'G-Scanner/1.0 (https://g-scanner.github.io)';

  static const String _webProxyBaseUrl = String.fromEnvironment(
    'OFF_PROXY_BASE_URL',
    defaultValue: '',
  );

  static Map<String, String> _headers({bool? isWebOverride}) {
    final bool web = isWebOverride ?? kIsWeb;
    if (web) {
      return const {'Accept': 'application/json'};
    }

    return const {'User-Agent': _userAgent, 'Accept': 'application/json'};
  }

  static Uri _buildProductUri(
    String barcode, {
    Map<String, String>? query,
    bool? isWebOverride,
    String? proxyBaseUrlOverride,
  }) {
    final bool web = isWebOverride ?? kIsWeb;
    final path = '/api/v2/product/$barcode.json';

    if (web) {
      final String proxy = (proxyBaseUrlOverride ?? _webProxyBaseUrl).trim();
      assert(
        proxy.isNotEmpty,
        'OFF_PROXY_BASE_URL must be set via --dart-define for web builds. '
        'Run: flutter build web --dart-define=OFF_PROXY_BASE_URL=https://your-proxy.workers.dev',
      );
      if (proxy.isEmpty) {
        throw StateError(
          'OFF_PROXY_BASE_URL is not configured. '
          'Pass --dart-define=OFF_PROXY_BASE_URL=<url> when building for web.',
        );
      }
      final String fullUrl = proxy.endsWith('/') || proxy.contains('?')
          ? '$proxy$path'
          : '$proxy/$path';
      return Uri.parse(fullUrl).replace(queryParameters: query);
    }

    return Uri.https('world.openfoodfacts.org', path, query);
  }

  static Future<http.Response> getProduct(
    String barcode, {
    List<String>? fields,
    Duration? timeout,
    http.Client? client,
    @visibleForTesting bool? isWebOverride,
    @visibleForTesting String? proxyBaseUrlOverride,
  }) async {
    final query = fields == null || fields.isEmpty
        ? null
        : {'fields': fields.join(',')};

    final uri = _buildProductUri(
      barcode,
      query: query,
      isWebOverride: isWebOverride,
      proxyBaseUrlOverride: proxyBaseUrlOverride,
    );
    final headers = _headers(isWebOverride: isWebOverride);

    final request = client != null
        ? client.get(uri, headers: headers)
        : http.get(uri, headers: headers);

    if (timeout == null) {
      return request;
    }

    return request.timeout(timeout);
  }
}

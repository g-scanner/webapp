// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class OffApiClient {
  static const String _userAgent =
      'G-Scanner/1.0 (https://g-scanner.github.io)';

  static const String _webProxyBaseUrl = String.fromEnvironment(
    'OFF_PROXY_BASE_URL',
    defaultValue: '',
  );

  static Map<String, String> _headers() {
    if (kIsWeb) {
      return const {'Accept': 'application/json'};
    }

    return const {'User-Agent': _userAgent, 'Accept': 'application/json'};
  }

  static Uri _buildProductUri(String barcode, {Map<String, String>? query}) {
    final path = '/api/v2/product/$barcode.json';

    if (kIsWeb) {
      final String proxy = _webProxyBaseUrl.trim().isNotEmpty
          ? _webProxyBaseUrl
          : 'https://corsproxy.io/?https://world.openfoodfacts.org';
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
  }) async {
    final query = fields == null || fields.isEmpty
        ? null
        : {'fields': fields.join(',')};
    final request = http.get(
      _buildProductUri(barcode, query: query),
      headers: _headers(),
    );

    if (timeout == null) {
      return request;
    }

    return request.timeout(timeout);
  }
}

// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

const OFF_BASE_URL = 'https://world.openfoodfacts.org';
const GITHUB_OFFLINE_BASE_URL = 'https://github.com/g-scanner/webapp/releases/download/offline-data';
const USER_AGENT = 'G-Scanner/1.0 (https://g-scanner.github.io)';

function buildCorsHeaders(origin = '*') {
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Accept, Content-Type',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };
}

function isAllowedProductPath(pathname) {
  return pathname.startsWith('/api/v2/product/') && pathname.endsWith('.json');
}

function isAllowedOfflineDataPath(pathname) {
  return pathname.startsWith('/offline-data/');
}

export default {
  async fetch(request) {
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: buildCorsHeaders(),
      });
    }

    if (request.method !== 'GET') {
      return new Response('Method not allowed', {
        status: 405,
        headers: {
          ...buildCorsHeaders(),
          Allow: 'GET, OPTIONS',
        },
      });
    }

    if (isAllowedOfflineDataPath(url.pathname)) {
      const fileName = url.pathname.replace('/offline-data/', '');
      const originUrl = new URL(fileName, `${GITHUB_OFFLINE_BASE_URL}/`);
      const upstreamResponse = await fetch(originUrl.toString(), {
        headers: {
          'User-Agent': USER_AGENT,
        },
      });

      const responseHeaders = new Headers(upstreamResponse.headers);
      Object.entries(buildCorsHeaders()).forEach(([key, value]) => {
        responseHeaders.set(key, value);
      });
      responseHeaders.set('Cache-Control', 'public, max-age=86400');

      return new Response(upstreamResponse.body, {
        status: upstreamResponse.status,
        statusText: upstreamResponse.statusText,
        headers: responseHeaders,
      });
    }

    if (!isAllowedProductPath(url.pathname)) {
      return new Response('Not found', {
        status: 404,
        headers: buildCorsHeaders(),
      });
    }

    const originUrl = new URL(url.pathname + url.search, OFF_BASE_URL);
    const upstreamResponse = await fetch(originUrl.toString(), {
      headers: {
        Accept: 'application/json',
        'User-Agent': USER_AGENT,
      },
      cf: {
        cacheEverything: true,
        cacheTtl: 3600,
      },
    });

    const responseHeaders = new Headers(upstreamResponse.headers);
    Object.entries(buildCorsHeaders()).forEach(([key, value]) => {
      responseHeaders.set(key, value);
    });
    responseHeaders.set('Cache-Control', 'public, max-age=3600');

    return new Response(upstreamResponse.body, {
      status: upstreamResponse.status,
      statusText: upstreamResponse.statusText,
      headers: responseHeaders,
    });
  },
};
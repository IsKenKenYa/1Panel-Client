import 'dart:io';

import '../config/api_config.dart';
import '../config/api_constants.dart';
import 'onepanel_auth_headers.dart';

class OnePanelWebSocketConnector {
  const OnePanelWebSocketConnector._();

  static Future<WebSocket> connect({
    required ApiConfig config,
    required String path,
    Map<String, String> queryParameters = const <String, String>{},
  }) async {
    final headers = <String, dynamic>{
      ...OnePanelAuthHeaders.build(config.apiKey),
      'User-Agent': ApiConstants.userAgent,
    };

    HttpClient? customClient;
    if (config.allowInsecureTls) {
      customClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate _, String __, int ___) => true;
    }

    return WebSocket.connect(
      _buildUri(
        baseUrl: config.url,
        path: path,
        queryParameters: queryParameters,
      ).toString(),
      headers: headers,
      customClient: customClient,
    );
  }

  static Uri buildUri({
    required ApiConfig config,
    required String path,
    Map<String, String> queryParameters = const <String, String>{},
  }) {
    return _buildUri(
      baseUrl: config.url,
      path: path,
      queryParameters: queryParameters,
    );
  }

  static Uri _buildUri({
    required String baseUrl,
    required String path,
    required Map<String, String> queryParameters,
  }) {
    final baseUri = Uri.parse(baseUrl);
    final normalizedBasePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return baseUri.replace(
      scheme: baseUri.scheme == 'https' ? 'wss' : 'ws',
      path: '$normalizedBasePath$normalizedPath',
      queryParameters:
          queryParameters.isEmpty ? null : Map<String, String>.from(queryParameters),
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../config/api_constants.dart';
import 'onepanel_auth_headers.dart';

class OnePanelWebSocketConnector {
  Future<WebSocket?>? _opening;
  HttpClient? _handshake;
  WebSocket? socket;
  StreamSubscription<dynamic>? _subscription;
  int _generation = 0;

  Future<WebSocket?> connect({
    ApiConfig? config,
    required String path,
    Map<String, String> queryParameters = const <String, String>{},
    required void Function(dynamic) onData,
    required void Function(Object, StackTrace) onError,
    void Function()? onConnected,
    void Function()? onDone,
  }) {
    if (socket != null) return Future.value(socket);
    final generation = _generation;
    Future<WebSocket?> open() async {
      if (kIsWeb) {
        throw UnsupportedError('浏览器 WebSocket 无法发送 1Panel 认证请求头，请在面板网页中使用此功能。');
      }
      final server = config ?? await ApiConfigManager.getCurrentConfig();
      if (_generation != generation) return null;
      if (server == null) throw StateError('No API config available');
      server.requireOnePanel();
      const timeout = Duration(seconds: ApiConstants.connectTimeout);
      final client = HttpClient()..connectionTimeout = timeout;
      _handshake = client;
      if (server.allowInsecureTls) {
        client.badCertificateCallback = (_, __, ___) => true;
      }
      try {
        final uri = buildUri(
            config: server, path: path, queryParameters: queryParameters);
        final connected = await WebSocket.connect(
          uri.toString(),
          headers: {
            ...OnePanelAuthHeaders.build(server.apiKey),
            'User-Agent': ApiConstants.userAgent,
          },
          customClient: client,
        ).timeout(timeout);
        if (_generation != generation) {
          await connected.close();
          return null;
        }
        socket = connected;
        void fail(Object error, StackTrace trace) {
          if (socket != connected) return;
          unawaited(close());
          onError(error, trace);
        }

        _subscription = connected.listen(
            (frame) {
              if (socket != connected) return;
              try {
                onData(frame);
              } on FormatException catch (_, trace) {
                fail(const FormatException('WebSocket 数据格式无效'), trace);
              }
            },
            onError: fail,
            onDone: () {
              if (socket != connected) return;
              socket = null;
              _subscription = null;
              onDone?.call();
            });
        onConnected?.call();
        return connected;
      } on WebSocketException {
        if (_generation != generation) return null;
        throw const WebSocketException('WebSocket 握手失败，请检查面板地址和认证设置');
      } on HttpException {
        if (_generation != generation) return null;
        throw const WebSocketException('面板在 WebSocket 握手期间中断连接');
      } on FormatException {
        if (_generation != generation) return null;
        throw const FormatException('面板 WebSocket 地址无效');
      } catch (_) {
        if (_generation != generation) return null;
        rethrow;
      } finally {
        client.close(force: true);
        if (_generation == generation) _handshake = null;
      }
    }

    return _opening ??= open().whenComplete(() {
      if (_generation == generation) _opening = null;
    });
  }

  Future<void> close() async {
    _generation++;
    _opening = null;
    _handshake?.close(force: true);
    _handshake = null;
    final subscription = _subscription;
    final connected = socket;
    _subscription = null;
    socket = null;
    await Future.wait<void>([
      if (subscription != null) subscription.cancel(),
      if (connected != null) connected.close(),
    ]);
  }

  static Uri buildUri({
    required ApiConfig config,
    required String path,
    Map<String, String> queryParameters = const <String, String>{},
  }) {
    final baseUri = Uri.parse(config.url);
    final normalizedBasePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return Uri(
      scheme: baseUri.scheme == 'https' ? 'wss' : 'ws',
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: '$normalizedBasePath$normalizedPath',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }
}

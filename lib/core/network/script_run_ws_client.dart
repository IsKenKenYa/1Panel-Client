import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import '../config/api_constants.dart';
import 'onepanel_auth_headers.dart';

class ScriptRunWsClient {
  ScriptRunWsClient();

  final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  final StreamController<bool> _runningController =
      StreamController<bool>.broadcast();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;

  Stream<String> get output => _outputController.stream;
  Stream<bool> get runningState => _runningController.stream;
  bool get isConnected => _socket != null;

  Future<void> connect({
    required int scriptId,
    int cols = 80,
    int rows = 40,
    String operateNode = 'local',
  }) async {
    if (_socket != null) return;
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) {
      throw StateError('No API config available');
    }

    final socket = await WebSocket.connect(
      _buildWsUri(
        baseUrl: config.url,
        scriptId: scriptId,
        cols: cols,
        rows: rows,
        operateNode: operateNode,
      ).toString(),
      headers: <String, dynamic>{
        ...OnePanelAuthHeaders.build(config.apiKey),
        'User-Agent': ApiConstants.userAgent,
      },
    );
    _socket = socket;
    _runningController.add(true);
    _subscription = socket.listen(
      (dynamic event) {
        if (event is! String) return;
        final payload = jsonDecode(event) as Map<String, dynamic>;
        if (payload['type'] == 'cmd' && payload['data'] is String) {
          final data = payload['data'] as String;
          if (data.isNotEmpty) {
            _outputController
                .add(utf8.decode(base64.decode(data), allowMalformed: true));
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _outputController.addError(error, stackTrace);
        _resetConnection();
      },
      onDone: () {
        _resetConnection();
      },
      cancelOnError: false,
    );
  }

  Future<void> close() async {
    await _subscription?.cancel();
    await _socket?.close();
    _resetConnection();
  }

  void _resetConnection() {
    _subscription = null;
    _socket = null;
    _runningController.add(false);
  }

  Uri _buildWsUri({
    required String baseUrl,
    required int scriptId,
    required int cols,
    required int rows,
    required String operateNode,
  }) {
    final baseUri = Uri.parse(baseUrl);
    final normalizedBasePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    final wsPath =
        '$normalizedBasePath${ApiConstants.buildApiPath('/core/script/run')}';
    return baseUri.replace(
      scheme: baseUri.scheme == 'https' ? 'wss' : 'ws',
      path: wsPath,
      queryParameters: <String, String>{
        'cols': '$cols',
        'rows': '$rows',
        'script_id': '$scriptId',
        'operateNode': operateNode,
      },
    );
  }
}

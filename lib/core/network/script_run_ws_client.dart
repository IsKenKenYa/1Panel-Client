import 'dart:async';
import 'dart:convert';

import '../config/api_config.dart';
import '../config/api_constants.dart';
import 'onepanel_websocket_connector.dart';

class ScriptRunWsClient {
  ScriptRunWsClient({ApiConfig? config}) : _config = config;
  final ApiConfig? _config;

  final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  final StreamController<bool> _runningController =
      StreamController<bool>.broadcast();

  final _connection = OnePanelWebSocketConnector();

  Stream<String> get output => _outputController.stream;
  Stream<bool> get runningState => _runningController.stream;
  bool get isConnected => _connection.socket != null;

  Future<void> connect({
    required int scriptId,
    int cols = 80,
    int rows = 40,
    String operateNode = 'local',
  }) async {
    await _connection.connect(
      config: _config,
      path: ApiConstants.buildApiPath('/core/script/run'),
      queryParameters: {
        'cols': '$cols',
        'rows': '$rows',
        'script_id': '$scriptId',
        'operateNode': operateNode,
      },
      onConnected: () => _runningController.add(true),
      onData: (event) {
        if (event is! String) return;
        final payload = jsonDecode(event);
        if (payload is! Map<String, dynamic>) {
          throw const FormatException('脚本输出格式无效');
        }
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
        _runningController.add(false);
      },
      onDone: () => _runningController.add(false),
    );
  }

  Future<void> close() async {
    final wasRunning = isConnected;
    final closing = _connection.close();
    if (wasRunning) _runningController.add(false);
    await closing;
  }
}

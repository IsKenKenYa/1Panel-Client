import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import '../config/api_constants.dart';
import 'onepanel_websocket_connector.dart';

class ProcessWsClient {
  ProcessWsClient({ApiConfig? config}) : _config = config;
  final ApiConfig? _config;
  final StreamController<dynamic> _messageController =
      StreamController<dynamic>.broadcast();

  final _connection = OnePanelWebSocketConnector();
  Completer<void>? _reply;
  String? _request;
  Timer? _responseTimeout;

  Stream<dynamic> get messages => _messageController.stream;
  bool get isConnected => _connection.socket != null;

  Future<void> connect({String operateNode = 'local'}) async {
    await _connect(operateNode);
  }

  Future<WebSocket?> _connect(String operateNode) {
    return _connection.connect(
      config: _config,
      path: ApiConstants.buildApiPath('/process/ws'),
      queryParameters: <String, String>{'operateNode': operateNode},
      onData: (event) {
        final items = event is String ? jsonDecode(event) : event;
        if (items != null && items is! List) {
          throw const FormatException('进程列表格式无效');
        }
        _messageController.add(items);
        _finishRequest();
      },
      onError: (error, trace) {
        if (_reply == null) {
          _messageController.addError(error, trace);
        } else {
          _finishRequest(error, trace);
        }
      },
      onDone: () => _finishRequest(const WebSocketException('进程会话连接已关闭')),
    );
  }

  Future<void> send(Map<String, dynamic> payload) async {
    final socket = _connection.socket ?? await _connect('local');
    if (socket == null) return;
    final request = jsonEncode(payload);
    while (_reply != null) {
      if (_request == request) return _reply!.future;
      await _reply!.future;
    }
    if (socket != _connection.socket) return;
    socket.add(request);
    _request = request;
    final reply = _reply = Completer<void>();
    _responseTimeout =
        Timer(const Duration(seconds: ApiConstants.receiveTimeout), () {
      unawaited(_connection.close());
      _finishRequest(TimeoutException('等待进程会话响应超时'));
    });
    await reply.future;
  }

  void _finishRequest([Object? error, StackTrace? trace]) {
    _responseTimeout?.cancel();
    _responseTimeout = null;
    final reply = _reply;
    _reply = null;
    _request = null;
    if (error == null) {
      reply?.complete();
    } else {
      reply?.completeError(error, trace);
    }
  }

  Future<void> close() {
    _finishRequest();
    return _connection.close();
  }
}

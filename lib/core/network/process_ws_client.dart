import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import '../config/api_constants.dart';
import 'onepanel_websocket_connector.dart';

class ProcessWsClient {
  ProcessWsClient();
  final StreamController<dynamic> _messageController =
      StreamController<dynamic>.broadcast();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;

  Stream<dynamic> get messages => _messageController.stream;
  bool get isConnected => _socket != null;

  Future<void> connect({String operateNode = 'local'}) async {
    if (_socket != null) {
      return;
    }

    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) {
      throw StateError('No API config available');
    }

    final socket = await OnePanelWebSocketConnector.connect(
      config: config,
      path: ApiConstants.buildApiPath('/process/ws'),
      queryParameters: <String, String>{'operateNode': operateNode},
    );
    _socket = socket;
    _subscription = socket.listen(
      (dynamic event) {
        if (event is String) {
          _messageController.add(jsonDecode(event));
        } else {
          _messageController.add(event);
        }
      },
      onError: _messageController.addError,
      onDone: () async {
        await close();
      },
      cancelOnError: false,
    );
  }

  Future<void> send(Map<String, dynamic> payload) async {
    if (_socket == null) {
      await connect();
    }
    _socket?.add(jsonEncode(payload));
  }

  Future<void> close() async {
    await _subscription?.cancel();
    await _socket?.close();
    _subscription = null;
    _socket = null;
  }
}

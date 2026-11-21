import 'dart:async';

import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/onepanel_websocket_connector.dart';
import 'package:onepanel_client/features/terminal/models/terminal_runtime_models.dart';

import 'terminal_frame_codec.dart';
import 'terminal_transport.dart';

class WebSocketTerminalTransport implements TerminalTransport {
  WebSocketTerminalTransport({
    required ApiConfig config,
    required TerminalLaunchIntent intent,
    required int columns,
    required int rows,
  })  : _config = config,
        _intent = intent,
        _columns = columns,
        _rows = rows;

  final ApiConfig _config;
  final TerminalLaunchIntent _intent;
  final StreamController<TerminalTransportEvent> _events =
      StreamController<TerminalTransportEvent>.broadcast();

  final _connection = OnePanelWebSocketConnector();
  int _columns;
  int _rows;

  @override
  Stream<TerminalTransportEvent> get events => _events.stream;

  @override
  Future<void> connect() async {
    await _connection.connect(
      config: _config,
      path: _intent.endpointPath(),
      queryParameters: _intent.queryParameters(
        columns: _columns,
        rows: _rows,
      ),
      onConnected: () => _events.add(const TerminalStatusEvent('connected')),
      onData: _handleFrame,
      onError: (error, _) => _events.add(TerminalErrorEvent(error.toString())),
      onDone: () => _events.add(const TerminalClosedEvent()),
    );
  }

  void _handleFrame(dynamic frame) {
    final event = TerminalFrameCodec.decode(frame);
    if (event != null) {
      _events.add(event);
    }
  }

  @override
  Future<void> sendInput(String data) async {
    _connection.socket?.add(TerminalFrameCodec.encodeInput(data));
  }

  @override
  Future<void> resize({
    required int columns,
    required int rows,
  }) async {
    _columns = columns;
    _rows = rows;
    _connection.socket?.add(TerminalFrameCodec.encodeResize(
      columns: columns,
      rows: rows,
    ));
  }

  @override
  Future<void> heartbeat() async {
    _connection.socket?.add(
      TerminalFrameCodec.encodeHeartbeat(
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await _connection.close();
    await _events.close();
  }
}

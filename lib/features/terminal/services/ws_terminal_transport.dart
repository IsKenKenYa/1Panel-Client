import 'dart:async';
import 'dart:io';

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

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  int _columns;
  int _rows;

  @override
  Stream<TerminalTransportEvent> get events => _events.stream;

  @override
  Future<void> connect() async {
    await dispose();
    _events.add(const TerminalStatusEvent('connecting'));

    try {
      final socket = await OnePanelWebSocketConnector.connect(
        config: _config,
        path: _intent.endpointPath(),
        queryParameters: _intent.queryParameters(
          columns: _columns,
          rows: _rows,
        ),
      );
      _socket = socket;
      _subscription = socket.listen(
        _handleFrame,
        onError: (Object error) {
          _events.add(TerminalErrorEvent(error.toString()));
        },
        onDone: () {
          _events.add(const TerminalClosedEvent());
        },
        cancelOnError: false,
      );
      _events.add(const TerminalStatusEvent('connected'));
    } catch (error) {
      _events.add(TerminalErrorEvent(error.toString()));
      rethrow;
    }
  }

  void _handleFrame(dynamic frame) {
    final event = TerminalFrameCodec.decode(frame);
    if (event != null) {
      _events.add(event);
    }
  }

  @override
  Future<void> sendInput(String data) async {
    _socket?.add(TerminalFrameCodec.encodeInput(data));
  }

  @override
  Future<void> resize({
    required int columns,
    required int rows,
  }) async {
    _columns = columns;
    _rows = rows;
    _socket?.add(TerminalFrameCodec.encodeResize(
      columns: columns,
      rows: rows,
    ));
  }

  @override
  Future<void> heartbeat() async {
    _socket?.add(
      TerminalFrameCodec.encodeHeartbeat(
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _socket?.close();
    _subscription = null;
    _socket = null;
  }
}

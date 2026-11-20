import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../features/terminal/models/terminal_runtime_models.dart';
import '../../features/terminal/services/terminal_transport.dart';
import '../../features/terminal/services/ws_terminal_transport.dart';
import '../config/api_config.dart';
import '../services/logger/logger_service.dart';

/// 原生容器终端会话桥。
///
/// 原生页面通过 `openTerminal` 建立会话，Dart 侧复用
/// [WebSocketTerminalTransport] 连接 `/hosts/terminal/container`，把输出、
/// 状态与关闭事件回推给原生层；输入、尺寸与心跳由原生层回调进来。
class NativeTerminalBridge {
  NativeTerminalBridge._();

  static const MethodChannel channel =
      MethodChannel('com.onepanel.client/terminal');

  static final Map<String, _Session> _sessions = <String, _Session>{};

  /// 由 `main.dart` 注册，原生层调用即进入 [_handle]。
  static void init() {
    channel.setMethodCallHandler(_handle);
  }

  static Future<dynamic> _handle(MethodCall call) async {
    final args = call.arguments is Map ? call.arguments as Map : const {};
    switch (call.method) {
      case 'openTerminal':
        return _open(args);
      case 'sendTerminalInput':
        await _session(args)?.transport.sendInput(args['data'] as String? ?? '');
        return true;
      case 'resizeTerminal':
        final session = _session(args);
        if (session == null) return false;
        await session.transport.resize(
          columns: args['cols'] as int? ?? 80,
          rows: args['rows'] as int? ?? 24,
        );
        return true;
      case 'heartbeatTerminal':
        await _session(args)?.transport.heartbeat();
        return true;
      case 'closeTerminal':
        return _close(args['sessionId'] as String? ?? '');
      default:
        throw MissingPluginException('Unknown terminal method: ${call.method}');
    }
  }

  static _Session? _session(Map args) {
    final id = args['sessionId'] as String? ?? '';
    return _sessions[id];
  }

  static Future<String> _open(Map args) async {
    final containerName = args['containerName'] as String? ?? '';
    if (containerName.isEmpty) {
      throw ArgumentError('containerName is required');
    }
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) {
      throw StateError('No API config available');
    }
    final sessionId =
        'term-${DateTime.now().microsecondsSinceEpoch}-$containerName';
    // 会话标识用容器名：1Panel 的容器操作与终端都以容器名为定位键。
    final intent = TerminalLaunchIntent.containerExec(
      containerId: containerName,
      containerName: containerName,
    );
    final transport = WebSocketTerminalTransport(
      config: config,
      intent: intent,
      columns: args['cols'] as int? ?? 80,
      rows: args['rows'] as int? ?? 24,
    );
    final session = _Session(sessionId, transport);
    _sessions[sessionId] = session;
    session.subscription = transport.events.listen(
      (event) => _forward(session, event),
    );
    appLogger.i('terminal session opened for container $containerName');
    await transport.connect();
    return sessionId;
  }

  static void _forward(_Session session, TerminalTransportEvent event) {
    if (!_sessions.containsKey(session.sessionId)) return;
    final Map<String, dynamic> payload = <String, dynamic>{
      'sessionId': session.sessionId,
    };
    switch (event) {
      case TerminalOutputEvent():
        // 服务端会先发 `{"type":"session","id":...}` 之类的控制帧，
        // 解码器把它们当成普通输出；这里跳过，避免终端里出现 JSON 文本。
        if (_isControlFrame(event.output)) {
          return;
        }
        payload['event'] = 'output';
        payload['data'] = event.output;
      case TerminalHeartbeatEvent():
        payload['event'] = 'heartbeat';
        payload['latencyMs'] = event.latencyMs;
      case TerminalStatusEvent():
        payload['event'] = 'status';
        payload['status'] = event.status;
      case TerminalClosedEvent():
        payload['event'] = 'closed';
        payload['reason'] = event.reason;
      case TerminalErrorEvent():
        payload['event'] = 'error';
        payload['message'] = event.message;
    }
    channel.invokeMethod<void>('terminalEvent', payload);
  }

  static Future<bool> _close(String sessionId) async {
    final session = _sessions.remove(sessionId);
    if (session == null) return false;
    await session.subscription?.cancel();
    await session.transport.dispose();
    appLogger.i('terminal session closed: $sessionId');
    return true;
  }

  /// 判断是否为协议控制帧（`session` 握手、`heartbeat` 回执等），
  /// 这些帧只携带 JSON 元数据，不应写进终端。
  static bool _isControlFrame(String output) {
    final trimmed = output.trim();
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
      return false;
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map) return false;
      final type = decoded['type'];
      return type == 'session' || type == 'heartbeat' || type == 'resize';
    } on FormatException {
      return false;
    }
  }
}

class _Session {
  _Session(this.sessionId, this.transport);

  final String sessionId;
  final WebSocketTerminalTransport transport;
  StreamSubscription<TerminalTransportEvent>? subscription;
}

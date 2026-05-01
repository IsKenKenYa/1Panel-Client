import 'dart:convert';

import 'terminal_transport.dart';

class TerminalFrameCodec {
  const TerminalFrameCodec._();

  static String encodeInput(String data) {
    return jsonEncode(<String, dynamic>{
      'type': 'cmd',
      'data': base64.encode(utf8.encode(data)),
    });
  }

  static String encodeResize({
    required int columns,
    required int rows,
  }) {
    return jsonEncode(<String, dynamic>{
      'type': 'resize',
      'cols': columns,
      'rows': rows,
    });
  }

  static String encodeHeartbeat({required int timestamp}) {
    return jsonEncode(<String, dynamic>{
      'type': 'heartbeat',
      'timestamp': '$timestamp',
    });
  }

  static TerminalTransportEvent? decode(
    dynamic frame, {
    DateTime? receivedAt,
  }) {
    if (frame is! String) {
      return TerminalOutputEvent(frame.toString());
    }

    final now = receivedAt ?? DateTime.now();

    try {
      final payload = jsonDecode(frame);
      if (payload is! Map<String, dynamic>) {
        return TerminalOutputEvent(frame);
      }

      final type = payload['type']?.toString();
      switch (type) {
        case 'cmd':
          final encoded = payload['data']?.toString() ?? '';
          if (encoded.isEmpty) {
            return null;
          }
          return TerminalOutputEvent(
            utf8.decode(base64.decode(encoded), allowMalformed: true),
          );
        case 'heartbeat':
          final timestamp =
              int.tryParse(payload['timestamp']?.toString() ?? '');
          if (timestamp == null) {
            return null;
          }
          return TerminalHeartbeatEvent(
            remoteTimestamp: timestamp,
            localReceivedAt: now,
          );
        case 'close':
          return TerminalClosedEvent(payload['message']?.toString());
        case 'error':
          return TerminalErrorEvent(
            payload['message']?.toString() ?? frame,
          );
        case 'status':
          return TerminalStatusEvent(payload['status']?.toString() ?? '');
        default:
          return TerminalOutputEvent(frame);
      }
    } catch (_) {
      return TerminalOutputEvent(frame);
    }
  }
}

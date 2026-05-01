import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/terminal/services/terminal_frame_codec.dart';
import 'package:onepanel_client/features/terminal/services/terminal_transport.dart';

void main() {
  group('TerminalFrameCodec', () {
    test('encodes input frame as base64 cmd payload', () {
      final frame = jsonDecode(TerminalFrameCodec.encodeInput('ls -la\n'));
      expect(frame['type'], 'cmd');
      expect(base64.decode(frame['data'] as String), utf8.encode('ls -la\n'));
    });

    test('decodes cmd payload into output event', () {
      final frame = jsonEncode(<String, dynamic>{
        'type': 'cmd',
        'data': base64.encode(utf8.encode('hello 你好')),
      });
      final event = TerminalFrameCodec.decode(frame);
      expect(event, isA<TerminalOutputEvent>());
      expect((event as TerminalOutputEvent).output, 'hello 你好');
    });

    test('decodes heartbeat payload into latency event', () {
      final frame = jsonEncode(<String, dynamic>{
        'type': 'heartbeat',
        'timestamp': '1000',
      });
      final event = TerminalFrameCodec.decode(
        frame,
        receivedAt: DateTime.fromMillisecondsSinceEpoch(1300),
      );
      expect(event, isA<TerminalHeartbeatEvent>());
      expect((event as TerminalHeartbeatEvent).latencyMs, 300);
    });

    test('passes through plain text as terminal output', () {
      final event = TerminalFrameCodec.decode('plain text');
      expect(event, isA<TerminalOutputEvent>());
      expect((event as TerminalOutputEvent).output, 'plain text');
    });
  });
}

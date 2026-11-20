import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/network/sse/sse_frame_decoder.dart';

void main() {
  Stream<String> decode(List<String> lines) =>
      Stream<String>.fromIterable(lines).transform(const SseFrameDecoder());

  String frame(String text) => 'data:${base64Encode(utf8.encode(text))}';

  group('SseFrameDecoder', () {
    test('decodes a base64 data frame into text', () async {
      final events = await decode(<String>[frame('hello world'), '']).toList();
      expect(events, <String>['hello world']);
    });

    test('splits multiple frames on blank lines', () async {
      final events = await decode(<String>[
        frame('first'),
        '',
        frame('second'),
        '',
      ]).toList();
      expect(events, <String>['first', 'second']);
    });

    test('emits the trailing frame without a terminating blank line', () async {
      final events = await decode(<String>[frame('tail')]).toList();
      expect(events, <String>['tail']);
    });

    test('drops data:null frames', () async {
      final events = await decode(<String>['data:null', '']).toList();
      expect(events, isEmpty);
    });

    test('drops frames with invalid base64 payloads', () async {
      final events = await decode(<String>['data:not-base64!!', '']).toList();
      expect(events, isEmpty);
    });

    test('ignores non-data SSE fields', () async {
      final events = await decode(<String>[
        'event: message',
        'id: 42',
        frame('payload'),
        '',
      ]).toList();
      expect(events, <String>['payload']);
    });

    test('keeps whitespace inside the decoded log text', () async {
      final events = await decode(<String>[frame('  indented line\n'), ''])
          .toList();
      expect(events.single, '  indented line\n');
    });
  });
}

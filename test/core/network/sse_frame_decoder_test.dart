import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/network/sse/sse_frame_decoder.dart';

void main() {
  Stream<SseFrame> decode(List<String> lines) =>
      Stream<String>.fromIterable(lines).transform(const SseFrameDecoder());

  String frame(String text) => 'data:${base64Encode(utf8.encode(text))}';

  String textOf(SseFrame frame) =>
      utf8.decode(frame.bytes, allowMalformed: true);

  group('SseFrameDecoder', () {
    test('decodes a base64 data frame into text', () async {
      final frames = await decode(<String>[frame('hello world'), '']).toList();
      expect(frames.single.isError, isFalse);
      expect(textOf(frames.single), 'hello world');
    });

    test('splits multiple frames on blank lines', () async {
      final frames = await decode(<String>[
        frame('first'),
        '',
        frame('second'),
        '',
      ]).toList();
      expect(frames.map(textOf), <String>['first', 'second']);
    });

    test('emits the trailing frame without a terminating blank line', () async {
      final frames = await decode(<String>[frame('tail')]).toList();
      expect(frames.map(textOf), <String>['tail']);
    });

    test('drops data:null frames', () async {
      final frames = await decode(<String>['data:null', '']).toList();
      expect(frames, isEmpty);
    });

    test('keeps UTF-8 characters split between Docker log chunks', () async {
      final bytes = utf8.encode('中\n');
      final frames = await decode([
        'data:${base64Encode(bytes.sublist(0, 1))}',
        '',
        'data:${base64Encode(bytes.sublist(1))}',
        '',
      ]).toList();
      final joined = frames.expand((frame) => frame.bytes).toList();
      expect(utf8.decode(joined), '中\n');
    });

    test('drops frames with invalid base64 payloads', () async {
      final frames =
          await decode(<String>['data:not-base64!!', '']).toList();
      expect(frames, isEmpty);
    });

    test('ignores non-data SSE fields', () async {
      final frames = await decode(<String>[
        'event: message',
        'id: 42',
        frame('payload'),
        '',
      ]).toList();
      expect(frames.map(textOf), <String>['payload']);
    });

    test('keeps whitespace inside the decoded log text', () async {
      final frames =
          await decode(<String>[frame('  indented line\n'), '']).toList();
      expect(textOf(frames.single), '  indented line\n');
    });

    test('keeps an error event as plaintext instead of decoding base64', () async {
      final frames = await decode(<String>[
        'event: error',
        'data: docker logs: no such container',
        '',
      ]).toList();
      expect(frames.single.isError, isTrue);
      expect(frames.single.event, 'error');
      expect(frames.single.errorText, 'docker logs: no such container');
    });

    test('accepts an error event without a space after the colon', () async {
      final frames = await decode(<String>[
        'event:error',
        'data:reader error: broken pipe',
        '',
      ]).toList();
      expect(frames.single.isError, isTrue);
      expect(frames.single.errorText, 'reader error: broken pipe');
    });

    test('keeps log frames before a trailing error event', () async {
      final frames = await decode(<String>[
        frame('line before error\n'),
        '',
        'event: error',
        'data: failed to start docker logs command',
        '',
      ]).toList();
      expect(frames.length, 2);
      expect(textOf(frames.first), 'line before error\n');
      expect(frames.last.isError, isTrue);
      expect(frames.last.errorText, 'failed to start docker logs command');
    });
  });
}
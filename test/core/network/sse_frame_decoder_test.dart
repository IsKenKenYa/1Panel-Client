import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/network/sse/sse_frame_decoder.dart';
import 'package:sse_parser/sse_parser.dart';

void main() {
  // 走生产链路：真实 SSE 文本块 → sse_parser → 容器日志帧解码。
  Stream<SseFrame> decode(List<String> chunks) =>
      Stream<String>.fromIterable(chunks)
          .parseSse()
          .transform(const SseFrameDecoder());

  String frame(String text) =>
      'data: ${base64Encode(utf8.encode(text))}\n\n';

  String textOf(SseFrame frame) =>
      utf8.decode(frame.bytes, allowMalformed: true);

  group('容器日志 SSE 帧解码', () {
    test('decodes a base64 data frame into text', () async {
      final frames = await decode(<String>[frame('hello world')]).toList();
      expect(frames.single.isError, isFalse);
      expect(textOf(frames.single), 'hello world');
    });

    test('splits multiple frames on blank lines', () async {
      final frames =
          await decode(<String>[frame('first'), frame('second')]).toList();
      expect(frames.map(textOf), <String>['first', 'second']);
    });

    test('drops data:null frames', () async {
      final frames = await decode(<String>['data: null\n\n']).toList();
      expect(frames, isEmpty);
    });

    test('keeps UTF-8 characters split between Docker log chunks', () async {
      final bytes = utf8.encode('中\n');
      final frames = await decode(<String>[
        'data: ${base64Encode(bytes.sublist(0, 1))}\n\n',
        'data: ${base64Encode(bytes.sublist(1))}\n\n',
      ]).toList();
      final joined = frames.expand((frame) => frame.bytes).toList();
      expect(utf8.decode(joined), '中\n');
    });

    test('drops frames with invalid base64 payloads', () async {
      final frames = await decode(<String>['data: not-base64!!\n\n']).toList();
      expect(frames, isEmpty);
    });

    test('keeps whitespace inside the decoded log text', () async {
      final frames = await decode(<String>[frame('  indented line\n')]).toList();
      expect(textOf(frames.single), '  indented line\n');
    });

    test('keeps an error event as plaintext instead of decoding base64',
        () async {
      final frames = await decode(<String>[
        'event: error\ndata: docker logs: no such container\n\n',
      ]).toList();
      expect(frames.single.isError, isTrue);
      expect(frames.single.event, 'error');
      expect(frames.single.errorText, 'docker logs: no such container');
    });

    test('accepts an error event without a space after the colon', () async {
      final frames = await decode(<String>[
        'event:error\ndata:reader error: broken pipe\n\n',
      ]).toList();
      expect(frames.single.isError, isTrue);
      expect(frames.single.errorText, 'reader error: broken pipe');
    });

    test('keeps log frames before a trailing error event', () async {
      final frames = await decode(<String>[
        frame('line before error\n'),
        'event: error\ndata: failed to start docker logs command\n\n',
      ]).toList();
      expect(frames.length, 2);
      expect(textOf(frames.first), 'line before error\n');
      expect(frames.last.isError, isTrue);
      expect(frames.last.errorText, 'failed to start docker logs command');
    });

    test('ignores comments and non-data fields', () async {
      final frames = await decode(<String>[
        ': keep-alive\nid: 42\nretry: 1000\n${frame('payload')}',
      ]).toList();
      expect(frames.map(textOf), <String>['payload']);
    });

    test('drops a trailing block that has no closing blank line', () async {
      // sse_parser 按规范丢弃未以空行结束的未完成块。
      final frames =
          await decode(<String>['data: ${base64Encode(utf8.encode('tail\n'))}'])
              .toList();
      expect(frames, isEmpty);
    });

    test('handles CRLF frames produced by HTTP stacks', () async {
      final frames = await decode(<String>[
        ': keep-alive\r\n',
        'data: ${base64Encode(utf8.encode('crlf line\n'))}\r\n\r\n',
      ]).toList();
      expect(frames.map(textOf), <String>['crlf line\n']);
    });
  });
}
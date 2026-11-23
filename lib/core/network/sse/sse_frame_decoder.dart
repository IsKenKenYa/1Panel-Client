import 'dart:async';
import 'dart:convert';

/// 一帧 SSE 事件。
///
/// 普通日志帧只携带原始字节，由订阅端跨帧做 UTF-8 解码；
/// `event: error` 帧携带服务端明文错误消息。
class SseFrame {
  const SseFrame._({
    required this.event,
    required this.bytes,
    required this.errorText,
  });

  const SseFrame.log(List<int> bytes)
      : this._(event: 'message', bytes: bytes, errorText: null);

  const SseFrame.error(String message)
      : this._(event: 'error', bytes: const <int>[], errorText: message);

  /// SSE 事件类型；普通日志为 `message`。
  final String event;

  /// 普通日志帧的原始字节。
  final List<int> bytes;

  /// 错误帧的服务端明文消息。
  final String? errorText;

  bool get isError => event == 'error';
}

/// 服务端在 SSE `event: error` 中发送的错误。
class SseServerError implements Exception {
  const SseServerError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 解析 1Panel 日志 SSE 帧。
///
/// 普通事件 `data:<base64>` 解码为日志字节；`event: error` 的 data 是
/// 服务端明文错误消息（见 agent/app/service/container.go 的
/// writeContainerLogMessage），保留明文交给订阅端转为流错误。
/// 空帧、`data:null` 与非法 base64 帧被丢弃，避免把协议噪声写入日志视图。
class SseFrameDecoder extends StreamTransformerBase<String, SseFrame> {
  const SseFrameDecoder();

  @override
  Stream<SseFrame> bind(Stream<String> stream) => _frames(stream);

  Stream<SseFrame> _frames(Stream<String> stream) async* {
    final buffer = StringBuffer();
    var event = '';
    await for (final line in stream) {
      if (line.isEmpty) {
        final frame = _decodeFrame(event, buffer.toString());
        buffer.clear();
        event = '';
        if (frame != null) yield frame;
        continue;
      }
      if (line.startsWith(':')) continue;
      final separator = line.indexOf(':');
      final field = separator < 0 ? line : line.substring(0, separator);
      var value = separator < 0 ? '' : line.substring(separator + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      switch (field) {
        case 'event':
          event = value.trim();
        case 'data':
          buffer.write(value);
      }
    }
    final frame = _decodeFrame(event, buffer.toString());
    if (frame != null) yield frame;
  }

  /// 错误帧保留明文；普通帧按 base64 解码，失败时返回 null。
  SseFrame? _decodeFrame(String event, String payload) {
    final data = payload.trim();
    if (data.isEmpty || data == 'null') {
      return null;
    }
    if (event == 'error') {
      return SseFrame.error(data);
    }
    try {
      return SseFrame.log(base64Decode(data));
    } on FormatException {
      return null;
    }
  }
}
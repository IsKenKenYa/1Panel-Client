import 'dart:async';
import 'dart:convert';

/// 解析 1Panel 日志 SSE 帧：`data:<base64>` 行为一个事件，空行分隔。
///
/// 服务端在声明 `Accept: text/event-stream` 时以 base64 携带日志文本块；
/// 空帧、`data:null` 与非法 base64 帧被丢弃，避免把协议噪声写入日志视图。
class SseFrameDecoder extends StreamTransformerBase<String, String> {
  const SseFrameDecoder();

  @override
  Stream<String> bind(Stream<String> stream) =>
      _frames(stream).transform(const Utf8Decoder(allowMalformed: true));

  Stream<List<int>> _frames(Stream<String> stream) async* {
    final buffer = StringBuffer();
    await for (final line in stream) {
      if (line.isEmpty) {
        final frame = buffer.toString();
        buffer.clear();
        final decoded = _decodeFrame(frame);
        if (decoded != null && decoded.isNotEmpty) {
          yield decoded;
        }
        continue;
      }
      if (line.startsWith('data:')) {
        buffer.write(line.substring(5).trim());
      }
      // event/id 等其余 SSE 字段对日志内容无意义，忽略。
    }
    final frame = buffer.toString();
    final decoded = _decodeFrame(frame);
    if (decoded != null && decoded.isNotEmpty) {
      yield decoded;
    }
  }

  /// 单帧为 base64 编码的日志文本；空帧或解码失败时返回 null。
  List<int>? _decodeFrame(String frame) {
    final payload = frame.trim();
    if (payload.isEmpty || payload == 'null') {
      return null;
    }
    try {
      return base64Decode(payload);
    } on FormatException {
      return null;
    }
  }
}

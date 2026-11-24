import 'dart:async';
import 'dart:convert';

import 'package:sse_parser/sse_parser.dart';

/// 一帧容器日志事件。
///
/// 普通事件携带 base64 解码后的原始字节，由订阅端跨帧做 UTF-8 解码；
/// `event: error` 事件携带服务端明文错误消息。
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

/// 把 `sse_parser` 解析出的 [SseEvent] 映射为容器日志帧。
///
/// 协议层（行终结符、注释、多行 data、BOM）由 `sse_parser` 处理；这里只做
/// 1Panel 的业务解码：普通事件 data 是 base64 编码的日志字节，
/// `event: error` 的 data 是服务端明文错误消息（见
/// agent/app/service/container.go 的 writeContainerLogMessage）。
/// 空帧、`data:null` 与非法 base64 帧被丢弃，避免把协议噪声写入日志视图。
class SseFrameDecoder extends StreamTransformerBase<SseEvent, SseFrame> {
  const SseFrameDecoder();

  @override
  Stream<SseFrame> bind(Stream<SseEvent> stream) => stream.expand(_toFrames);

  Iterable<SseFrame> _toFrames(SseEvent event) sync* {
    final data = event.data.trim();
    if (data.isEmpty || data == 'null') {
      return;
    }
    if (event.event == 'error') {
      yield SseFrame.error(data);
      return;
    }
    try {
      yield SseFrame.log(base64Decode(data));
    } on FormatException {
      // 非法 base64 帧按协议噪声丢弃。
    }
  }
}
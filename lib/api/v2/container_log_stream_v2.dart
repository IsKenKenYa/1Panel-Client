import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/interceptors/retry_interceptor.dart';

/// 1Panel container log SSE stream client.
///
/// 覆盖 swagger `GET /containers/search/log`：仅在 `Accept:
/// text/event-stream` 时返回 base64 编码的 SSE 帧（声明 JSON 时固定返回
/// `data: null`，见 container_v2.dart 日志下载注释）。SSE 连接不重试，
/// 避免日志帧重复下发。
class ContainerLogStreamV2Api {
  ContainerLogStreamV2Api(this._client);

  final DioClient _client;

  /// 订阅容器日志流。
  ///
  /// [follow] 为 true 时服务端持续推送新日志；[tail] 控制起始行数；
  /// [timestamps] 控制是否携带时间戳。每个事件为一个已解码的日志文本块。
  Stream<String> streamContainerLogs({
    required String container,
    String? since,
    String? tail,
    bool follow = false,
    bool timestamps = false,
  }) async* {
    final response = await _client.get<ResponseBody>(
      ApiConstants.buildApiPath('/containers/search/log'),
      queryParameters: <String, dynamic>{
        'container': container,
        'since': since ?? 'all',
        'follow': follow.toString(),
        'timestamp': timestamps.toString(),
        if (tail != null) 'tail': tail,
      },
      options: Options(
        responseType: ResponseType.stream,
        headers: <String, dynamic>{'Accept': 'text/event-stream'},
        extra: <String, dynamic>{RetryInterceptor.disableRetryKey: true},
      ),
    );

    final body = response.data;
    if (body == null) {
      return;
    }

    yield* body.stream
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .transform(_SseFrameDecoder());
  }
}

/// 解析 1Panel 容器日志 SSE 帧：`data:<base64>` 行为一个事件，空行分隔。
class _SseFrameDecoder extends StreamTransformerBase<String, String> {
  @override
  Stream<String> bind(Stream<String> stream) async* {
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
  String? _decodeFrame(String frame) {
    final payload = frame.trim();
    if (payload.isEmpty || payload == 'null') {
      return null;
    }
    try {
      final bytes = base64Decode(payload);
      return utf8.decode(bytes, allowMalformed: true);
    } on FormatException {
      return null;
    }
  }
}

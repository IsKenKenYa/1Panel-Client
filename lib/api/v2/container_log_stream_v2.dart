import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/interceptors/retry_interceptor.dart';
import '../../core/network/sse/sse_frame_decoder.dart';

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
        .transform(const SseFrameDecoder());
  }
}

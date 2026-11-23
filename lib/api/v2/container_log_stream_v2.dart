import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
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
  /// [timestamps] 控制是否携带时间戳。普通帧为已解码的日志文本块；
  /// 服务端以 `event: error` 发送的错误转为流错误并结束本次订阅。
  Stream<String> streamContainerLogs({
    required String container,
    String? since,
    String? tail,
    bool follow = false,
    bool timestamps = false,
  }) {
    final cancelToken = CancelToken();
    bool cancelled = false;
    bool finished = false;
    StreamSubscription<SseFrame>? subscription;
    late final StreamController<String> events;
    Future<void> listen() async {
      try {
        final opening = _client.get<ResponseBody>(
          ApiConstants.buildApiPath('/containers/search/log'),
          cancelToken: cancelToken,
          queryParameters: <String, dynamic>{
            'container': container,
            'since': since ?? 'all',
            'follow': follow.toString(),
            'timestamp': timestamps.toString(),
            if (tail != null) 'tail': tail,
          },
          options: Options(
            responseType: ResponseType.stream,
            receiveTimeout: follow ? Duration.zero : null,
            followRedirects: false,
            receiveDataWhenStatusError: false,
            headers: <String, dynamic>{'Accept': 'text/event-stream'},
            extra: DioClient.sensitiveOptions.extra,
          ),
        );
        final response = await opening.timeout(
          const Duration(seconds: ApiConstants.receiveTimeout),
          onTimeout: () {
            cancelToken.cancel();
            throw TimeoutException('等待面板返回日志响应超时');
          },
        );

        final body = response.data;
        if (cancelled) return;
        final mediaType = response.headers
            .value(Headers.contentTypeHeader)
            ?.split(';')
            .first
            .trim()
            .toLowerCase();
        if (body == null || mediaType != 'text/event-stream') {
          if (body != null) {
            final discarded = body.stream.listen(null, onError: (Object _) {});
            cancelToken.cancel();
            await discarded.cancel();
          }
          throw const FormatException('面板未返回容器日志事件流');
        }
        final textSink = const Utf8Decoder(allowMalformed: true)
            .startChunkedConversion(events);
        subscription = body.stream
            .cast<List<int>>()
            .transform(const Utf8Decoder())
            .transform(const LineSplitter())
            .transform(const SseFrameDecoder())
            .listen(
          (frame) {
            if (cancelled || finished) return;
            final errorText = frame.errorText;
            if (errorText != null) {
              finished = true;
              events.addError(SseServerError(errorText));
              cancelToken.cancel();
              final active = subscription;
              if (active != null) unawaited(active.cancel());
              unawaited(events.close());
              return;
            }
            textSink.add(frame.bytes);
          },
          onError: (Object error, StackTrace trace) {
            if (cancelled || finished) return;
            finished = true;
            events.addError(error, trace);
            unawaited(events.close());
          },
          onDone: () {
            if (cancelled || finished) return;
            finished = true;
            textSink.close();
            unawaited(events.close());
          },
        );
        if (events.isPaused) subscription!.pause();
      } catch (error, trace) {
        if (cancelled) return;
        finished = true;
        events.addError(error, trace);
        unawaited(events.close());
      }
    }

    events = StreamController<String>(
      onListen: listen,
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () {
        cancelled = true;
        cancelToken.cancel();
      },
    );
    return events.stream;
  }
}

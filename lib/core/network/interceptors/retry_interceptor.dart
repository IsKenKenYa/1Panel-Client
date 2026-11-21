import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio, {this.delay = const Duration(seconds: 1)});

  static const disableRetryKey = 'disableRetry';
  static const retriedKey = 'networkRetried';
  final Dio _dio;
  final Duration delay;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    await Future<void>.delayed(delay);
    final cancelled = request.cancelToken?.cancelError;
    if (cancelled != null) {
      handler.reject(cancelled);
      return;
    }

    final next = request.copyWith(extra: {...request.extra, retriedKey: true});
    try {
      handler.resolve(await _dio.fetch<dynamic>(next));
    } on DioException catch (error) {
      // 同一客户端已处理第二次请求的错误。
      handler.reject(error);
    }
  }

  bool _shouldRetry(DioException err) {
    final request = err.requestOptions;
    if (request.extra[disableRetryKey] == true ||
        request.extra[retriedKey] == true ||
        request.cancelToken?.isCancelled == true ||
        (request.method != 'GET' && request.method != 'HEAD') ||
        request.data != null ||
        request.responseType == ResponseType.stream) {
      return false;
    }
    // 有 Retry-After 时把本次结果交给调用方，保留服务端的等待窗口。
    if (err.response?.headers['retry-after'] != null) return false;
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      DioExceptionType.badResponse =>
        const {408, 429, 500, 502, 503, 504}.contains(err.response?.statusCode),
      _ => false,
    };
  }
}

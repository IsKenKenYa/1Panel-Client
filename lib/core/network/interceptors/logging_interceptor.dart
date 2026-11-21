import 'package:dio/dio.dart';

import '../../services/logger/log_level.dart';
import '../../services/logger/logger_service.dart';
import 'retry_interceptor.dart';

class LoggingInterceptor extends Interceptor {
  static const sensitiveBody = 'sensitiveBody';
  static const _timerKey = 'networkElapsed';
  static final _apiModule = RegExp(r'^/api/v2/(?:core/)?[a-z]+(?=[/?#]|$)');

  static bool isSensitive(RequestOptions options) =>
      options.extra[sensitiveBody] == true;

  /// 路径只保留面板模块名称，流请求的耗时截至收到响应头。
  static String describe(
    RequestOptions request, {
    int? status,
    int? businessCode,
    DioExceptionType? error,
  }) {
    final timer = request.extra[_timerKey] as Stopwatch?;
    final module = _apiModule.firstMatch(request.path)?.group(0);
    return [
      request.method,
      if (module != null) module,
      if (status != null) 'HTTP $status',
      if (businessCode != null) 'code=$businessCode',
      if (error != null) error.name,
      if (timer != null) '${timer.elapsedMilliseconds}ms',
      if (request.extra[RetryInterceptor.retriedKey] == true) 'retry=1',
    ].join(' ');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra.putIfAbsent(_timerKey, () => Stopwatch()..start());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (appLogger.minLogLevel.weight <= AppLogLevel.debug.weight) {
      appLogger.dWithPackage(
        'core.network.http',
        describe(response.requestOptions, status: response.statusCode),
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!CancelToken.isCancel(err)) {
      final data = err.response?.data;
      final code = data is Map ? data['code'] : null;
      appLogger.wWithPackage(
        'core.network.http',
        describe(
          err.requestOptions,
          status: err.response?.statusCode,
          businessCode: code is int ? code : null,
          error: err.type,
        ),
      );
    }
    handler.next(err);
  }
}

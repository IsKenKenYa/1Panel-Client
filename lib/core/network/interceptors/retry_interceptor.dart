import 'dart:async';
import 'package:dio/dio.dart';
import '../../services/logger/logger_service.dart';

/// 简化的重试拦截器
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final List<Duration> retryDelays;
  final AppLogger _logger = AppLogger();

  RetryInterceptor({
    this.maxRetries = 4,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 30),
    ],
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final currentRetry = err.requestOptions.extra['retryCount'] as int? ?? 0;

    if (_shouldRetry(err) && currentRetry < maxRetries) {
      final delay = retryDelays[currentRetry.clamp(0, retryDelays.length - 1)];

      _logger.w(
          '[network] Retrying ${err.requestOptions.path} (attempt ${currentRetry + 1}/$maxRetries)');

      await Future.delayed(delay);

      final newOptions = err.requestOptions.copyWith(
        extra: {...err.requestOptions.extra, 'retryCount': currentRetry + 1},
      );

      try {
        final response = await Dio().fetch(newOptions);
        handler.resolve(response);
        return;
      } on DioException catch (e) {
        handler.next(e);
        return;
      }
    }

    super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    // 网络相关错误
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // HTTP状态码错误
    final statusCode = err.response?.statusCode;
    return (statusCode != null && (statusCode >= 500 || statusCode == 429));
  }
}

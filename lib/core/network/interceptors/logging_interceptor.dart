import 'package:dio/dio.dart';
import '../../services/logger/logger_service.dart';

/// 简化的日志拦截器
class LoggingInterceptor extends Interceptor {
  final bool enabled;
  final bool logBody;

  LoggingInterceptor([this.enabled = true, this.logBody = true]);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled) {
      super.onRequest(options, handler);
      return;
    }

    appLogger.dWithPackage('network', '${options.method} ${options.path}');
    if (logBody && options.data != null) {
      appLogger.dWithPackage('network', 'Request Body: ${options.data}');
    }
    if (options.queryParameters.isNotEmpty) {
      appLogger.dWithPackage(
          'network', 'Query Params: ${options.queryParameters}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!enabled) {
      super.onResponse(response, handler);
      return;
    }

    appLogger.iWithPackage(
        'network', '${response.statusCode} ${response.requestOptions.path}');
    if (logBody && response.data != null) {
      final dataStr = response.data.toString();
      if (dataStr.length > 500) {
        appLogger.iWithPackage(
            'network', 'Response: ${dataStr.substring(0, 500)}...');
      } else {
        appLogger.iWithPackage('network', 'Response: $dataStr');
      }
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enabled) {
      super.onError(err, handler);
      return;
    }

    appLogger.eWithPackage(
        'network', '${err.type} ${err.requestOptions.path}: ${err.message}');
    if (err.response?.data != null) {
      appLogger.eWithPackage(
          'network', 'Error Response: ${err.response?.data}');
    }
    super.onError(err, handler);
  }
}

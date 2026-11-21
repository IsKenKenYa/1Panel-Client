import 'package:dio/dio.dart';
import 'logging_interceptor.dart';

/// 业务响应拦截器
/// 检查响应体中的code字段，如果不是200则抛出异常
class BusinessResponseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final code = data['code'];

      if (code != null && code != 200) {
        final serverMessage = data['message'];
        final message = LoggingInterceptor.isSensitive(response.requestOptions)
            ? '服务器拒绝请求 ($code)'
            : serverMessage is String && serverMessage.isNotEmpty
                ? serverMessage
                : '未知错误';
        final exception = DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: message,
        );
        handler.reject(exception, true);
        return;
      }
    }
    super.onResponse(response, handler);
  }
}

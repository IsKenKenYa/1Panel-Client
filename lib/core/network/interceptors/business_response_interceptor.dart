import 'package:dio/dio.dart';
import '../../services/logger/logger_service.dart';

/// 业务响应拦截器
/// 检查响应体中的code字段，如果不是200则抛出异常
class BusinessResponseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final code = data['code'];

      if (code != null && code != 200) {
        final message = data['message'] ?? '未知错误';
        appLogger.eWithPackage('network', '业务错误: code=$code, message=$message');

        final exception = DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: message,
        );
        handler.reject(exception);
        return;
      }
    }
    super.onResponse(response, handler);
  }
}

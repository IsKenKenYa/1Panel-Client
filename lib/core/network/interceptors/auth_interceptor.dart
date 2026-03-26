import 'package:dio/dio.dart';
import '../../services/logger/logger_service.dart';
import '../../config/api_constants.dart';
import '../onepanel_auth_headers.dart';

/// 1Panel API认证拦截器 - 严格按照服务器端认证要求实现
class AuthInterceptor extends Interceptor {
  final AppLogger _logger = AppLogger();
  String? _apiKey;

  AuthInterceptor([String? apiKey]) : _apiKey = apiKey;

  /// 更新API密钥
  void updateApiKey(String? apiKey) {
    _apiKey = apiKey;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_apiKey == null || _apiKey!.isEmpty) {
      _logger.w('[network] No API key provided for authentication');
      super.onRequest(options, handler);
      return;
    }

    // 1Panel服务器要求使用秒级时间戳
    final authHeaders = OnePanelAuthHeaders.build(_apiKey!);

    // 添加1Panel API服务器要求的认证头部
    options.headers.addAll({
      ...authHeaders,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': ApiConstants.userAgent,
    });

    _logger.d('[network] 1Panel auth headers added for ${options.path}');
    super.onRequest(options, handler);
  }
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _logger.w('[network] 1Panel authentication failed for ${err.requestOptions.path}');
      _logger.w('[network] Response: ${err.response?.data}');
    }
    super.onError(err, handler);
  }
}

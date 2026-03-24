import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../services/logger/logger_service.dart';
import '../../config/api_constants.dart';

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
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();

    // 按照1Panel服务器规则生成MD5认证token: MD5("1panel" + apiKey + timestamp)
    final authToken = _generate1PanelAuthToken(timestamp);

    // 添加1Panel API服务器要求的认证头部
    options.headers.addAll({
      ApiConstants.authHeaderToken: authToken,        // 服务器期望的头部名称
      ApiConstants.authHeaderTimestamp: timestamp,   // 服务器期望的头部名称
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': ApiConstants.userAgent,
    });

    _logger.d('[network] 1Panel auth headers added for ${options.path}');
    super.onRequest(options, handler);
  }

  /// 生成1Panel API认证token - 严格按服务器规则
  String _generate1PanelAuthToken(String timestamp) {
    if (_apiKey == null || _apiKey!.isEmpty) {
      _logger.w('[network] No API key provided for authentication');
      return '';
    }

    try {
      // 1Panel服务器端认证规则（来自 api_auth.go:79）：
      // MD5("1panel" + system1PanelToken + panelTimestamp)
      final authString = '${ApiConstants.authPrefix}$_apiKey$timestamp';
      final bytes = utf8.encode(authString);
      final digest = md5.convert(bytes);

      final authToken = digest.toString();
      return authToken;
    } catch (e) {
      _logger.e('[network] Failed to generate 1Panel auth token: $e');
      return '';
    }
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

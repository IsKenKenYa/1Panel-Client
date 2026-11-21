import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_constants.dart';
import '../onepanel_auth_headers.dart';

/// 1Panel API认证拦截器 - 严格按照服务器端认证要求实现
class AuthInterceptor extends Interceptor {
  String? _apiKey;

  AuthInterceptor([String? apiKey]) : _apiKey = apiKey;

  /// 更新API密钥
  void updateApiKey(String? apiKey) {
    _apiKey = apiKey;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_apiKey == null || _apiKey!.isEmpty) {
      super.onRequest(options, handler);
      return;
    }

    // 1Panel服务器要求使用秒级时间戳
    final authHeaders = OnePanelAuthHeaders.build(_apiKey!);

    // 添加1Panel API服务器要求的认证头部。
    // Accept 允许调用方覆盖：SSE 端点（如 /containers/search/log）必须
    // 声明 text/event-stream，覆盖为 application/json 会导致服务端固定
    // 返回 data: null。
    options.headers.addAll({
      ...authHeaders,
      if (options.data is! FormData && options.contentType == null)
        'Content-Type': 'application/json',
      if (!options.headers.containsKey('Accept')) 'Accept': 'application/json',
      if (!kIsWeb) 'User-Agent': ApiConstants.userAgent,
    });

    super.onRequest(options, handler);
  }
}

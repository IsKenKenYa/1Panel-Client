import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/logger/logger_service.dart';
import '../config/api_constants.dart';
import 'auth_failure_diagnostics.dart';
import 'network_exceptions.dart';
import 'browser_connection_policy.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/business_response_interceptor.dart';

/// 基于Dio的HTTP客户端 - 支持1Panel API认证
class DioClient {
  final Dio _dio;
  late AuthInterceptor _authInterceptor;

  DioClient({
    String? baseUrl,
    String? apiKey,
    bool allowInsecureTls = false,
  }) : _dio = Dio(_createBaseOptionsStatic(baseUrl)) {
    _authInterceptor = AuthInterceptor(apiKey);
    _configureTls(allowInsecureTls);
    _addInterceptors();
  }

  /// 创建基础配置（静态方法，用于构造函数）
  static BaseOptions _createBaseOptionsStatic(String? baseUrl) {
    if (kIsWeb && baseUrl != null &&
        BrowserConnectionPolicy.issue(baseUrl) != null) {
      throw ArgumentError('需要有效的 HTTP 或 HTTPS 面板地址');
    }
    return BaseOptions(
      baseUrl: baseUrl ?? ApiConstants.defaultBaseUrl,
      connectTimeout: const Duration(seconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(seconds: ApiConstants.receiveTimeout),
      sendTimeout: const Duration(seconds: ApiConstants.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (!kIsWeb) 'User-Agent': ApiConstants.userAgent,
      },
      responseType: ResponseType.json,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    );
  }

  /// 添加拦截器
  void _addInterceptors() {
    _dio.interceptors.add(_authInterceptor);
    _dio.interceptors.add(BusinessResponseInterceptor());
    _dio.interceptors.add(LoggingInterceptor(ApiConstants.isDebugMode, !kIsWeb));
    _dio.interceptors.add(RetryInterceptor());
  }

  void _configureTls(bool allowInsecureTls) {
    if (!allowInsecureTls || kIsWeb) {
      return;
    }

    final adapter = _dio.httpClientAdapter;
    try {
      (adapter as dynamic).onHttpClientCreate = (dynamic httpClient) {
        httpClient.badCertificateCallback =
            (dynamic cert, String host, int port) => true;
        return httpClient;
      };
      _safeLog('w', '[network] Insecure TLS certificate validation enabled');
    } catch (_) {
      _safeLog(
        'w',
        '[network] Failed to enable insecure TLS mode for current adapter',
      );
    }
  }

  /// 安全日志输出
  void _safeLog(String level, String message) {
    try {
      final logger = AppLogger();
      switch (level) {
        case 'd':
          logger.d(message);
          break;
        case 'e':
          logger.e(message);
          break;
        case 'w':
          logger.w(message);
          break;
        default:
          logger.i(message);
      }
    } catch (_) {
      // 忽略日志错误
      return;
    }
  }

  /// 执行请求并统一处理错误 - 返回完整Response对象
  Future<Response<T>> _executeRequest<T>(
    Future<Response<T>> Function() requestFunction,
  ) async {
    try {
      final response = await requestFunction();
      _throwIfHtmlFallbackPage(response);
      return response;
    } on DioException catch (e) {
      _safeLog('e',
          kIsWeb
              ? '[network] DioException: ${e.type}, status: ${e.response?.statusCode}'
              : '[network] DioException: ${e.type}, message: ${e.message}, response: ${e.response?.data}');
      throw _convertException(e);
    } on EndpointNotFoundException {
      rethrow;
    } catch (e) {
      _safeLog('e', '[network] Unexpected error: ${kIsWeb ? e.runtimeType : e}');
      throw NetworkConnectionException('请求失败: $e');
    }
  }

  /// 识别 1Panel 服务端的 SPA 回退页。
  ///
  /// 服务端对不存在的路由返回 HTTP 200 + index.html（content-type 为
  /// text/html），客户端若按 JSON 信封解析会抛出 TypeError 或静默返回脏数据。
  /// 此处仅对 /api/ 前缀、期望 JSON 的请求生效；download() 走独立路径
  /// （文件下载/预览可能合法返回 HTML），不受影响。
  void _throwIfHtmlFallbackPage<T>(Response<T> response) {
    final path = response.requestOptions.uri.path;
    if (!path.contains('/api/')) {
      return;
    }
    final data = response.data;
    if (data is! String) {
      return;
    }
    final contentType =
        response.headers.value(Headers.contentTypeHeader) ?? '';
    final normalized = data.trimLeft().toLowerCase();
    final looksLikeHtml = normalized.startsWith('<!doctype html') ||
        normalized.startsWith('<html');
    if (!looksLikeHtml && !contentType.contains('text/html')) {
      return;
    }
    _safeLog('e', '[network] SPA fallback page detected for $path');
    throw EndpointNotFoundException(
      '当前面板版本不支持该功能',
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
    );
  }

  /// 转换DioException为自定义异常
  Exception _convertException(DioException e) {
    final statusCode = e.response?.statusCode;
    final errorMessage = e.message ?? e.toString();
    final responseData = e.response?.data;

    _safeLog('d',
        kIsWeb
            ? '[network] Converting exception: type=${e.type}, statusCode=$statusCode'
            : '[network] Converting exception: type=${e.type}, statusCode=$statusCode, message=$errorMessage');

    // HTML 回退页 + Map 泛型请求：Dio 在 transform 阶段对 String body 做
    // Map 强转即抛 TypeError（包装为 DioException.unknown 且 response 为
    // null），来不及走 _throwIfHtmlFallbackPage，此处还原为端点不存在语义。
    if (e.type == DioExceptionType.unknown &&
        e.error is TypeError &&
        e.requestOptions.uri.path.contains('/api/')) {
      return EndpointNotFoundException(
        '当前面板版本不支持该功能',
        requestOptions: e.requestOptions,
      );
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkConnectionException(
        '网络连接失败: $errorMessage',
        requestOptions: e.requestOptions,
      );
    }

    if (statusCode == 401) {
      return AuthException(
        AuthFailureDiagnostics.describe(e),
        requestOptions: e.requestOptions,
        statusCode: statusCode,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return ServerException(
        '服务器错误($statusCode): $errorMessage',
        requestOptions: e.requestOptions,
        statusCode: statusCode,
      );
    }

    if (statusCode != null && statusCode >= 400) {
      return HttpException(
        'HTTP错误($statusCode): ${responseData ?? errorMessage}',
        requestOptions: e.requestOptions,
        statusCode: statusCode,
      );
    }

    return HttpException(
      '请求失败: $errorMessage',
      requestOptions: e.requestOptions,
      statusCode: statusCode,
    );
  }

  /// GET请求 - 返回完整Response对象
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _executeRequest(() => _dio.get<T>(
          path,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  /// POST请求 - 返回完整Response对象
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _executeRequest(() => _dio.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  /// PUT请求 - 返回完整Response对象
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _executeRequest(() => _dio.put<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  /// DELETE请求 - 返回完整Response对象
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _executeRequest(() => _dio.delete<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  /// PATCH请求 - 返回完整Response对象
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _executeRequest(() => _dio.patch<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  /// 文件上传
  Future<Response<T>> upload<T>(
    String path,
    FormData formData, {
    ProgressCallback? onSendProgress,
    Options? options,
  }) {
    return _executeRequest(() => _dio.post<T>(
          path,
          data: formData,
          options: options,
          onSendProgress: onSendProgress,
        ));
  }

  /// 文件下载
  Future<Response> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Options? options,
  }) async {
    try {
      return await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: options,
      );
    } on DioException catch (e) {
      throw _convertException(e);
    }
  }

  /// 更新认证信息
  void updateAuth(String? apiKey) {
    _authInterceptor.updateApiKey(apiKey);
    _safeLog('d', '[network] Auth updated with new API key');
  }

  /// 获取Dio实例（用于高级用法）
  Dio get dio => _dio;
}

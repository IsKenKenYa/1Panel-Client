import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../core/services/logger/logger_service.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/setting_models.dart' show PasskeyInfo;
import 'api_response_parser.dart';

class AuthV2Api {
  final DioClient _client;

  AuthV2Api(this._client);

  dynamic _extractDataRaw(dynamic payload) {
    return ApiResponseParser.unwrap(payload);
  }

  Map<String, dynamic>? _extractDataMap(
    dynamic data, {
    bool fallbackToRootMap = false,
  }) {
    if (data is! Map) {
      return null;
    }
    final parsed = ApiResponseParser.asMap(
      data,
      fallbackToRootMap: fallbackToRootMap,
    );
    if (parsed.isNotEmpty) {
      return parsed;
    }
    return null;
  }

  String? _extractStringData(dynamic data) {
    final raw = _extractDataRaw(data);
    if (raw is String && raw.trim().isNotEmpty) {
      if (_looksLikeHtmlPage(raw)) {
        appLogger.wWithPackage(
            'api.v2.auth', 'API returned HTML instead of JSON, endpoint may not exist');
        return null;
      }
      return raw;
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final key in <String>['language', 'value', 'data', 'message']) {
        final value = map[key];
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  CaptchaData? _extractCaptchaData(dynamic data) {
    final raw = _extractDataRaw(data);
    if (raw is String && raw.trim().isNotEmpty) {
      if (_looksLikeHtmlPage(raw)) {
        return null;
      }
      return CaptchaData(base64: raw);
    }
    if (raw is Map) {
      final parsed = CaptchaData.fromJson(Map<String, dynamic>.from(raw));
      if (parsed.base64 != null ||
          parsed.imagePath != null ||
          parsed.captchaId != null) {
        return parsed;
      }
    }
    return null;
  }

  // Some endpoints return an HTML error page instead of JSON when the
  // resource does not exist (e.g. captcha on older servers).
  bool _looksLikeHtmlPage(String value) {
    final normalized = value.trimLeft().toLowerCase();
    return normalized.startsWith('<!doctype html') ||
        normalized.startsWith('<html');
  }

  Map<String, dynamic> _extractBoolOrMapData(
    dynamic data, {
    required String key,
  }) {
    final raw = _extractDataRaw(data);
    if (raw is bool) {
      return <String, dynamic>{key: raw};
    }
    return _extractDataMap(data, fallbackToRootMap: true) ??
        const <String, dynamic>{};
  }

  // EntranceCode is a 1Panel security feature: a secret URL suffix that
  // must be sent as a header to access the login endpoint.
  Options? _withEntranceCode(String? entranceCode) {
    final normalized = entranceCode?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return Options(headers: <String, dynamic>{'EntranceCode': normalized});
  }

  /// 获取验证码
  ///
  /// 获取登录验证码图片
  /// @return 验证码数据
  Future<Response<CaptchaData?>> getCaptcha() async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/core/auth/captcha'),
    );
    return Response<CaptchaData?>(
      data: _extractCaptchaData(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  /// 检查系统是否为演示模式
  ///
  /// @return 演示模式状态
  Future<Response<Map<String, dynamic>>> checkDemoMode() async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/core/auth/demo'),
    );
    return Response<Map<String, dynamic>>(
      data: _extractBoolOrMapData(response.data, key: 'demo'),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  /// 获取安全状态
  ///
  /// @return 安全状态信息
  Future<Response<Map<String, dynamic>>> getSafetyStatus() async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/core/auth/issafety'),
    );
    return Response<Map<String, dynamic>>(
      data: _extractBoolOrMapData(response.data, key: 'issafety'),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  /// 获取系统语言
  ///
  /// @return 系统语言设置
  Future<Response<String>> getSystemLanguage() async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/core/auth/language'),
    );
    return Response<String>(
      data: _extractStringData(response.data) ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  /// 用户登录
  ///
  /// 使用用户名和密码进行登录
  /// @param request 登录请求
  /// @return 登录结果
  Future<Response<Map<String, dynamic>>> login(
    Map<String, dynamic> request, {
    String? entranceCode,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/auth/login'),
      data: request,
      options: _withEntranceCode(entranceCode),
    );
    return Response(
      data: _extractDataMap(response.data) ?? const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  /// 用户登出
  ///
  /// 退出当前用户会话
  /// @return 登出结果
  Future<Response<Map<String, dynamic>>> logout() async {
    final response = await _client.post<dynamic>(
      ApiConstants.buildApiPath('/core/auth/logout'),
    );
    return Response<Map<String, dynamic>>(
      data: _extractDataMap(response.data) ?? const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  /// 多因素认证登录
  ///
  /// 使用MFA码进行登录验证
  /// @param request MFA登录请求
  /// @return 登录结果
  Future<Response<Map<String, dynamic>>> mfaLogin(
    Map<String, dynamic> request, {
    String? entranceCode,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/auth/mfalogin'),
      data: request,
      options: _withEntranceCode(entranceCode),
    );
    return Response(
      data: _extractDataMap(response.data) ?? const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  Future<Response<PasskeyBeginResponse?>> passkeyBeginLogin({
    String? entranceCode,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/auth/passkey/begin'),
      options: _withEntranceCode(entranceCode),
    );
    final data = _extractDataMap(response.data);
    return Response<PasskeyBeginResponse?>(
      data: data == null ? null : PasskeyBeginResponse.fromJson(data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  Future<Response<Map<String, dynamic>>> passkeyFinishLogin({
    required Map<String, dynamic> credential,
    required String sessionId,
    String? entranceCode,
  }) async {
    final headers = <String, dynamic>{
      'Passkey-Session': sessionId,
      if (entranceCode != null && entranceCode.trim().isNotEmpty)
        'EntranceCode': entranceCode.trim(),
    };
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/auth/passkey/finish'),
      data: credential,
      options: Options(headers: headers),
    );
    return Response<Map<String, dynamic>>(
      data: _extractDataMap(response.data, fallbackToRootMap: true) ??
          const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  /// 获取登录设置
  ///
  /// 获取系统登录相关设置信息
  /// @return 登录设置
  Future<Response<Map<String, dynamic>>> getLoginSettings() async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/core/auth/setting'),
    );
    return Response<Map<String, dynamic>>(
      data: _extractDataMap(response.data) ?? const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  // ==================== New auth endpoints (R5 API adaptation) ====================

  /// Get welcome page content.
  Future<Response<String>> getWelcome() async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/core/auth/welcome'),
    );
    return Response<String>(
      data: _extractStringData(response.data) ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  /// Load current user info.
  Future<Response<Map<String, dynamic>>> getCurrentUser() async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/core/auth/current'),
      options: DioClient.sensitiveOptions,
    );
    return Response<Map<String, dynamic>>(
      data: _extractDataMap(response.data) ?? const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  /// Update current user info.
  Future<Response<Map<String, dynamic>>> updateCurrentUser(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/auth/current/update'),
      data: request,
      options: DioClient.sensitiveOptions,
    );
    return Response<Map<String, dynamic>>(
      data: _extractDataMap(response.data) ?? const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  /// Load MFA info (auth-scoped endpoint).
  Future<Response<Map<String, dynamic>>> loadMfaInfo(
      Map<String, dynamic> request) async {
    final response = await _client.post<dynamic>(
      ApiConstants.buildApiPath('/core/auth/mfa'),
      data: request,
      options: DioClient.sensitiveOptions,
    );
    return Response<Map<String, dynamic>>(
      data: _extractDataMap(response.data) ?? const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  /// Bind MFA.
  Future<Response<Map<String, dynamic>>> bindMfa(
      Map<String, dynamic> request) async {
    final response = await _client.post<dynamic>(
      ApiConstants.buildApiPath('/core/auth/mfa/bind'),
      data: request,
      options: DioClient.sensitiveOptions,
    );
    return Response<Map<String, dynamic>>(
      data: _extractDataMap(response.data) ?? const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  /// Close/unbind MFA.
  Future<Response<Map<String, dynamic>>> closeMfa() async {
    final response = await _client.post<dynamic>(
      ApiConstants.buildApiPath('/core/auth/mfa/close'),
      options: DioClient.sensitiveOptions,
    );
    return Response<Map<String, dynamic>>(
      data: _extractDataMap(response.data) ?? const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  /// Generate API key.
  Future<Response<String>> generateApiKey() async {
    final response = await _client.post<dynamic>(
      ApiConstants.buildApiPath('/core/auth/api/generate'),
      options: DioClient.sensitiveOptions,
    );
    final key = _extractDataRaw(response.data);
    if (key is! String || key.isEmpty) {
      throw const FormatException('面板未返回 API 密钥');
    }
    return ApiResponseParser.withData(response, key);
  }

  /// Update API config.
  Future<Response<Map<String, dynamic>>> updateApiConfig(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/auth/api/update'),
      data: request,
      options: DioClient.sensitiveOptions,
    );
    return Response<Map<String, dynamic>>(
      data: _extractDataMap(response.data) ?? const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  /// Reset expired password.
  Future<Response<Map<String, dynamic>>> resetExpiredPassword(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/auth/expired/reset'),
      data: request,
    );
    return Response<Map<String, dynamic>>(
      data: _extractDataMap(response.data) ?? const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  /// List passkeys (auth-scoped endpoint).
  Future<List<PasskeyInfo>> listPasskeysAuth() async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/core/auth/passkey/list'),
      options: DioClient.sensitiveOptions,
    );
    final raw = _extractDataRaw(response.data);
    if (raw is! List) {
      throw const FormatException('Passkey 列表格式无效');
    }
    return raw.cast<Map<String, dynamic>>().map(PasskeyInfo.fromJson).toList();
  }

  /// Delete passkey (auth-scoped endpoint).
  Future<void> deletePasskeyAuth(String id) async {
    await _client.post<dynamic>(
      ApiConstants.buildApiPath('/core/auth/passkey/del'),
      data: {'id': id},
      options: DioClient.sensitiveOptions,
    );
  }

  /// Begin passkey registration (auth-scoped endpoint).
  Future<Response<PasskeyBeginResponse?>> beginPasskeyRegisterAuth(String name) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/auth/passkey/register/begin'),
      data: {'name': name},
      options: DioClient.sensitiveOptions,
    );
    final data = _extractDataMap(response.data);
    return Response<PasskeyBeginResponse?>(
      data: data == null ? null : PasskeyBeginResponse.fromJson(data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  /// Finish passkey registration (auth-scoped endpoint).
  Future<void> finishPasskeyRegisterAuth({
    required String sessionId,
    required Map<String, dynamic> credential,
  }) async {
    await _client.post<dynamic>(
      ApiConstants.buildApiPath('/core/auth/passkey/register/finish'),
      data: credential,
      options: DioClient.sensitiveOptions.copyWith(headers: <String, dynamic>{
        'Passkey-Session': sessionId,
      }),
    );
  }
}

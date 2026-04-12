import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/auth_models.dart';
import 'api_response_parser.dart';

class AuthV2Api {
  final DioClient _client;

  AuthV2Api(this._client);

  Map<String, dynamic>? _extractDataMap(dynamic data) {
    if (data is! Map) {
      return null;
    }
    final parsed = ApiResponseParser.asMap(data, fallbackToRootMap: true);
    if (parsed.isNotEmpty) {
      return parsed;
    }
    return null;
  }

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
  Future<Response<String>> getCaptcha() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/core/auth/captcha'),
    );
    return Response(
      data: response.data.toString(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 检查系统是否为演示模式
  ///
  /// @return 演示模式状态
  Future<Response<Map<String, dynamic>>> checkDemoMode() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/core/auth/demo'),
    );
    return Response(
      data: response.data as Map<String, dynamic>,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取安全状态
  ///
  /// @return 安全状态信息
  Future<Response<Map<String, dynamic>>> getSafetyStatus() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/core/auth/issafety'),
    );
    return Response(
      data: response.data as Map<String, dynamic>,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取系统语言
  ///
  /// @return 系统语言设置
  Future<Response<String>> getSystemLanguage() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/core/auth/language'),
    );
    return Response(
      data: response.data.toString(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
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
    final response = await _client.post(
      ApiConstants.buildApiPath('/core/auth/logout'),
    );
    return Response(
      data: response.data as Map<String, dynamic>,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
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

  /// 获取登录设置
  ///
  /// 获取系统登录相关设置信息
  /// @return 登录设置
  Future<Response<Map<String, dynamic>>> getLoginSettings() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/core/auth/setting'),
    );
    return Response(
      data: response.data as Map<String, dynamic>,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }
}

import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';

class AuthV2Api {
  final DioClient _client;

  AuthV2Api(this._client);

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
      Map<String, dynamic> request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/core/auth/login'),
      data: request,
    );
    return Response(
      data: response.data as Map<String, dynamic>,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
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
      Map<String, dynamic> request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/core/auth/mfalogin'),
      data: request,
    );
    return Response(
      data: response.data as Map<String, dynamic>,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
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

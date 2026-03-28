import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/user_models.dart';
import '../../data/models/common_models.dart';

class UserV2Api {
  final DioClient _client;

  UserV2Api(this._client);

  /// 用户登录
  ///
  /// 用户登录认证
  /// @param login 登录信息
  /// @return 登录结果
  Future<Response<UserLoginResponse>> login(UserLogin login) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/core/auth/login'),
      data: login.toJson(),
    );
    return Response(
      data: UserLoginResponse.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 用户登出
  ///
  /// 用户登出
  /// @return 登出结果
  Future<Response> logout() async {
    return await _client.post(
      ApiConstants.buildApiPath('/core/auth/logout'),
    );
  }

  /// MFA登录
  ///
  /// 多因子认证登录
  /// @param mfaLogin MFA登录信息
  /// @return 登录结果
  Future<Response<UserLoginResponse>> mfaLogin(UserMFALogin mfaLogin) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/core/auth/mfalogin'),
      data: mfaLogin.toJson(),
    );
    return Response(
      data: UserLoginResponse.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取验证码
  ///
  /// 获取登录验证码
  /// @return 验证码图片
  Future<Response<CaptchaResponse>> getCaptcha() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/core/auth/captcha'),
    );
    return Response(
      data: CaptchaResponse.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取认证设置
  ///
  /// 获取认证相关设置
  /// @return 认证设置
  Future<Response<AuthSettings>> getAuthSettings() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/core/auth/setting'),
    );
    return Response(
      data: AuthSettings.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取用户列表
  ///
  /// 获取所有用户列表
  /// @param search 搜索关键词（可选）
  /// @param role 用户角色（可选）
  /// @param status 用户状态（可选）
  /// @param page 页码（可选，默认为1）
  /// @param pageSize 每页数量（可选，默认为10）
  /// @return 用户列表
  Future<Response<PageResult<UserInfo>>> getUsers({
    String? search,
    String? role,
    UserStatus? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    final request = UserSearch(
      page: page,
      pageSize: pageSize,
      search: search,
      role: role,
      status: status,
    );
    final response = await _client.post(
      ApiConstants.buildApiPath('/users/search'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserInfo.fromJson(json as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 创建用户
  ///
  /// 创建新用户
  /// @param user 用户信息
  /// @return 创建结果
  Future<Response> createUser(UserCreate user) async {
    return await _client.post(
      ApiConstants.buildApiPath('/users'),
      data: user.toJson(),
    );
  }

  /// 获取用户详情
  ///
  /// 获取指定用户的详细信息
  /// @param id 用户ID
  /// @return 用户详情
  Future<Response<UserInfo>> getUserDetail(int id) async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/users/$id'),
    );
    return Response(
      data: UserInfo.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新用户
  ///
  /// 更新用户信息
  /// @param user 用户更新信息
  /// @return 更新结果
  Future<Response> updateUser(UserUpdate user) async {
    return await _client.post(
      ApiConstants.buildApiPath('/users/${user.id}'),
      data: user.toJson(),
    );
  }

  /// 删除用户
  ///
  /// 删除指定的用户
  /// @param ids 用户ID列表
  /// @return 删除结果
  Future<Response> deleteUser(List<int> ids) async {
    final operation = BatchDelete(ids: ids);
    return await _client.post(
      ApiConstants.buildApiPath('/users/del'),
      data: operation.toJson(),
    );
  }

  /// 启用用户
  ///
  /// 启用指定的用户
  /// @param ids 用户ID列表
  /// @return 启用结果
  Future<Response> enableUser(List<int> ids) async {
    final operation = UserOperate(ids: ids, operation: 'enable');
    return await _client.post(
      ApiConstants.buildApiPath('/users/enable'),
      data: operation.toJson(),
    );
  }

  /// 禁用用户
  ///
  /// 禁用指定的用户
  /// @param ids 用户ID列表
  /// @return 禁用结果
  Future<Response> disableUser(List<int> ids) async {
    final operation = UserOperate(ids: ids, operation: 'disable');
    return await _client.post(
      ApiConstants.buildApiPath('/users/disable'),
      data: operation.toJson(),
    );
  }

  /// 重置用户密码
  ///
  /// 重置指定用户的密码
  /// @param id 用户ID
  /// @param password 新密码
  /// @return 重置结果
  Future<Response> resetUserPassword({
    required int id,
    required String password,
  }) async {
    final update = UserUpdate(
      id: id,
      password: password,
    );
    return await _client.post(
      ApiConstants.buildApiPath('/users/$id/password/reset'),
      data: update.toJson(),
    );
  }

  /// 修改当前用户密码
  ///
  /// 修改当前用户的密码
  /// @param oldPassword 旧密码
  /// @param newPassword 新密码
  /// @return 修改结果
  Future<Response> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final data = {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };
    return await _client.post(
      ApiConstants.buildApiPath('/users/password/change'),
      data: data,
    );
  }

  /// 获取当前用户信息
  ///
  /// 获取当前登录用户的信息
  /// @return 当前用户信息
  Future<Response<UserInfo>> getCurrentUser() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/users/current'),
    );
    return Response(
      data: UserInfo.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新当前用户信息
  ///
  /// 更新当前登录用户的信息
  /// @param user 用户更新信息
  /// @return 更新结果
  Future<Response> updateCurrentUser(UserUpdate user) async {
    return await _client.post(
      ApiConstants.buildApiPath('/users/current'),
      data: user.toJson(),
    );
  }

  /// 获取角色列表
  ///
  /// 获取所有用户角色列表
  /// @return 角色列表
  Future<Response<List<Role>>> getRoles() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/users/roles'),
    );
    return Response(
      data: (response.data as List?)
              ?.map((item) => Role.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取权限列表
  ///
  /// 获取所有用户权限列表
  /// @return 权限列表
  Future<Response<List<Permission>>> getPermissions() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/users/permissions'),
    );
    return Response(
      data: (response.data as List?)
              ?.map((item) => Permission.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取用户会话列表
  ///
  /// 获取用户会话列表
  /// @param userId 用户ID（可选）
  /// @param page 页码（可选，默认为1）
  /// @param pageSize 每页数量（可选，默认为10）
  /// @return 会话列表
  Future<Response<PageResult<UserSession>>> getUserSessions({
    int? userId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final data = {
      'page': page,
      'pageSize': pageSize,
      if (userId != null) 'userId': userId,
    };
    final response = await _client.post(
      ApiConstants.buildApiPath('/users/sessions/search'),
      data: data,
    );
    return Response(
      data: PageResult.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserSession.fromJson(json as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 强制用户下线
  ///
  /// 强制指定用户下线
  /// @param sessionIds 会话ID列表
  /// @return 下线结果
  Future<Response> forceLogoutUser(List<String> sessionIds) async {
    final data = {
      'sessionIds': sessionIds,
    };
    return await _client.post(
      ApiConstants.buildApiPath('/users/force-logout'),
      data: data,
    );
  }
}

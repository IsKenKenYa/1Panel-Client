import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/common_models.dart';
import '../../data/models/ssh_cert_models.dart';
import '../../data/models/ssh_log_models.dart';
import '../../data/models/ssh_settings_models.dart';

class SshV2Api {
  SshV2Api(this._client);

  final DioClient _client;

  Future<Response<SshInfo>> getSshInfo() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/hosts/ssh/search'),
    );
    return Response<SshInfo>(
      data: SshInfo.fromJson(
        response.data?['data'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> operateSsh(SshOperateRequest request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/hosts/ssh/operate'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> updateSsh(SshUpdateRequest request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/hosts/ssh/update'),
      data: request.toJson(),
    );
  }

  Future<Response<String>> loadSshFile(SshFileLoadRequest request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/hosts/ssh/file'),
      data: request.toJson(),
    );
    return Response<String>(
      data: response.data?['data'] as String? ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> updateSshFile(SshFileUpdateRequest request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/hosts/ssh/file/update'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> createSshCert(SshCertOperate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/hosts/ssh/cert'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> updateSshCert(SshCertOperate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/hosts/ssh/cert/update'),
      data: request.toJson(),
    );
  }

  Future<Response<PageResult<SshCertInfo>>> searchSshCerts(
    SshCertSearchRequest request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/hosts/ssh/cert/search'),
      data: request.toJson(),
    );
    return Response<PageResult<SshCertInfo>>(
      data: PageResult<SshCertInfo>.fromJson(
        response.data?['data'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
        (dynamic item) => SshCertInfo.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> deleteSshCerts(ForceDelete request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/hosts/ssh/cert/delete'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> syncSshCerts() {
    return _client
        .post<void>(ApiConstants.buildApiPath('/hosts/ssh/cert/sync'));
  }

  Future<Response<PageResult<SshLogEntry>>> searchSshLogs(
    SshLogSearchRequest request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/hosts/ssh/log'),
      data: request.toJson(),
    );
    return Response<PageResult<SshLogEntry>>(
      data: PageResult<SshLogEntry>.fromJson(
        response.data?['data'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
        (dynamic item) => SshLogEntry.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<String>> exportSshLogs(SshLogSearchRequest request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/hosts/ssh/log/export'),
      data: request.toJson(),
    );
    return Response<String>(
      data: response.data?['data'] as String? ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // ==================== SSH 设置模块 ====================

  /// 加载本地 SSH 连接信息
  Future<Response<SshLocalConnectionInfo>> getSshConn() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/settings/ssh/conn'),
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    return Response<SshLocalConnectionInfo>(
      data: SshLocalConnectionInfo.fromJson(data ?? const <String, dynamic>{}),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新 SSH 设置
  Future<Response<void>> updateSshSettings(Map<String, dynamic> request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/settings/ssh'),
      data: request,
    );
  }

  /// 检查 SSH 基础信息
  Future<Response<bool>> checkSshInfo({
    SshLocalConnectionInfo? request,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/settings/ssh/check/info'),
      data: request?.toJson(),
    );
    final data = response.data?['data'] as bool?;
    return Response<bool>(
      data: data,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 设置默认 SSH 连接
  Future<Response<void>> setDefaultSshConn(
    SshDefaultConnectionVisibilityUpdate request,
  ) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/settings/ssh/conn/default'),
      data: request.toJson(),
    );
  }

  /// 获取Fail2ban SSHD运行状态
  Future<Response<void>> getFail2banSshdStatus() async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/toolbox/fail2ban/operate/sshd'),
      data: const <String, dynamic>{'operate': 'status'},
    );
  }

  /// 启动/停止 Fail2ban SSHD (操作: start, stop, restart)
  Future<Response<void>> operateFail2banSshd(Map<String, dynamic> request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/toolbox/fail2ban/operate/sshd'),
      data: request,
    );
  }
}

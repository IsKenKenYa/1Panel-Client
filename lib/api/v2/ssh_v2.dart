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
        response.data?['data'] as Map<String, dynamic>? ?? const <String, dynamic>{},
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
        response.data?['data'] as Map<String, dynamic>? ?? const <String, dynamic>{},
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
    return _client.post<void>(ApiConstants.buildApiPath('/hosts/ssh/cert/sync'));
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
        response.data?['data'] as Map<String, dynamic>? ?? const <String, dynamic>{},
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
}

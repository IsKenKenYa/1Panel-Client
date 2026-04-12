import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/common_models.dart';
import '../../data/models/container_models.dart';
import '../../data/models/logs_models.dart';

class LogsV2Api {
  LogsV2Api(this._client);

  final DioClient _client;

  Future<Response<PageResult<LoginLogEntry>>> searchLoginLogs(
    LoginLogSearchRequest request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/logs/login'),
      data: request.toJson(),
    );
    return Response<PageResult<LoginLogEntry>>(
      data: PageResult.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
        (dynamic item) => LoginLogEntry.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<PageResult<OperationLogEntry>>> searchOperationLogs(
    OperationLogSearchRequest request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/logs/operation'),
      data: request.toJson(),
    );
    return Response<PageResult<OperationLogEntry>>(
      data: PageResult.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
        (dynamic item) =>
            OperationLogEntry.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> cleanLogs(LogsCleanRequest request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/logs/clean'),
      data: request.toJson(),
    );
  }

  Future<Response<List<String>>> getSystemLogFiles() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/logs/system/files'),
    );
    final rawItems = response.data?['data'] as List<dynamic>? ?? const [];
    return Response<List<String>>(
      data: rawItems.map((dynamic item) => item.toString()).toList(
            growable: false,
          ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<dynamic>> searchContainerLogs({
    required String container,
    String? since,
    bool? follow,
    String? tail,
  }) {
    final queryParams = <String, dynamic>{'container': container};
    if (since != null) queryParams['since'] = since;
    if (follow != null) queryParams['follow'] = follow.toString();
    if (tail != null) queryParams['tail'] = tail;
    return _client.get<dynamic>(
      ApiConstants.buildApiPath('/containers/search/log'),
      queryParameters: queryParams,
      options: Options(responseType: ResponseType.plain),
    );
  }

  Future<Response<void>> cleanContainerLogs(OperationWithName request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/containers/clean/log'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> cleanComposeLogs(
    ContainerComposeLogCleanRequest request,
  ) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/containers/compose/clean/log'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> updateContainerLogOptions(LogOption request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/containers/logoption/update'),
      data: request.toJson(),
    );
  }

  Future<Response<String>> getCronjobRecordLog(OperateByID request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/cronjobs/records/log'),
      data: request.toJson(),
    );
    return Response<String>(
      data: response.data?['data']?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }
}

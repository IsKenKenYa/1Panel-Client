import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/common_models.dart';
import '../../data/models/cronjob_models.dart';

class CronjobV2Api {
  CronjobV2Api(this._client);

  final DioClient _client;

  Future<Response<void>> createCronjob(CronJobCreate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/cronjobs'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> updateCronjob(CronJobUpdate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/cronjobs/update'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> deleteCronjob(OperateByIDs request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/cronjobs/del'),
      data: request.toJson(),
    );
  }

  Future<Response<PageResult<CronJobInfo>>> searchCronjobs(
    CronJobSearch request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/cronjobs/search'),
      data: request.toJson(),
    );
    return Response<PageResult<CronJobInfo>>(
      data: PageResult.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
        (dynamic item) => CronJobInfo.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<List<String>>> loadNextHandle(String spec) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/cronjobs/next'),
      data: <String, dynamic>{'spec': spec},
    );
    final rawItems = response.data?['data'] as List<dynamic>? ?? const [];
    return Response<List<String>>(
      data: rawItems
          .map((dynamic item) => item.toString())
          .toList(growable: false),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<Map<String, dynamic>>> loadCronjobInfo(int id) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/cronjobs/load/info'),
      data: <String, dynamic>{'id': id},
    );
    return Response<Map<String, dynamic>>(
      data: response.data?['data'] as Map<String, dynamic>? ?? const {},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> stopCronjob(int id) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/cronjobs/stop'),
      data: <String, dynamic>{'id': id},
    );
  }

  Future<Response<void>> updateCronjobStatus({
    required int id,
    required String status,
  }) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/cronjobs/status'),
      data: <String, dynamic>{'id': id, 'status': status},
    );
  }

  Future<Response<void>> handleCronjobOnce(int id) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/cronjobs/handle'),
      data: <String, dynamic>{'id': id},
    );
  }

  Future<Response<void>> updateCronjobGroup({
    required int id,
    required int groupId,
  }) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/cronjobs/group/update'),
      data: <String, dynamic>{'id': id, 'groupID': groupId},
    );
  }

  Future<Response<PageResult<CronJobLog>>> searchCronjobRecords(
    SearchWithPage request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/cronjobs/search/records'),
      data: request.toJson(),
    );
    return Response<PageResult<CronJobLog>>(
      data: PageResult.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
        (dynamic item) => CronJobLog.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<String>> getRecordLog(int id) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/cronjobs/records/log'),
      data: <String, dynamic>{'id': id},
    );
    return Response<String>(
      data: response.data?['data'] as String? ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> cleanRecords({
    required int cronjobId,
    required bool cleanData,
    required bool cleanRemoteData,
  }) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/cronjobs/records/clean'),
      data: <String, dynamic>{
        'cronjobID': cronjobId,
        'cleanData': cleanData,
        'cleanRemoteData': cleanRemoteData,
      },
    );
  }

  Future<Response<List<ScriptOptions>>> getScriptOptions() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/cronjobs/script/options'),
    );
    final rawItems = response.data?['data'] as List<dynamic>? ?? const [];
    return Response<List<ScriptOptions>>(
      data: rawItems
          .whereType<Map<String, dynamic>>()
          .map(ScriptOptions.fromJson)
          .toList(growable: false),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }
}

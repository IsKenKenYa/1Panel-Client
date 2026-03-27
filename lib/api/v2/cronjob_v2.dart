import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/common_models.dart';
import '../../data/models/cronjob_form_request_models.dart';
import '../../data/models/cronjob_form_response_models.dart';
import '../../data/models/cronjob_list_models.dart';
import '../../data/models/cronjob_record_models.dart';

class CronjobV2Api {
  CronjobV2Api(this._client);

  final DioClient _client;

  Future<Response<void>> createCronjob(CronjobOperateRequest request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/cronjobs'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> updateCronjob(CronjobOperateRequest request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/cronjobs/update'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> deleteCronjob(CronjobBatchDeleteRequest request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/cronjobs/del'),
      data: request.toJson(),
    );
  }

  Future<Response<PageResult<CronjobSummary>>> searchCronjobs(
    CronjobListQuery request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/cronjobs/search'),
      data: request.toJson(),
    );
    return Response<PageResult<CronjobSummary>>(
      data: PageResult<CronjobSummary>.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
        (dynamic item) => CronjobSummary.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<List<String>>> loadNextHandle(
    CronjobNextPreviewRequest request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/cronjobs/next'),
      data: request.toJson(),
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

  Future<Response<CronjobOperateResponse>> loadCronjobInfo(int id) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/cronjobs/load/info'),
      data: <String, dynamic>{'id': id},
    );
    return Response<CronjobOperateResponse>(
      data: CronjobOperateResponse.fromJson(
        response.data?['data'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
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

  Future<Response<void>> updateCronjobStatus(CronjobStatusUpdate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/cronjobs/status'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> handleCronjobOnce(CronjobHandleRequest request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/cronjobs/handle'),
      data: request.toJson(),
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

  Future<Response<PageResult<CronjobRecordInfo>>> searchCronjobRecords(
    CronjobRecordQuery request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/cronjobs/search/records'),
      data: request.toJson(),
    );
    return Response<PageResult<CronjobRecordInfo>>(
      data: PageResult<CronjobRecordInfo>.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
        (dynamic item) =>
            CronjobRecordInfo.fromJson(item as Map<String, dynamic>),
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

  Future<Response<void>> cleanRecords(CronjobRecordCleanRequest request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/cronjobs/records/clean'),
      data: request.toJson(),
    );
  }

  Future<Response<List<CronjobScriptOption>>> getScriptOptions() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/cronjobs/script/options'),
    );
    final rawItems = response.data?['data'] as List<dynamic>? ?? const [];
    return Response<List<CronjobScriptOption>>(
      data: rawItems
          .whereType<Map<String, dynamic>>()
          .map(CronjobScriptOption.fromJson)
          .toList(growable: false),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> importCronjobs(CronjobImportRequest request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/cronjobs/import'),
      data: request.toJson(),
    );
  }

  Future<Response<List<int>>> exportCronjobs(CronjobExportRequest request) {
    return _client.post<List<int>>(
      ApiConstants.buildApiPath('/cronjobs/export'),
      data: request.toJson(),
      options: Options(responseType: ResponseType.bytes),
    );
  }
}

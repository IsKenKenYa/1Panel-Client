import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/backup_account_models.dart';
import '../../data/models/backup_request_models.dart';
import '../../data/models/common_models.dart'
    hide CommonBackup, CommonRecover, RecordSearch;

class BackupAccountV2Api {
  BackupAccountV2Api(this._client);

  final DioClient _client;

  Future<Response<void>> createBackupAccount(BackupOperate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/backups'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> updateBackupAccount(BackupOperate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/backups/update'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> deleteBackupAccount(OperateByID request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/backups/del'),
      data: request.toJson(),
    );
  }

  Future<Response<PageResult<BackupAccountInfo>>> searchBackupAccounts(
    BackupAccountSearchRequest request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/backups/search'),
      data: request.toJson(),
    );
    return Response<PageResult<BackupAccountInfo>>(
      data: PageResult.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
        (dynamic item) =>
            BackupAccountInfo.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<List<BackupOption>>> getBackupAccountOptions() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/backups/options'),
    );
    final rawItems = response.data?['data'] as List<dynamic>? ?? const [];
    return Response<List<BackupOption>>(
      data: rawItems
          .whereType<Map<String, dynamic>>()
          .map(BackupOption.fromJson)
          .toList(growable: false),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<String>> getLocalBackupDir() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/backups/local'),
    );
    return Response<String>(
      data: response.data?['data']?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<BackupCheckResult>> checkBackupConnection(
    BackupOperate request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/backups/check'),
      data: request.toJson(),
    );
    return Response<BackupCheckResult>(
      data: BackupCheckResult.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<List<dynamic>>> getBuckets(
      BackupBucketRequest request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/backups/buckets'),
      data: request.toJson(),
    );
    final rawItems = response.data?['data'] as List<dynamic>? ?? const [];
    return Response<List<dynamic>>(
      data: rawItems.toList(growable: false),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> backupSystemData(
    BackupRunRequest request, {
    String operateNode = 'local',
  }) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/backups/backup'),
      data: request.toJson()..addAll({'operateNode': operateNode}),
    );
  }

  Future<Response<void>> recoverSystemData(
    BackupRecoverRequest request, {
    String operateNode = 'local',
  }) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/backups/recover'),
      data: request.toJson()..addAll({'operateNode': operateNode}),
    );
  }

  Future<Response<void>> recoverSystemDataFromUpload(
    BackupRecoverRequest request, {
    String operateNode = 'local',
  }) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/backups/recover/byupload'),
      data: request.toJson()..addAll({'operateNode': operateNode}),
    );
  }

  Future<Response<void>> uploadForRecover(
    BackupUploadRequest request, {
    String operateNode = 'local',
  }) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/backups/upload'),
      data: request.toJson()..addAll({'operateNode': operateNode}),
    );
  }

  Future<Response<String>> downloadBackupRecord(
    DownloadRecord request, {
    String operateNode = 'local',
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/backups/record/download'),
      data: request.toJson()..addAll({'operateNode': operateNode}),
    );
    return Response<String>(
      data: response.data?['data']?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<PageResult<BackupRecord>>> searchBackupRecords(
    BackupRecordQuery request, {
    String operateNode = 'local',
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/backups/record/search'),
      data: request.toJson()..addAll({'operateNode': operateNode}),
    );
    return Response<PageResult<BackupRecord>>(
      data: PageResult.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
        (dynamic item) => BackupRecord.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<PageResult<BackupRecord>>> searchBackupRecordsByCronjob(
    BackupRecordByCronjobQuery request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/backups/record/search/bycronjob'),
      data: request.toJson(),
    );
    return Response<PageResult<BackupRecord>>(
      data: PageResult.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
        (dynamic item) => BackupRecord.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<List<RecordFileSize>>> loadBackupRecordSizes(
    BackupRecordSizeQuery request, {
    String operateNode = 'local',
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/backups/record/size'),
      data: request.toJson(),
      queryParameters: <String, dynamic>{'operateNode': operateNode},
    );
    final rawItems = response.data?['data'] as List<dynamic>? ?? const [];
    return Response<List<RecordFileSize>>(
      data: rawItems
          .whereType<Map<String, dynamic>>()
          .map(RecordFileSize.fromJson)
          .toList(growable: false),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<List<String>>> listBackupFiles(OperateByID request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/backups/search/files'),
      data: request.toJson(),
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

  Future<Response<void>> deleteBackupRecords(
    BatchDelete request, {
    String operateNode = 'local',
  }) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/backups/record/del'),
      data: request.toJson(),
      queryParameters: <String, dynamic>{'operateNode': operateNode},
    );
  }

  Future<Response<void>> updateRecordDescription({
    required int id,
    required String description,
    String operateNode = 'local',
  }) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/backups/record/description/update'),
      data: <String, dynamic>{
        'id': id,
        'description': description,
      },
      queryParameters: <String, dynamic>{'operateNode': operateNode},
    );
  }

  Future<Response<void>> refreshBackupToken(OperateByID request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/backups/refresh/token'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> createCoreBackupAccount(BackupOperate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/backups'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> updateCoreBackupAccount(BackupOperate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/backups/update'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> deleteCoreBackupAccount(OperationWithName request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/backups/del'),
      data: <String, dynamic>{'name': request.name},
    );
  }

  Future<Response<void>> refreshCoreBackupToken(OperationWithName request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/backups/refresh/token'),
      data: <String, dynamic>{'name': request.name},
    );
  }

  Future<Response<BackupClientInfo>> getBackupClientInfo(
    String clientType,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/backups/client/$clientType'),
    );
    return Response<BackupClientInfo>(
      data: BackupClientInfo.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 创建备份账户
  Future<Response<void>> createBackupAccountCore(Map<String, dynamic> request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/core/backups'),
      data: request,
    );
  }

  /// 获取指定类型的客户端
  Future<Response<void>> getBackupClient(String type) async {
    return await _client.get<void>(
      ApiConstants.buildApiPath('/core/backups/client/$type'),
    );
  }

  /// 删除备份账户
  Future<Response<void>> deleteBackupAccountCore(Map<String, dynamic> request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/core/backups/del'),
      data: request,
    );
  }

  /// 刷新 OneDrive Token
  Future<Response<void>> refreshOneDriveToken(Map<String, dynamic> request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/core/backups/refresh/token'),
      data: request,
    );
  }

  /// 更新备份账户
  Future<Response<void>> updateBackupAccountCore(Map<String, dynamic> request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/core/backups/update'),
      data: request,
    );
  }
}

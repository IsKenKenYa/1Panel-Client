import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/backup_account_models.dart';
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
    BackupAccountSearch request,
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
      ApiConstants.buildApiPath('/backups/conn/check'),
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

  Future<Response<List<dynamic>>> getBuckets(BackupOperate request) async {
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

  Future<Response<void>> backupSystemData(CommonBackup request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/backups/backup'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> recoverSystemData(CommonRecover request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/backups/recover'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> recoverSystemDataFromUpload(CommonRecover request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/backups/recover/byupload'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> uploadForRecover({
    required String filePath,
    required String targetDir,
  }) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/backups/upload'),
      data: <String, dynamic>{
        'filePath': filePath,
        'targetDir': targetDir,
      },
    );
  }

  Future<Response<String>> downloadBackupRecord(DownloadRecord request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/backups/record/download'),
      data: request.toJson(),
    );
    return Response<String>(
      data: response.data?['data']?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<PageResult<BackupRecord>>> searchBackupRecords(
    RecordSearch request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/backups/record/search'),
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

  Future<Response<PageResult<BackupRecord>>> searchBackupRecordsByCronjob(
    RecordSearchByCronjob request,
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
    SearchForSize request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/backups/record/size'),
      data: request.toJson(),
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

  Future<Response<void>> deleteBackupRecords(BatchDelete request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/backups/record/del'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> updateRecordDescription({
    required int id,
    required String description,
  }) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/backups/record/description/update'),
      data: <String, dynamic>{
        'id': id,
        'description': description,
      },
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
}

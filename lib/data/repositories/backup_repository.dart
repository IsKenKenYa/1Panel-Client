import 'dart:convert';

import 'package:onepanel_client/api/v2/backup_account_v2.dart';
import 'package:onepanel_client/api/v2/file_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/backup_request_models.dart';
import 'package:onepanel_client/data/models/common_models.dart';

class BackupRepository {
  BackupRepository({
    ApiClientManager? clientManager,
    BackupAccountV2Api? backupApi,
    FileV2Api? fileApi,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _backupApi = backupApi,
        _fileApi = fileApi;

  final ApiClientManager _clientManager;
  BackupAccountV2Api? _backupApi;
  FileV2Api? _fileApi;

  Future<BackupAccountV2Api> _ensureBackupApi() async {
    return _backupApi ??= await _clientManager.getBackupAccountApi();
  }

  Future<FileV2Api> _ensureFileApi() async {
    return _fileApi ??= await _clientManager.getFileApi();
  }

  Future<PageResult<BackupAccountInfo>> searchAccounts(
    BackupAccountSearchRequest request,
  ) async {
    final api = await _ensureBackupApi();
    final response = await api.searchBackupAccounts(request);
    return response.data ??
        const PageResult<BackupAccountInfo>(
          items: <BackupAccountInfo>[],
          total: 0,
        );
  }

  Future<List<BackupOption>> getOptions() async {
    final api = await _ensureBackupApi();
    final response = await api.getBackupAccountOptions();
    return response.data ?? const <BackupOption>[];
  }

  Future<String> getLocalDir() async {
    final api = await _ensureBackupApi();
    final response = await api.getLocalBackupDir();
    return response.data ?? '';
  }

  Future<void> createAccount(BackupOperate request) async {
    final api = await _ensureBackupApi();
    final encoded = _encodeOperate(request);
    if (encoded.isPublic) {
      await api.createCoreBackupAccount(encoded);
      return;
    }
    await api.createBackupAccount(encoded);
  }

  Future<void> updateAccount(BackupOperate request) async {
    final api = await _ensureBackupApi();
    final encoded = _encodeOperate(request);
    if (encoded.isPublic) {
      await api.updateCoreBackupAccount(encoded);
      return;
    }
    await api.updateBackupAccount(encoded);
  }

  Future<void> deleteAccount(BackupAccountInfo info) async {
    final api = await _ensureBackupApi();
    if (info.isPublic) {
      await api.deleteCoreBackupAccount(
        OperationWithName(name: info.name),
      );
      return;
    }
    await api.deleteBackupAccount(OperateByID(id: info.id ?? 0));
  }

  Future<BackupCheckResult> checkConnection(BackupOperate request) async {
    final api = await _ensureBackupApi();
    final response = await api.checkBackupConnection(_encodeOperate(request));
    return response.data ?? const BackupCheckResult(isOk: false);
  }

  Future<List<dynamic>> loadBuckets(BackupBucketRequest request) async {
    final api = await _ensureBackupApi();
    final encoded = BackupBucketRequest(
      type: request.type,
      accessKey: _encodeString(request.accessKey),
      credential: _encodeString(request.credential),
      vars: request.vars,
    );
    final response = await api.getBuckets(encoded);
    return response.data ?? const <dynamic>[];
  }

  Future<void> refreshToken(BackupAccountInfo info) async {
    final api = await _ensureBackupApi();
    if (info.isPublic) {
      await api.refreshCoreBackupToken(OperationWithName(name: info.name));
      return;
    }
    await api.refreshBackupToken(OperateByID(id: info.id ?? 0));
  }

  Future<BackupClientInfo> getClientInfo(String clientType) async {
    final api = await _ensureBackupApi();
    final response = await api.getBackupClientInfo(clientType);
    return response.data ?? const BackupClientInfo();
  }

  Future<PageResult<BackupRecord>> searchRecords(
    BackupRecordQuery request,
  ) async {
    final api = await _ensureBackupApi();
    final response = await api.searchBackupRecords(request);
    return response.data ??
        const PageResult<BackupRecord>(items: <BackupRecord>[], total: 0);
  }

  Future<PageResult<BackupRecord>> searchRecordsByCronjob(
    BackupRecordByCronjobQuery request,
  ) async {
    final api = await _ensureBackupApi();
    final response = await api.searchBackupRecordsByCronjob(request);
    return response.data ??
        const PageResult<BackupRecord>(items: <BackupRecord>[], total: 0);
  }

  Future<List<RecordFileSize>> loadRecordSizes(
    BackupRecordSizeQuery request,
  ) async {
    final api = await _ensureBackupApi();
    final response = await api.loadBackupRecordSizes(request);
    return response.data ?? const <RecordFileSize>[];
  }

  Future<String> requestDownloadPath(DownloadRecord request) async {
    final api = await _ensureBackupApi();
    final response = await api.downloadBackupRecord(request);
    return response.data ?? '';
  }

  Future<List<int>> downloadFile(String path) async {
    final api = await _ensureFileApi();
    final response = await api.downloadFile(path);
    return response.data ?? const <int>[];
  }

  Future<void> deleteRecords(List<int> ids) async {
    final api = await _ensureBackupApi();
    await api.deleteBackupRecords(BatchDelete(ids: ids));
  }

  Future<void> updateRecordDescription(int id, String description) async {
    final api = await _ensureBackupApi();
    await api.updateRecordDescription(id: id, description: description);
  }

  Future<List<String>> listFiles(int accountId) async {
    final api = await _ensureBackupApi();
    final response = await api.listBackupFiles(OperateByID(id: accountId));
    return response.data ?? const <String>[];
  }

  Future<void> backup(BackupRunRequest request) async {
    final api = await _ensureBackupApi();
    await api.backupSystemData(request);
  }

  Future<void> recover(BackupRecoverRequest request) async {
    final api = await _ensureBackupApi();
    await api.recoverSystemData(request);
  }

  Future<void> recoverByUpload(BackupRecoverRequest request) async {
    final api = await _ensureBackupApi();
    await api.recoverSystemDataFromUpload(request);
  }

  Future<void> uploadForRecover(BackupUploadRequest request) async {
    final api = await _ensureBackupApi();
    await api.uploadForRecover(request);
  }

  BackupOperate _encodeOperate(BackupOperate request) {
    return BackupOperate(
      id: request.id,
      name: request.name,
      type: request.type,
      isPublic: request.isPublic,
      accessKey: _encodeIfPresent(request.accessKey),
      credential: _encodeIfPresent(request.credential),
      bucket: request.bucket,
      backupPath: request.backupPath,
      rememberAuth: request.rememberAuth,
      vars: request.vars,
    );
  }

  String? _encodeIfPresent(String? value) {
    if (value == null || value.isEmpty) {
      return value;
    }
    return _encodeString(value);
  }

  String _encodeString(String value) {
    return base64Encode(utf8.encode(value));
  }
}

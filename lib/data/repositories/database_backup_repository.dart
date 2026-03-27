import 'package:onepanel_client/api/v2/backup_account_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart' as backup;
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/database_support.dart';

class DatabaseBackupRepository {
  DatabaseBackupRepository({ApiClientManager? clientManager})
      : _clientManager = clientManager ?? ApiClientManager.instance;

  final ApiClientManager _clientManager;

  Future<BackupAccountV2Api> _getApi() async {
    final client = await _clientManager.getCurrentClient();
    return BackupAccountV2Api(client);
  }

  Future<PageResult<backup.BackupRecord>> loadBackupRecords(
    DatabaseListItem item, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final api = await _getApi();
    final response = await api.searchBackupRecords(
      backup.RecordSearch(
        type: databaseBackupType(item),
        name: databaseBackupName(item),
        detailName: databaseBackupDetailName(item),
        page: page,
        pageSize: pageSize,
      ),
    );
    final rawPage = response.data;
    return PageResult<backup.BackupRecord>(
      items: rawPage?.items
              .map(
                (value) => backup.BackupRecord.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ),
              )
              .toList(growable: false) ??
          const <backup.BackupRecord>[],
      total: rawPage?.total ?? 0,
      page: rawPage?.page ?? page,
      pageSize: rawPage?.pageSize ?? pageSize,
      totalPages: rawPage?.totalPages ?? 0,
    );
  }

  Future<void> createBackup(
    DatabaseListItem item, {
    String? secret,
  }) async {
    final api = await _getApi();
    await api.backupSystemData(
      backup.CommonBackup(
        type: databaseBackupType(item),
        name: databaseBackupName(item),
        detailName: databaseBackupDetailName(item),
        secret: _emptyToNull(secret),
        taskID: _taskId(),
      ),
    );
  }

  Future<void> restoreBackup(
    DatabaseListItem item,
    backup.BackupRecord record, {
    String? secret,
  }) async {
    final api = await _getApi();
    await api.recoverSystemData(
      backup.CommonRecover(
        type: databaseBackupType(item),
        name: databaseBackupName(item),
        detailName: databaseBackupDetailName(item),
        secret: _emptyToNull(secret),
        taskID: _taskId(),
        backupRecordID: record.id,
        downloadAccountID: record.downloadAccountID,
        file: _recordFile(record),
      ),
    );
  }

  Future<void> deleteBackupRecord(int id) async {
    final api = await _getApi();
    await api.deleteBackupRecord(OperateByID(id: id));
  }

  String _taskId() => DateTime.now().millisecondsSinceEpoch.toString();

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String _recordFile(backup.BackupRecord record) {
    final fileDir = record.fileDir;
    final fileName = record.fileName;
    if (fileDir != null && fileDir.isNotEmpty && fileName != null) {
      return '$fileDir/$fileName';
    }
    return fileName ?? '';
  }
}

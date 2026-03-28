import 'package:onepanel_client/data/models/backup_account_models.dart'
    as backup;
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/data/repositories/database_backup_repository.dart';

class DatabaseBackupService {
  DatabaseBackupService({DatabaseBackupRepository? repository})
      : _repository = repository ?? DatabaseBackupRepository();

  final DatabaseBackupRepository _repository;

  Future<PageResult<backup.BackupRecord>> loadRecords(
    DatabaseListItem item, {
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.loadBackupRecords(
      item,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> createBackup(
    DatabaseListItem item, {
    String? secret,
  }) {
    return _repository.createBackup(item, secret: secret);
  }

  Future<void> restoreBackup(
    DatabaseListItem item,
    backup.BackupRecord record, {
    String? secret,
  }) {
    return _repository.restoreBackup(item, record, secret: secret);
  }

  Future<void> deleteBackupRecord(int id) {
    return _repository.deleteBackupRecord(id);
  }
}

import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/data/models/backup_account_models.dart' as backup;
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/providers/database_backup_provider.dart';
import 'package:onepanel_client/features/databases/services/database_backup_service.dart';

class _FakeDatabaseBackupService extends DatabaseBackupService {
  _FakeDatabaseBackupService({
    this.pageResult = const PageResult<backup.BackupRecord>(items: [], total: 0),
    this.throwOnCreate = false,
    this.throwOnRestore = false,
    this.throwOnDelete = false,
  });

  final PageResult<backup.BackupRecord> pageResult;
  final bool throwOnCreate;
  final bool throwOnRestore;
  final bool throwOnDelete;

  int loadCallCount = 0;
  int createCallCount = 0;
  int restoreCallCount = 0;
  int deleteCallCount = 0;

  @override
  Future<PageResult<backup.BackupRecord>> loadRecords(
    DatabaseListItem item, {
    int page = 1,
    int pageSize = 20,
  }) async {
    loadCallCount += 1;
    return pageResult;
  }

  @override
  Future<void> createBackup(
    DatabaseListItem item, {
    String? secret,
  }) async {
    createCallCount += 1;
    if (throwOnCreate) {
      throw Exception('create failed');
    }
  }

  @override
  Future<void> restoreBackup(
    DatabaseListItem item,
    backup.BackupRecord record, {
    String? secret,
  }) async {
    restoreCallCount += 1;
    if (throwOnRestore) {
      throw Exception('restore failed');
    }
  }

  @override
  Future<void> deleteBackupRecord(int id) async {
    deleteCallCount += 1;
    if (throwOnDelete) {
      throw Exception('delete failed');
    }
  }
}

void main() {
  const item = DatabaseListItem(
    scope: DatabaseScope.mysql,
    name: 'app_db',
    engine: 'mysql-main',
    source: 'local',
  );

  const record = backup.BackupRecord(
    id: 1,
    name: 'mysql-main',
    type: 'mysql',
    fileName: 'app_db.sql.gz',
    size: 1,
    status: 'Success',
    downloadAccountID: 1,
    fileDir: '/backup/mysql',
  );

  test('DatabaseBackupProvider createBackup reloads page', () async {
    final service = _FakeDatabaseBackupService(
      pageResult: const PageResult(items: [record], total: 1),
    );
    final provider = DatabaseBackupProvider(item: item, service: service);

    await provider.load();
    final ok = await provider.createBackup(secret: '123');

    expect(ok, isTrue);
    expect(service.createCallCount, 1);
    expect(service.loadCallCount, 2);
    expect(provider.state.error, isNull);
  });

  test('DatabaseBackupProvider restore surfaces failures', () async {
    final service = _FakeDatabaseBackupService(
      pageResult: const PageResult(items: [record], total: 1),
      throwOnRestore: true,
    );
    final provider = DatabaseBackupProvider(item: item, service: service);

    await provider.load();
    final ok = await provider.restoreBackup(record);

    expect(ok, isFalse);
    expect(service.restoreCallCount, 1);
    expect(provider.state.error, contains('restore failed'));
  });

  test('DatabaseBackupProvider createBackup surfaces failures', () async {
    final service = _FakeDatabaseBackupService(
      pageResult: const PageResult(items: [record], total: 1),
      throwOnCreate: true,
    );
    final provider = DatabaseBackupProvider(item: item, service: service);

    await provider.load();
    final ok = await provider.createBackup();

    expect(ok, isFalse);
    expect(service.createCallCount, 1);
    expect(provider.state.error, contains('create failed'));
  });

  test('DatabaseBackupProvider deleteBackupRecord reloads on success', () async {
    final service = _FakeDatabaseBackupService(
      pageResult: const PageResult(items: [record], total: 1),
    );
    final provider = DatabaseBackupProvider(item: item, service: service);

    await provider.load();
    final ok = await provider.deleteBackupRecord(record);

    expect(ok, isTrue);
    expect(service.deleteCallCount, 1);
    expect(service.loadCallCount, 2);
  });

  test('DatabaseBackupProvider deleteBackupRecord surfaces failures', () async {
    final service = _FakeDatabaseBackupService(
      pageResult: const PageResult(items: [record], total: 1),
      throwOnDelete: true,
    );
    final provider = DatabaseBackupProvider(item: item, service: service);

    await provider.load();
    final ok = await provider.deleteBackupRecord(record);

    expect(ok, isFalse);
    expect(service.deleteCallCount, 1);
    expect(provider.state.error, contains('delete failed'));
  });
}

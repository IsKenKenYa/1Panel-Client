import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/services/file_save_service.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/features/backups/models/backup_record_list_item.dart';
import 'package:onepanel_client/features/backups/models/backup_records_args.dart';
import 'package:onepanel_client/features/backups/providers/backup_records_provider.dart';
import 'package:onepanel_client/features/backups/services/backup_record_service.dart';

class _MockBackupRecordService extends Mock implements BackupRecordService {}

void main() {
  late _MockBackupRecordService service;
  late BackupRecordsProvider provider;

  final item = BackupRecordListItem(
    record: const BackupRecord(
      id: 1,
      accountType: 'S3',
      accountName: 'bucket',
      downloadAccountID: 1,
      fileDir: '/data',
      fileName: 'dump.tar.gz',
      status: 'Success',
      createdAt: '2026-03-27',
    ),
    size: 100,
  );

  setUpAll(() {
    registerFallbackValue(const BackupRecordsArgs(type: 'app'));
    registerFallbackValue(
      const BackupRecord(
        id: 1,
        accountType: 'S3',
        accountName: 'bucket',
        downloadAccountID: 1,
        fileDir: '/data',
        fileName: 'dump.tar.gz',
        status: 'Success',
        createdAt: '2026-03-27',
      ),
    );
  });

  setUp(() {
    service = _MockBackupRecordService();
    when(() => service.loadRecords(
          args: any(named: 'args'),
          type: any(named: 'type'),
          name: any(named: 'name'),
          detailName: any(named: 'detailName'),
        )).thenAnswer((_) async => <BackupRecordListItem>[item]);
    when(() => service.downloadRecord(any())).thenAnswer(
      (_) async =>
          const FileSaveResult(success: true, filePath: '/tmp/dump.tar.gz'),
    );
    when(() => service.deleteRecord(any())).thenAnswer((_) async {});
    provider = BackupRecordsProvider(service: service);
  });

  test('initialize loads records', () async {
    await provider.initialize(const BackupRecordsArgs(type: 'app'));

    expect(provider.items, hasLength(1));
  });

  test('delete reloads list', () async {
    await provider.initialize(const BackupRecordsArgs(type: 'app'));
    final result = await provider.delete(item);

    expect(result, isTrue);
    verify(() => service.deleteRecord(item.record)).called(1);
  });
}

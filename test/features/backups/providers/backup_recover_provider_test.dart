import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/backup_request_models.dart';
import 'package:onepanel_client/data/models/database_option_models.dart';
import 'package:onepanel_client/features/backups/models/backup_recover_args.dart';
import 'package:onepanel_client/features/backups/providers/backup_recover_provider.dart';
import 'package:onepanel_client/features/backups/services/backup_recover_service.dart';

class _MockBackupRecoverService extends Mock implements BackupRecoverService {}

void main() {
  late _MockBackupRecoverService service;
  late BackupRecoverProvider provider;

  final record = const BackupRecord(
    id: 1,
    accountType: 'S3',
    accountName: 'bucket',
    downloadAccountID: 1,
    fileDir: '/data',
    fileName: 'dump.tar.gz',
    status: 'Success',
    createdAt: '2026-03-27',
  );

  setUpAll(() {
    registerFallbackValue(record);
    registerFallbackValue(
      const BackupRecoverRequest(
        downloadAccountID: 1,
        type: 'app',
        name: 'wordpress',
        detailName: 'WordPress',
        file: '/data/dump.tar.gz',
        taskID: 'task-1',
      ),
    );
  });

  setUp(() {
    service = _MockBackupRecoverService();
    when(() => service.loadAppOptions()).thenAnswer(
      (_) async => <AppInstallInfo>[
        AppInstallInfo(id: 1, name: 'WordPress', appKey: 'wordpress'),
      ],
    );
    when(() => service.loadWebsiteOptions())
        .thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(() => service.loadDatabaseOptions(any())).thenAnswer(
      (_) async => const <DatabaseItemOption>[
        DatabaseItemOption(id: 1, from: 'local', database: 'mysql', name: 'db1'),
      ],
    );
    when(() => service.loadCandidateRecords(
          type: any(named: 'type'),
          name: any(named: 'name'),
          detailName: any(named: 'detailName'),
        )).thenAnswer((_) async => <BackupRecord>[record]);
    when(() => service.buildRecoverRequest(
          record: any(named: 'record'),
          type: any(named: 'type'),
          name: any(named: 'name'),
          detailName: any(named: 'detailName'),
          secret: any(named: 'secret'),
          timeout: any(named: 'timeout'),
        )).thenReturn(
      const BackupRecoverRequest(
        downloadAccountID: 1,
        type: 'app',
        name: 'wordpress',
        detailName: 'WordPress',
        file: '/data/dump.tar.gz',
        taskID: 'task-1',
      ),
    );
    when(() => service.recover(any())).thenAnswer((_) async {});
    provider = BackupRecoverProvider(service: service);
  });

  test('initialize loads resource options', () async {
    await provider.initialize(const BackupRecoverArgs());

    expect(provider.apps, hasLength(1));
  });

  test('submitRecover sends recover request', () async {
    await provider.initialize(const BackupRecoverArgs());
    provider.selectApp(provider.apps.first);
    await provider.loadRecords();
    provider.selectRecord(record);

    final result = await provider.submitRecover();

    expect(result, isTrue);
    verify(() => service.recover(any())).called(1);
  });
}

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

class _SourceExpectation {
  const _SourceExpectation({
    required this.type,
    required this.category,
    required this.recordType,
    required this.requestType,
    required this.databaseType,
    required this.supportsRecoverAction,
  });

  final String type;
  final String category;
  final String recordType;
  final String requestType;
  final String databaseType;
  final bool supportsRecoverAction;
}

void main() {
  late _MockBackupRecoverService service;
  late BackupRecoverProvider provider;
  final mappingService = BackupRecoverService();

  const record = BackupRecord(
    id: 1,
    accountType: 'S3',
    accountName: 'bucket',
    downloadAccountID: 1,
    fileDir: '/data',
    fileName: 'dump.tar.gz',
    status: 'Success',
    createdAt: '2026-03-27',
  );

  const sourceCases = <_SourceExpectation>[
    _SourceExpectation(
      type: 'app',
      category: 'app',
      recordType: 'app',
      requestType: 'app',
      databaseType: 'mysql',
      supportsRecoverAction: true,
    ),
    _SourceExpectation(
      type: 'website',
      category: 'website',
      recordType: 'website',
      requestType: 'website',
      databaseType: 'mysql',
      supportsRecoverAction: true,
    ),
    _SourceExpectation(
      type: 'mysql',
      category: 'database',
      recordType: 'mysql',
      requestType: 'mysql',
      databaseType: 'mysql',
      supportsRecoverAction: true,
    ),
    _SourceExpectation(
      type: 'postgresql',
      category: 'database',
      recordType: 'postgresql',
      requestType: 'postgresql',
      databaseType: 'postgresql',
      supportsRecoverAction: true,
    ),
    _SourceExpectation(
      type: 'redis',
      category: 'database',
      recordType: 'redis',
      requestType: 'redis',
      databaseType: 'redis',
      supportsRecoverAction: true,
    ),
    _SourceExpectation(
      type: 'directory',
      category: 'other',
      recordType: 'directory',
      requestType: 'directory',
      databaseType: 'mysql',
      supportsRecoverAction: false,
    ),
    _SourceExpectation(
      type: 'snapshot',
      category: 'other',
      recordType: 'snapshot',
      requestType: 'snapshot',
      databaseType: 'mysql',
      supportsRecoverAction: false,
    ),
    _SourceExpectation(
      type: 'log',
      category: 'other',
      recordType: 'log',
      requestType: 'log',
      databaseType: 'mysql',
      supportsRecoverAction: false,
    ),
  ];

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
    when(() => service.resolveSource(any())).thenAnswer(
      (invocation) => mappingService.resolveSource(
        invocation.positionalArguments.first as BackupRecoverArgs?,
      ),
    );
    when(
      () => service.sourceForCategory(
        any(),
        fallbackOtherType: any(named: 'fallbackOtherType'),
      ),
    ).thenAnswer(
      (invocation) => mappingService.sourceForCategory(
        invocation.positionalArguments.first as String,
        fallbackOtherType:
            invocation.namedArguments[#fallbackOtherType] as String?,
      ),
    );
    when(() => service.sourceForRawType(
          any(),
          name: any(named: 'name'),
          detailName: any(named: 'detailName'),
        )).thenAnswer(
      (invocation) => mappingService.sourceForRawType(
        invocation.positionalArguments.first as String?,
        name: invocation.namedArguments[#name] as String? ?? '',
        detailName: invocation.namedArguments[#detailName] as String? ?? '',
      ),
    );
    when(() => service.isRecoverSupportedType(any())).thenAnswer(
      (invocation) => mappingService.isRecoverSupportedType(
        invocation.positionalArguments.first as String,
      ),
    );
    when(() => service.loadWebsiteOptions())
        .thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(() => service.loadDatabaseOptions(any())).thenAnswer(
      (_) async => const <DatabaseItemOption>[
        DatabaseItemOption(
          id: 1,
          from: 'local',
          database: 'mysql',
          name: 'db1',
        ),
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
        )).thenAnswer(
      (invocation) => BackupRecoverRequest(
        downloadAccountID: 1,
        type: invocation.namedArguments[#type] as String,
        name: invocation.namedArguments[#name] as String,
        detailName: invocation.namedArguments[#detailName] as String,
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

  test('initialize maps supported and unsupported record sources', () async {
    for (final item in sourceCases) {
      await provider.initialize(
        BackupRecoverArgs(
          type: item.type,
          name: 'demo',
          detailName: 'demo-item',
          initialRecord: record,
        ),
      );

      expect(provider.resourceType, item.category);
      expect(provider.recordType, item.recordType);
      expect(provider.requestType, item.requestType);
      expect(provider.databaseType, item.databaseType);
      expect(provider.supportsRecoverAction, item.supportsRecoverAction);
      expect(provider.resourceName, 'demo');
      expect(provider.resourceDetailName, 'demo-item');
      expect(provider.selectedRecord?.id, record.id);
      expect(provider.canSubmit, item.supportsRecoverAction);

      verify(
        () => service.loadCandidateRecords(
          type: item.recordType,
          name: 'demo',
          detailName: 'demo-item',
        ),
      ).called(1);
      clearInteractions(service);
    }
  });

  test(
      'initialize preserves mysql-family request type while showing database UI',
      () async {
    await provider.initialize(
      const BackupRecoverArgs(
        type: 'mysql-cluster',
        name: 'db-main',
        detailName: 'cluster-a',
        initialRecord: record,
      ),
    );

    expect(provider.resourceType, 'database');
    expect(provider.recordType, 'mysql-cluster');
    expect(provider.requestType, 'mysql-cluster');
    expect(provider.databaseType, 'mysql');
    expect(provider.supportsRecoverAction, isTrue);
    expect(provider.canSubmit, isTrue);
  });

  test('submitRecover sends recover request with resolved request type',
      () async {
    await provider.initialize(
      const BackupRecoverArgs(
        type: 'postgresql',
        name: 'db-main',
        detailName: 'prod',
      ),
    );
    provider.selectRecord(record);

    final result = await provider.submitRecover();

    expect(result, isTrue);
    verify(
      () => service.buildRecoverRequest(
        record: record,
        type: 'postgresql',
        name: 'db-main',
        detailName: 'prod',
        secret: '',
        timeout: 3600,
      ),
    ).called(1);
    verify(() => service.recover(any())).called(1);
  });

  test('submitRecover stays blocked for unsupported record sources', () async {
    await provider.initialize(
      const BackupRecoverArgs(
        type: 'snapshot',
        name: 'snap-1',
        detailName: 'snapshot-1',
        initialRecord: record,
      ),
    );

    final result = await provider.submitRecover();

    expect(provider.canSubmit, isFalse);
    expect(result, isFalse);
    verifyNever(() => service.buildRecoverRequest(
          record: any(named: 'record'),
          type: any(named: 'type'),
          name: any(named: 'name'),
          detailName: any(named: 'detailName'),
          secret: any(named: 'secret'),
          timeout: any(named: 'timeout'),
        ));
  });
}

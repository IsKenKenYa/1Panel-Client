import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/features/backups/models/backup_account_form_args.dart';
import 'package:onepanel_client/features/backups/providers/backup_accounts_provider.dart';
import 'package:onepanel_client/features/backups/services/backup_account_service.dart';

class _MockBackupAccountService extends Mock implements BackupAccountService {}

void main() {
  late _MockBackupAccountService service;
  late BackupAccountsProvider provider;

  setUpAll(() {
    registerFallbackValue(const BackupAccountFormArgs());
    registerFallbackValue(
      const BackupAccountInfo(name: 'fallback', type: 'S3'),
    );
  });

  final accounts = <BackupAccountInfo>[
    const BackupAccountInfo(
      id: 1,
      name: 'backup-s3',
      type: 'S3',
      isPublic: false,
      bucket: 'bucket',
      backupPath: '/1panel',
    ),
  ];

  setUp(() {
    service = _MockBackupAccountService();
    when(() => service.searchAccounts(
        keyword: any(named: 'keyword'),
        type: any(named: 'type'))).thenAnswer((_) async => accounts);
    when(() => service.initializeDraft(any()))
        .thenAnswer((_) async => throw UnimplementedError());
    when(() => service.listFiles(any()))
        .thenAnswer((_) async => const <String>['a.tar.gz']);
    when(() => service.refreshToken(any())).thenAnswer((_) async {});
    when(() => service.deleteAccount(any())).thenAnswer((_) async {});
    provider = BackupAccountsProvider(service: service);
  });

  test('load fetches accounts', () async {
    await provider.load();

    expect(provider.items, hasLength(1));
  });

  test('refreshToken triggers service', () async {
    final result = await provider.refreshToken(accounts.first);

    expect(result, isTrue);
    verify(() => service.refreshToken(accounts.first)).called(1);
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/features/backups/models/backup_account_draft.dart';
import 'package:onepanel_client/features/backups/models/backup_account_form_args.dart';
import 'package:onepanel_client/features/backups/providers/backup_account_form_provider.dart';
import 'package:onepanel_client/features/backups/services/backup_account_service.dart';
import 'package:onepanel_client/features/backups/services/backup_oauth_callback_service.dart';

class _MockBackupAccountService extends Mock implements BackupAccountService {}

class _MockBackupOauthCallbackService extends Mock
    implements BackupOauthCallbackService {}

void main() {
  late _MockBackupAccountService service;
  late _MockBackupOauthCallbackService callbackService;
  late BackupAccountFormProvider provider;
  late StreamController<Uri> controller;

  setUpAll(() {
    registerFallbackValue(const BackupAccountFormArgs());
    registerFallbackValue(const BackupAccountDraft(type: 'SFTP'));
  });

  setUp(() {
    controller = StreamController<Uri>.broadcast();
    service = _MockBackupAccountService();
    callbackService = _MockBackupOauthCallbackService();
    when(() => callbackService.start()).thenAnswer((_) async {});
    when(() => callbackService.callbacks).thenAnswer((_) => controller.stream);
    when(() => callbackService.consumeInitialUri()).thenReturn(null);
    when(() => callbackService.dispose()).thenAnswer((_) async {});
    when(() => service.initializeDraft(any())).thenAnswer(
      (_) async => const BackupAccountDraft(type: 'SFTP'),
    );
    when(() => service.supportsOAuth(any())).thenReturn(false);
    when(() => service.loadBuckets(any()))
        .thenAnswer((_) async => const <String>['bucket-a']);
    when(() => service.testConnection(any())).thenAnswer(
      (_) async => const BackupCheckResult(isOk: true, msg: 'ok'),
    );
    when(() => service.saveDraft(any())).thenAnswer((_) async {});
    provider = BackupAccountFormProvider(
      service: service,
      callbackService: callbackService,
    );
  });

  tearDown(() async {
    await controller.close();
  });

  test('initialize starts callback service', () async {
    await provider.initialize(const BackupAccountFormArgs());

    verify(() => callbackService.start()).called(1);
  });

  test('loadBuckets fills bucket list', () async {
    await provider.initialize(const BackupAccountFormArgs());
    await provider.loadBuckets();

    expect(provider.bucketOptions, contains('bucket-a'));
  });

  test('testConnection enables save', () async {
    await provider.initialize(const BackupAccountFormArgs());
    provider.updateBasic(name: 'backup-sftp');

    final result = await provider.testConnection();

    expect(result, isTrue);
    expect(provider.canSave, isTrue);
  });
}

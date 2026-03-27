import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/cronjob_record_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/cronjobs/models/cronjob_form_args.dart';
import 'package:onepanel_client/features/cronjobs/models/cronjob_form_draft.dart';
import 'package:onepanel_client/features/cronjobs/providers/cronjob_form_provider.dart';
import 'package:onepanel_client/features/cronjobs/services/cronjob_form_service.dart';

class _MockCronjobFormService extends Mock implements CronjobFormService {}

void main() {
  late _MockCronjobFormService service;
  late CronjobFormProvider provider;

  setUpAll(() {
    registerFallbackValue(const CronjobFormArgs());
    registerFallbackValue(const CronjobFormDraft());
  });

  setUp(() {
    service = _MockCronjobFormService();
    when(() => service.loadDraft(any())).thenAnswer(
      (_) async => const CronjobFormDraft(
        primaryType: 'shell',
        name: '',
        executor: 'bash',
        scriptMode: 'input',
        script: '',
        user: 'root',
      ),
    );
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer(
      (_) async => const <GroupInfo>[
        GroupInfo(id: 1, name: 'Default', type: 'cronjob', isDefault: true),
      ],
    );
    when(() => service.loadScriptOptions()).thenAnswer(
      (_) async => const <CronjobScriptOption>[
        CronjobScriptOption(id: 1, name: 'deploy'),
      ],
    );
    when(() => service.loadBackupOptions()).thenAnswer(
      (_) async => const <BackupOption>[
        BackupOption(id: 1, isPublic: false, name: 'local', type: 'LOCAL'),
      ],
    );
    when(() => service.loadInstalledApps()).thenAnswer(
      (_) async => <AppInstallInfo>[
        AppInstallInfo(id: 1, name: 'WordPress', appKey: 'wordpress'),
      ],
    );
    when(() => service.loadWebsiteOptions())
        .thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(() => service.loadDatabaseItems(any()))
        .thenAnswer((_) async => const []);
    when(() => service.loadNextPreview(any()))
        .thenAnswer((_) async => const <String>['2026-03-28 00:00']);
    when(() => service.saveDraft(any())).thenAnswer((_) async {});
    provider = CronjobFormProvider(service: service);
  });

  test('initialize hydrates draft and default group', () async {
    await provider.initialize(const CronjobFormArgs());

    expect(provider.draft.groupID, 1);
    expect(provider.scriptOptions, hasLength(1));
    expect(provider.backupOptions, hasLength(1));
  });

  test('previewNext loads next run items', () async {
    await provider.initialize(const CronjobFormArgs());
    provider.updateBasic(name: 'nightly');
    provider.updateShell(script: 'echo hello');

    await provider.previewNext();

    expect(provider.nextPreview, contains('2026-03-28 00:00'));
  });

  test('save uses service when draft becomes valid', () async {
    await provider.initialize(const CronjobFormArgs());
    provider.updateBasic(name: 'nightly');
    provider.updateShell(script: 'echo hello');

    final result = await provider.save();

    expect(result, isTrue);
    verify(() => service.saveDraft(any())).called(1);
  });
}

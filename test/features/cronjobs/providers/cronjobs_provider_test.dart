import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/cronjob_list_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/cronjobs/providers/cronjobs_provider.dart';
import 'package:onepanel_client/features/cronjobs/services/cronjob_service.dart';

class _MockCronjobService extends Mock implements CronjobService {}

void main() {
  late _MockCronjobService service;
  late CronjobsProvider provider;

  final groups = <GroupInfo>[
    const GroupInfo(id: 1, name: 'Default', type: 'cronjob', isDefault: true),
  ];
  const item = CronjobSummary(
    id: 1,
    name: 'nightly-backup',
    type: 'shell',
    groupId: 1,
    groupBelong: 'Default',
    spec: '0 0 * * *',
    specCustom: false,
    status: 'Enable',
    lastRecordStatus: 'Success',
    lastRecordTime: '2026-03-27 00:00:00',
    retainCopies: 7,
    scriptMode: '',
    command: 'echo ok',
    executor: 'root',
  );

  setUpAll(() {
    registerFallbackValue(const CronjobListQuery());
  });

  setUp(() {
    service = _MockCronjobService();
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => groups);
    when(() => service.searchCronjobs(any())).thenAnswer(
      (_) async => const PageResult<CronjobSummary>(
        items: <CronjobSummary>[item],
        total: 1,
      ),
    );
    when(() => service.updateStatus(any(), any())).thenAnswer((_) async {});
    when(() => service.handleOnce(any())).thenAnswer((_) async {});
    when(() => service.stop(any())).thenAnswer((_) async {});
    provider = CronjobsProvider(service: service);
  });

  test('load sets cronjobs and groups', () async {
    await provider.load();

    expect(provider.items, hasLength(1));
    expect(provider.groups, hasLength(1));
    expect(provider.selectedGroupId, isNull);
  });

  test('updateStatus calls service and reloads list', () async {
    await provider.load();
    clearInteractions(service);
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => groups);
    when(() => service.searchCronjobs(any())).thenAnswer(
      (_) async => const PageResult<CronjobSummary>(
        items: <CronjobSummary>[item],
        total: 1,
      ),
    );

    final result = await provider.updateStatus(item, 'Disable');

    expect(result, isTrue);
    verify(() => service.updateStatus(1, 'Disable')).called(1);
    verify(() => service.searchCronjobs(any())).called(1);
  });

  test('handleOnce calls service and reloads list', () async {
    await provider.load();
    clearInteractions(service);
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => groups);
    when(() => service.searchCronjobs(any())).thenAnswer(
      (_) async => const PageResult<CronjobSummary>(
        items: <CronjobSummary>[item],
        total: 1,
      ),
    );

    final result = await provider.handleOnce(item);

    expect(result, isTrue);
    verify(() => service.handleOnce(1)).called(1);
    verify(() => service.searchCronjobs(any())).called(1);
  });
}

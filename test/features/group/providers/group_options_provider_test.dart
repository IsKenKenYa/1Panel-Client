import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/group/providers/group_options_provider.dart';
import 'package:onepanel_client/features/group/services/group_service.dart';

class _MockGroupService extends Mock implements GroupService {}

void main() {
  late _MockGroupService service;
  late GroupOptionsProvider provider;

  final group = GroupInfo(id: 1, name: 'Ops', type: 'command');

  setUp(() {
    service = _MockGroupService();
    when(() =>
            service.listGroups(any(), forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => [group]);
    provider = GroupOptionsProvider(service: service);
  });

  test('load sets groups and selects default', () async {
    await provider.initialize(groupType: 'command');

    expect(provider.groups.first.name, 'Ops');
    expect(provider.selectedGroupId, 1);
    expect(provider.status, isNotNull);
  });

  test('load preserves null selection when empty selection is allowed',
      () async {
    await provider.initialize(
      groupType: 'command',
      allowEmptySelection: true,
    );

    expect(provider.groups.first.name, 'Ops');
    expect(provider.selectedGroupId, isNull);
  });

  test('createGroup refreshes list and selects created group', () async {
    when(() => service.createGroup(
        type: any(named: 'type'),
        name: any(named: 'name'))).thenAnswer((_) async => [group]);
    await provider.initialize(groupType: 'command');

    await provider.createGroup('NewOps');

    verify(() => service.createGroup(type: 'command', name: 'NewOps'))
        .called(1);
    expect(provider.selectedGroupId, 1);
  });

  test('updateGroup refreshes selection', () async {
    when(() => service.updateGroup(
        id: any(named: 'id'),
        type: any(named: 'type'),
        name: any(named: 'name'),
        isDefault: any(named: 'isDefault'))).thenAnswer((_) async => [group]);
    await provider.initialize(groupType: 'command');

    await provider.updateGroup(id: 1, name: 'OpsRenamed');

    verify(() => service.updateGroup(
          id: 1,
          type: 'command',
          name: 'OpsRenamed',
          isDefault: false,
        )).called(1);
  });

  test('deleteGroup refreshes list and resets selection', () async {
    when(() =>
            service.deleteGroup(id: any(named: 'id'), type: any(named: 'type')))
        .thenAnswer((_) async => []);
    await provider.initialize(groupType: 'command');

    await provider.deleteGroup(1);

    verify(() => service.deleteGroup(id: 1, type: 'command')).called(1);
    expect(provider.selectedGroupId, isNull);
  });
}

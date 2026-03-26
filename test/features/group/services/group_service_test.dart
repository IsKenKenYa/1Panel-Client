import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/data/repositories/group_repository.dart';
import 'package:onepanel_client/features/group/services/group_service.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late _MockGroupRepository repository;
  late GroupService service;

  final group = GroupInfo(id: 1, name: 'Default', type: 'command');

  setUp(() {
    repository = _MockGroupRepository();
    service = GroupService(repository: repository);
  });

  test('listGroups caches results and only calls repo once', () async {
    when(() => repository.listGroups('command')).thenAnswer(
      (_) async => [group],
    );

    final first = await service.listGroups('command');
    final second = await service.listGroups('command');

    expect(first, same(second));
    verify(() => repository.listGroups('command')).called(1);
  });

  test('invalidate clears cache for type only', () async {
    when(() => repository.listGroups('command')).thenAnswer(
      (_) async => [group],
    );

    await service.listGroups('command');
    service.invalidate(type: 'command');
    await service.listGroups('command');

    verify(() => repository.listGroups('command')).called(2);
  });

  test('invalidate clears all cached types', () async {
    when(() => repository.listGroups('command')).thenAnswer(
      (_) async => [group],
    );
    when(() => repository.listGroups('agent')).thenAnswer(
      (_) async => [group],
    );

    await service.listGroups('command');
    await service.listGroups('agent');
    service.invalidate();
    await service.listGroups('command');

    verify(() => repository.listGroups('command')).called(2);
    verify(() => repository.listGroups('agent')).called(1);
  });
}

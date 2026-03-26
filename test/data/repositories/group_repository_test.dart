import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/api/v2/system_group_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart'
    as group_models;
import 'package:onepanel_client/data/repositories/group_repository.dart';

class _MockApiClientManager extends Mock implements ApiClientManager {}

class _MockSystemGroupV2Api extends Mock implements SystemGroupV2Api {}

Response<List<group_models.GroupInfo>> _fakeGroupResponse(
  List<group_models.GroupInfo> data,
) =>
    Response<List<group_models.GroupInfo>>(
      data: data,
      requestOptions: RequestOptions(path: '/'),
      statusCode: 200,
    );

void main() {
  late _MockApiClientManager clientManager;
  late _MockSystemGroupV2Api api;
  late GroupRepository repository;

  setUpAll(() {
    registerFallbackValue(const group_models.GroupSearch(type: 'command'));
    registerFallbackValue(const group_models.GroupCreate(name: 'group', type: 'command'));
    registerFallbackValue(
      const group_models.GroupUpdate(
        id: 1,
        name: 'group',
        type: 'command',
      ),
    );
    registerFallbackValue(const OperateByID(id: 1));
  });

  setUp(() {
    clientManager = _MockApiClientManager();
    api = _MockSystemGroupV2Api();
    when(() => clientManager.getSystemGroupApi())
        .thenAnswer((_) async => api);
    repository = GroupRepository(clientManager: clientManager);
  });

  test('listGroups calls core search API when scope is core', () async {
    when(() => api.searchCoreGroups(any())).thenAnswer(
      (_) async => _fakeGroupResponse([group_models.GroupInfo(id: 1, name: 'A', type: 'command')]),
    );

    final groups = await repository.listGroups('command', scope: GroupApiScope.core);

    expect(groups, hasLength(1));
    verify(() => api.searchCoreGroups(any())).called(1);
    verifyNever(() => api.searchAgentGroups(any()));
  });

  test('listGroups calls agent search API when scope is agent', () async {
    when(() => api.searchAgentGroups(any())).thenAnswer(
      (_) async => _fakeGroupResponse([group_models.GroupInfo(id: 2, name: 'B', type: 'shell')]),
    );

    await repository.listGroups('shell', scope: GroupApiScope.agent);

    verify(() => api.searchAgentGroups(any())).called(1);
    verifyNever(() => api.searchCoreGroups(any()));
  });

  test('createGroup routes to correct namespace', () async {
    when(() => api.createCoreGroup(any()))
        .thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/')));
    when(() => api.createAgentGroup(any()))
        .thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/')));

    await repository.createGroup(type: 'command', name: 'New', scope: GroupApiScope.core);
    verify(() => api.createCoreGroup(any())).called(1);

    await repository.createGroup(type: 'command', name: 'New', scope: GroupApiScope.agent);
    verify(() => api.createAgentGroup(any())).called(1);
  });

  test('updateGroup routes to correct namespace', () async {
    when(() => api.updateCoreGroup(any()))
        .thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/')));
    when(() => api.updateAgentGroup(any()))
        .thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/')));

    await repository.updateGroup(
      id: 1,
      type: 'command',
      name: 'Updated',
      scope: GroupApiScope.core,
    );
    verify(() => api.updateCoreGroup(any())).called(1);

    await repository.updateGroup(
      id: 2,
      type: 'command',
      name: 'Updated',
      scope: GroupApiScope.agent,
    );
    verify(() => api.updateAgentGroup(any())).called(1);
  });

  test('deleteGroup routes to correct namespace', () async {
    when(() => api.deleteCoreGroup(any()))
        .thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/')));
    when(() => api.deleteAgentGroup(any()))
        .thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/')));

    await repository.deleteGroup(1, scope: GroupApiScope.core);
    verify(() => api.deleteCoreGroup(any())).called(1);

    await repository.deleteGroup(2, scope: GroupApiScope.agent);
    verify(() => api.deleteAgentGroup(any())).called(1);
  });
}

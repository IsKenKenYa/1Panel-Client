import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart'
    as group_models;

enum GroupApiScope {
  core,
  agent,
}

class GroupRepository {
  GroupRepository({
    ApiClientManager? clientManager,
  }) : _clientManager = clientManager ?? ApiClientManager.instance;

  final ApiClientManager _clientManager;

  Future<List<group_models.GroupInfo>> listGroups(
    String type, {
    GroupApiScope scope = GroupApiScope.core,
  }) async {
    final api = await _clientManager.getSystemGroupApi();
    final request = group_models.GroupSearch(type: type);
    final response = switch (scope) {
      GroupApiScope.core => await api.searchCoreGroups(request),
      GroupApiScope.agent => await api.searchAgentGroups(request),
    };
    return response.data ?? const <group_models.GroupInfo>[];
  }

  Future<void> createGroup({
    required String type,
    required String name,
    GroupApiScope scope = GroupApiScope.core,
  }) async {
    final api = await _clientManager.getSystemGroupApi();
    final request = group_models.GroupCreate(name: name, type: type);
    switch (scope) {
      case GroupApiScope.core:
        await api.createCoreGroup(request);
      case GroupApiScope.agent:
        await api.createAgentGroup(request);
    }
  }

  Future<void> updateGroup({
    required int id,
    required String type,
    required String name,
    bool isDefault = false,
    GroupApiScope scope = GroupApiScope.core,
  }) async {
    final api = await _clientManager.getSystemGroupApi();
    final request = group_models.GroupUpdate(
      id: id,
      name: name,
      type: type,
      isDefault: isDefault,
    );
    switch (scope) {
      case GroupApiScope.core:
        await api.updateCoreGroup(request);
      case GroupApiScope.agent:
        await api.updateAgentGroup(request);
    }
  }

  Future<void> deleteGroup(
    int id, {
    GroupApiScope scope = GroupApiScope.core,
  }) async {
    final api = await _clientManager.getSystemGroupApi();
    final request = OperateByID(id: id);
    switch (scope) {
      case GroupApiScope.core:
        await api.deleteCoreGroup(request);
      case GroupApiScope.agent:
        await api.deleteAgentGroup(request);
    }
  }
}

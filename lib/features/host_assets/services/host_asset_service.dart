import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/host_asset_models.dart';
import 'package:onepanel_client/data/models/host_models.dart';
import 'package:onepanel_client/data/models/host_tree_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/data/repositories/host_asset_repository.dart';
import 'package:onepanel_client/features/group/services/group_service.dart';

class HostAssetService {
  HostAssetService({
    HostAssetRepository? repository,
    GroupService? groupService,
  })  : _repository = repository ?? HostAssetRepository(),
        _groupService = groupService ?? GroupService();

  final HostAssetRepository _repository;
  final GroupService _groupService;

  Future<PageResult<HostInfo>> searchHosts(HostSearchRequest request) {
    return _repository.searchHosts(request);
  }

  Future<List<GroupInfo>> loadGroups({bool forceRefresh = false}) {
    return _groupService.listGroups('host', forceRefresh: forceRefresh);
  }

  Future<HostInfo> getHostById(int id) => _repository.getHostById(id);

  Future<bool> testHostById(int id) => _repository.testHostById(id);

  Future<bool> testHostByInfo(HostConnTest request) =>
      _repository.testHostByInfo(request);

  Future<void> createHost(HostOperate request) =>
      _repository.createHost(request);

  Future<HostInfo> updateHost(HostOperate request) =>
      _repository.updateHost(request);

  Future<void> deleteHosts(List<int> ids) => _repository.deleteHosts(ids);

  Future<void> updateHostGroup(HostGroupChange request) =>
      _repository.updateHostGroup(request);

  Future<List<HostTreeNode>> loadHostTree({String? info}) =>
      _repository.loadHostTree(info: info);

  int? resolveDefaultGroupId(List<GroupInfo> groups) {
    for (final group in groups) {
      final normalized = group.name?.trim().toLowerCase();
      if (group.isDefault == true ||
          normalized == null ||
          normalized.isEmpty ||
          normalized == 'default') {
        return group.id;
      }
    }
    return groups.isNotEmpty ? groups.first.id : null;
  }

  HostOperate fromHostInfo(HostInfo info) {
    appLogger.dWithPackage(
      'features.host_assets.services.host_asset',
      'fromHostInfo: id=${info.id}',
    );
    return HostOperate(
      id: info.id,
      name: info.name,
      groupID: info.groupID,
      addr: info.addr ?? '',
      port: info.port ?? 22,
      user: info.user ?? '',
      authMode: info.authMode ?? 'password',
      password: info.password,
      privateKey: info.privateKey,
      passPhrase: info.passPhrase,
      rememberPassword: info.rememberPassword ?? false,
      description: info.description,
    );
  }
}

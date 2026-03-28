import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/data/repositories/group_repository.dart';

class GroupService {
  GroupService({
    GroupRepository? repository,
  }) : _repository = repository ?? GroupRepository();

  final GroupRepository _repository;
  final Map<String, List<GroupInfo>> _cache = <String, List<GroupInfo>>{};

  Future<List<GroupInfo>> listGroups(
    String type, {
    bool forceRefresh = false,
    GroupApiScope scope = GroupApiScope.core,
  }) async {
    final cacheKey = _cacheKey(type, scope);
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      appLogger.dWithPackage(
        'features.group.services.group',
        'listGroups cache hit: type=$type, scope=$scope',
      );
      return _cache[cacheKey]!;
    }

    appLogger.dWithPackage(
      'features.group.services.group',
      'listGroups cache miss: type=$type, scope=$scope',
    );
    final groups = await _repository.listGroups(type, scope: scope);
    final normalized = _normalizeGroups(groups);
    _cache[cacheKey] = normalized;
    return normalized;
  }

  Future<List<GroupInfo>> createGroup({
    required String type,
    required String name,
    GroupApiScope scope = GroupApiScope.core,
  }) async {
    await _repository.createGroup(type: type, name: name, scope: scope);
    invalidate(type: type, scope: scope);
    return listGroups(type, forceRefresh: true, scope: scope);
  }

  Future<List<GroupInfo>> updateGroup({
    required int id,
    required String type,
    required String name,
    bool isDefault = false,
    GroupApiScope scope = GroupApiScope.core,
  }) async {
    await _repository.updateGroup(
      id: id,
      type: type,
      name: name,
      isDefault: isDefault,
      scope: scope,
    );
    invalidate(type: type, scope: scope);
    return listGroups(type, forceRefresh: true, scope: scope);
  }

  Future<List<GroupInfo>> deleteGroup({
    required int id,
    required String type,
    GroupApiScope scope = GroupApiScope.core,
  }) async {
    await _repository.deleteGroup(id, scope: scope);
    invalidate(type: type, scope: scope);
    return listGroups(type, forceRefresh: true, scope: scope);
  }

  void invalidate({String? type, GroupApiScope? scope}) {
    if (type == null) {
      _cache.clear();
      return;
    }
    if (scope == null) {
      _cache.removeWhere((String key, _) => key.endsWith(':$type'));
      return;
    }
    _cache.remove(_cacheKey(type, scope));
  }

  String _cacheKey(String type, GroupApiScope scope) => '${scope.name}:$type';

  List<GroupInfo> _normalizeGroups(List<GroupInfo> input) {
    final deduped = <int?, GroupInfo>{};
    for (final group in input) {
      deduped[group.id] = group;
    }
    final groups = deduped.values.toList();
    groups.sort((left, right) {
      final leftRank = _isDefault(left) ? 0 : 1;
      final rightRank = _isDefault(right) ? 0 : 1;
      final rankCompare = leftRank.compareTo(rightRank);
      if (rankCompare != 0) {
        return rankCompare;
      }
      final leftName = (left.name ?? '').trim().toLowerCase();
      final rightName = (right.name ?? '').trim().toLowerCase();
      return leftName.compareTo(rightName);
    });
    return List<GroupInfo>.unmodifiable(groups);
  }

  bool _isDefault(GroupInfo group) {
    final normalizedName = group.name?.trim().toLowerCase();
    return group.isDefault == true ||
        normalizedName == null ||
        normalizedName.isEmpty ||
        normalizedName == 'default';
  }
}

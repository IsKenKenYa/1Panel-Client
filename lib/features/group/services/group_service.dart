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
  }) async {
    if (!forceRefresh && _cache.containsKey(type)) {
      appLogger.dWithPackage(
        'features.group.services.group',
        'listGroups cache hit: type=$type',
      );
      return _cache[type]!;
    }

    appLogger.dWithPackage(
      'features.group.services.group',
      'listGroups cache miss: type=$type',
    );
    final groups = await _repository.listGroups(type);
    final normalized = _normalizeGroups(groups);
    _cache[type] = normalized;
    return normalized;
  }

  Future<List<GroupInfo>> createGroup({
    required String type,
    required String name,
  }) async {
    await _repository.createGroup(type: type, name: name);
    invalidate(type: type);
    return listGroups(type, forceRefresh: true);
  }

  Future<List<GroupInfo>> updateGroup({
    required int id,
    required String type,
    required String name,
    bool isDefault = false,
  }) async {
    await _repository.updateGroup(
      id: id,
      type: type,
      name: name,
      isDefault: isDefault,
    );
    invalidate(type: type);
    return listGroups(type, forceRefresh: true);
  }

  Future<List<GroupInfo>> deleteGroup({
    required int id,
    required String type,
  }) async {
    await _repository.deleteGroup(id);
    invalidate(type: type);
    return listGroups(type, forceRefresh: true);
  }

  void invalidate({String? type}) {
    if (type == null) {
      _cache.clear();
      return;
    }
    _cache.remove(type);
  }

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

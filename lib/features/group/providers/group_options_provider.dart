import 'package:flutter/material.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/group/services/group_service.dart';

class GroupOptionsProvider extends ChangeNotifier with AsyncStateNotifier {
  GroupOptionsProvider({
    GroupService? service,
  }) : _service = service ?? GroupService();

  final GroupService _service;

  String? _groupType;
  int? _selectedGroupId;
  List<GroupInfo> _groups = const <GroupInfo>[];
  bool _isMutating = false;

  String? get groupType => _groupType;
  int? get selectedGroupId => _selectedGroupId;
  List<GroupInfo> get groups => _groups;
  bool get isMutating => _isMutating;

  Future<void> initialize({
    required String groupType,
    int? selectedGroupId,
  }) async {
    _groupType = groupType;
    _selectedGroupId = selectedGroupId;
    await load();
  }

  Future<void> load({bool forceRefresh = false}) async {
    final type = _groupType;
    if (type == null) {
      return;
    }

    appLogger.dWithPackage(
      'features.group.providers.group_options',
      'load: type=$type, forceRefresh=$forceRefresh',
    );
    setLoading();
    try {
      _groups = await _service.listGroups(type, forceRefresh: forceRefresh);
      _selectedGroupId ??= _groups.firstOrNull?.id;
      setSuccess(isEmpty: _groups.isEmpty);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.group.providers.group_options',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _groups = const <GroupInfo>[];
      setError(error);
    }
  }

  void selectGroup(int? id) {
    _selectedGroupId = id;
    notifyListeners();
  }

  Future<void> createGroup(String name) async {
    final type = _requireType();
    await _runMutation(() async {
      _groups = await _service.createGroup(type: type, name: name);
      _selectedGroupId = _matchByName(name)?.id ?? _selectedGroupId;
    });
  }

  Future<void> updateGroup({
    required int id,
    required String name,
    bool isDefault = false,
  }) async {
    final type = _requireType();
    await _runMutation(() async {
      _groups = await _service.updateGroup(
        id: id,
        type: type,
        name: name,
        isDefault: isDefault,
      );
      _selectedGroupId = id;
    });
  }

  Future<void> deleteGroup(int id) async {
    final type = _requireType();
    await _runMutation(() async {
      _groups = await _service.deleteGroup(id: id, type: type);
      if (_selectedGroupId == id) {
        _selectedGroupId = _groups.firstOrNull?.id;
      }
    });
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    _isMutating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await action();
      setSuccess(isEmpty: _groups.isEmpty, notify: false);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.group.providers.group_options',
        'mutation failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  String _requireType() {
    final type = _groupType;
    if (type == null) {
      throw StateError('groupType has not been initialized');
    }
    return type;
  }

  GroupInfo? _matchByName(String name) {
    final normalized = name.trim().toLowerCase();
    for (final group in _groups) {
      if ((group.name ?? '').trim().toLowerCase() == normalized) {
        return group;
      }
    }
    return null;
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

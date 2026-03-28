import 'package:flutter/material.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/data/repositories/group_repository.dart';
import 'package:onepanel_client/features/group/services/group_service.dart';

class GroupCenterProvider extends ChangeNotifier {
  GroupCenterProvider({GroupService? service})
      : _service = service ?? GroupService();

  final GroupService _service;

  static const List<String> supportedTypes = <String>[
    'host',
    'command',
    'cronjob',
    'backup',
    'website',
    'ssh',
  ];

  bool _isLoading = false;
  bool _isMutating = false;
  String? _error;
  GroupApiScope _scope = GroupApiScope.core;
  String _groupType = supportedTypes.first;
  List<GroupInfo> _groups = const <GroupInfo>[];

  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get error => _error;
  GroupApiScope get scope => _scope;
  String get groupType => _groupType;
  List<GroupInfo> get groups => _groups;

  Future<void> load({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _groups = await _service.listGroups(
        _groupType,
        forceRefresh: forceRefresh,
        scope: _scope,
      );
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.group.providers.group_center',
        'load groups failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changeScope(GroupApiScope value) async {
    if (_scope == value) {
      return;
    }
    _scope = value;
    await load();
  }

  Future<void> changeGroupType(String value) async {
    if (_groupType == value) {
      return;
    }
    _groupType = value;
    await load();
  }

  Future<bool> createGroup(String name) => _runMutation(() async {
        _groups = await _service.createGroup(
          type: _groupType,
          name: name,
          scope: _scope,
        );
      });

  Future<bool> updateGroup({
    required int id,
    required String name,
    bool isDefault = false,
  }) =>
      _runMutation(() async {
        _groups = await _service.updateGroup(
          id: id,
          type: _groupType,
          name: name,
          isDefault: isDefault,
          scope: _scope,
        );
      });

  Future<bool> deleteGroup(int id) => _runMutation(() async {
        _groups = await _service.deleteGroup(
          id: id,
          type: _groupType,
          scope: _scope,
        );
      });

  Future<bool> _runMutation(Future<void> Function() action) async {
    _isMutating = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.group.providers.group_center',
        'group mutation failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/cronjob_list_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/cronjobs/services/cronjob_service.dart';

class CronjobsProvider extends ChangeNotifier with AsyncStateNotifier {
  CronjobsProvider({
    CronjobService? service,
  }) : _service = service ?? CronjobService();

  final CronjobService _service;

  List<CronjobSummary> _items = const <CronjobSummary>[];
  List<GroupInfo> _groups = const <GroupInfo>[];
  String _searchQuery = '';
  int? _selectedGroupId;
  bool _isMutating = false;

  List<CronjobSummary> get items => _items;
  List<GroupInfo> get groups => _groups;
  String get searchQuery => _searchQuery;
  int? get selectedGroupId => _selectedGroupId;
  bool get isMutating => _isMutating;

  Future<void> load({bool forceRefresh = false}) async {
    setLoading();
    try {
      _groups = await _service.loadGroups(forceRefresh: forceRefresh);
      final result = await _service.searchCronjobs(
        CronjobListQuery(
          info: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
          groupIds: _selectedGroupId == null
              ? const <int>[]
              : <int>[_selectedGroupId!],
        ),
      );
      _items = result.items;
      setSuccess(isEmpty: _items.isEmpty);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.cronjobs.providers.list',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _items = const <CronjobSummary>[];
      setError(error);
    }
  }

  void updateSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void updateGroupFilter(int? value) {
    _selectedGroupId = value;
    notifyListeners();
  }

  Future<bool> updateStatus(CronjobSummary item, String status) async {
    return _runMutation(() async {
      await _service.updateStatus(item.id, status);
      await load(forceRefresh: true);
    });
  }

  Future<bool> handleOnce(CronjobSummary item) async {
    return _runMutation(() async {
      await _service.handleOnce(item.id);
      await load(forceRefresh: true);
    });
  }

  Future<bool> stop(CronjobSummary item) async {
    return _runMutation(() async {
      await _service.stop(item.id);
      await load(forceRefresh: true);
    });
  }

  Future<bool> delete(CronjobSummary item) async {
    return _runMutation(() async {
      await _service.delete(item.id);
      await load(forceRefresh: true);
    });
  }

  Future<bool> _runMutation(Future<void> Function() action) async {
    _isMutating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await action();
      setSuccess(isEmpty: _items.isEmpty, notify: false);
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.cronjobs.providers.list',
        'mutation failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}

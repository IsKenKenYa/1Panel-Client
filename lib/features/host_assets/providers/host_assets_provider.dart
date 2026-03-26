import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/host_asset_models.dart';
import 'package:onepanel_client/data/models/host_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/host_assets/models/host_asset_test_state.dart';
import 'package:onepanel_client/features/host_assets/services/host_asset_service.dart';

class HostAssetsProvider extends ChangeNotifier with AsyncStateNotifier {
  HostAssetsProvider({
    HostAssetService? service,
  }) : _service = service ?? HostAssetService();

  final HostAssetService _service;

  List<HostInfo> _hosts = const <HostInfo>[];
  List<GroupInfo> _groups = const <GroupInfo>[];
  final Set<int> _selectedIds = <int>{};
  final Map<int, HostAssetTestState> _testStates = <int, HostAssetTestState>{};
  String _searchQuery = '';
  int? _selectedGroupId;
  bool _isMutating = false;

  List<HostInfo> get hosts => _hosts;
  List<GroupInfo> get groups => _groups;
  Set<int> get selectedIds => Set<int>.unmodifiable(_selectedIds);
  String get searchQuery => _searchQuery;
  int? get selectedGroupId => _selectedGroupId;
  bool get isMutating => _isMutating;

  HostAssetTestState testStateFor(int id) =>
      _testStates[id] ?? HostAssetTestState.notTested;

  Future<void> load({bool forceRefresh = false}) async {
    setLoading();
    try {
      _groups = await _service.loadGroups(forceRefresh: forceRefresh);
      final result = await _service.searchHosts(
        HostSearchRequest(
          info: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
          groupID: _selectedGroupId,
        ),
      );
      _hosts = result.items;
      _selectedIds.clear();
      setSuccess(isEmpty: _hosts.isEmpty);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.host_assets.providers.host_assets',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _hosts = const <HostInfo>[];
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

  void toggleSelection(int id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  Future<void> testHost(HostInfo host) async {
    _isMutating = true;
    notifyListeners();
    try {
      final success = await _service.testHostById(host.id);
      _testStates[host.id] = HostAssetTestState(
        status: success
            ? HostAssetTestStatus.success
            : HostAssetTestStatus.failure,
      );
    } catch (error) {
      _testStates[host.id] = HostAssetTestState(
        status: HostAssetTestStatus.failure,
        message: error.toString(),
      );
      setError(error, notify: false);
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> deleteHost(HostInfo host) async {
    await _deleteByIds(<int>[host.id]);
  }

  Future<void> deleteSelected() async {
    if (_selectedIds.isEmpty) {
      return;
    }
    await _deleteByIds(_selectedIds.toList(growable: false));
  }

  Future<void> moveHostGroup({
    required HostInfo host,
    required int groupId,
  }) async {
    _isMutating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.updateHostGroup(
        HostGroupChange(id: host.id, groupID: groupId),
      );
      await load(forceRefresh: true);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.host_assets.providers.host_assets',
        'moveHostGroup failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> _deleteByIds(List<int> ids) async {
    _isMutating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.deleteHosts(ids);
      await load(forceRefresh: true);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.host_assets.providers.host_assets',
        'delete failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}

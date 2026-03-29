import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/services/runtime_service.dart';

class RuntimesProvider extends ChangeNotifier with AsyncStateNotifier {
  RuntimesProvider({
    RuntimeService? service,
  }) : _service = service ?? RuntimeService();

  final RuntimeService _service;

  String _selectedType = RuntimeService.orderedTypes.first;
  String _keyword = '';
  String _statusFilter = '';
  List<RuntimeInfo> _items = const <RuntimeInfo>[];
  bool _isSyncing = false;
  bool _isMutating = false;

  String get selectedType => _selectedType;
  String get keyword => _keyword;
  String get statusFilter => _statusFilter;
  List<RuntimeInfo> get items => _items;
  bool get isSyncing => _isSyncing;
  bool get isMutating => _isMutating;

  Future<void> load() async {
    setLoading();
    try {
      final result = await _service.searchRuntimes(
        type: _selectedType,
        name: _keyword,
        status: _statusFilter,
      );
      _items = result.items;
      setSuccess(isEmpty: _items.isEmpty);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.list',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _items = const <RuntimeInfo>[];
      setError('runtime.list.loadFailed');
    }
  }

  void updateType(String value) {
    _selectedType = value;
    notifyListeners();
  }

  void updateKeyword(String value) {
    _keyword = value;
    notifyListeners();
  }

  void updateStatus(String value) {
    _statusFilter = value;
    notifyListeners();
  }

  Future<bool> syncStatus() async {
    _isSyncing = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.syncRuntimeStatus();
      await load();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.list',
        'sync failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError('runtime.list.syncFailed', notify: false);
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<bool> operate(RuntimeInfo item, String action) async {
    if (item.id == null) return false;
    _isMutating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.operateRuntime(item.id!, action);
      await load();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.list',
        'operate failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError('runtime.list.operateFailed', notify: false);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<bool> delete(RuntimeInfo item) async {
    if (item.id == null) return false;
    _isMutating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.deleteRuntime(item.id!);
      await load();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.list',
        'delete failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError('runtime.list.deleteFailed', notify: false);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>?> checkDeleteDependency(
      RuntimeInfo item) async {
    if (item.id == null) return const <Map<String, dynamic>>[];
    try {
      return await _service.checkDeleteDependency(item.id!);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.list',
        'check delete dependency failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError('runtime.list.deleteFailed');
      return null;
    }
  }

  bool canStart(RuntimeInfo item) => _service.canStart(item);
  bool canStop(RuntimeInfo item) => _service.canStop(item);
  bool canRestart(RuntimeInfo item) => _service.canRestart(item);
  bool canEdit(RuntimeInfo item) => _service.canEdit(item);
}

import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_detail_args.dart';
import 'package:onepanel_client/features/runtimes/services/runtime_service.dart';

class RuntimeDetailProvider extends ChangeNotifier with AsyncStateNotifier {
  RuntimeDetailProvider({
    RuntimeService? service,
  }) : _service = service ?? RuntimeService();

  final RuntimeService _service;

  RuntimeInfo? _runtime;
  int? _runtimeId;
  bool _isSyncing = false;
  bool _isOperating = false;
  bool _isSavingRemark = false;

  RuntimeInfo? get runtime => _runtime;
  int? get runtimeId => _runtimeId;
  bool get isSyncing => _isSyncing;
  bool get isOperating => _isOperating;
  bool get isSavingRemark => _isSavingRemark;

  Future<void> initialize(RuntimeDetailArgs args) async {
    _runtimeId = args.runtimeId;
    await load();
  }

  Future<void> load() async {
    final id = _runtimeId;
    if (id == null) {
      setError('runtime.detail.loadFailed');
      return;
    }
    setLoading();
    try {
      _runtime = await _service.getRuntimeDetail(id);
      setSuccess(isEmpty: _runtime == null);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.detail',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _runtime = null;
      setError('runtime.detail.loadFailed');
    }
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
        'features.runtimes.providers.detail',
        'sync failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError('runtime.detail.syncFailed', notify: false);
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<bool> operate(String action) async {
    final id = _runtime?.id;
    if (id == null) return false;
    _isOperating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.operateRuntime(id, action);
      await load();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.detail',
        'operate failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError('runtime.detail.operateFailed', notify: false);
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  Future<bool> updateRemark(String value) async {
    final id = _runtime?.id;
    if (id == null) return false;
    _isSavingRemark = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.updateRuntimeRemark(id, value);
      await load();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.detail',
        'updateRemark failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is Exception && error.toString().contains('runtime.remark')) {
        setError(error.toString().replaceAll('Exception: ', ''), notify: false);
      } else {
        setError('runtime.detail.remarkFailed', notify: false);
      }
      return false;
    } finally {
      _isSavingRemark = false;
      notifyListeners();
    }
  }

  bool canStart() => _runtime != null && _service.canStart(_runtime!);
  bool canStop() => _runtime != null && _service.canStop(_runtime!);
  bool canRestart() => _runtime != null && _service.canRestart(_runtime!);
  bool canEdit() => _runtime != null && _service.canEdit(_runtime!);
  bool canOpenAdvanced() =>
      _runtime != null && _service.canOpenAdvanced(_runtime!);
}

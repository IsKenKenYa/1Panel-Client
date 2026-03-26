import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/process_detail_models.dart';
import 'package:onepanel_client/features/processes/services/process_service.dart';

class ProcessDetailProvider extends ChangeNotifier with AsyncStateNotifier {
  ProcessDetailProvider({
    ProcessService? service,
  }) : _service = service ?? ProcessService();

  final ProcessService _service;

  int? _pid;
  ProcessDetail? _detail;
  bool _isStopping = false;

  int? get pid => _pid;
  ProcessDetail? get detail => _detail;
  bool get isStopping => _isStopping;

  Future<void> load(int pid) async {
    _pid = pid;
    setLoading();
    try {
      _detail = await _service.loadDetail(pid);
      setSuccess(isEmpty: false);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.processes.providers.detail',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _detail = null;
      setError(error);
    }
  }

  Future<bool> stopProcess() async {
    final currentPid = _pid;
    if (currentPid == null) {
      return false;
    }
    _isStopping = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.stopProcess(currentPid);
      try {
        _detail = await _service.loadDetail(currentPid);
        setSuccess(isEmpty: false, notify: false);
        return false;
      } catch (_) {
        _detail = null;
        setSuccess(isEmpty: true, notify: false);
        return true;
      }
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.processes.providers.detail',
        'stop failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      return false;
    } finally {
      _isStopping = false;
      notifyListeners();
    }
  }
}

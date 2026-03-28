import 'package:flutter/material.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';
import 'package:onepanel_client/features/runtimes/services/php_runtime_service.dart';

class PhpSupervisorProvider extends ChangeNotifier with AsyncStateNotifier {
  PhpSupervisorProvider({
    PhpRuntimeService? service,
  }) : _service = service ?? PhpRuntimeService();

  final PhpRuntimeService _service;

  int? _runtimeId;
  String _runtimeName = '';
  List<SupervisorProcessInfo> _items = const <SupervisorProcessInfo>[];
  bool _isOperating = false;
  bool _isFileLoading = false;
  bool _isFileSaving = false;
  String _activeProcessName = '';
  String _activeFileName = '';
  String _activeFileContent = '';
  String? _fileErrorMessage;

  String get runtimeName => _runtimeName;
  List<SupervisorProcessInfo> get items => _items;
  bool get isOperating => _isOperating;
  bool get isFileLoading => _isFileLoading;
  bool get isFileSaving => _isFileSaving;
  String get activeProcessName => _activeProcessName;
  String get activeFileName => _activeFileName;
  String get activeFileContent => _activeFileContent;
  String? get fileErrorMessage => _fileErrorMessage;
  bool get hasActiveFile =>
      _activeProcessName.isNotEmpty && _activeFileName.isNotEmpty;

  Future<void> initialize(RuntimeManageArgs args) async {
    _runtimeId = args.runtimeId;
    _runtimeName = args.runtimeName ?? '';
    await load();
  }

  Future<void> load() async {
    final runtimeId = _runtimeId;
    if (runtimeId == null) {
      setError('runtime.detail.loadFailed');
      return;
    }
    setLoading();
    try {
      _items = await _service.loadSupervisorProcesses(runtimeId);
      setSuccess(isEmpty: _items.isEmpty);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.php_supervisor',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _items = const <SupervisorProcessInfo>[];
      setError('runtime.detail.loadFailed');
    }
  }

  String processState(SupervisorProcessInfo item) {
    if (item.status.isEmpty) {
      return 'STOPPED';
    }

    var runningCount = 0;
    for (final status in item.status) {
      final normalized = status.status.trim().toUpperCase();
      if (normalized == 'STARTING') {
        return 'STARTING';
      }
      if (normalized == 'RUNNING') {
        runningCount += 1;
      }
    }

    if (runningCount == item.status.length) {
      return 'RUNNING';
    }
    if (runningCount > 0) {
      return 'WARNING';
    }
    return 'STOPPED';
  }

  Future<bool> operateProcess({
    required String processName,
    required String operation,
  }) async {
    final runtimeId = _runtimeId;
    if (runtimeId == null || processName.trim().isEmpty) {
      return false;
    }

    _isOperating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.operateSupervisorProcess(
        runtimeId: runtimeId,
        name: processName.trim(),
        operate: operation,
      );
      await load();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.php_supervisor',
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

  Future<bool> openFile({
    required String processName,
    required String fileName,
  }) async {
    _activeProcessName = processName.trim();
    _activeFileName = fileName.trim();
    _activeFileContent = '';
    _fileErrorMessage = null;
    notifyListeners();
    return refreshActiveFile();
  }

  Future<bool> refreshActiveFile() async {
    final runtimeId = _runtimeId;
    if (runtimeId == null || !hasActiveFile) {
      return false;
    }

    _isFileLoading = true;
    _fileErrorMessage = null;
    notifyListeners();
    try {
      _activeFileContent = await _service.loadSupervisorFile(
        runtimeId: runtimeId,
        name: _activeProcessName,
        file: _activeFileName,
      );
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.php_supervisor',
        'load file failed',
        error: error,
        stackTrace: stackTrace,
      );
      _activeFileContent = '';
      _fileErrorMessage = 'runtime.detail.loadFailed';
      return false;
    } finally {
      _isFileLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveActiveConfig(String content) async {
    final runtimeId = _runtimeId;
    if (runtimeId == null || !hasActiveFile || _activeFileName != 'config') {
      return false;
    }

    _isFileSaving = true;
    _fileErrorMessage = null;
    notifyListeners();
    try {
      await _service.updateSupervisorFile(
        runtimeId: runtimeId,
        name: _activeProcessName,
        file: _activeFileName,
        content: content,
      );
      _activeFileContent = content;
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.php_supervisor',
        'save file failed',
        error: error,
        stackTrace: stackTrace,
      );
      _fileErrorMessage = 'runtime.form.saveFailed';
      return false;
    } finally {
      _isFileSaving = false;
      notifyListeners();
    }
  }

  Future<bool> clearActiveLog() async {
    final runtimeId = _runtimeId;
    if (runtimeId == null ||
        !hasActiveFile ||
        (_activeFileName != 'out.log' && _activeFileName != 'err.log')) {
      return false;
    }

    _isFileSaving = true;
    _fileErrorMessage = null;
    notifyListeners();
    try {
      await _service.clearSupervisorLog(
        runtimeId: runtimeId,
        name: _activeProcessName,
        file: _activeFileName,
      );
      await refreshActiveFile();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.php_supervisor',
        'clear log failed',
        error: error,
        stackTrace: stackTrace,
      );
      _fileErrorMessage = 'runtime.detail.operateFailed';
      return false;
    } finally {
      _isFileSaving = false;
      notifyListeners();
    }
  }

  void closeFile() {
    _activeProcessName = '';
    _activeFileName = '';
    _activeFileContent = '';
    _fileErrorMessage = null;
    notifyListeners();
  }
}

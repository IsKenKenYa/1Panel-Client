import 'package:flutter/material.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';
import 'package:onepanel_client/features/runtimes/services/php_runtime_service.dart';

class PhpConfigProvider extends ChangeNotifier with AsyncStateNotifier {
  PhpConfigProvider({
    PhpRuntimeService? service,
  }) : _service = service ?? PhpRuntimeService();

  final PhpRuntimeService _service;

  int? _runtimeId;
  String _runtimeName = '';
  PHPConfig _config = const PHPConfig();
  List<FpmStatusItem> _fpmStatus = const <FpmStatusItem>[];
  bool _isSaving = false;

  String _uploadMaxSize = '';
  String _maxExecutionTime = '';
  String _disableFunctions = '';

  String get runtimeName => _runtimeName;
  PHPConfig get config => _config;
  List<FpmStatusItem> get fpmStatus => _fpmStatus;
  bool get isSaving => _isSaving;
  String get uploadMaxSize => _uploadMaxSize;
  String get maxExecutionTime => _maxExecutionTime;
  String get disableFunctions => _disableFunctions;

  Future<void> initialize(RuntimeManageArgs args) async {
    _runtimeId = args.runtimeId;
    _runtimeName = args.runtimeName ?? '';
    await load();
  }

  void updateUploadMaxSize(String value) {
    _uploadMaxSize = value;
    notifyListeners();
  }

  void updateMaxExecutionTime(String value) {
    _maxExecutionTime = value;
    notifyListeners();
  }

  void updateDisableFunctions(String value) {
    _disableFunctions = value;
    notifyListeners();
  }

  Future<void> load() async {
    final runtimeId = _runtimeId;
    if (runtimeId == null) {
      setError('runtime.detail.loadFailed');
      return;
    }
    setLoading();
    try {
      final results = await Future.wait<dynamic>([
        _service.loadConfig(runtimeId),
        _service.loadFpmStatus(runtimeId),
      ]);
      _config = results[0] as PHPConfig? ?? const PHPConfig();
      _fpmStatus = results[1] as List<FpmStatusItem>;
      _uploadMaxSize = _config.uploadMaxSize ?? '';
      _maxExecutionTime = _config.maxExecutionTime ?? '';
      _disableFunctions = _config.disableFunctions.join(',');
      setSuccess(isEmpty: false);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.php_config',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _config = const PHPConfig();
      _fpmStatus = const <FpmStatusItem>[];
      setError('runtime.detail.loadFailed');
    }
  }

  Future<bool> save() async {
    final runtimeId = _runtimeId;
    if (runtimeId == null) {
      return false;
    }
    _isSaving = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.saveConfig(
        PHPConfigUpdate(
          id: runtimeId,
          scope: 'php',
          params: _config.params,
          disableFunctions: _disableFunctions
              .split(',')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false),
          uploadMaxSize:
              _uploadMaxSize.trim().isEmpty ? null : _uploadMaxSize.trim(),
          maxExecutionTime: _maxExecutionTime.trim().isEmpty
              ? null
              : _maxExecutionTime.trim(),
        ),
      );
      await load();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.php_config',
        'save failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError('runtime.form.saveFailed', notify: false);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}

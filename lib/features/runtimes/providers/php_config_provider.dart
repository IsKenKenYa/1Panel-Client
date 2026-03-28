import 'package:flutter/material.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';
import 'package:onepanel_client/features/runtimes/services/php_runtime_service.dart';

part 'php_config_provider_deep.dart';
part 'php_config_provider_deep_save.dart';

class PhpConfigProvider extends ChangeNotifier with AsyncStateNotifier {
  PhpConfigProvider({
    PhpRuntimeService? service,
  }) : _service = service ?? PhpRuntimeService();

  final PhpRuntimeService _service;
  static const String phpFileType = 'php';
  static const String fpmFileType = 'fpm';

  int? _runtimeId;
  String _runtimeName = '';
  PHPConfig _config = const PHPConfig();
  List<FpmStatusItem> _fpmStatus = const <FpmStatusItem>[];
  PHPFpmConfig _fpmConfig = const PHPFpmConfig(id: 0);
  PHPContainerConfig _containerConfig = const PHPContainerConfig(id: 0);
  String _phpFilePath = '';
  String _phpFileContent = '';
  String _fpmFilePath = '';
  String _fpmFileContent = '';

  bool _isSaving = false;
  bool _isSavingFpmConfig = false;
  bool _isSavingContainerConfig = false;
  bool _isSavingPhpFile = false;
  bool _isSavingFpmFile = false;

  String _uploadMaxSize = '';
  String _maxExecutionTime = '';
  String _disableFunctions = '';

  String get runtimeName => _runtimeName;
  PHPConfig get config => _config;
  List<FpmStatusItem> get fpmStatus => _fpmStatus;
  PHPFpmConfig get fpmConfig => _fpmConfig;
  PHPContainerConfig get containerConfig => _containerConfig;
  String get phpFilePath => _phpFilePath;
  String get phpFileContent => _phpFileContent;
  String get fpmFilePath => _fpmFilePath;
  String get fpmFileContent => _fpmFileContent;
  bool get isSaving => _isSaving;
  bool get isSavingFpmConfig => _isSavingFpmConfig;
  bool get isSavingContainerConfig => _isSavingContainerConfig;
  bool get isSavingPhpFile => _isSavingPhpFile;
  bool get isSavingFpmFile => _isSavingFpmFile;
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

  void updateFpmParam(String key, String value) {
    phpConfigProviderUpdateFpmParam(this, key, value);
  }

  void updateContainerName(String value) {
    phpConfigProviderUpdateContainerName(this, value);
  }

  void updatePhpFileContent(String value) {
    phpConfigProviderUpdatePhpFileContent(this, value);
  }

  void updateFpmFileContent(String value) {
    phpConfigProviderUpdateFpmFileContent(this, value);
  }

  void addEnvironment() {
    phpConfigProviderAddEnvironment(this);
  }

  void updateEnvironment(int index, {String? key, String? value}) {
    phpConfigProviderUpdateEnvironment(
      this,
      index,
      key: key,
      value: value,
    );
  }

  void removeEnvironment(int index) {
    phpConfigProviderRemoveEnvironment(this, index);
  }

  void addExposedPort() {
    phpConfigProviderAddExposedPort(this);
  }

  void updateExposedPort(
    int index, {
    int? containerPort,
    String? hostIP,
    int? hostPort,
  }) {
    phpConfigProviderUpdateExposedPort(
      this,
      index,
      containerPort: containerPort,
      hostIP: hostIP,
      hostPort: hostPort,
    );
  }

  void removeExposedPort(int index) {
    phpConfigProviderRemoveExposedPort(this, index);
  }

  void addExtraHost() {
    phpConfigProviderAddExtraHost(this);
  }

  void updateExtraHost(int index, {String? hostname, String? ip}) {
    phpConfigProviderUpdateExtraHost(
      this,
      index,
      hostname: hostname,
      ip: ip,
    );
  }

  void removeExtraHost(int index) {
    phpConfigProviderRemoveExtraHost(this, index);
  }

  void addVolume() {
    phpConfigProviderAddVolume(this);
  }

  void updateVolume(int index, {String? source, String? target}) {
    phpConfigProviderUpdateVolume(
      this,
      index,
      source: source,
      target: target,
    );
  }

  void removeVolume(int index) {
    phpConfigProviderRemoveVolume(this, index);
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
        _service.loadFpmConfig(runtimeId),
        _service.loadContainerConfig(runtimeId),
        _service.loadConfigFile(runtimeId: runtimeId, type: phpFileType),
        _service.loadConfigFile(runtimeId: runtimeId, type: fpmFileType),
      ]);
      _config = results[0] as PHPConfig? ?? const PHPConfig();
      _fpmStatus = results[1] as List<FpmStatusItem>;
      _fpmConfig = results[2] as PHPFpmConfig;
      _containerConfig = results[3] as PHPContainerConfig;
      final phpFile = results[4] as PHPConfigFileContent;
      final fpmFile = results[5] as PHPConfigFileContent;
      _phpFilePath = phpFile.path;
      _phpFileContent = phpFile.content;
      _fpmFilePath = fpmFile.path;
      _fpmFileContent = fpmFile.content;
      _uploadMaxSize = _config.uploadMaxSize ?? '';
      _maxExecutionTime = _config.maxExecutionTime ?? '';
      _disableFunctions = _config.disableFunctions.join(',');
      _containerConfig = _containerConfig.copyWith(
        id: _containerConfig.id == 0 ? runtimeId : _containerConfig.id,
      );
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
      _fpmConfig = PHPFpmConfig(id: runtimeId);
      _containerConfig = PHPContainerConfig(id: runtimeId);
      _phpFilePath = '';
      _phpFileContent = '';
      _fpmFilePath = '';
      _fpmFileContent = '';
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

  Future<bool> saveFpmConfig() {
    return phpConfigProviderSaveFpmConfig(this);
  }

  Future<bool> saveContainerConfig() {
    return phpConfigProviderSaveContainerConfig(this);
  }

  Future<bool> savePhpFile() {
    return phpConfigProviderSavePhpFile(this);
  }

  Future<bool> saveFpmFile() {
    return phpConfigProviderSaveFpmFile(this);
  }

  void _notifyStateChange() {
    notifyListeners();
  }

  void _clearProviderError({bool notify = true}) {
    clearError(notify: notify);
  }

  void _setProviderError(Object error, {bool notify = true}) {
    setError(error, notify: notify);
  }
}

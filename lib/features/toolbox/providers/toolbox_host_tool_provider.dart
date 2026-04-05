import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/host_tool_models.dart';
import 'package:onepanel_client/features/toolbox/services/toolbox_host_tool_service.dart';

class ToolboxHostToolProvider extends ChangeNotifier with SafeChangeNotifier {
  ToolboxHostToolProvider({ToolboxHostToolService? service})
      : _service = service ?? ToolboxHostToolService();

  final ToolboxHostToolService _service;

  bool _isLoading = false;
  bool _isMutating = false;
  String? _error;
  SupervisorServiceInfo _serviceInfo = const SupervisorServiceInfo();
  String _configContent = '';
  List<HostToolProcessConfig> _processes = const <HostToolProcessConfig>[];

  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get error => _error;
  SupervisorServiceInfo get serviceInfo => _serviceInfo;
  String get configContent => _configContent;
  List<HostToolProcessConfig> get processes => _processes;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _service.loadSnapshot();
      _serviceInfo = snapshot.serviceInfo;
      _configContent = snapshot.configContent;
      _processes = snapshot.processes;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_host_tool',
        'load host tool failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> initSupervisor({
    required String configPath,
    required String serviceName,
  }) {
    return _runMutation(
      () => _service.initSupervisor(
        configPath: configPath,
        serviceName: serviceName,
      ),
    );
  }

  Future<bool> operateSupervisor(String operate) {
    return _runMutation(() => _service.operateSupervisor(operate));
  }

  Future<bool> saveSupervisorConfig(String content) {
    return _runMutation(() => _service.saveSupervisorConfig(content));
  }

  Future<bool> saveProcess(HostToolProcessConfigRequest request) {
    return _runMutation(() => _service.saveProcess(request));
  }

  Future<bool> operateProcess({
    required String name,
    required String operate,
  }) {
    return _runMutation(
      () => _service.operateProcess(name: name, operate: operate),
    );
  }

  Future<String?> loadProcessFile({
    required String name,
    required String file,
  }) async {
    try {
      _error = null;
      notifyListeners();
      return await _service.loadProcessFile(name: name, file: file);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_host_tool',
        'load process file failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> clearProcessFile({
    required String name,
    required String file,
  }) {
    return _runMutation(
        () => _service.clearProcessFile(name: name, file: file));
  }

  Future<bool> updateProcessFile({
    required String name,
    required String file,
    required String content,
  }) {
    return _runMutation(
      () =>
          _service.updateProcessFile(name: name, file: file, content: content),
    );
  }

  Future<bool> _runMutation(Future<void> Function() action) async {
    _isMutating = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      await load();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_host_tool',
        'host tool mutation failed',
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

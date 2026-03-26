import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/ssh_settings_models.dart';
import 'package:onepanel_client/features/ssh/services/ssh_service.dart';

class SshSettingsProvider extends ChangeNotifier with AsyncStateNotifier {
  SshSettingsProvider({
    SSHService? service,
  }) : _service = service ?? SSHService();

  final SSHService _service;

  SshInfo? _info;
  String _rawConfig = '';
  bool _isMutating = false;

  SshInfo? get info => _info;
  String get rawConfig => _rawConfig;
  bool get isMutating => _isMutating;

  Future<void> load() async {
    setLoading();
    try {
      _info = await _service.loadInfo();
      _rawConfig = await _service.loadRawConfig();
      setSuccess(isEmpty: false);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ssh.providers.settings',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _info = null;
      _rawConfig = '';
      setError(error);
    }
  }

  Future<bool> operate(String operation) async {
    return _runMutation(() async {
      await _service.operate(operation);
      await load();
    });
  }

  Future<bool> toggleAutoStart(bool enabled) async {
    return operate(enabled ? 'enable' : 'disable');
  }

  Future<bool> updateSetting({
    required String key,
    required String newValue,
    String oldValue = '',
  }) {
    return _runMutation(() async {
      await _service.updateSetting(
        key: key,
        oldValue: oldValue,
        newValue: newValue,
      );
      await load();
    });
  }

  Future<bool> saveRawConfig(String value) async {
    return _runMutation(() async {
      await _service.saveRawConfig(value);
      _rawConfig = value;
      _info = await _service.loadInfo();
    });
  }

  Future<void> reloadRawConfig() async {
    try {
      _rawConfig = await _service.loadRawConfig();
      notifyListeners();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ssh.providers.settings',
        'reloadRawConfig failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error);
    }
  }

  Future<bool> _runMutation(Future<void> Function() action) async {
    _isMutating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await action();
      setSuccess(isEmpty: false, notify: false);
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ssh.providers.settings',
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

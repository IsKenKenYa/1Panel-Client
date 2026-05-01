import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/features/toolbox/services/toolbox_fail2ban_service.dart';

class ToolboxFail2banProvider extends ChangeNotifier with SafeChangeNotifier {
  ToolboxFail2banProvider({ToolboxFail2banService? service})
      : _service = service ?? ToolboxFail2banService();

  final ToolboxFail2banService _service;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isOperating = false;
  String? _error;
  Fail2banBaseInfo _baseInfo = const Fail2banBaseInfo();
  String _configText = '';
  List<Fail2banRecord> _records = const <Fail2banRecord>[];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isOperating => _isOperating;
  bool get isBusy => _isSaving || _isOperating;
  String? get error => _error;
  Fail2banBaseInfo get baseInfo => _baseInfo;
  String get configText => _configText;
  List<Fail2banRecord> get records => _records;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final snapshot = await _service.loadSnapshot();
      _baseInfo = snapshot.baseInfo;
      _configText = snapshot.configText;
      _records = snapshot.records;
      _error = null;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_fail2ban',
        'load fail2ban failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveConfig({
    required String bantime,
    required String findtime,
    required String maxretry,
    required String port,
    required bool isEnable,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateConfig(
        Fail2banUpdate(
          bantime: bantime.trim(),
          findtime: findtime.trim(),
          maxretry: maxretry.trim(),
          port: port.trim(),
          isEnable: isEnable,
        ),
      );
      await load(silent: true);
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_fail2ban',
        'save fail2ban config failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> toggle(bool enabled) {
    return _operate(enabled ? 'enable' : 'disable');
  }

  Future<bool> restart() {
    return _operate('restart');
  }

  Future<bool> start() {
    return _operate('start');
  }

  Future<bool> stop() {
    return _operate('stop');
  }

  Future<bool> operateSshd({
    required String operate,
    List<String> ips = const <String>[],
  }) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      await _service.operateSshd(operate: operate, ips: ips);
      await load(silent: true);
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_fail2ban',
        'operate fail2ban sshd failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  Future<bool> _operate(String operation) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      await _service.operate(operation);
      await load(silent: true);
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_fail2ban',
        'operate fail2ban failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }
}

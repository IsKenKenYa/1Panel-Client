import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/features/toolbox/services/toolbox_device_service.dart';

class ToolboxDeviceProvider extends ChangeNotifier {
  ToolboxDeviceProvider({ToolboxDeviceService? service})
      : _service = service ?? ToolboxDeviceService();

  final ToolboxDeviceService _service;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isCheckingDns = false;
  bool _isUpdatingPassword = false;
  bool _isUpdatingSwap = false;
  String? _error;
  DeviceBaseInfo _baseInfo = const DeviceBaseInfo();
  Map<String, dynamic> _conf = const <String, dynamic>{};
  List<String> _users = const <String>[];
  List<String> _zoneOptions = const <String>[];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isCheckingDns => _isCheckingDns;
  bool get isUpdatingPassword => _isUpdatingPassword;
  bool get isUpdatingSwap => _isUpdatingSwap;
  bool get isBusy =>
      _isSaving || _isCheckingDns || _isUpdatingPassword || _isUpdatingSwap;
  String? get error => _error;
  DeviceBaseInfo get baseInfo => _baseInfo;
  Map<String, dynamic> get conf => _conf;
  List<String> get users => _users;
  List<String> get zoneOptions => _zoneOptions;

  String get dns => _readValue(['dns']);
  String get hostname => _readValue(['hostname']);
  String get ntp => _readValue(['ntp']);
  String get swap => _readValue(['swap']);

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final snapshot = await _service.loadSnapshot();
      _baseInfo = snapshot.baseInfo;
      _conf = snapshot.conf;
      _users = snapshot.users;
      _zoneOptions = snapshot.zoneOptions;
      _error = null;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_device',
        'load device info failed',
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
    required String hostname,
    required String dns,
    required String ntp,
    required String swap,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateConfig(
        hostname: hostname.trim(),
        dns: dns.trim(),
        ntp: ntp.trim(),
        swap: swap.trim(),
      );
      await load(silent: true);
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_device',
        'save device config failed',
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

  Future<bool> checkDns(String dns) async {
    if (dns.trim().isEmpty) {
      _error = 'dns-empty';
      notifyListeners();
      return false;
    }

    _isCheckingDns = true;
    _error = null;
    notifyListeners();

    try {
      await _service.verifyDns(dns.trim());
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_device',
        'check dns failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      return false;
    } finally {
      _isCheckingDns = false;
      notifyListeners();
    }
  }

  Future<bool> updateSwap(String swap) async {
    final trimmed = swap.trim();
    if (trimmed.isEmpty) {
      _error = 'swap-empty';
      notifyListeners();
      return false;
    }

    _isUpdatingSwap = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateSwap(trimmed);
      await load(silent: true);
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_device',
        'update swap failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      return false;
    } finally {
      _isUpdatingSwap = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final oldTrimmed = oldPassword.trim();
    final newTrimmed = newPassword.trim();
    final confirmTrimmed = confirmPassword.trim();

    if (oldTrimmed.isEmpty || newTrimmed.isEmpty || confirmTrimmed.isEmpty) {
      _error = 'password-empty';
      notifyListeners();
      return false;
    }

    if (newTrimmed.length < 6) {
      _error = 'password-too-short';
      notifyListeners();
      return false;
    }

    if (newTrimmed != confirmTrimmed) {
      _error = 'password-mismatch';
      notifyListeners();
      return false;
    }

    _isUpdatingPassword = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updatePassword(
        oldPassword: oldTrimmed,
        newPassword: newTrimmed,
      );
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_device',
        'change password failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      return false;
    } finally {
      _isUpdatingPassword = false;
      notifyListeners();
    }
  }

  String _readValue(List<String> keys) {
    for (final key in keys) {
      final confValue = _service.readConfigValue(_conf, [key]);
      if (confValue != '-') {
        return confValue;
      }
    }

    final baseCandidates = <String?>[
      if (keys.contains('dns')) _baseInfo.dns,
      if (keys.contains('hostname')) _baseInfo.hostname,
      if (keys.contains('ntp')) _baseInfo.ntp,
    ];
    for (final value in baseCandidates) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '-';
  }
}

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/security/app_local_auth_service.dart';
import 'package:onepanel_client/core/security/app_lock_settings_store.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';

const String _appLockControllerPackage =
    'features.security.app_lock_controller';

class AppLockController extends ChangeNotifier {
  AppLockController({
    AppLockSettingsStore? settingsStore,
    AppLocalAuthService? localAuthService,
    DateTime Function()? now,
  })  : _settingsStore = settingsStore ?? AppLockSettingsStore(),
        _localAuthService = localAuthService ?? AppLocalAuthService(),
        _now = now ?? DateTime.now;

  final AppLockSettingsStore _settingsStore;
  final AppLocalAuthService _localAuthService;
  final DateTime Function() _now;

  bool _isLoaded = false;
  bool _isUnlocking = false;
  bool _sessionUnlocked = false;
  DateTime? _backgroundAt;
  DateTime? _lastUnlockedAt;
  String? _lastError;

  AppLockSettings _settings = AppLockSettings.defaults;
  LocalAuthAvailability _availability = const LocalAuthAvailability.unknown();

  bool get isLoaded => _isLoaded;
  bool get isUnlocking => _isUnlocking;
  bool get isSessionUnlocked => _sessionUnlocked;
  DateTime? get lastUnlockedAt => _lastUnlockedAt;
  String? get lastError => _lastError;
  AppLockSettings get settings => _settings;
  LocalAuthAvailability get availability => _availability;

  bool get isEnabled => _settings.enabled;
  bool get canUseLocalAuth => _availability.isSupported;

  Future<void> load() async {
    try {
      _settings = await _settingsStore.load();
      _availability = await _localAuthService.checkAvailability();
      _sessionUnlocked = !_settings.enabled;
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        _appLockControllerPackage,
        'load failed',
        error: e,
        stackTrace: stackTrace,
      );
      _lastError = e.toString();
      _settings = AppLockSettings.defaults;
      _availability = const LocalAuthAvailability.unknown();
      _sessionUnlocked = true;
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> refreshAvailability() async {
    _availability = await _localAuthService.checkAvailability();
    notifyListeners();
  }

  Future<bool> enableWithVerification({required String reason}) async {
    if (_settings.enabled) {
      return true;
    }
    if (!_availability.isSupported) {
      _lastError = _availability.reason ?? '当前设备不支持本地认证';
      notifyListeners();
      return false;
    }

    final unlocked = await authenticateForUnlock(reason: reason);
    if (!unlocked) {
      return false;
    }

    _settings = _settings.copyWith(enabled: true);
    await _settingsStore.save(_settings);
    _sessionUnlocked = true;
    notifyListeners();
    return true;
  }

  Future<void> disable() async {
    if (!_settings.enabled) {
      return;
    }

    _settings = _settings.copyWith(enabled: false);
    await _settingsStore.save(_settings);
    _sessionUnlocked = true;
    _lastError = null;
    notifyListeners();
  }

  Future<void> updateLockOnAppOpen(bool enabled) async {
    _settings = _settings.copyWith(lockOnAppOpen: enabled);
    await _settingsStore.save(_settings);
    notifyListeners();
  }

  Future<void> updateLockOnProtectedModule(bool enabled) async {
    _settings = _settings.copyWith(lockOnProtectedModule: enabled);
    await _settingsStore.save(_settings);
    notifyListeners();
  }

  Future<void> updateRelockAfterMinutes(int minutes) async {
    if (minutes <= 0) {
      return;
    }
    _settings = _settings.copyWith(relockAfterMinutes: minutes);
    await _settingsStore.save(_settings);
    notifyListeners();
  }

  Future<void> updateProtectedModuleIds(List<String> moduleIds) async {
    _settings = _settings.copyWith(protectedModuleIds: moduleIds);
    await _settingsStore.save(_settings);
    notifyListeners();
  }

  bool shouldRequireUnlockForAppOpen() {
    return _settings.enabled && _settings.lockOnAppOpen && !_sessionUnlocked;
  }

  bool shouldRequireUnlockForModuleId(String moduleId) {
    if (!_settings.enabled || !_settings.lockOnProtectedModule) {
      return false;
    }
    if (!_settings.protectedModuleIds.contains(moduleId)) {
      return false;
    }
    return !_sessionUnlocked;
  }

  Future<bool> authenticateForUnlock({
    required String reason,
    bool biometricOnly = false,
  }) async {
    if (!_settings.enabled && !_isLoaded) {
      await load();
    }

    if (_isUnlocking) {
      return false;
    }

    if (!_availability.isSupported) {
      _lastError = _availability.reason ?? '当前设备不支持本地认证';
      notifyListeners();
      return false;
    }

    _isUnlocking = true;
    _lastError = null;
    notifyListeners();

    final result = await _localAuthService.authenticate(
      localizedReason: reason,
      biometricOnly: biometricOnly,
    );

    _isUnlocking = false;
    if (result.success) {
      _sessionUnlocked = true;
      _lastUnlockedAt = _now();
      _lastError = null;
    } else {
      _lastError = result.message ?? '本地认证失败';
    }
    notifyListeners();
    return result.success;
  }

  void onAppLifecycleChanged(AppLifecycleState state) {
    if (!_settings.enabled) {
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _backgroundAt = _now();
      return;
    }

    if (state == AppLifecycleState.resumed && _backgroundAt != null) {
      final elapsed = _now().difference(_backgroundAt!);
      _backgroundAt = null;
      if (elapsed.inMinutes >= _settings.relockAfterMinutes) {
        _sessionUnlocked = false;
        notifyListeners();
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/security/app_local_auth_service.dart';
import 'package:onepanel_client/core/security/app_lock_settings_store.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:synchronized/synchronized.dart';

const String _appLockControllerPackage =
    'features.security.app_lock_controller';

class AppLockController extends ChangeNotifier with SafeChangeNotifier {
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
  final Lock _settingsLock = Lock();

  bool _isLoaded = false;
  bool _isUnlocking = false;
  bool _sessionUnlocked = false;
  bool _expiredInBackground = false;
  DateTime? _backgroundAt;
  DateTime? _lastUnlockedAt;
  String? _lastError;

  AppLockSettings _settings = AppLockSettings.defaults;
  LocalAuthAvailability _availability = const LocalAuthAvailability.unknown();

  bool get isLoaded => _isLoaded;
  bool get isUnlocking => _isUnlocking;
  bool get isSessionUnlocked => _sessionUnlocked;
  bool get requiresResumeUnlock =>
      _expiredInBackground && shouldRequireUnlockForAppOpen();
  DateTime? get lastUnlockedAt => _lastUnlockedAt;
  String? get lastError => _lastError;
  AppLockSettings get settings => _settings;
  LocalAuthAvailability get availability => _availability;

  bool get isEnabled => _settings.enabled;
  bool get canUseLocalAuth => _availability.isSupported;

  Future<void> load() => _settingsLock.synchronized(() async {
        if (_isLoaded) return;
        try {
          _settings = await _settingsStore.load();
          _availability = await _localAuthService.checkAvailability();
          _sessionUnlocked = !_settings.enabled;
          _lastError = null;
          _isLoaded = true;
        } catch (e, stackTrace) {
          appLogger.eWithPackage(
            _appLockControllerPackage,
            'load failed',
            error: e,
            stackTrace: stackTrace,
          );
          _lastError = e.toString();
          _sessionUnlocked = false;
        }

        notifyListeners();
      });

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

    // Require a successful biometric/PIN auth before enabling the lock
    // to prevent an unauthorized user from locking the owner out.
    final unlocked = await authenticateForUnlock(reason: reason);
    if (!unlocked) {
      return false;
    }

    await _changeSettings((current) => current.copyWith(enabled: true));
    return true;
  }

  Future<void> disable() async {
    if (!_settings.enabled) {
      return;
    }

    await _changeSettings((current) => current.copyWith(enabled: false));
  }

  Future<void> updateLockOnAppOpen(bool enabled) async {
    await _changeSettings(
      (current) => current.copyWith(lockOnAppOpen: enabled),
    );
  }

  Future<void> updateLockOnProtectedModule(bool enabled) async {
    await _changeSettings(
      (current) => current.copyWith(lockOnProtectedModule: enabled),
    );
  }

  Future<void> updateRelockAfterMinutes(int minutes) async {
    if (minutes <= 0) {
      return;
    }
    await _changeSettings(
      (current) => current.copyWith(relockAfterMinutes: minutes),
    );
  }

  Future<void> updateProtectedModuleIds(List<String> moduleIds) async {
    await _changeSettings(
      (current) =>
          current.copyWith(protectedModuleIds: List.unmodifiable(moduleIds)),
    );
  }

  Future<void> setModuleProtected(String moduleId, bool enabled) =>
      _changeSettings((current) {
        final ids = current.protectedModuleIds.toSet();
        if (enabled) {
          ids.add(moduleId);
        } else {
          ids.remove(moduleId);
        }
        return current.copyWith(
          protectedModuleIds: ids.toList(growable: false),
        );
      });

  Future<void> _changeSettings(
    AppLockSettings Function(AppLockSettings) change,
  ) =>
      _settingsLock.synchronized(() async {
        if (_settings.enabled && !_sessionUnlocked) {
          throw StateError('修改应用锁设置前需要验证身份');
        }
        final next = change(_settings);
        await _settingsStore.save(next);
        _settings = next;
        if (!next.enabled) _sessionUnlocked = true;
        _lastError = null;
        notifyListeners();
      });

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
    _backgroundAt = null;
    _lastError = null;
    notifyListeners();

    final result = await _localAuthService.authenticate(
      localizedReason: reason,
      biometricOnly: biometricOnly,
    );

    _isUnlocking = false;
    if (result.success) {
      _sessionUnlocked = true;
      _expiredInBackground = false;
      _lastUnlockedAt = _now();
      _lastError = null;
    } else {
      _lastError = result.message ?? '本地认证失败';
    }
    notifyListeners();
    return result.success;
  }

  void onAppLifecycleChanged(AppLifecycleState state) {
    if (!_settings.enabled || _isUnlocking) {
      return;
    }

    // Record when the app goes to background so we can decide on resume
    // whether enough time has elapsed to require re-authentication.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _backgroundAt ??= _now();
      return;
    }

    if (state == AppLifecycleState.resumed && _backgroundAt != null) {
      final elapsed = _now().difference(_backgroundAt!);
      _backgroundAt = null;
      if (elapsed.inMinutes >= _settings.relockAfterMinutes) {
        _sessionUnlocked = false;
        _expiredInBackground = true;
        notifyListeners();
      }
    }
  }
}

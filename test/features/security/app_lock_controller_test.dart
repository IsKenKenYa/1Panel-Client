import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:onepanel_client/core/security/app_local_auth_service.dart';
import 'package:onepanel_client/core/security/app_lock_settings_store.dart';
import 'package:onepanel_client/features/security/app_lock_controller.dart';

class _InMemorySettingsStore extends AppLockSettingsStore {
  _InMemorySettingsStore(this._settings);

  AppLockSettings _settings;

  @override
  Future<AppLockSettings> load() async => _settings;

  @override
  Future<void> save(AppLockSettings settings) async {
    _settings = settings;
  }
}

class _FakeLocalAuthGateway implements LocalAuthGateway {
  bool canCheck = true;
  bool deviceSupported = true;
  List<BiometricType> biometrics = <BiometricType>[BiometricType.fingerprint];
  bool authResult = true;
  String? platformErrorCode;

  @override
  Future<bool> canCheckBiometrics() async => canCheck;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => biometrics;

  @override
  Future<bool> isDeviceSupported() async => deviceSupported;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required AuthenticationOptions options,
  }) async {
    if (platformErrorCode != null) {
      throw PlatformException(code: platformErrorCode!);
    }
    return authResult;
  }
}

void main() {
  group('AppLockController', () {
    test('load defaults to unlocked session when disabled', () async {
      final gateway = _FakeLocalAuthGateway();
      final controller = AppLockController(
        settingsStore: _InMemorySettingsStore(AppLockSettings.defaults),
        localAuthService: AppLocalAuthService(gateway: gateway),
      );

      await controller.load();

      expect(controller.isLoaded, isTrue);
      expect(controller.settings.enabled, isFalse);
      expect(controller.isSessionUnlocked, isTrue);
      expect(controller.canUseLocalAuth, isTrue);
    });

    test('enableWithVerification turns on app lock after auth success',
        () async {
      final gateway = _FakeLocalAuthGateway()..authResult = true;
      final store = _InMemorySettingsStore(AppLockSettings.defaults);
      final controller = AppLockController(
        settingsStore: store,
        localAuthService: AppLocalAuthService(gateway: gateway),
      );

      await controller.load();
      final ok = await controller.enableWithVerification(reason: 'enable');

      expect(ok, isTrue);
      expect(controller.settings.enabled, isTrue);
      expect(controller.isSessionUnlocked, isTrue);
      final persisted = await store.load();
      expect(persisted.enabled, isTrue);
    });

    test('relocks after background timeout and protects modules', () async {
      final gateway = _FakeLocalAuthGateway()..authResult = true;
      final store = _InMemorySettingsStore(
        AppLockSettings.defaults.copyWith(
          enabled: true,
          protectedModuleIds: const <String>['files'],
          relockAfterMinutes: 5,
        ),
      );

      var now = DateTime(2026, 3, 31, 10, 0, 0);
      final controller = AppLockController(
        settingsStore: store,
        localAuthService: AppLocalAuthService(gateway: gateway),
        now: () => now,
      );

      await controller.load();
      await controller.authenticateForUnlock(reason: 'unlock');
      expect(controller.isSessionUnlocked, isTrue);

      controller.onAppLifecycleChanged(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 6));
      controller.onAppLifecycleChanged(AppLifecycleState.resumed);

      expect(controller.isSessionUnlocked, isFalse);
      expect(controller.shouldRequireUnlockForModuleId('files'), isTrue);
      expect(controller.shouldRequireUnlockForModuleId('containers'), isFalse);
    });

    test('reports auth failure message when platform throws', () async {
      final gateway = _FakeLocalAuthGateway()..platformErrorCode = 'LockedOut';
      final controller = AppLockController(
        settingsStore: _InMemorySettingsStore(
          AppLockSettings.defaults.copyWith(enabled: true),
        ),
        localAuthService: AppLocalAuthService(gateway: gateway),
      );

      await controller.load();
      final ok = await controller.authenticateForUnlock(reason: 'unlock');

      expect(ok, isFalse);
      expect(controller.lastError, isNotNull);
    });
  });
}

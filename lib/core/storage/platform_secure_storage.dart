import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:onepanel_client/core/platform/platform_capabilities.dart';

import 'browser_vault.dart';

enum _Backend { browser, native, ohos, macKeychain }

class PlatformSecureStorage {
  const PlatformSecureStorage._(this._backend);

  final _Backend _backend;

  static const _native = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      accountName: 'kenpanel',
    ),
    lOptions: LinuxOptions(),
  );

  /// macOS 走 Runner 内的 SecItem 通道，理由见 `MacKeychainVault`。
  static const _macKeychain = MethodChannel('onepanel/secure_storage');
  static const _ohos = MethodChannel('onepanel/secure_storage');

  static Future<PlatformSecureStorage> create() async {
    final platform = PlatformCapabilities.current();
    if (platform.isWeb) {
      await BrowserVault.instance.initialize();
      if (!BrowserVault.instance.isUnlocked) {
        throw StateError('Browser secure storage is locked');
      }
      return const PlatformSecureStorage._(_Backend.browser);
    }
    if (platform.isOhos) return const PlatformSecureStorage._(_Backend.ohos);
    if (platform.targetPlatform == TargetPlatform.macOS) {
      return const PlatformSecureStorage._(_Backend.macKeychain);
    }
    return const PlatformSecureStorage._(_Backend.native);
  }

  Future<String?> read({required String key}) => switch (_backend) {
        _Backend.browser => BrowserVault.instance.read(key),
        _Backend.native => _native.read(key: key),
        _Backend.macKeychain => _macKeychain.invokeMethod<String>('read', {'key': key}),
        _Backend.ohos => _ohos.invokeMethod<String>('read', {'key': key}),
      };

  Future<void> write({required String key, required String? value}) {
    if (value == null) return delete(key: key);
    return switch (_backend) {
      _Backend.browser => BrowserVault.instance.write(key, value),
      _Backend.native => _native.write(key: key, value: value),
      _Backend.macKeychain => _mutateChannel(
          _macKeychain, 'write', {'key': key, 'value': value},
          backend: 'macOS',
        ),
      _Backend.ohos => _mutateOhos('write', {'key': key, 'value': value}),
    };
  }

  Future<void> delete({required String key}) => switch (_backend) {
        _Backend.browser => BrowserVault.instance.delete(key),
        _Backend.native => _native.delete(key: key),
        _Backend.macKeychain => _mutateChannel(
          _macKeychain, 'delete', {'key': key},
          backend: 'macOS',
        ),
        _Backend.ohos => _mutateOhos('delete', {'key': key}),
      };

  Future<void> deleteAll() => switch (_backend) {
        _Backend.browser => BrowserVault.instance.deleteAll(),
        _Backend.native => _native.deleteAll(),
        _Backend.macKeychain => _mutateChannel(
          _macKeychain, 'deleteAll', null,
          backend: 'macOS',
        ),
        _Backend.ohos => _mutateOhos('deleteAll'),
      };

  static Future<void> _mutateChannel(
    MethodChannel channel,
    String method,
    Map<String, String>? arguments, {
    required String backend,
  }) async {
    if (await channel.invokeMethod<bool>(method, arguments) != true) {
      throw StateError('$backend secure storage did not confirm $method');
    }
  }

  static Future<void> _mutateOhos(
    String method, [
    Map<String, String>? arguments,
  ]) async {
    if (await _ohos.invokeMethod<bool>(method, arguments) != true) {
      throw StateError('OHOS secure storage did not confirm $method');
    }
  }
}

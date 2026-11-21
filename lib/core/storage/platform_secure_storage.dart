import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:onepanel_client/core/platform/platform_capabilities.dart';

import 'browser_vault.dart';

enum _Backend { browser, native, ohos }

class PlatformSecureStorage {
  const PlatformSecureStorage._(this._backend);

  final _Backend _backend;
  static const _native = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    lOptions: LinuxOptions(),
  );
  static const _ohos = MethodChannel('onepanel/secure_storage');

  static Future<PlatformSecureStorage> create() async {
    final platform = PlatformCapabilities.current();
    if (platform.isWeb) {
      await BrowserVault.instance.initialize();
      if (!BrowserVault.instance.isUnlocked) {
        throw StateError('浏览器加密存储尚未解锁');
      }
      return const PlatformSecureStorage._(_Backend.browser);
    }
    if (platform.isOhos) return const PlatformSecureStorage._(_Backend.ohos);
    return const PlatformSecureStorage._(_Backend.native);
  }

  Future<String?> read({required String key}) => switch (_backend) {
        _Backend.browser => BrowserVault.instance.read(key),
        _Backend.native => _native.read(key: key),
        _Backend.ohos => _ohos.invokeMethod<String>('read', {'key': key}),
      };

  Future<void> write({required String key, required String? value}) {
    if (value == null) return delete(key: key);
    return switch (_backend) {
      _Backend.browser => BrowserVault.instance.write(key, value),
      _Backend.native => _native.write(key: key, value: value),
      _Backend.ohos => _mutateOhos('write', {'key': key, 'value': value}),
    };
  }

  Future<void> delete({required String key}) => switch (_backend) {
        _Backend.browser => BrowserVault.instance.delete(key),
        _Backend.native => _native.delete(key: key),
        _Backend.ohos => _mutateOhos('delete', {'key': key}),
      };

  Future<void> deleteAll() => switch (_backend) {
        _Backend.browser => BrowserVault.instance.deleteAll(),
        _Backend.native => _native.deleteAll(),
        _Backend.ohos => _mutateOhos('deleteAll'),
      };

  static Future<void> _mutateOhos(
    String method, [
    Map<String, String>? arguments,
  ]) async {
    if (await _ohos.invokeMethod<bool>(method, arguments) != true) {
      throw StateError('OHOS 安全存储未确认操作成功 ($method)');
    }
  }
}

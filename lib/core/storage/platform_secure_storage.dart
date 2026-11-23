import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:onepanel_client/core/platform/platform_capabilities.dart';
import 'package:path_provider/path_provider.dart';

import 'browser_vault.dart';
import 'local_credential_vault.dart';

enum _Backend { browser, native, ohos, macFile }

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
  static const _ohos = MethodChannel('onepanel/secure_storage');

  /// macOS 用应用目录下的凭据文件：钥匙串读取会要求系统密码，
  /// 数据保护钥匙串还要求与签名匹配的访问组，本机自用得不偿失。
  static LocalCredentialVault? _macVault;

  static LocalCredentialVault get _macCredentials =>
      _macVault ??= LocalCredentialVault(getApplicationSupportDirectory);

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
      return const PlatformSecureStorage._(_Backend.macFile);
    }
    return const PlatformSecureStorage._(_Backend.native);
  }

  Future<String?> read({required String key}) => switch (_backend) {
        _Backend.browser => BrowserVault.instance.read(key),
        _Backend.native => _native.read(key: key),
        _Backend.macFile => _macCredentials.read(key),
        _Backend.ohos => _ohos.invokeMethod<String>('read', {'key': key}),
      };

  Future<void> write({required String key, required String? value}) {
    if (value == null) return delete(key: key);
    return switch (_backend) {
      _Backend.browser => BrowserVault.instance.write(key, value),
      _Backend.native => _native.write(key: key, value: value),
      _Backend.macFile => _macCredentials.write(key, value),
      _Backend.ohos => _mutateOhos('write', {'key': key, 'value': value}),
    };
  }

  Future<void> delete({required String key}) => switch (_backend) {
        _Backend.browser => BrowserVault.instance.delete(key),
        _Backend.native => _native.delete(key: key),
        _Backend.macFile => _macCredentials.delete(key),
        _Backend.ohos => _mutateOhos('delete', {'key': key}),
      };

  Future<void> deleteAll() => switch (_backend) {
        _Backend.browser => BrowserVault.instance.deleteAll(),
        _Backend.native => _native.deleteAll(),
        _Backend.macFile => _macCredentials.deleteAll(),
        _Backend.ohos => _mutateOhos('deleteAll'),
      };

  static Future<void> _mutateOhos(
    String method, [
    Map<String, String>? arguments,
  ]) async {
    if (await _ohos.invokeMethod<bool>(method, arguments) != true) {
      throw StateError('OHOS secure storage did not confirm $method');
    }
  }
}
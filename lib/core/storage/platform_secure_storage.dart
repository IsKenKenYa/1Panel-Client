import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../platform/platform_capabilities.dart';
import 'browser_vault.dart';
import 'local_credential_vault.dart';

enum _Backend { browser, native, file }

/// 浏览器、系统安全存储与应用私有凭据文件的统一入口。
class PlatformSecureStorage {
  const PlatformSecureStorage._(this._backend, [this._vault]);

  final _Backend _backend;
  final LocalCredentialVault? _vault;

  static const _native = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      accountName: 'kenpanel',
    ),
    lOptions: LinuxOptions(),
  );
  static final _vaults = <String, LocalCredentialVault>{};

  static String credentialFileName(String namespace) => namespace.isEmpty
      ? 'panel_credentials.json'
      : 'panel_credentials.${Uri.encodeComponent(namespace)}.json';

  static Future<PlatformSecureStorage> create({String namespace = ''}) async {
    final platform = PlatformCapabilities.current();
    if (platform.isWeb) {
      if (namespace.isNotEmpty) {
        throw UnsupportedError('浏览器凭据存储不支持文件命名空间');
      }
      await BrowserVault.instance.initialize();
      if (!BrowserVault.instance.isUnlocked) {
        throw StateError('浏览器凭据存储尚未解锁');
      }
      return const PlatformSecureStorage._(_Backend.browser);
    }
    if (namespace.isEmpty &&
        !platform.isOhos &&
        platform.targetPlatform != TargetPlatform.macOS) {
      return const PlatformSecureStorage._(_Backend.native);
    }
    return _fileStorage(await getApplicationSupportDirectory(), namespace);
  }

  /// 在指定目录使用真实文件，供存储回归测试调用。
  @visibleForTesting
  static PlatformSecureStorage forTesting({
    required Directory directory,
    String namespace = '',
  }) =>
      _fileStorage(directory, namespace);

  static PlatformSecureStorage _fileStorage(
    Directory directory,
    String namespace,
  ) {
    final fileName = credentialFileName(namespace);
    final filePath = path.normalize(path.join(directory.absolute.path, fileName));
    final vault = _vaults.putIfAbsent(
      filePath,
      () => LocalCredentialVault(
        () async => Directory(path.dirname(filePath)),
        fileName: fileName,
      ),
    );
    return PlatformSecureStorage._(_Backend.file, vault);
  }

  Future<String?> read({required String key}) => switch (_backend) {
        _Backend.browser => BrowserVault.instance.read(key),
        _Backend.native => _native.read(key: key),
        _Backend.file => _vault!.read(key),
      };

  Future<void> write({required String key, required String? value}) {
    if (value == null) return delete(key: key);
    return switch (_backend) {
      _Backend.browser => BrowserVault.instance.write(key, value),
      _Backend.native => _native.write(key: key, value: value),
      _Backend.file => _vault!.write(key, value),
    };
  }

  Future<void> delete({required String key}) => switch (_backend) {
        _Backend.browser => BrowserVault.instance.delete(key),
        _Backend.native => _native.delete(key: key),
        _Backend.file => _vault!.delete(key),
      };

  Future<void> deleteAll() => switch (_backend) {
        _Backend.browser => BrowserVault.instance.deleteAll(),
        _Backend.native => _native.deleteAll(),
        _Backend.file => _vault!.deleteAll(),
      };
}

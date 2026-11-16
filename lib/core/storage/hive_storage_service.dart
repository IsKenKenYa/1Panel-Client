import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/logger/logger_service.dart';
import 'storage_service.dart';
import 'platform_secure_storage.dart';

/// 基于Hive的存储服务实现
///
/// 支持AES-256加密，自动管理密钥
class HiveStorageService implements StorageService {
  final String boxName;
  final bool isEncrypted;

  late Box _box;
  PlatformSecureStorage? _secureStorage;

  HiveStorageService({
    required this.boxName,
    this.isEncrypted = false,
  });

  @override
  Future<void> init() async {
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box(boxName);
      return;
    }

    await Hive.initFlutter();

    if (kIsWeb && isEncrypted) {
      final storage = await PlatformSecureStorage.create();
      final storedKey = await storage.read(key: '${boxName}_key');
      final key = storedKey == null
          ? Hive.generateSecureKey()
          : base64Url.decode(storedKey);
      if (storedKey == null) {
        await storage.write(key: '${boxName}_key', value: base64Url.encode(key));
      }
      _box = await Hive.openBox(boxName, encryptionCipher: HiveAesCipher(key));
      return;
    }

    List<int>? encryptionKey;

    if (isEncrypted) {
      _secureStorage = await PlatformSecureStorage.create();
      try {
        // 尝试获取现有密钥
        String? keyStr = await _secureStorage!.read(key: '${boxName}_key');

        if (keyStr == null) {
          // 生成新密钥
          final key = Hive.generateSecureKey();
          await _secureStorage!
              .write(key: '${boxName}_key', value: base64Url.encode(key));
          encryptionKey = key;
        } else {
          encryptionKey = base64Url.decode(keyStr);
        }
      } catch (e, s) {
        // Degrade to unencrypted Hive rather than crash -- the app remains
        // usable and data is not lost, just less protected at rest.
        appLogger.wWithPackage(
          'core.storage.hive_storage',
          'Secure storage unavailable, degraded to non-encrypted Hive',
          error: e,
          stackTrace: s,
        );
        encryptionKey = null;
      }
    }

    try {
      if (isEncrypted && encryptionKey != null) {
        _box = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(encryptionKey),
        );
      } else {
        _box = await Hive.openBox(boxName);
      }
    } catch (e) {
      appLogger.eWithPackage(
        'core.storage.hive_storage',
        'Error opening box $boxName',
        error: e,
      );
      // Encryption key rotation or data corruption makes the box unreadable;
      // wipe and recreate so the app remains usable.
      await Hive.deleteBoxFromDisk(boxName);
      if (isEncrypted && encryptionKey != null) {
        _box = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(encryptionKey),
        );
      } else {
        _box = await Hive.openBox(boxName);
      }
    }
  }

  @override
  T? get<T>(String key, {T? defaultValue}) {
    return _box.get(key, defaultValue: defaultValue);
  }

  @override
  Future<void> put<T>(String key, T value) async {
    await _box.put(key, value);
  }

  @override
  Future<void> putAll(Map<String, dynamic> entries) async {
    await _box.putAll(entries);
  }

  @override
  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    await _box.deleteAll(keys);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  @override
  Stream<dynamic> watch(String key) {
    return _box.watch(key: key).map((event) => event.value);
  }

  @override
  List<dynamic> get keys => _box.keys.toList();

  @override
  List<dynamic> get values => _box.values.toList();

  @override
  bool containsKey(String key) {
    return _box.containsKey(key);
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:synchronized/synchronized.dart';

import 'platform_secure_storage.dart';
import 'storage_service.dart';

/// 基于Hive的存储服务实现
///
/// 支持AES-256加密，自动管理密钥
class HiveStorageService implements StorageService {
  final String boxName;
  final bool isEncrypted;

  late Box _box;
  static final _openLock = Lock();
  static final _openKeys = Expando<String>();

  HiveStorageService({
    required this.boxName,
    this.isEncrypted = false,
  });

  @override
  Future<void> init() => _openLock.synchronized(() async {
        await Hive.initFlutter();
        final key = isEncrypted ? await _encryptionKey() : null;
        if (Hive.isBoxOpen(boxName)) {
          // Hive 复用已打开的 box 时会忽略传入的加密参数。
          final box = Hive.box(boxName);
          if (_openKeys[box] != key) {
            throw StateError('已打开的 Hive 数据库 $boxName 使用了不同的加密设置');
          }
          _box = box;
          return;
        }
        _box = await Hive.openBox(
          boxName,
          encryptionCipher:
              key == null ? null : HiveAesCipher(base64Url.decode(key)),
          // Hive 默认会截去校验失败的记录，密钥错误时须保留原文件。
          crashRecovery: !isEncrypted,
        );
        _openKeys[_box] = key;
      });

  Future<String> _encryptionKey() async {
    final storage = await PlatformSecureStorage.create();
    final keyName = '${boxName}_key';
    final stored = await storage.read(key: keyName);
    if (stored != null) return stored;
    if (Hive.isBoxOpen(boxName) || await Hive.boxExists(boxName)) {
      throw StateError('已有 Hive 数据库 $boxName 缺少加密密钥');
    }
    final key = base64Url.encode(Hive.generateSecureKey());
    await storage.write(key: keyName, value: key);
    return key;
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

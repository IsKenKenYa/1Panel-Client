import 'dart:convert';
import 'dart:io';

import 'package:synchronized/synchronized.dart';

/// 桌面端的凭据文件存储。
///
/// 取舍：macOS 钥匙串在读取条目时会要求输入系统密码，数据保护钥匙串还要
/// 求与签名匹配的访问组，对本机自用与开发构建得不偿失。这里把凭据写进
/// 应用支持目录下的单个 JSON 文件，随应用数据保存与迁移，读写都不触发
/// 系统授权；文件权限依赖用户目录本身，不做额外加固。
class LocalCredentialVault {
  LocalCredentialVault(this._resolveDirectory, {String fileName = 'panel_credentials.json'})
      : _fileName = fileName;

  final Future<Directory> Function() _resolveDirectory;
  final String _fileName;
  final _lock = Lock();
  Map<String, String>? _cache;

  Future<File> _file() async {
    final directory = await _resolveDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<String?> read(String key) async {
    final entries = await _entries();
    return entries[key];
  }

  Future<void> write(String key, String value) async {
    await _lock.synchronized(() async {
      final entries = await _entriesLocked();
      entries[key] = value;
      await _persist(entries);
    });
  }

  Future<void> delete(String key) async {
    await _lock.synchronized(() async {
      final entries = await _entriesLocked();
      if (entries.remove(key) == null) return;
      await _persist(entries);
    });
  }

  Future<void> deleteAll() async {
    await _lock.synchronized(() async {
      _cache = <String, String>{};
      final file = await _file();
      if (await file.exists()) await file.delete();
    });
  }

  Future<Map<String, String>> _entries() =>
      _lock.synchronized(_entriesLocked);

  /// 文件内容无法解析时抛出，避免把损坏文件当成空表静默覆盖。
  Future<Map<String, String>> _entriesLocked() async {
    final cached = _cache;
    if (cached != null) return cached;
    final file = await _file();
    if (!await file.exists()) {
      return _cache = <String, String>{};
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      throw const FormatException('Credential file is not a JSON object');
    }
    return _cache = <String, String>{
      for (final entry in decoded.entries)
        if (entry.value is String) '${entry.key}': entry.value as String,
    };
  }

  /// 先写临时文件再改名，避免写入中断留下半截内容。
  Future<void> _persist(Map<String, String> entries) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(entries), flush: true);
    await temp.rename(file.path);
  }
}
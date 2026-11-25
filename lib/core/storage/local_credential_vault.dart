import 'dart:convert';
import 'dart:io';

import 'package:synchronized/synchronized.dart';

import '../platform/platform_capabilities.dart';
import '../services/logger/logger_service.dart';

/// 原生端应用私有目录中的凭据文件存储。
///
/// 内容以 JSON 持久保存；macOS 与 Linux 文件权限限定为仅所有者可读写。
class LocalCredentialVault {
  LocalCredentialVault(
    this._resolveDirectory, {
    String fileName = 'panel_credentials.json',
  }) : _fileName = fileName;

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
      final entries = Map<String, String>.of(await _entriesLocked());
      entries[key] = value;
      await _persist(entries);
      _cache = entries;
    });
  }

  Future<void> delete(String key) async {
    await _lock.synchronized(() async {
      final entries = Map<String, String>.of(await _entriesLocked());
      if (entries.remove(key) == null) return;
      await _persist(entries);
      _cache = entries;
    });
  }

  Future<void> deleteAll() async {
    await _lock.synchronized(() async {
      final file = await _file();
      final type = await FileSystemEntity.type(file.path, followLinks: false);
      if (type != FileSystemEntityType.notFound) await file.delete();
      _cache = <String, String>{};
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
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Credential file is not a JSON object');
    }
    if (decoded.values.any((value) => value is! String)) {
      throw const FormatException('Credential file contains a non-string value');
    }
    return _cache = Map<String, String>.from(decoded);
  }

  /// 通过同目录临时文件与改名持久保存，桌面端同时设置文件权限。
  Future<void> _persist(Map<String, String> entries) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(entries), flush: true);
    await _restrictPermissions(temp);
    await temp.rename(file.path);
  }

  Future<void> _restrictPermissions(File file) async {
    if (PlatformCapabilities.current().isOhos ||
        (!Platform.isMacOS && !Platform.isLinux)) {
      return;
    }
    try {
      final result = await Process.run('chmod', ['600', file.path]);
      if (result.exitCode != 0) {
        appLogger.w(
          'chmod 600 failed for credential file: ${result.stderr}',
        );
      }
    } on ProcessException catch (error) {
      appLogger.w('chmod unavailable for credential file: $error');
    }
  }
}

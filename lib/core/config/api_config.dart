import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/storage/platform_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

class ApiConfig {
  static const onePanelType = '1panel';

  ApiConfig({
    required this.id,
    required this.name,
    required this.url,
    required this.apiKey,
    this.revision = '',
    this.credentialId = '',
    this.panelType = onePanelType,
    Map<String, String> additionalCredentials = const {},
    this.tokenValidity = 0,
    this.allowInsecureTls = false,
    this.isDefault = false,
    DateTime? lastUsed,
  })  : additionalCredentials = Map.unmodifiable(additionalCredentials),
        lastUsed = lastUsed ?? DateTime.now();

  final String id;
  final String name;
  final String url;
  final String panelType;
  final String apiKey;
  final String revision;
  final String credentialId;
  final Map<String, String> additionalCredentials;
  final int tokenValidity;
  final bool allowInsecureTls;
  final bool isDefault;
  final DateTime lastUsed;

  bool sameConnectionAs(ApiConfig other) =>
      id == other.id &&
      panelType == other.panelType &&
      url == other.url &&
      apiKey == other.apiKey &&
      tokenValidity == other.tokenValidity &&
      allowInsecureTls == other.allowInsecureTls &&
      mapEquals(additionalCredentials, other.additionalCredentials);

  void requireOnePanel() {
    if (panelType != onePanelType) throw UnsupportedError('This operation requires a 1Panel connection');
  }

  /// 可存入普通设置或发送给界面的服务器信息。
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'panelType': panelType,
        'revision': revision,
        'credentialId': credentialId,
        'tokenValidity': tokenValidity,
        'allowInsecureTls': allowInsecureTls,
        'isDefault': isDefault,
        'lastUsed': lastUsed.toIso8601String(),
      };

  factory ApiConfig.fromJson(
    Map<String, dynamic> json, {
    String apiKey = '',
    Map<String, String> additionalCredentials = const {},
  }) =>
      ApiConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        url: json['url'] as String,
        panelType: json['panelType'] as String? ?? onePanelType,
        revision: json['revision'] as String? ?? '',
        credentialId: json['credentialId'] as String? ?? '',
        apiKey: apiKey,
        additionalCredentials: additionalCredentials,
        tokenValidity: json['tokenValidity'] as int? ?? 0,
        allowInsecureTls: json['allowInsecureTls'] as bool? ?? false,
        isDefault: json['isDefault'] as bool? ?? false,
        lastUsed: json['lastUsed'] == null
            ? DateTime.now()
            : DateTime.parse(json['lastUsed'] as String),
      );
}

/// 服务器目录读取结果。
typedef ServerDirectory = ({List<ApiConfig> servers, String? selectedId});

/// 该连接缺少凭据，界面提示用户重新录入。
class MissingCredentialException implements Exception {
  const MissingCredentialException();

  @override
  String toString() => 'Saved credential for this connection is missing. Open the server and enter the API key again.';
}

abstract final class ApiConfigManager {
  /// 存储键按「连接」语义命名，不绑定具体面板品牌；新增面板类型时继续复用。
  ///
  /// 测试可通过 [useStorageNamespace] 把目录键与凭据文件切到独立命名空间，
  /// 让测试配置与用户真实配置互不可见。
  static const _serversKey = 'panel_server_directory';
  static const _credentialKeyPrefix = 'panel_credentials_';
  static final _lock = Lock();
  static PlatformSecureStorage? _storage;
  /// 当前存储命名空间前缀；为空表示用户真实存储。
  static String _namespace = '';

  /// 切换到独立存储命名空间。
  ///
  /// 全部读写（目录键与凭据文件）都绑定该命名空间；传入空字符串恢复用户
  /// 命名空间。已缓存的凭据实例会重建。
  static void useStorageNamespace(String namespace) {
    _namespace = namespace;
    _storage = null;
  }

  static String _ns(String key) => '$_namespace$key';

  static Future<PlatformSecureStorage> _vault() async =>
      _storage ??= await PlatformSecureStorage.create(namespace: _namespace);

  static Future<SharedPreferences> _preferences() =>
      SharedPreferences.getInstance();

  // 每次保存使用独立的凭据条目，且绑定服务器、面板类型与面板地址。
  static String _secretKey(ApiConfig config) =>
      _ns('$_credentialKeyPrefix${_secretHash(config)}');

  static String _secretHash(ApiConfig config) {
    final identity = jsonEncode(
      [config.id, config.panelType, config.url, config.credentialId],
    );
    return sha256.convert(utf8.encode(identity)).toString();
  }

  /// 读取服务器目录，解析错误交由调用方处理。
  static ServerDirectory _read(SharedPreferences prefs) {
    final raw = prefs.getString(_ns(_serversKey));
    if (raw == null) return (servers: <ApiConfig>[], selectedId: null);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return (
      servers: (data['servers'] as List)
          .map((item) => ApiConfig.fromJson(item as Map<String, dynamic>))
          .toList(),
      selectedId: data['selectedId'] as String?,
    );
  }

  static Future<ServerDirectory> getServerDirectory() =>
      _lock.synchronized(() async {
        return _read(await _preferences());
      });

  static Future<List<ApiConfig>> getServerMetadata() async =>
      (await getServerDirectory()).servers;

  static Future<ApiConfig> _withCredentials(ApiConfig config) async {
    final vault = await _vault();
    final raw = await vault.read(key: _secretKey(config));
    if (raw == null) throw const MissingCredentialException();
    final secrets = jsonDecode(raw) as Map<String, dynamic>;
    return ApiConfig.fromJson(
      config.toJson(),
      apiKey: secrets['apiKey'] as String,
      additionalCredentials: Map<String, String>.from(secrets['fields'] as Map),
    );
  }

  static Future<ApiConfig> getConfig(String id) => _lock.synchronized(() async {
        final entries = _read(await _preferences()).servers;
        return _withCredentials(entries.firstWhere((c) => c.id == id));
      });

  static Future<void> _writeDirectory(
    SharedPreferences prefs,
    ServerDirectory directory,
  ) async {
    final value = jsonEncode({
      'servers': directory.servers,
      'selectedId': directory.selectedId,
    });
    if (!await prefs.setString(_ns(_serversKey), value)) {
      throw StateError('Unable to save the server directory');
    }
  }

  static Future<void> _replaceConfig({
    required SharedPreferences prefs,
    required ServerDirectory after,
    required ApiConfig? previous,
    required ApiConfig? next,
  }) async {
    final vault = await _vault();
    if (next != null) {
      await vault.write(
        key: _secretKey(next),
        value: jsonEncode({
          'apiKey': next.apiKey,
          'fields': next.additionalCredentials,
        }),
      );
    }
    await _writeDirectory(prefs, after);
    if (previous != null &&
        (next == null || _secretKey(previous) != _secretKey(next))) {
      await vault.delete(key: _secretKey(previous));
    }
  }

  static Future<void> saveConfig(ApiConfig config) => _saveConfig(config);

  static Future<void> updateConfig(ApiConfig config, {required ApiConfig expected}) {
    if (config.id != expected.id || config.panelType != expected.panelType) {
      throw ArgumentError('Editing must keep the server id and panel type');
    }
    return _saveConfig(config, expected: expected);
  }

  static Future<void> _saveConfig(ApiConfig config, {ApiConfig? expected}) =>
      _lock.synchronized(() async {
        final prefs = await _preferences();
        final state = _read(prefs);
        final entries = {for (final c in state.servers) c.id: c};
        final previous = entries[config.id];
        if (expected != null) {
          if (previous == null) throw StateError('This server has been deleted');
          if (expected.revision.isEmpty ||
              previous.revision != expected.revision) {
            throw StateError('Server configuration changed; reopen the editor');
          }
        }
        if (config.isDefault) {
          for (final c in state.servers.where((c) => c.isDefault && c.id != config.id)) {
            entries[c.id] = ApiConfig.fromJson({
              ...c.toJson(),
              'isDefault': false,
              'revision': const Uuid().v4(),
            });
          }
        }
        final revision = const Uuid().v4();
        final next = ApiConfig.fromJson(
          {...config.toJson(), 'revision': revision, 'credentialId': revision},
          apiKey: config.apiKey,
          additionalCredentials: config.additionalCredentials,
        );
        entries[config.id] = next;
        await _replaceConfig(
          prefs: prefs,
          after: (servers: entries.values.toList(), selectedId: state.selectedId ?? config.id),
          previous: previous,
          next: next,
        );
      });

  static Future<void> deleteConfig(String id) => _lock.synchronized(() async {
        final prefs = await _preferences();
        final state = _read(prefs);
        final entries = state.servers;
        final target = entries.where((c) => c.id == id).firstOrNull;
        if (target == null) return;
        final remaining = entries.where((c) => c.id != id).toList();
        final next = state.selectedId == id
            ? (remaining.where((c) => c.isDefault).firstOrNull ?? remaining.firstOrNull)?.id
            : state.selectedId;
        await _replaceConfig(
          prefs: prefs,
          after: (servers: remaining, selectedId: next),
          previous: target,
          next: null,
        );
      });

  static Future<ApiConfig?> getCurrentServerMetadata() async {
    final state = await getServerDirectory();
    if (state.selectedId == null) return null;
    return state.servers.firstWhere((c) => c.id == state.selectedId);
  }

  /// 清空当前命名空间下的服务器目录与其引用的凭据条目。
  static Future<void> clearServerDirectory() => _lock.synchronized(() async {
        final prefs = await _preferences();
        final state = _read(prefs);
        final vault = await _vault();
        for (final config in state.servers) {
          await vault.delete(key: _secretKey(config));
        }
        await prefs.remove(_ns(_serversKey));
      });

  static Future<ApiConfig?> getCurrentConfig() => _lock.synchronized(() async {
        final state = _read(await _preferences());
        if (state.selectedId == null) return null;
        return _withCredentials(state.servers.firstWhere((c) => c.id == state.selectedId));
      });

  static Future<ServerDirectory> setCurrentConfig(String id) => _lock.synchronized(() async {
        final prefs = await _preferences();
        final state = _read(prefs);
        if (!state.servers.any((c) => c.id == id)) {
          throw StateError('Server not found');
        }
        if (state.selectedId == id) return state;
        final directory = (servers: state.servers, selectedId: id);
        await _writeDirectory(prefs, directory);
        return directory;
      });
}

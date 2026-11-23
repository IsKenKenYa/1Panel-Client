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
        // 旧版本存档没有面板类型与凭据版本字段，一律视为 1Panel 连接。
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

class ConfigStorageException implements Exception {
  const ConfigStorageException(
    this.changeCommitted,
    this.cause, [
    this.recoveryErrors = const [],
  ]);

  /// null 表示平台未能确认哪份目录已持久保存。
  final bool? changeCommitted;
  final Object cause;
  final List<Object> recoveryErrors;

  @override
  String toString() {
    final status = switch (changeCommitted) {
      true => 'directory updated; reopen the server list',
      false => 'previous directory kept; you can retry',
      null => 'saved directory could not be confirmed; reload the list',
    };
    final errors = [cause, ...recoveryErrors].map((e) => e.runtimeType).join(', ');
    return 'Server storage error ($errors). $status';
  }
}

typedef ServerDirectory = ({List<ApiConfig> servers, String? selectedId});

/// 安全存储里没有该连接的凭据。界面据此提示重新录入，而不是显示堆栈类型。
class MissingCredentialException implements Exception {
  const MissingCredentialException();

  @override
  String toString() => 'Saved credential for this connection is missing. Open the server and enter the API key again.';
}

/// 安全存储里有条目但内容无法解析，通常来自旧版本的不同结构。
class CredentialUnreadableException implements Exception {
  const CredentialUnreadableException();

  @override
  String toString() => 'Saved credential for this connection cannot be read. Open the server and enter the API key again.';
}

abstract final class ApiConfigManager {
  /// 存储键按「连接」语义命名，不绑定具体面板品牌；新增面板类型时继续复用。
  static const _serversKey = 'panel_server_directory';
  static const _credentialKeyPrefix = 'panel_credentials_';
  // 更早的品牌命名键与旧数组格式键；仅用于升级迁移。
  static const _brandConfigsKey = 'kenpanel_servers';
  static const _brandCredentialPrefix = 'kenpanel_credentials_';
  static const _legacyConfigsKey = 'api_configs';
  static const _legacySelectedIdKey = 'current_api_config_id';
  static const _legacyCredentialPrefix = 'api_config_api_key_';
  // 早期桌面调试写在偏好设置里的明文回退键前缀。
  static const _plaintextFallbackPrefix = 'secure_api_key_fallback_';
  static final _lock = Lock();
  static PlatformSecureStorage? _storage;
  static bool _requiresReload = false;

  static Future<PlatformSecureStorage> _vault() async =>
      _storage ??= await PlatformSecureStorage.create();

  static Future<SharedPreferences> _preferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_requiresReload) {
      await prefs.reload();
      _requiresReload = false;
    }
    return prefs;
  }

  // 每次保存使用独立的凭据条目，且绑定服务器、面板类型与面板地址。
  static String _secretKey(ApiConfig config) =>
      '$_credentialKeyPrefix${_secretHash(config)}';

  /// 品牌命名时期的凭据键，仅用于首次读取时的迁移。
  static String _brandSecretKey(ApiConfig config) =>
      '$_brandCredentialPrefix${_secretHash(config)}';

  static String _secretHash(ApiConfig config) {
    final identity = jsonEncode(
      [config.id, config.panelType, config.url, config.credentialId],
    );
    return sha256.convert(utf8.encode(identity)).toString();
  }

  /// 读取服务器目录。优先新键，其次品牌命名键，最后旧数组格式。
  static ServerDirectory _read(SharedPreferences prefs) {
    final raw = prefs.getString(_serversKey) ?? prefs.getString(_brandConfigsKey);
    if (raw == null) return _readLegacy(prefs);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return (
      servers: [
        for (final item in data['servers'] as List)
          ApiConfig.fromJson(item as Map<String, dynamic>),
      ],
      selectedId: data['selectedId'] as String?,
    );
  }

  /// 旧版本把服务器列表存成数组并使用独立的凭据键。
  /// 这里按原样读出，凭据在首次读取详情时迁移到新键。
  static ServerDirectory _readLegacy(SharedPreferences prefs) {
    final legacy = prefs.getString(_legacyConfigsKey);
    if (legacy == null) return (servers: <ApiConfig>[], selectedId: null);
    final decoded = jsonDecode(legacy);
    if (decoded is! List) return (servers: <ApiConfig>[], selectedId: null);
    return (
      servers: [
        for (final item in decoded)
          if (item is Map<String, dynamic>) ApiConfig.fromJson(item),
      ],
      selectedId: prefs.getString(_legacySelectedIdKey),
    );
  }

  static Future<ServerDirectory> getServerDirectory() =>
      _lock.synchronized(() async {
        final prefs = await _preferences();
        final directory = _read(prefs);
        // 命中旧键时补写新键并移除旧键；写入失败不阻断读取，下次再迁移。
        if (prefs.getString(_serversKey) != null) return directory;
        if (prefs.getString(_brandConfigsKey) == null &&
            prefs.getString(_legacyConfigsKey) == null) {
          return directory;
        }
        final value = jsonEncode({
          'servers': directory.servers,
          'selectedId': directory.selectedId,
        });
        if (await prefs.setString(_serversKey, value)) {
          await prefs.remove(_brandConfigsKey);
          await prefs.remove(_legacyConfigsKey);
          await prefs.remove(_legacySelectedIdKey);
        }
        return directory;
      });

  static Future<List<ApiConfig>> getServerMetadata() async =>
      (await getServerDirectory()).servers;

  static Future<ApiConfig> _withCredentials(ApiConfig config) async {
    final vault = await _vault();
    final raw = await vault.read(key: _secretKey(config));
    if (raw != null) {
      final secrets = decodeStoredCredential(raw);
      if (secrets != null) {
        return ApiConfig.fromJson(
          config.toJson(),
          apiKey: secrets.apiKey,
          additionalCredentials: secrets.fields,
        );
      }
    }
    // 新键缺失或无法识别时，依次尝试品牌命名键与明文旧键。
    final migrated = await _tryMigrateLegacy(config, vault);
    if (migrated != null) return migrated;
    if (raw == null) throw const MissingCredentialException();
    throw const CredentialUnreadableException();
  }

  /// 迁移历史凭据：品牌命名键、明文旧键与偏好设置里的明文回退键。
  /// 成功搬移到新键后才清理来源键。
  static Future<ApiConfig?> _tryMigrateLegacy(
    ApiConfig config,
    PlatformSecureStorage vault,
  ) async {
    final brandKey = _brandSecretKey(config);
    final brandValue = await vault.read(key: brandKey);
    if (brandValue != null) {
      final secrets = decodeStoredCredential(brandValue);
      if (secrets != null) {
        await _writeCredential(config, secrets.apiKey, secrets.fields, vault);
        await vault.delete(key: brandKey);
        return ApiConfig.fromJson(
          config.toJson(),
          apiKey: secrets.apiKey,
          additionalCredentials: secrets.fields,
        );
      }
    }
    final legacyKey = '$_legacyCredentialPrefix${config.id}';
    final legacy = await vault.read(key: legacyKey);
    if (legacy != null && legacy.isNotEmpty) {
      final migrated = ApiConfig.fromJson(config.toJson(), apiKey: legacy);
      // 与正常保存使用同一结构，避免后续读取走不同的解析分支。
      await _writeCredential(
        migrated,
        legacy,
        migrated.additionalCredentials,
        vault,
      );
      await vault.delete(key: legacyKey);
      return migrated;
    }
    return _migratePrefsFallback(config, vault);
  }

  /// 早期桌面调试把密钥写进了偏好设置的明文回退键。
  /// 读入后立即搬进安全存储并删除明文，避免继续留存在偏好设置。
  static Future<ApiConfig?> _migratePrefsFallback(
    ApiConfig config,
    PlatformSecureStorage vault,
  ) async {
    final prefs = await _preferences();
    final fallbackKey = '$_plaintextFallbackPrefix$_legacyCredentialPrefix${config.id}';
    final plaintext = prefs.getString(fallbackKey);
    if (plaintext == null || plaintext.isEmpty) return null;
    final migrated = ApiConfig.fromJson(config.toJson(), apiKey: plaintext);
    await _writeCredential(
      migrated,
      plaintext,
      migrated.additionalCredentials,
      vault,
    );
    await prefs.remove(fallbackKey);
    return migrated;
  }

  static Future<void> _writeCredential(
    ApiConfig config,
    String apiKey,
    Map<String, String> fields,
    PlatformSecureStorage vault,
  ) =>
      vault.write(
        key: _secretKey(config),
        value: jsonEncode({'apiKey': apiKey, 'fields': fields}),
      );

  static Future<ApiConfig> getConfig(String id) => _lock.synchronized(() async {
        final entries = _read(await _preferences()).servers;
        return _withCredentials(entries.firstWhere((c) => c.id == id));
      });

  static Future<ConfigStorageException?> _writeDirectory(
    SharedPreferences prefs,
    ServerDirectory directory,
  ) async {
    final before = prefs.getString(_serversKey);
    final value = jsonEncode({'servers': directory.servers, 'selectedId': directory.selectedId});
    try {
      if (!await prefs.setString(_serversKey, value)) {
        throw StateError('Unable to save the server directory');
      }
      return null;
    } catch (error) {
      // SharedPreferences 在平台答复之前更新缓存。重新读取才能判断目录指向哪个凭据。
      try {
        await prefs.reload();
        final stored = prefs.getString(_serversKey);
        bool? committed;
        if (stored == value) {
          committed = true;
        } else if (stored == before) {
          committed = false;
        }
        return ConfigStorageException(committed, error);
      } catch (readError) {
        _requiresReload = true;
        return ConfigStorageException(null, error, [readError]);
      }
    }
  }

  static Future<Never> _discardStaged(
    PlatformSecureStorage vault,
    String? stagedKey,
    Object cause, [
    List<Object> recoveryErrors = const [],
  ]) async {
    if (stagedKey != null) {
      try {
        if (await vault.read(key: stagedKey) != null) await vault.delete(key: stagedKey);
      } catch (error) {
        throw ConfigStorageException(false, cause, [...recoveryErrors, error]);
      }
    }
    throw ConfigStorageException(false, cause, recoveryErrors);
  }

  static Future<void> _replaceConfig({
    required SharedPreferences prefs,
    required ServerDirectory before,
    required ServerDirectory after,
    required ApiConfig? previous,
    required ApiConfig? next,
  }) async {
    final vault = await _vault();
    final retiredKey = previous == null ? null : _secretKey(previous);
    final retiredValue = retiredKey == null ? null : await vault.read(key: retiredKey);
    final stagedKey = next == null ? null : _secretKey(next);
    if (next != null && stagedKey != null) {
      try {
        await vault.write(key: stagedKey, value: jsonEncode({
          'apiKey': next.apiKey,
          'fields': next.additionalCredentials,
        }));
      } catch (error) {
        await _discardStaged(vault, stagedKey, error);
      }
    }

    final commitError = await _writeDirectory(prefs, after);
    if (commitError != null) {
      if (commitError.changeCommitted == false) {
        await _discardStaged(vault, stagedKey, commitError.cause, commitError.recoveryErrors);
      }
      // 保留可能被持久目录引用的凭据。
      throw commitError;
    }

    if (retiredKey == null || retiredValue == null) return;
    try {
      await vault.delete(key: retiredKey);
    } catch (deleteError) {
      // 恢复期间也应始终能读取当前目录引用的凭据。
      try {
        if (await vault.read(key: retiredKey) != retiredValue) {
          await vault.write(key: retiredKey, value: retiredValue);
        }
      } catch (restoreError) {
        throw ConfigStorageException(true, deleteError, [restoreError]);
      }
      final revertError = await _writeDirectory(prefs, before);
      if (revertError != null && revertError.changeCommitted != true) {
        final committed = revertError.changeCommitted == false ? true : null;
        throw ConfigStorageException(committed, deleteError, [revertError]);
      }
      await _discardStaged(vault, stagedKey, deleteError, [if (revertError != null) revertError]);
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
              previous.revision != expected.revision ||
              !(await _withCredentials(previous)).sameConnectionAs(expected)) {
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
          before: state,
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
          before: state,
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
        final error = await _writeDirectory(prefs, directory);
        if (error != null) throw error;
        return directory;
      });
}

/// 解析存储中的凭据条目。
///
/// 早期迁移只写入了 `apiKey`，正常保存写入 `apiKey` 与 `fields`，
/// 两种结构都必须能读出来；内容无法识别时返回 null。
({String apiKey, Map<String, String> fields})? decodeStoredCredential(
  String raw,
) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) return null;
  final apiKey = decoded['apiKey'];
  if (apiKey is! String) return null;
  final rawFields = decoded['fields'];
  return (
    apiKey: apiKey,
    fields: rawFields is Map
        ? Map<String, String>.from(rawFields)
        : const <String, String>{},
  );
}

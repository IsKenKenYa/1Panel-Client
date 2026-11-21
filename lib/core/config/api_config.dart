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
    if (panelType != onePanelType) throw UnsupportedError('此操作需要 1Panel 连接');
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
        panelType: json['panelType'] as String,
        revision: json['revision'] as String,
        credentialId: json['credentialId'] as String,
        apiKey: apiKey,
        additionalCredentials: additionalCredentials,
        tokenValidity: json['tokenValidity'] as int,
        allowInsecureTls: json['allowInsecureTls'] as bool,
        isDefault: json['isDefault'] as bool,
        lastUsed: DateTime.parse(json['lastUsed'] as String),
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
      true => '目录已变更，请重新打开服务器配置',
      false => '目录保留原配置，可重新尝试',
      null => '暂时无法确认已保存的目录，请重新读取配置',
    };
    final errors = [cause, ...recoveryErrors].map((e) => e.runtimeType).join(', ');
    return '服务器存储操作出错（$errors）。$status';
  }
}

typedef ServerDirectory = ({List<ApiConfig> servers, String? selectedId});

abstract final class ApiConfigManager {
  static const _serversKey = 'kenpanel_servers';
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

  // 每次保存使用独立的凭据条目，且绑定服务器与面板地址。
  static String _secretKey(ApiConfig config) {
    final identity = jsonEncode([config.id, config.panelType, config.url, config.credentialId]);
    return 'kenpanel_credentials_${sha256.convert(utf8.encode(identity))}';
  }

  static ServerDirectory _read(SharedPreferences prefs) {
    final raw = prefs.getString(_serversKey);
    if (raw == null) return (servers: <ApiConfig>[], selectedId: null);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return (
      servers: [
        for (final item in data['servers'] as List)
          ApiConfig.fromJson(item as Map<String, dynamic>),
      ],
      selectedId: data['selectedId'] as String?,
    );
  }

  static Future<ServerDirectory> getServerDirectory() =>
      _lock.synchronized(() async => _read(await _preferences()));

  static Future<List<ApiConfig>> getServerMetadata() async =>
      (await getServerDirectory()).servers;

  static Future<ApiConfig> _withCredentials(ApiConfig config) async {
    final raw = await (await _vault()).read(key: _secretKey(config));
    if (raw == null) throw StateError('无法读取已保存的面板凭据');
    try {
      final secrets = jsonDecode(raw) as Map<String, dynamic>;
      return ApiConfig.fromJson(
        config.toJson(),
        apiKey: secrets['apiKey'] as String,
        additionalCredentials: Map<String, String>.from(secrets['fields'] as Map),
      );
    } catch (error) {
      if (error is! FormatException && error is! TypeError) rethrow;
      // JSON 解码异常可能包含凭据原文。
      throw const FormatException('已保存的面板凭据格式无效');
    }
  }

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
        throw StateError('无法保存服务器列表');
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
      throw ArgumentError('编辑时必须保留服务器标识和面板类型');
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
          if (previous == null) throw StateError('该服务器已删除');
          if (expected.revision.isEmpty ||
              previous.revision != expected.revision ||
              !(await _withCredentials(previous)).sameConnectionAs(expected)) {
            throw StateError('服务器配置已更改，请重新打开编辑页面');
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
          throw StateError('找不到指定的服务器');
        }
        if (state.selectedId == id) return state;
        final directory = (servers: state.servers, selectedId: id);
        final error = await _writeDirectory(prefs, directory);
        if (error != null) throw error;
        return directory;
      });
}

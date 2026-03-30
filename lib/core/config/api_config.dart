import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _apiConfigManagerPackage = 'core.config.api_config';

abstract class ApiKeyStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureApiKeyStore implements ApiKeyStore {
  SecureApiKeyStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const Duration _operationTimeout = Duration(milliseconds: 200);

  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = <String, String>{};

  @override
  Future<String?> read(String key) async {
    try {
      final value = await _storage
          .read(key: key)
          .timeout(_operationTimeout, onTimeout: () => null);
      return value ?? _memoryFallback[key];
    } on TimeoutException catch (e, stackTrace) {
      appLogger.wWithPackage(
        _apiConfigManagerPackage,
        'secure storage read timeout, using in-memory fallback',
        error: e,
        stackTrace: stackTrace,
      );
      return _memoryFallback[key];
    } catch (e, stackTrace) {
      appLogger.wWithPackage(
        _apiConfigManagerPackage,
        'secure storage read failed, using in-memory fallback',
        error: e,
        stackTrace: stackTrace,
      );
      return _memoryFallback[key];
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value).timeout(_operationTimeout);
      _memoryFallback.remove(key);
    } on TimeoutException catch (e, stackTrace) {
      appLogger.wWithPackage(
        _apiConfigManagerPackage,
        'secure storage write timeout, using in-memory fallback',
        error: e,
        stackTrace: stackTrace,
      );
      _memoryFallback[key] = value;
    } catch (e, stackTrace) {
      appLogger.wWithPackage(
        _apiConfigManagerPackage,
        'secure storage write failed, using in-memory fallback',
        error: e,
        stackTrace: stackTrace,
      );
      _memoryFallback[key] = value;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key).timeout(_operationTimeout);
    } on TimeoutException catch (e, stackTrace) {
      appLogger.wWithPackage(
        _apiConfigManagerPackage,
        'secure storage delete timeout, clearing in-memory fallback',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      appLogger.wWithPackage(
        _apiConfigManagerPackage,
        'secure storage delete failed, clearing in-memory fallback',
        error: e,
        stackTrace: stackTrace,
      );
    }
    _memoryFallback.remove(key);
  }
}

class ApiConfig {
  final String id;
  final String name;
  final String url;
  final String apiKey;
  final int tokenValidity;
  final bool allowInsecureTls;
  final bool isDefault;
  final DateTime lastUsed;

  ApiConfig({
    required this.id,
    required this.name,
    required this.url,
    required this.apiKey,
    this.tokenValidity = 0,
    this.allowInsecureTls = false,
    this.isDefault = false,
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'apiKey': apiKey,
      'tokenValidity': tokenValidity,
      'allowInsecureTls': allowInsecureTls,
      'isDefault': isDefault,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      apiKey: json['apiKey'],
      tokenValidity: json['tokenValidity'] as int? ?? 0,
      allowInsecureTls: json['allowInsecureTls'] as bool? ?? false,
      isDefault: json['isDefault'] ?? false,
      lastUsed: json['lastUsed'] == null
          ? DateTime.now()
          : DateTime.parse(json['lastUsed'] as String),
    );
  }
}

class ApiConfigManager {
  static const _configsKey = 'api_configs';
  static const _currentConfigIdKey = 'current_api_config_id';
  static const _apiKeyPrefix = 'api_config_api_key_';

  static ApiKeyStore _apiKeyStore = SecureApiKeyStore();

  static String _apiKeyStorageKey(String serverId) => '$_apiKeyPrefix$serverId';

  @visibleForTesting
  static void setApiKeyStoreForTest(ApiKeyStore store) {
    _apiKeyStore = store;
  }

  @visibleForTesting
  static void resetApiKeyStoreForTest() {
    _apiKeyStore = SecureApiKeyStore();
  }

  static Map<String, dynamic> _toPersistedJson(ApiConfig config) {
    final json = config.toJson();
    json.remove('apiKey');
    return json;
  }

  static Future<void> _persistConfigs(
    SharedPreferences prefs,
    List<ApiConfig> configs,
  ) async {
    await prefs.setString(
      _configsKey,
      jsonEncode(configs.map(_toPersistedJson).toList(growable: false)),
    );
  }

  static Future<List<ApiConfig>> getConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getString(_configsKey);

    if (configsJson == null) {
      return [];
    }

    final decoded = jsonDecode(configsJson);
    if (decoded is! List) {
      return [];
    }

    final configs = <ApiConfig>[];
    var shouldPersist = false;

    for (final entry in decoded) {
      if (entry is! Map) {
        continue;
      }

      final map = Map<String, dynamic>.from(entry);
      final serverId = map['id']?.toString();
      if (serverId == null || serverId.isEmpty) {
        continue;
      }

      final legacyApiKey = map['apiKey']?.toString();
      String? apiKey;
      if (legacyApiKey != null && legacyApiKey.isNotEmpty) {
        await _apiKeyStore.write(_apiKeyStorageKey(serverId), legacyApiKey);
        map.remove('apiKey');
        apiKey = legacyApiKey;
        shouldPersist = true;
      } else {
        apiKey = await _apiKeyStore.read(_apiKeyStorageKey(serverId));
      }

      final normalizedJson = <String, dynamic>{
        ...map,
        'id': serverId,
        'apiKey': apiKey ?? '',
      };
      configs.add(ApiConfig.fromJson(normalizedJson));
    }

    if (shouldPersist) {
      await _persistConfigs(prefs, configs);
    }

    return configs;
  }

  static Future<void> saveConfig(ApiConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final configs = await getConfigs();

    // 检查是否已存在相同ID的配置
    final index = configs.indexWhere((c) => c.id == config.id);
    if (index >= 0) {
      configs[index] = config;
    } else {
      configs.add(config);
    }

    // 如果设置为默认配置，需要将其他配置设为非默认
    if (config.isDefault) {
      for (var i = 0; i < configs.length; i++) {
        final c = configs[i];
        if (c.id != config.id) {
          configs[i] = ApiConfig(
            id: c.id,
            name: c.name,
            url: c.url,
            apiKey: c.apiKey,
            tokenValidity: c.tokenValidity,
            allowInsecureTls: c.allowInsecureTls,
            isDefault: false,
            lastUsed: c.lastUsed,
          );
        }
      }
    }

    await _apiKeyStore.write(_apiKeyStorageKey(config.id), config.apiKey);

    await _persistConfigs(prefs, configs);
  }

  static Future<void> deleteConfig(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final configs = await getConfigs();

    configs.removeWhere((c) => c.id == id);

    await _persistConfigs(prefs, configs);
    await _apiKeyStore.delete(_apiKeyStorageKey(id));

    // 如果删除的是当前选中的配置，清除当前配置ID
    final currentConfigId = prefs.getString(_currentConfigIdKey);
    if (currentConfigId == id) {
      await prefs.remove(_currentConfigIdKey);
    }
  }

  static Future<ApiConfig?> getCurrentConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final currentConfigId = prefs.getString(_currentConfigIdKey);

    if (currentConfigId == null) {
      // 如果没有当前配置，尝试获取默认配置
      final configs = await getConfigs();
      final defaultConfig = configs.where((c) => c.isDefault).toList();

      if (defaultConfig.isNotEmpty) {
        await setCurrentConfig(defaultConfig.first.id);
        return defaultConfig.first;
      }

      // 如果没有默认配置，返回第一个配置
      if (configs.isNotEmpty) {
        await setCurrentConfig(configs.first.id);
        return configs.first;
      }

      return null;
    }

    final configs = await getConfigs();
    if (configs.isEmpty) {
      return null;
    }
    return configs.firstWhere((c) => c.id == currentConfigId,
        orElse: () => configs.first);
  }

  static Future<void> setCurrentConfig(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentConfigIdKey, id);
  }

  static Future<ApiConfig?> getDefaultConfig() async {
    final configs = await getConfigs();
    final defaultConfigs = configs.where((c) => c.isDefault).toList();
    return defaultConfigs.isNotEmpty ? defaultConfigs.first : null;
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  final String id;
  final String name;
  final String url;
  final String apiKey;
  final int tokenValidity;
  final bool isDefault;
  final DateTime lastUsed;

  ApiConfig({
    required this.id,
    required this.name,
    required this.url,
    required this.apiKey,
    this.tokenValidity = 0,
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
      isDefault: json['isDefault'] ?? false,
      lastUsed: DateTime.parse(json['lastUsed']),
    );
  }
}

class ApiConfigManager {
  static const _configsKey = 'api_configs';
  static const _currentConfigIdKey = 'current_api_config_id';

  static Future<List<ApiConfig>> getConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getString(_configsKey);

    if (configsJson == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(configsJson);
    return decoded.map((json) => ApiConfig.fromJson(json)).toList();
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
      for (var c in configs) {
        if (c.id != config.id) {
          c = ApiConfig(
            id: c.id,
            name: c.name,
            url: c.url,
            apiKey: c.apiKey,
            isDefault: false,
            lastUsed: c.lastUsed,
          );
        }
      }
    }

    await prefs.setString(
        _configsKey, jsonEncode(configs.map((c) => c.toJson()).toList()));
  }

  static Future<void> deleteConfig(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final configs = await getConfigs();

    configs.removeWhere((c) => c.id == id);

    await prefs.setString(
        _configsKey, jsonEncode(configs.map((c) => c.toJson()).toList()));

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

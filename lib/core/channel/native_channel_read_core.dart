import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/api_config.dart';
import '../services/app_preferences_service.dart';
import '../services/logger/logger_service.dart';
import '../../features/server/server_repository.dart';
import 'native_server_config.dart';

/// 读通道连接与设置域：服务器列表、当前连接、界面渲染模式、语言与文案。
class NativeChannelCoreHandlers {
  static Future<dynamic> getServers(dynamic arguments) async {
    final repository = ServerRepository();
    // 原生轨道的服务器列表直接展示 CPU 与内存，必须带指标返回。
    final servers = await repository.loadServerCards(withMetrics: true);
    return servers
        .map((s) => {
              ...describeNativeServer(s.config, isCurrent: s.isCurrent),
              'cpu': s.metrics.cpuPercent,
              'memory': s.metrics.memoryPercent,
              'reachable': s.metrics.isReachable,
              'latencyMs': s.metrics.latencyMs,
            })
        .toList();
  }

  static Future<Map<String, Object?>?> getCurrentServer() async {
    final config = await ApiConfigManager.getCurrentServerMetadata();
    return config == null ? null : describeNativeServer(config, isCurrent: true);
  }

  static Future<String> getUIRenderMode() async {
    final prefs = AppPreferencesService();
    final mode = await prefs.loadUIRenderMode(refresh: true);
    return mode.name;
  }

  static Future<dynamic> getSettings(dynamic arguments) async {
    final prefs = AppPreferencesService();
    final mode = await prefs.loadUIRenderMode(refresh: true);
    final locale = await prefs.loadLocale();
    return {
      'renderMode': mode.name,
      'language': locale?.languageCode ?? 'system',
    };
  }

  static Future<dynamic> getTranslations() async {
    final prefs = AppPreferencesService();
    var locale = await prefs.loadLocale(refresh: true);
    if (locale == null) {
      final sysLocale = Platform.localeName;
      if (sysLocale.startsWith('zh')) {
        locale = const Locale('zh');
      } else {
        locale = const Locale('en');
      }
    }
    String arbPath = 'lib/l10n/app_en.arb';
    if (locale.languageCode == 'zh') {
      arbPath = 'lib/l10n/app_zh.arb';
    }
    appLogger.d('translations served for locale ${locale.languageCode}');
    try {
      final jsonString = await rootBundle.loadString(arbPath);
      final Map<String, dynamic> translations = jsonDecode(jsonString);
      translations.removeWhere((key, value) => key.startsWith('@'));
      return translations;
    } catch (e) {
      appLogger.e('Failed to load translations: $e');
      return {};
    }
  }
}
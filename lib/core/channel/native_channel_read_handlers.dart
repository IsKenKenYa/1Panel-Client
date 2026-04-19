import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/ai/ai_repository.dart';
import '../../features/apps/app_service.dart';
import '../../features/backups/services/backup_record_service.dart';
import '../../features/containers/container_service.dart';
import '../../features/cronjobs/services/cronjob_service.dart';
import '../../features/dashboard/services/dashboard_service.dart';
import '../../features/databases/databases_service.dart';
import '../../features/files/services/file_browser_service.dart';
import '../../features/firewall/firewall_service.dart';
import '../../features/monitoring/monitoring_service.dart';
import '../../features/server/server_repository.dart';
import '../../features/websites/services/websites_service.dart';
import '../../data/models/cronjob_list_models.dart';
import '../../data/models/database_models.dart';
import '../services/app_preferences_service.dart';
import '../services/logger/logger_service.dart';
import '../theme/ui_render_mode.dart';

/// 所有 Native Channel 读操作 handlers 的集中实现。
/// 被 [NativeChannelManager] 的 dispatch switch 调用。
class NativeChannelReadHandlers {
  static String _serializeRenderMode(UIRenderMode mode) {
    return mode == UIRenderMode.native ? 'native' : 'md3';
  }

  // ── 原有 handlers ────────────────────────────────────────────────────────

  static Future<dynamic> getServers(dynamic arguments) async {
    final repository = ServerRepository();
    final servers = await repository.loadServerCards();
    return servers
        .map((s) => {
              'id': s.config.id,
              'name': s.config.name,
              'url': s.config.url,
              'isCurrent': s.isCurrent,
              'cpu': s.metrics.cpuPercent,
              'memory': s.metrics.memoryPercent,
            })
        .toList();
  }

  static Future<dynamic> getFiles(dynamic arguments) async {
    final service = FileBrowserService();
    final path = arguments?['path'] as String? ?? '/';
    final files = await service.getFiles(path: path);
    return files
        .map((f) => {
              'name': f.name,
              'path': f.path,
              'isDir': f.isDir,
              'size': f.size,
              'modTime': f.modifiedAt?.millisecondsSinceEpoch ?? 0,
            })
        .toList();
  }

  static Future<dynamic> getApps(dynamic arguments) async {
    final service = AppService();
    final apps = await service.getInstalledApps();
    return apps
        .map((a) => {
              'name': a.name,
              'status': a.status,
              'version': a.version,
              'appId': a.appId,
            })
        .toList();
  }

  static Future<dynamic> getWebsites(dynamic arguments) async {
    final service = WebsitesService();
    final websites = await service.fetchWebsites();
    return websites
        .map((w) => {
              'id': w.id,
              'primaryDomain': w.primaryDomain,
              'status': w.status,
              'remark': w.remark,
              'createdAt': w.createdAt,
            })
        .toList();
  }

  static Future<dynamic> getMonitoring(dynamic arguments) async {
    final service = MonitoringService();
    final metrics = await service.getCurrentMetrics();
    return {
      'cpu': metrics.cpuPercent,
      'memory': metrics.memoryPercent,
      'disk': metrics.diskPercent,
      'load1': metrics.load1,
      'load5': metrics.load5,
      'load15': metrics.load15,
    };
  }

  static Future<dynamic> getContainers(dynamic arguments) async {
    try {
      final service = ContainerService();
      final containers = await service.listContainers();
      return containers
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'image': c.image,
                'status': c.status,
                'state': c.state,
                'createTime': c.createTime,
                'cpuUsage': c.cpuUsage,
                'memoryUsage': c.memoryUsage,
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get containers for native: $e');
      return [];
    }
  }

  static Future<String> getUIRenderMode() async {
    final prefs = AppPreferencesService();
    final mode = await prefs.loadUIRenderMode();
    return _serializeRenderMode(mode);
  }

  static Future<dynamic> getSettings(dynamic arguments) async {
    final prefs = AppPreferencesService();
    final mode = await prefs.loadUIRenderMode();
    final locale = await prefs.loadLocale();
    return {
      'renderMode': _serializeRenderMode(mode),
      'language': locale?.languageCode ?? 'system',
      'version': '0.5.0-alpha.1',
    };
  }

  static Future<dynamic> getTranslations() async {
    final prefs = AppPreferencesService();
    var locale = await prefs.loadLocale();
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

  // ── 新增 handlers ────────────────────────────────────────────────────────

  /// 仪表盘：返回 CPU/内存/磁盘/运行时长/系统信息。
  static Future<dynamic> getDashboard(dynamic arguments) async {
    try {
      final service = DashboardService();
      final data = await service.loadDashboardData();
      final m = data.metrics;
      final s = data.systemInfo;
      return {
        'cpu': data.cpuPercent ?? m?.cpuPercent ?? 0.0,
        'memory': data.memoryPercent ?? m?.memoryPercent ?? 0.0,
        'disk': data.diskPercent ?? m?.diskPercent ?? 0.0,
        'memoryUsage': data.memoryUsage,
        'diskUsage': data.diskUsage,
        'uptime': data.uptime,
        'hostname': s?.hostname ?? m?.hostname ?? '',
        'os': s?.os ?? m?.os ?? '',
        'kernelVersion': s?.kernelVersion ?? m?.kernelVersion ?? '',
        'cpuCores': s?.cpuCores ?? m?.cpuCores ?? 0,
        'load1': m?.cpuPercent ?? 0.0,
        'panelVersion': s?.panelVersion ?? '',
      };
    } catch (e) {
      if (e.toString().contains('No API config available')) {
        appLogger.i('Native dashboard polling skipped: No active server configured.');
      } else {
        appLogger.e('Failed to get dashboard for native: $e');
      }
      return <String, dynamic>{};
    }
  }

  /// 数据库：遍历所有 scope，合并返回数据库列表。
  static Future<dynamic> getDatabases(dynamic arguments) async {
    final service = DatabasesService();
    final result = <Map<String, dynamic>>[];
    for (final scope in DatabaseScope.values) {
      try {
        final page = await service.loadPage(scope: scope, pageSize: 100);
        for (final item in page.items) {
          result.add({
            'id': item.id,
            'name': item.name,
            'type': scope.value,
            'version': item.version ?? '',
            'status': item.status ?? '',
            'username': item.username ?? '',
            'description': item.description ?? '',
          });
        }
      } catch (e) {
        if (e.toString().contains('No API config available')) {
          appLogger.i('getDatabases scope=$scope skipped: No active server configured.');
        } else {
          appLogger.w('getDatabases scope=$scope failed: $e');
        }
      }
    }
    return result;
  }

  /// 防火墙：返回端口规则列表。
  static Future<dynamic> getFirewallRules(dynamic arguments) async {
    try {
      final service = FirewallService();
      final page = await service.searchRules(page: 1, pageSize: 200);
      return page.items
          .map((r) => {
                'id': r.id ?? 0,
                'protocol': r.protocol ?? '',
                'port': r.port ?? '',
                'address': r.address ?? '',
                'strategy': r.strategy ?? '',
                'description': r.description ?? '',
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get firewall rules for native: $e');
      return [];
    }
  }

  /// 定时任务：返回任务列表（含下次执行时间预览）。
  static Future<dynamic> getCronJobs(dynamic arguments) async {
    try {
      final service = CronjobService();
      final page = await service.searchCronjobs(
        const CronjobListQuery(page: 1, pageSize: 100),
      );
      return page.items
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'type': c.type,
                'status': c.status,
                'spec': c.spec,
                'lastRecordStatus': c.lastRecordStatus,
                'lastRecordTime': c.lastRecordTime,
                'nextHandle': c.nextHandlePreview ?? '',
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get cronjobs for native: $e');
      return [];
    }
  }

  /// 备份：返回备份记录列表。
  static Future<dynamic> getBackups(dynamic arguments) async {
    try {
      final service = BackupRecordService();
      final records = await service.loadRecords();
      return records
          .map((item) => {
                'id': item.record.id ?? 0,
                'name': item.record.name,
                'type': item.record.type,
                'size': item.size ?? item.record.size,
                'status': item.record.status,
                'createdAt': item.record.createdAt ?? '',
                'backupTime': item.record.backupTime ?? '',
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get backups for native: $e');
      return [];
    }
  }

  /// AI 模型：返回 Ollama 模型列表。
  static Future<dynamic> getAIModels(dynamic arguments) async {
    try {
      final repository = AIRepository();
      final page = await repository.searchOllamaModels(page: 1, pageSize: 100);
      return page.items
          .map((m) => {
                'id': m.id,
                'name': m.name ?? '',
                'size': m.size ?? '',
                'modified': m.modified ?? '',
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get AI models for native: $e');
      return [];
    }
  }
}

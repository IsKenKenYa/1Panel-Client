import 'package:flutter/services.dart';
import '../../features/server/server_repository.dart';
import '../../features/files/services/file_browser_service.dart';
import '../../features/apps/app_service.dart';
import '../../features/websites/services/websites_service.dart';
import '../../features/monitoring/monitoring_service.dart';
import '../services/app_preferences_service.dart';
import '../theme/ui_render_mode.dart';

class NativeChannelManager {
  static const MethodChannel _methodChannel =
      MethodChannel('com.onepanel.client/method');

  static void init() {
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'getServers':
        return await _getServers(call.arguments);
      case 'getFiles':
        return await _getFiles(call.arguments);
      case 'getApps':
        return await _getApps(call.arguments);
      case 'getWebsites':
        return await _getWebsites(call.arguments);
      case 'getMonitoring':
        return await _getMonitoring(call.arguments);
      case 'getUIRenderMode':
        return await _getUIRenderMode();
      default:
        throw MissingPluginException();
    }
  }

  static Future<String> _getUIRenderMode() async {
    final prefs = AppPreferencesService();
    final mode = await prefs.loadUIRenderMode();
    return mode == UIRenderMode.native ? 'native' : 'md3';
  }

  static Future<dynamic> _getServers(dynamic arguments) async {
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

  static Future<dynamic> _getFiles(dynamic arguments) async {
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

  static Future<dynamic> _getApps(dynamic arguments) async {
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

  static Future<dynamic> _getWebsites(dynamic arguments) async {
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

  static Future<dynamic> _getMonitoring(dynamic arguments) async {
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
}

import '../config/api_config.dart';
import '../config/api_constants.dart';
import '../network/api_client_manager.dart';
import '../../api/v2/api_response_parser.dart';
import '../../data/models/database_models.dart';
import '../../data/repositories/database_repository.dart';
import '../../features/dashboard/services/dashboard_service.dart';
import '../../features/databases/databases_service.dart';
import '../../features/files/services/file_browser_service.dart';
import '../../features/monitoring/monitoring_service.dart';
import '../../features/toolbox/services/toolbox_device_service.dart';
import '../services/logger/logger_service.dart';

/// 读通道数据浏览域：文件浏览与收藏、仪表盘概览、数据库、监控指标、
/// 设备快照。
class NativeChannelDataReadHandlers {
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

  /// 文件内容。参数：`{path: String 必填}`。
  /// POST /files/content `{path, expand: true}`，返回服务端原始 data 对象
  /// （含 `content` 键），C# 端取 content 字段。
  static Future<dynamic> getFileContentHandler(dynamic arguments) async {
    try {
      final path = arguments?['path'] as String? ?? '';
      if (path.isEmpty) {
        return <String, dynamic>{};
      }
      final client = await ApiClientManager.instance.getCurrentClient();
      final response = await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/files/content'),
        data: <String, dynamic>{'path': path, 'expand': true},
      );
      return ApiResponseParser.asMap(response.data);
    } catch (e) {
      appLogger.e('Failed to get file content for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 收藏列表。参数：`{page?: int, pageSize?: int}`（C# 传 `{}` 取默认值）。
  /// POST /files/favorite/search（dto.PageInfo），items 列表原样透传。
  static Future<dynamic> getFavoritesHandler(dynamic arguments) async {
    try {
      final client = await ApiClientManager.instance.getCurrentClient();
      final response = await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/files/favorite/search'),
        data: <String, dynamic>{
          'page': int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
          'pageSize': int.tryParse('${arguments?['pageSize'] ?? 100}') ?? 100,
        },
      );
      return ApiResponseParser.asList(response.data, nestedItemsKey: 'items');
    } catch (e) {
      appLogger.e('Failed to get favorites for native: $e');
      return [];
    }
  }

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
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) return <Map<String, dynamic>>[];
    final service = DatabasesService(
      repository: DatabaseRepository(config: config),
    );
    final result = <Map<String, dynamic>>[];
    for (final scope in DatabaseScope.values) {
      try {
        final page = await service.loadPage(scope: scope, pageSize: 100);
        for (final item in page.items) {
          result.add({
            'id': item.id,
            'name': item.name,
            'lookupName': item.lookupName,
            'source': item.source,
            'type': scope.value,
            'engine': item.engine,
            'serverId': config.id,
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

  /// 工具箱设备快照（B15）。
  static Future<dynamic> getDeviceSnapshot(dynamic arguments) async {
    try {
      final snapshot = await ToolboxDeviceService().loadSnapshot();
      final base = snapshot.baseInfo;
      return {
        'dns': base.dns ?? '',
        'hostname': base.hostname ?? '',
        'localTime': base.localTime ?? '',
        'ntp': base.ntp ?? '',
        'productName': base.productName ?? '',
        'productVersion': base.productVersion ?? '',
        'systemName': base.systemName ?? '',
        'systemVersion': base.systemVersion ?? '',
        'timeZone': base.timeZone ?? '',
        'swapMemoryTotal': base.swapMemoryTotal ?? 0,
        'users': snapshot.users,
      };
    } catch (e) {
      if (e.toString().contains('No API config available')) {
        appLogger.i('getDeviceSnapshot skipped: No active server configured.');
      } else {
        appLogger.e('Failed to get device snapshot for native: $e');
      }
      return <String, dynamic>{};
    }
  }
}
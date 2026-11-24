import '../../features/ai/model_downloader_service.dart';
import 'native_model_downloader_payloads.dart';
import '../../features/host_assets/services/host_asset_service.dart';
import '../../data/models/host_asset_models.dart';
import '../../features/monitoring/monitoring_service.dart';
import 'native_monitoring_payloads.dart';
import '../../features/runtimes/services/runtime_service.dart';
import '../../features/toolbox/services/toolbox_disk_service.dart';
import '../services/logger/logger_service.dart';

/// 读通道运行态域：模型下载器、监控中心、运维模块入口数据。
class NativeChannelModelMonitorReadHandlers {
  // ── 模型下载器 ──────────────────────────────────────────────────────────

  /// 推荐模型。参数：`{family?, page?, pageSize?}`。POST /xpack/model/downloader/featured/search。
  static Future<dynamic> getModelDownloaderFeatured(dynamic arguments) async {
    final family = (arguments?['family'] as String? ?? '').trim();
    final page = int.tryParse('${arguments?['page'] ?? 1}') ?? 1;
    final pageSize = int.tryParse('${arguments?['pageSize'] ?? 50}') ?? 50;
    final result = await ModelDownloaderService().searchFeatured(
      page: page,
      pageSize: pageSize,
      family: family.isEmpty ? null : family,
    );
    return <String, dynamic>{
      'items':
          result.items.map(modelDownloaderFeaturedPayload).toList(growable: false),
      'total': result.total,
      'families': result.families,
    };
  }

  /// 市场搜索。参数：`{source: hf|modelScope, query?, sort?, page?, pageSize?}`。
  static Future<dynamic> getModelDownloaderSearch(dynamic arguments) async {
    final source = (arguments?['source'] as String? ?? 'hf').trim();
    final query = (arguments?['query'] as String? ?? '').trim();
    final sort = (arguments?['sort'] as String? ?? 'trending').trim();
    final page = int.tryParse('${arguments?['page'] ?? 1}') ?? 1;
    final pageSize = int.tryParse('${arguments?['pageSize'] ?? 50}') ?? 50;
    final service = ModelDownloaderService();
    final result = source == 'hf'
        ? await service.searchHuggingFace(
            page: page,
            pageSize: pageSize,
            query: query.isEmpty ? null : query,
            sort: sort.isEmpty ? null : sort,
          )
        : await service.searchModelScope(
            page: page,
            pageSize: pageSize,
            query: query.isEmpty ? null : query,
            sort: sort.isEmpty ? null : sort,
          );
    return <String, dynamic>{
      'items':
          result.items.map(modelDownloaderMarketPayload).toList(growable: false),
      'total': result.total,
    };
  }

  /// 下载任务。参数：`{status?}`。
  static Future<dynamic> getModelDownloaderTasks(dynamic arguments) async {
    final status = (arguments?['status'] as String? ?? '').trim();
    final result = await ModelDownloaderService().searchTasks(
      page: 1,
      pageSize: 100,
      status: status.isEmpty ? null : status,
      includeLocal: true,
    );
    return <String, dynamic>{
      'items':
          result.items.map(modelDownloaderTaskPayload).toList(growable: false),
      'total': result.total,
    };
  }

  /// 本地模型。参数：`{info?}`。
  static Future<dynamic> getModelDownloaderLocal(dynamic arguments) async {
    final info = (arguments?['info'] as String? ?? '').trim();
    final result = await ModelDownloaderService().searchLocal(
      page: 1,
      pageSize: 100,
      info: info.isEmpty ? null : info,
    );
    return <String, dynamic>{
      'items':
          result.items.map(modelDownloaderLocalPayload).toList(growable: false),
      'total': result.total,
    };
  }

  /// 下载设置。GET /xpack/model/downloader/settings。
  static Future<dynamic> getModelDownloaderSettings(dynamic arguments) async {
    final setting = await ModelDownloaderService().getSettings();
    return modelDownloaderSettingsPayload(setting);
  }

  /// 下载器固定选项：来源、排序、下载内容与任务状态。
  static Future<dynamic> getModelDownloaderOptions(dynamic arguments) async {
    return modelDownloaderOptionsPayload();
  }

  // ── 监控中心 ────────────────────────────────────────────────────────────

  /// 监控历史曲线。参数：`{hours?: int}`，默认 1 小时，上限 168 小时。
  static Future<dynamic> getMonitoringHistory(dynamic arguments) async {
    final requested = int.tryParse('${arguments?['hours'] ?? 1}') ?? 1;
    final hours = requested.clamp(1, 168);
    final package = await MonitoringService().getMonitorData(
      duration: Duration(hours: hours),
    );
    return monitoringHistoryPayload(package);
  }

  /// 监控设置。GET /hosts/monitor/setting。
  static Future<dynamic> getMonitoringSettings(dynamic arguments) async {
    final setting = await MonitoringService().getSetting();
    return monitoringSettingsPayload(setting);
  }

  /// 监控可用网卡与磁盘设备。用于设置的默认网卡与默认磁盘。
  static Future<dynamic> getMonitoringOptions(dynamic arguments) async {
    final service = MonitoringService();
    var networks = const <String>[];
    var ios = const <String>[];
    try {
      networks = await service.getNetworkOptions();
    } catch (e) {
      appLogger.w('getMonitoringOptions networks failed: $e');
    }
    try {
      ios = await service.getIOOptions();
    } catch (e) {
      appLogger.w('getMonitoringOptions io failed: $e');
    }
    return monitoringOptionsPayload(networks: networks, ios: ios);
  }

  // ── 运维模块入口数据 ────────────────────────────────────────────────────

  /// 运行环境列表：按 PHP、Node、Java、Go、Python、.NET 依次汇总。
  static Future<dynamic> getRuntimes(dynamic arguments) async {
    final service = RuntimeService();
    final pages = await Future.wait(
      RuntimeService.orderedTypes.map(
        (type) => service.searchRuntimes(type: type),
      ),
    );
    return pages
        .expand((page) => page.items)
        .map((runtime) => <String, Object?>{
              'id': runtime.id ?? 0,
              'name': runtime.name ?? '',
              'type': runtime.type ?? '',
              'version': runtime.version ?? '',
              'status': runtime.status ?? '',
              'port': runtime.port ?? '',
              'image': runtime.image ?? '',
              'containerStatus': runtime.containerStatus ?? '',
              'remark': runtime.remark ?? '',
            })
        .toList(growable: false);
  }

  /// 工具箱磁盘快照：磁盘与未分区磁盘。
  static Future<dynamic> getToolboxDiskSnapshot(dynamic arguments) async {
    final snapshot = await ToolboxDiskService().loadSnapshot();
    return <String, dynamic>{
      'totalDisks': snapshot.totalDisks,
      'totalCapacity': snapshot.totalCapacity,
      'disks': snapshot.disks
          .map((disk) => <String, Object?>{
                'device': disk.device,
                'model': disk.model,
                'size': disk.size,
                'diskType': disk.diskType,
                'mountPoint': disk.mountPoint,
                'usePercent': disk.usePercent,
                'isSystem': disk.isSystem,
                'isMounted': disk.isMounted,
              })
          .toList(growable: false),
      'unpartitioned': snapshot.unpartitionedDisks
          .map((disk) => <String, Object?>{
                'device': disk.device,
                'model': disk.model,
                'size': disk.size,
                'diskType': disk.diskType,
                'isRemovable': disk.isRemovable,
              })
          .toList(growable: false),
    };
  }

  /// 主机资源列表。POST /hosts/search。
  static Future<dynamic> getHostAssets(dynamic arguments) async {
    final page = await HostAssetService().searchHosts(
      const HostSearchRequest(page: 1, pageSize: 100),
    );
    return page.items
        .map((host) => <String, Object?>{
              'id': host.id,
              'name': host.name,
              'addr': host.addr ?? '',
              'port': host.port ?? 0,
              'user': host.user ?? '',
              'group': host.groupBelong ?? '',
              'status': host.status,
              'osType': host.osType ?? '',
              'osArch': host.osArch ?? '',
            })
        .toList(growable: false);
  }
}
import 'dart:async';

import '../config/api_config.dart';
import '../../data/models/ai/agent_account_model_pool_models.dart';
import '../../data/models/ai/agent_account_models.dart';
import '../../data/models/ai/agent_core_models.dart';
import '../../data/models/alert_models.dart';
import '../../data/models/common_models.dart';
import '../../data/models/mcp_models.dart';
import '../../data/models/host_asset_models.dart';
import '../../features/ai/ai_repository.dart';
import '../../features/ai/model_downloader_service.dart';
import 'native_model_downloader_payloads.dart';
import '../../features/alert/alert_service.dart';
import 'native_alert_payloads.dart';
import '../../features/host_assets/services/host_asset_service.dart';
import '../../features/monitoring/monitoring_service.dart';
import 'native_monitoring_payloads.dart';
import '../../features/runtimes/services/runtime_service.dart';
import '../../features/toolbox/services/toolbox_disk_service.dart';
import '../../features/vm/vm_service.dart';
import 'native_vm_payloads.dart';
import '../services/logger/logger_service.dart';

/// 读通道平台域：AI 深度配置、虚拟机、告警中心、模型下载器、监控中心、
/// 运维模块入口数据。
class NativeChannelPlatformReadHandlers {
  // ── AI 管理深度（B3，只读）────────────────────────────────────────────
  // 协议单一事实源：docs/development/modules/b3_ai_channel_contract.md。
  // 读语义：透传解析数据（不做字段裁剪），缺参/失败返回空值并记录日志。

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

  /// GPU/XPU 负载。参数：`{}`。GET /ai/gpu/load。
  static Future<dynamic> getGpuLoad(dynamic arguments) async {
    try {
      final gpus = await AIRepository().loadGpuInfo();
      return gpus.map((g) => g.toJson()).toList();
    } catch (e) {
      appLogger.e('Failed to get gpu load for native: $e');
      return [];
    }
  }

  /// GPU 设备选项。参数：`{}`。GET /ai/gpu/options。
  /// 返回 `{chartHide: [...], chartSelect: [...]}` 原始对象。
  static Future<dynamic> getGpuOptions(dynamic arguments) async {
    try {
      return await AIRepository().getGpuOptions();
    } catch (e) {
      appLogger.e('Failed to get gpu options for native: $e');
      return <String, dynamic>{};
    }
  }

  /// GPU 历史监控。参数：
  /// `{deviceID?: String, productName?: String, startTime: String, endTime: String}`。
  /// POST /ai/gpu/search，返回时间序列对象；缺少设备时服务端报错，这里
  /// 先经 `/ai/gpu/options` 取设备，无 GPU 时直接返回空对象。
  static Future<dynamic> searchGpuHistory(dynamic arguments) async {
    try {
      final startTime = arguments?['startTime'] as String? ?? '';
      final endTime = arguments?['endTime'] as String? ?? '';
      if (startTime.isEmpty || endTime.isEmpty) {
        return <String, dynamic>{};
      }
      final repository = AIRepository();
      var deviceId = arguments?['deviceID'] as String? ?? '';
      var productName = arguments?['productName'] as String? ?? '';
      var legacy = arguments?['legacy'] as bool? ?? false;
      if (deviceId.isEmpty && productName.isEmpty) {
        final device =
            AIRepository.firstGpuDevice(await repository.getGpuOptions());
        if (device == null) return <String, dynamic>{};
        deviceId = device.deviceId;
        productName = device.productName;
        legacy = device.legacy;
      }
      return await repository.searchGpu(<String, dynamic>{
        'deviceID': deviceId,
        'productName': productName,
        'legacy': legacy,
        'startTime': startTime,
        'endTime': endTime,
      });
    } catch (e) {
      appLogger.e('Failed to search gpu history for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 智能体渠道账号分页。参数：`{page: int, pageSize: int, name?: String}`。
  /// POST /ai/accounts/search。
  static Future<dynamic> getAgentAccounts(dynamic arguments) async {
    try {
      final page = (await (await AIRepository().getApi()).pageAgentAccounts(
        AgentAccountSearch(
          page: int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
          pageSize: int.tryParse('${arguments?['pageSize'] ?? 20}') ?? 20,
          name: arguments?['name'] as String? ?? '',
        ),
      ))
          .data!;
      return <String, dynamic>{
        'items': page.items.map((a) => a.toJson()).toList(),
        'total': page.total,
        'page': page.page,
        'pageSize': page.pageSize,
        'totalPages': page.totalPages,
      };
    } catch (e) {
      appLogger.e('Failed to get agent accounts for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 渠道账号可选 provider 列表。参数：无。GET /ai/accounts/providers。
  static Future<dynamic> getAgentProviders(dynamic arguments) async {
    try {
      final providers = (await (await AIRepository().getApi())
                  .getAgentProviders())
              .data ??
          const <ProviderInfo>[];
      return providers
          .map((p) => {
                'provider': p.provider,
                'displayName': p.displayName,
                'baseUrl': p.baseUrl,
                'defaultApiType': p.defaultApiType,
                'apiTypes': p.apiTypes,
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get agent providers for native: $e');
      return [];
    }
  }

  /// 渠道账号可用模型列表。参数：`{accountId: int}`。POST /ai/accounts/models。
  static Future<dynamic> getAgentAccountModels(dynamic arguments) async {
    try {
      final accountId = int.tryParse('${arguments?['accountId'] ?? ''}');
      if (accountId == null) {
        return [];
      }
      final models = (await (await AIRepository().getApi())
              .getAgentAccountModels(AgentAccountModelReq(accountId: accountId)))
          .data!;
      return models.map((m) => m.toJson()).toList();
    } catch (e) {
      appLogger.e('Failed to get agent account models for native: $e');
      return [];
    }
  }

  /// MCP 服务器分页。参数：`{page: int, pageSize: int, name?: String}`。
  /// POST /ai/mcp/search。
  static Future<dynamic> getMcpServers(dynamic arguments) async {
    try {
      return (await (await AIRepository().getApi()).searchMcpServers(
                McpServerSearch(
                  page: int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
                  pageSize:
                      int.tryParse('${arguments?['pageSize'] ?? 20}') ?? 20,
                  name: arguments?['name'] as String? ?? '',
                ),
              ))
                  .data
                  ?.toJson() ??
          <String, dynamic>{};
    } catch (e) {
      appLogger.e('Failed to get mcp servers for native: $e');
      return <String, dynamic>{};
    }
  }

  /// MCP 服务器详情。参数：`{id: int}`。POST /ai/mcp/server/detail。
  static Future<dynamic> getMcpServerDetail(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null) {
        return <String, dynamic>{};
      }
      return await (await AIRepository().getApi())
          .getMcpServerDetail(<String, dynamic>{'id': id})
          .then((r) => r.data ?? <String, dynamic>{});
    } catch (e) {
      appLogger.e('Failed to get mcp server detail for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 智能体实例分页。参数：`{page: int, pageSize: int}`。POST /ai/agents/search。
  static Future<dynamic> pageAgentsNative(dynamic arguments) async {
    try {
      final page = (await (await AIRepository().getApi()).pageAgents(
              SearchWithPage(
                page: int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
                pageSize: int.tryParse('${arguments?['pageSize'] ?? 20}') ?? 20,
              ),
            ))
                .data!;
      return <String, dynamic>{
        'items': page.items.map((a) => a.toJson()).toList(),
        'total': page.total,
        'page': page.page,
        'pageSize': page.pageSize,
        'totalPages': page.totalPages,
      };
    } catch (e) {
      appLogger.e('Failed to page agents for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 智能体总览。参数：`{agentId: int}`。POST /ai/agents/overview。
  static Future<dynamic> getAgentOverviewNative(dynamic arguments) async {
    try {
      final agentId = int.tryParse('${arguments?['agentId'] ?? ''}');
      if (agentId == null) {
        return <String, dynamic>{};
      }
      return (await (await AIRepository().getApi())
                  .getAgentOverview(AgentOverviewReq(agentId: agentId)))
              .data
              ?.toJson() ??
          <String, dynamic>{};
    } catch (e) {
      appLogger.e('Failed to get agent overview for native: $e');
      return <String, dynamic>{};
    }
  }

  /// AI 服务绑定域名。参数：`{appInstallID: int}`。POST /ai/domain/get。
  static Future<dynamic> getAIBindDomain(dynamic arguments) async {
    try {
      final appInstallID = int.tryParse('${arguments?['appInstallID'] ?? ''}');
      if (appInstallID == null) {
        return <String, dynamic>{};
      }
      return (await AIRepository().getBindDomain(appInstallID: appInstallID))
          .toJson();
    } catch (e) {
      appLogger.e('Failed to get AI bind domain for native: $e');
      return <String, dynamic>{};
    }
  }

  // ── 虚拟机 ──────────────────────────────────────────────────────────────

  /// 运行环境探测。GET /vms/environment。
  static Future<dynamic> getVmEnvironment(dynamic arguments) async {
    final environment = await VMService().checkEnvironment();
    return vmEnvironmentPayload(environment);
  }

  /// 实例列表。参数：`{info?: String}`。POST /vms/search。
  static Future<dynamic> getVms(dynamic arguments) async {
    final info = (arguments?['info'] as String? ?? '').trim();
    final result = await VMService().searchVMs(info: info.isEmpty ? null : info);
    return <String, dynamic>{
      'items': result.items.map(vmSummaryPayload).toList(growable: false),
      'total': result.total,
      'limit': result.limit,
    };
  }

  /// 实例详情。参数：`{name: String, checkDisks?: bool}`。POST /vms/info。
  static Future<dynamic> getVmInfo(dynamic arguments) async {
    final name = (arguments?['name'] as String? ?? '').trim();
    if (name.isEmpty) {
      throw ArgumentError('name is required');
    }
    final checkDisks = arguments?['checkDisks'] as bool? ?? false;
    final vm = await VMService().getVMInfo(name, checkDisks: checkDisks);
    return vmDetailPayload(vm);
  }

  /// 实例快照。参数：`{name: String}`。
  ///
  /// 恢复快照要求实例处于关机状态，可用性在这里判定。
  static Future<dynamic> getVmSnapshots(dynamic arguments) async {
    final name = (arguments?['name'] as String? ?? '').trim();
    if (name.isEmpty) {
      throw ArgumentError('name is required');
    }
    final service = VMService();
    final vm = await service.getVMInfo(name);
    final snapshots = await service.listSnapshots(name);
    final canRecover = vm.status.trim().toLowerCase() == 'shut off';
    return <String, dynamic>{
      'canCreate': vmCapabilitiesPayload(vm)['canCreateSnapshot'],
      'canRecover': canRecover,
      'items': snapshots
          .map((snapshot) =>
              vmSnapshotPayload(snapshot, canRecover: canRecover))
          .toList(growable: false),
    };
  }

  /// 实例健康检查。参数：`{name: String}`。POST /vms/health/check。
  static Future<dynamic> getVmHealth(dynamic arguments) async {
    final name = (arguments?['name'] as String? ?? '').trim();
    if (name.isEmpty) {
      throw ArgumentError('name is required');
    }
    final result = await VMService().healthCheck(name);
    return vmHealthPayload(result);
  }

  /// 实时统计采样。参数：`{name: String}`。POST /vms/stats。
  ///
  /// 返回 CPU 与内存百分比、磁盘与网络速率，差值计算在 Dart 侧完成。
  static Future<dynamic> getVmStats(dynamic arguments) async {
    final name = (arguments?['name'] as String? ?? '').trim();
    if (name.isEmpty) {
      throw ArgumentError('name is required');
    }
    final config = await ApiConfigManager.getCurrentServerMetadata();
    final stats = await VMService().getVMStats(name);
    return _vmStatsSampler.sample(
      serverId: config?.id ?? '',
      stats: stats,
    );
  }

  /// ISO 镜像列表。GET /vms/isos。
  static Future<dynamic> getVmIsos(dynamic arguments) async {
    final isos = await VMService().listIso();
    return isos.map(vmIsoPayload).toList(growable: false);
  }

  /// 虚拟机模板列表。POST /vms/templates/list。
  static Future<dynamic> getVmTemplates(dynamic arguments) async {
    final templates = await VMService().listTemplates();
    return templates.map(vmTemplatePayload).toList(growable: false);
  }

  /// 虚拟机网络列表。GET /vms/networks。
  static Future<dynamic> getVmNetworks(dynamic arguments) async {
    final networks = await VMService().listNetworks();
    return networks.map(vmNetworkPayload).toList(growable: false);
  }

  /// 创建网络可选的网桥与宿主机接口。GET /vms/networks/bridges 与 interfaces。
  static Future<dynamic> getVmNetworkOptions(dynamic arguments) async {
    final service = VMService();
    final bridges = await service.listNetworkBridges();
    final interfaces = await service.listNetworkInterfaces();
    return <String, dynamic>{
      'bridges': bridges
          .map((bridge) => <String, Object?>{
                'name': bridge.name,
                'recommended': bridge.recommended,
                'description': bridge.description,
              })
          .toList(growable: false),
      'interfaces': interfaces
          .map((interface) => <String, Object?>{
                'name': interface.name,
                'addresses': interface.addresses,
              })
          .toList(growable: false),
    };
  }

  /// 虚拟机存储池列表。GET /vms/storages。
  static Future<dynamic> getVmStorages(dynamic arguments) async {
    final storages = await VMService().listStorages();
    return storages.map(vmStoragePayload).toList(growable: false);
  }

  // ── 告警中心 ────────────────────────────────────────────────────────────

  /// 告警任务列表。参数：`{page?, pageSize?, type?, status?}`。POST /alert/search。
  static Future<dynamic> getAlertRules(dynamic arguments) async {
    final page = int.tryParse('${arguments?['page'] ?? 1}') ?? 1;
    final pageSize = int.tryParse('${arguments?['pageSize'] ?? 50}') ?? 50;
    final type = (arguments?['type'] as String? ?? '').trim();
    final status = (arguments?['status'] as String? ?? '').trim();
    final result = await AlertService().searchAlerts(
      page: page,
      pageSize: pageSize,
      type: type.isEmpty ? null : type,
      status: status.isEmpty ? null : status,
    );
    return <String, dynamic>{
      'items': result.items.map(alertRulePayload).toList(growable: false),
      'total': result.total,
      'page': result.page,
      'pageSize': result.pageSize,
    };
  }

  /// 告警日志列表。参数：`{page?, pageSize?, status?}`。POST /alert/logs/search。
  static Future<dynamic> getAlertLogs(dynamic arguments) async {
    final page = int.tryParse('${arguments?['page'] ?? 1}') ?? 1;
    final pageSize = int.tryParse('${arguments?['pageSize'] ?? 50}') ?? 50;
    final status = (arguments?['status'] as String? ?? '').trim();
    final result = await AlertService().searchLogs(
      page: page,
      pageSize: pageSize,
      status: status.isEmpty ? null : status,
    );
    return <String, dynamic>{
      'items': result.items.map(alertLogPayload).toList(growable: false),
      'total': result.total,
      'page': result.page,
      'pageSize': result.pageSize,
    };
  }

  /// 通知渠道列表。GET /alert/config/info。
  static Future<dynamic> getAlertChannels(dynamic arguments) async {
    final channels = await AlertService().listConfigs();
    return channels.map(alertChannelPayload).toList(growable: false);
  }

  /// 告警表单选项：磁盘、病毒扫描任务、计划任务、类型与预设。
  static Future<dynamic> getAlertOptions(dynamic arguments) async {
    final service = AlertService();
    final results = await Future.wait(<Future<Object>>[
      service.listDisks(),
      service.listClams(),
      service.listCronJobs(),
    ]);
    return alertOptionsPayload(
      disks: results[0] as List<AlertDisk>,
      clams: results[1] as List<AlertClam>,
      cronJobs: results[2] as List<AlertCronJob>,
    );
  }

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

/// 实时统计采样器在通道进程内共享，按服务器与实例名隔离。
final VmStatsSampler _vmStatsSampler = VmStatsSampler();
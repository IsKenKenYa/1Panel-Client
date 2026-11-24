import '../config/api_config.dart';
import '../../data/models/alert_models.dart';
import '../../features/alert/alert_service.dart';
import '../../features/vm/vm_service.dart';
import 'native_alert_payloads.dart';
import 'native_vm_payloads.dart';

/// 读通道虚拟化域：虚拟机环境、实例、快照、健康与统计、镜像模板网络存储，
/// 以及告警任务、告警日志、通知渠道与告警表单选项。
class NativeChannelVirtualizationReadHandlers {
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
}

/// 实时统计采样器在通道进程内共享，按服务器与实例名隔离。
final VmStatsSampler _vmStatsSampler = VmStatsSampler();
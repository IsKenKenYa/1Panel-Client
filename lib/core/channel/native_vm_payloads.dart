import '../../data/models/vm/vm_models.dart';
import '../../data/models/vm/vm_resource_models.dart';
import '../../features/vm/vm_status.dart';

/// 虚拟机通道返回结构。
///
/// 原生轨道只负责展示，状态判定、操作可用性与监控数值计算在这里完成，
/// Swift 侧直接消费字段，不再判断 `status` 字符串或重算采样差值。

Map<String, Object?> vmEnvironmentPayload(VMEnvironment environment) {
  return <String, Object?>{
    'arch': environment.arch,
    'archSupported': environment.archSupported,
    'ready': environment.ready,
    'helperExist': environment.helperExist,
    'helperMessage': environment.helperMessage,
    'kvmExist': environment.kvmExist,
    'kvmMessage': environment.kvmMessage,
    'libvirtExist': environment.libvirtExist,
    'libvirtActive': environment.libvirtActive,
    'libvirtMessage': environment.libvirtMessage,
    'storageExist': environment.storageExist,
    'storageMessage': environment.storageMessage,
  };
}

/// 状态在界面上的语义分组。
String vmStatusTone(String status) {
  switch (VmStatus.normalize(status)) {
    case VmStatus.running:
      return 'positive';
    case VmStatus.blocked:
    case VmStatus.paused:
    case VmStatus.pmsuspended:
      return 'warning';
    case VmStatus.shutOff:
      return 'neutral';
    case VmStatus.creating:
      return 'info';
    default:
      return 'negative';
  }
}

Map<String, Object?> vmCapabilitiesPayload(VMItem vm) {
  return <String, Object?>{
    'canStart': VmStatus.canOperate(vm, 'start'),
    'canShutdown': VmStatus.canOperate(vm, 'shutdown'),
    'canReboot': VmStatus.canOperate(vm, 'reboot'),
    'canSuspend': VmStatus.canOperate(vm, 'suspend'),
    'canResume': VmStatus.canOperate(vm, 'resume'),
    'canDestroy': VmStatus.canOperate(vm, 'destroy'),
    'canMonitor': VmStatus.isRunning(vm) ||
        VmStatus.normalize(vm.status) == VmStatus.blocked,
    'canOpenConsole': VmStatus.canOpenConsole(vm),
    'canCreateSnapshot': VmStatus.canInspectResources(vm),
    'canHealthCheck': VmStatus.canInspectResources(vm),
    'canResizeDisk': VmStatus.canResizeDisk(vm),
  };
}

Map<String, Object?> vmSummaryPayload(VMItem vm) {
  return <String, Object?>{
    'id': vm.id,
    'name': vm.name,
    'status': vm.status,
    'statusKey': VmStatus.normalize(vm.status),
    'statusTone': vmStatusTone(vm.status),
    'cpu': vm.cpu,
    'memoryMiB': vm.memory,
    'diskSize': vm.diskSize,
    'diskBus': vm.diskBus,
    'storagePool': vm.storagePool,
    'network': vm.network,
    'autoStart': vm.autoStart,
    'description': vm.description,
    'graphicsType': vm.graphics?.type ?? '',
    'capabilities': vmCapabilitiesPayload(vm),
  };
}

Map<String, Object?> vmDetailPayload(VMItem vm) {
  return <String, Object?>{
    ...vmSummaryPayload(vm),
    'uuid': vm.uuid,
    'diskPath': vm.diskPath,
    'isoPaths': vm.isoPaths,
    'imagePath': vm.imagePath,
    'bootOrder': vm.bootOrder,
    'taskID': vm.taskID,
    'createTaskID': vm.createTaskID,
    'disks': vm.disks.map(vmDiskPayload).toList(growable: false),
    'interfaces': vm.interfaces.map(vmInterfacePayload).toList(growable: false),
    'graphics': vm.graphics == null
        ? null
        : <String, Object?>{
            'type': vm.graphics!.type,
            'port': vm.graphics!.port,
            'listen': vm.graphics!.listen,
            'url': vm.graphics!.url,
          },
  };
}

Map<String, Object?> vmDiskPayload(VMDisk disk) {
  return <String, Object?>{
    'capacity': disk.capacity,
    'format': disk.format,
    'readOnly': disk.readOnly,
    'shareable': disk.shareable,
    'resizeBlocked': disk.resizeBlocked,
    'device': disk.device,
    'type': disk.type,
    'source': disk.source,
    'target': disk.target,
    'bus': disk.bus,
  };
}

Map<String, Object?> vmInterfacePayload(VMInterface interface) {
  return <String, Object?>{
    'type': interface.type,
    'source': interface.source,
    'model': interface.model,
    'mac': interface.mac,
    'ip': interface.ip,
  };
}

Map<String, Object?> vmSnapshotPayload(
  VMSnapshotItem snapshot, {
  required bool canRecover,
}) {
  return <String, Object?>{
    'name': snapshot.name,
    'description': snapshot.description,
    'createdAt': snapshot.createdAt,
    'createdAtMillis': _timestampMillis(snapshot.createdAt),
    'state': snapshot.state,
    'parent': snapshot.parent,
    'size': snapshot.size,
    'current': snapshot.current,
    'children': snapshot.children,
    'canRecover': canRecover,
  };
}

/// 快照时间在秒与毫秒两种量级之间兼容，输出统一的毫秒时间戳。
int _timestampMillis(int value) {
  if (value <= 0) return 0;
  return value > 100000000000 ? value : value * 1000;
}

Map<String, Object?> vmIsoPayload(VMIsoItem iso) {
  return <String, Object?>{
    'id': iso.id,
    'type': iso.type,
    'name': iso.name,
    'path': iso.path,
    'isExist': iso.isExist,
    'size': iso.size,
    'status': iso.status,
    'error': iso.error,
    'createdAt': iso.createdAt,
    'description': iso.description,
  };
}

Map<String, Object?> vmTemplatePayload(VMTemplateItem template) {
  return <String, Object?>{
    'id': template.id,
    'name': template.name,
    'sourceVM': template.sourceVM,
    'cpu': template.cpu,
    'memoryMiB': template.memory,
    'diskSize': template.diskSize,
    'storagePool': template.storagePool,
    'network': template.network,
    'isExist': template.isExist,
    'size': template.size,
    'status': template.status,
    'error': template.error,
    'createdAt': template.createdAt,
    'description': template.description,
  };
}

Map<String, Object?> vmNetworkPayload(VMNetworkItem network) {
  return <String, Object?>{
    'id': network.id,
    'name': network.name,
    'type': network.type,
    'bridgeName': network.bridgeName,
    'sourceInterface': network.sourceInterface,
    'cidr': network.cidr,
    'gateway': network.gateway,
    'dhcpStart': network.dhcpStart,
    'dhcpEnd': network.dhcpEnd,
    'autoStart': network.autoStart,
    'status': network.status,
    'error': network.error,
    'vmCount': network.vmCount,
    'registered': network.registered,
    'description': network.description,
    'vms': network.vms
        .map((vm) => <String, Object?>{'id': vm.id, 'name': vm.name})
        .toList(growable: false),
    'usedIPs': network.usedIPs
        .map((usage) => <String, Object?>{
              'ip': usage.ip,
              'vmName': usage.vmName,
              'mac': usage.mac,
              'source': usage.source,
            })
        .toList(growable: false),
  };
}

Map<String, Object?> vmStoragePayload(VMStorageItem storage) {
  return <String, Object?>{
    'id': storage.id,
    'name': storage.name,
    'type': storage.type,
    'path': storage.path,
    'autoStart': storage.autoStart,
    'status': storage.status,
    'error': storage.error,
    'capacity': storage.capacity,
    'available': storage.available,
    'usedPercent': storage.usagePercent,
    'vmCount': storage.vmCount,
    'description': storage.description,
  };
}

Map<String, Object?> vmHealthPayload(VMHealthCheckResult result) {
  return <String, Object?>{
    'pass': result.pass,
    'warn': result.warn,
    'fail': result.fail,
    'items': result.items
        .map((item) => <String, Object?>{
              'level': item.level,
              'check': item.check,
              'reason': item.reason,
              'detail': item.detail,
              'fixCommand': item.fixCommand,
            })
        .toList(growable: false),
  };
}

/// 虚拟机实时统计采样器。
///
/// 服务端返回累计值，CPU 使用率、磁盘与网络速率需要两次采样求差。
/// 采样状态按服务器与实例名分别保存，切换服务器时不会串用旧数据。
class VmStatsSampler {
  final Map<String, VMStats> _previous = <String, VMStats>{};

  Map<String, Object?> sample({
    required String serverId,
    required VMStats stats,
  }) {
    final key = '$serverId/${stats.name}';
    final previous = _previous[key];
    _previous[key] = stats;

    var diskBytesPerSecond = 0.0;
    var networkBytesPerSecond = 0.0;
    if (previous != null) {
      final elapsed = _elapsedSeconds(stats, previous);
      final diskDelta =
          (stats.disk.readBytes - previous.disk.readBytes).abs() +
              (stats.disk.writeBytes - previous.disk.writeBytes).abs();
      final networkDelta =
          (stats.network.rxBytes - previous.network.rxBytes).abs() +
              (stats.network.txBytes - previous.network.txBytes).abs();
      diskBytesPerSecond = diskDelta / elapsed;
      networkBytesPerSecond = networkDelta / elapsed;
    }

    return <String, Object?>{
      'name': stats.name,
      'status': stats.status,
      'isRunning': const <String>{'running', 'blocked'}
          .contains(stats.status.trim().toLowerCase()),
      'timestamp': stats.timestamp,
      'cpuPercent': _cpuPercent(stats, previous),
      'memoryPercent': _memoryPercent(stats),
      'diskBytesPerSecond': diskBytesPerSecond,
      'networkBytesPerSecond': networkBytesPerSecond,
      'hasDelta': previous != null,
    };
  }

  static double _elapsedSeconds(VMStats stats, VMStats previous) {
    final seconds = (stats.timestamp - previous.timestamp).abs();
    return seconds <= 0 ? 1 : seconds.toDouble();
  }

  static double _cpuPercent(VMStats stats, VMStats? previous) {
    if (previous == null || stats.vcpu <= 0) return 0;
    final delta = stats.cpuTime - previous.cpuTime;
    if (delta <= 0) return 0;
    final ratio = delta / (_elapsedSeconds(stats, previous) * stats.vcpu);
    return ratio.clamp(0, 1).toDouble() * 100;
  }

  static double _memoryPercent(VMStats stats) {
    final total = stats.memory.actualKiB;
    if (total <= 0) return 0;
    final used = total - stats.memory.availableKiB;
    if (used <= 0) return 0;
    return (used / total).clamp(0, 1).toDouble() * 100;
  }
}
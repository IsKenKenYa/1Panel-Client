// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vm_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VMEnvironment _$VMEnvironmentFromJson(Map<String, dynamic> json) =>
    VMEnvironment(
      arch: json['arch'] as String,
      archSupported: json['archSupported'] as bool,
      ready: json['ready'] as bool,
      helperExist: json['helperExist'] as bool,
      helperMessage: json['helperMessage'] as String,
      kvmExist: json['kvmExist'] as bool,
      kvmMessage: json['kvmMessage'] as String,
      libvirtExist: json['libvirtExist'] as bool,
      libvirtActive: json['libvirtActive'] as bool,
      libvirtMessage: json['libvirtMessage'] as String,
      storageExist: json['storageExist'] as bool,
      storageMessage: json['storageMessage'] as String,
    );

Map<String, dynamic> _$VMEnvironmentToJson(VMEnvironment instance) =>
    <String, dynamic>{
      'arch': instance.arch,
      'archSupported': instance.archSupported,
      'ready': instance.ready,
      'helperExist': instance.helperExist,
      'helperMessage': instance.helperMessage,
      'kvmExist': instance.kvmExist,
      'kvmMessage': instance.kvmMessage,
      'libvirtExist': instance.libvirtExist,
      'libvirtActive': instance.libvirtActive,
      'libvirtMessage': instance.libvirtMessage,
      'storageExist': instance.storageExist,
      'storageMessage': instance.storageMessage,
    };

VMHealthCheckItem _$VMHealthCheckItemFromJson(Map<String, dynamic> json) =>
    VMHealthCheckItem(
      level: json['level'] as String,
      check: json['check'] as String,
      reason: json['reason'] as String?,
      params: (json['params'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      detail: json['detail'] as String?,
      fixCommand: json['fixCommand'] as String?,
    );

Map<String, dynamic> _$VMHealthCheckItemToJson(VMHealthCheckItem instance) =>
    <String, dynamic>{
      'level': instance.level,
      'check': instance.check,
      'reason': instance.reason,
      'params': instance.params,
      'detail': instance.detail,
      'fixCommand': instance.fixCommand,
    };

VMHealthCheckResult _$VMHealthCheckResultFromJson(Map<String, dynamic> json) =>
    VMHealthCheckResult(
      pass: (json['pass'] as num).toInt(),
      warn: (json['warn'] as num).toInt(),
      fail: (json['fail'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => VMHealthCheckItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$VMHealthCheckResultToJson(
  VMHealthCheckResult instance,
) => <String, dynamic>{
  'pass': instance.pass,
  'warn': instance.warn,
  'fail': instance.fail,
  'items': instance.items,
};

VMDisk _$VMDiskFromJson(Map<String, dynamic> json) => VMDisk(
  capacity: (json['capacity'] as num).toInt(),
  format: json['format'] as String,
  readOnly: json['readOnly'] as bool,
  shareable: json['shareable'] as bool,
  resizeBlocked: json['resizeBlocked'] as String,
  device: json['device'] as String,
  type: json['type'] as String,
  source: json['source'] as String,
  target: json['target'] as String,
  bus: json['bus'] as String,
);

Map<String, dynamic> _$VMDiskToJson(VMDisk instance) => <String, dynamic>{
  'capacity': instance.capacity,
  'format': instance.format,
  'readOnly': instance.readOnly,
  'shareable': instance.shareable,
  'resizeBlocked': instance.resizeBlocked,
  'device': instance.device,
  'type': instance.type,
  'source': instance.source,
  'target': instance.target,
  'bus': instance.bus,
};

VMInterface _$VMInterfaceFromJson(Map<String, dynamic> json) => VMInterface(
  type: json['type'] as String,
  source: json['source'] as String,
  model: json['model'] as String,
  mac: json['mac'] as String,
  ip: json['ip'] as String,
);

Map<String, dynamic> _$VMInterfaceToJson(VMInterface instance) =>
    <String, dynamic>{
      'type': instance.type,
      'source': instance.source,
      'model': instance.model,
      'mac': instance.mac,
      'ip': instance.ip,
    };

VMGraphics _$VMGraphicsFromJson(Map<String, dynamic> json) => VMGraphics(
  type: json['type'] as String,
  port: json['port'] as String,
  listen: json['listen'] as String,
  url: json['url'] as String?,
);

Map<String, dynamic> _$VMGraphicsToJson(VMGraphics instance) =>
    <String, dynamic>{
      'type': instance.type,
      'port': instance.port,
      'listen': instance.listen,
      'url': instance.url,
    };

VMMemoryStats _$VMMemoryStatsFromJson(Map<String, dynamic> json) =>
    VMMemoryStats(
      availableKiB: (json['availableKiB'] as num).toInt(),
      unusedKiB: (json['unusedKiB'] as num).toInt(),
      usableKiB: (json['usableKiB'] as num).toInt(),
      rssKiB: (json['rssKiB'] as num).toInt(),
      actualKiB: (json['actualKiB'] as num).toInt(),
    );

Map<String, dynamic> _$VMMemoryStatsToJson(VMMemoryStats instance) =>
    <String, dynamic>{
      'availableKiB': instance.availableKiB,
      'unusedKiB': instance.unusedKiB,
      'usableKiB': instance.usableKiB,
      'rssKiB': instance.rssKiB,
      'actualKiB': instance.actualKiB,
    };

VMDiskStats _$VMDiskStatsFromJson(Map<String, dynamic> json) => VMDiskStats(
  readBytes: (json['readBytes'] as num).toInt(),
  writeBytes: (json['writeBytes'] as num).toInt(),
  readReqs: (json['readReqs'] as num).toInt(),
  writeReqs: (json['writeReqs'] as num).toInt(),
);

Map<String, dynamic> _$VMDiskStatsToJson(VMDiskStats instance) =>
    <String, dynamic>{
      'readBytes': instance.readBytes,
      'writeBytes': instance.writeBytes,
      'readReqs': instance.readReqs,
      'writeReqs': instance.writeReqs,
    };

VMNetworkStats _$VMNetworkStatsFromJson(Map<String, dynamic> json) =>
    VMNetworkStats(
      rxBytes: (json['rxBytes'] as num).toInt(),
      txBytes: (json['txBytes'] as num).toInt(),
      rxPackets: (json['rxPackets'] as num).toInt(),
      txPackets: (json['txPackets'] as num).toInt(),
    );

Map<String, dynamic> _$VMNetworkStatsToJson(VMNetworkStats instance) =>
    <String, dynamic>{
      'rxBytes': instance.rxBytes,
      'txBytes': instance.txBytes,
      'rxPackets': instance.rxPackets,
      'txPackets': instance.txPackets,
    };

VMStats _$VMStatsFromJson(Map<String, dynamic> json) => VMStats(
  name: json['name'] as String,
  status: json['status'] as String,
  timestamp: (json['timestamp'] as num).toInt(),
  cpuTime: (json['cpuTime'] as num).toInt(),
  vcpu: (json['vcpu'] as num).toInt(),
  memory: VMMemoryStats.fromJson(json['memory'] as Map<String, dynamic>),
  disk: VMDiskStats.fromJson(json['disk'] as Map<String, dynamic>),
  network: VMNetworkStats.fromJson(json['network'] as Map<String, dynamic>),
);

Map<String, dynamic> _$VMStatsToJson(VMStats instance) => <String, dynamic>{
  'name': instance.name,
  'status': instance.status,
  'timestamp': instance.timestamp,
  'cpuTime': instance.cpuTime,
  'vcpu': instance.vcpu,
  'memory': instance.memory,
  'disk': instance.disk,
  'network': instance.network,
};

VMItem _$VMItemFromJson(Map<String, dynamic> json) => VMItem(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  uuid: json['uuid'] as String,
  cpu: (json['cpu'] as num).toInt(),
  memory: (json['memory'] as num).toInt(),
  diskSize: (json['diskSize'] as num).toInt(),
  diskBus: json['diskBus'] as String,
  diskPath: json['diskPath'] as String,
  storagePool: json['storagePool'] as String,
  isoPaths: (json['isoPaths'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  imagePath: json['imagePath'] as String,
  network: json['network'] as String,
  bootOrder: json['bootOrder'] as String,
  autoStart: json['autoStart'] as bool,
  status: json['status'] as String,
  disks: (json['disks'] as List<dynamic>)
      .map((e) => VMDisk.fromJson(e as Map<String, dynamic>))
      .toList(),
  interfaces: (json['interfaces'] as List<dynamic>)
      .map((e) => VMInterface.fromJson(e as Map<String, dynamic>))
      .toList(),
  graphics: json['graphics'] == null
      ? null
      : VMGraphics.fromJson(json['graphics'] as Map<String, dynamic>),
  taskID: json['taskID'] as String,
  createTaskID: json['createTaskID'] as String,
  description: json['description'] as String,
);

Map<String, dynamic> _$VMItemToJson(VMItem instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'uuid': instance.uuid,
  'cpu': instance.cpu,
  'memory': instance.memory,
  'diskSize': instance.diskSize,
  'diskBus': instance.diskBus,
  'diskPath': instance.diskPath,
  'storagePool': instance.storagePool,
  'isoPaths': instance.isoPaths,
  'imagePath': instance.imagePath,
  'network': instance.network,
  'bootOrder': instance.bootOrder,
  'autoStart': instance.autoStart,
  'status': instance.status,
  'disks': instance.disks,
  'interfaces': instance.interfaces,
  'graphics': instance.graphics,
  'taskID': instance.taskID,
  'createTaskID': instance.createTaskID,
  'description': instance.description,
};

VMSearchResult _$VMSearchResultFromJson(Map<String, dynamic> json) =>
    VMSearchResult(
      items: (json['items'] as List<dynamic>)
          .map((e) => VMItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
    );

Map<String, dynamic> _$VMSearchResultToJson(VMSearchResult instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'limit': instance.limit,
    };

VMTaskResp _$VMTaskRespFromJson(Map<String, dynamic> json) =>
    VMTaskResp(taskID: json['taskID'] as String);

Map<String, dynamic> _$VMTaskRespToJson(VMTaskResp instance) =>
    <String, dynamic>{'taskID': instance.taskID};

VMReq _$VMReqFromJson(Map<String, dynamic> json) =>
    VMReq(name: json['name'] as String);

Map<String, dynamic> _$VMReqToJson(VMReq instance) => <String, dynamic>{
  'name': instance.name,
};

VMInfoReq _$VMInfoReqFromJson(Map<String, dynamic> json) => VMInfoReq(
  name: json['name'] as String,
  checkDisks: json['checkDisks'] as bool? ?? false,
);

Map<String, dynamic> _$VMInfoReqToJson(VMInfoReq instance) => <String, dynamic>{
  'name': instance.name,
  'checkDisks': instance.checkDisks,
};

VMCreate _$VMCreateFromJson(Map<String, dynamic> json) => VMCreate(
  taskID: json['taskID'] as String?,
  name: json['name'] as String,
  cpu: (json['cpu'] as num).toInt(),
  memory: (json['memory'] as num).toInt(),
  diskSize: (json['diskSize'] as num).toInt(),
  osType: json['osType'] as String?,
  diskBus: json['diskBus'] as String?,
  templateID: (json['templateID'] as num?)?.toInt(),
  diskPath: json['diskPath'] as String?,
  storagePool: json['storagePool'] as String?,
  isoPaths:
      (json['isoPaths'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  imagePath: json['imagePath'] as String?,
  network: json['network'] as String,
  bootOrder: json['bootOrder'] as String?,
  startAfterCreate: json['startAfterCreate'] as bool,
  autoStart: json['autoStart'] as bool,
  description: json['description'] as String?,
);

Map<String, dynamic> _$VMCreateToJson(VMCreate instance) => <String, dynamic>{
  'taskID': instance.taskID,
  'name': instance.name,
  'cpu': instance.cpu,
  'memory': instance.memory,
  'diskSize': instance.diskSize,
  'osType': instance.osType,
  'diskBus': instance.diskBus,
  'templateID': instance.templateID,
  'diskPath': instance.diskPath,
  'storagePool': instance.storagePool,
  'isoPaths': instance.isoPaths,
  'imagePath': instance.imagePath,
  'network': instance.network,
  'bootOrder': instance.bootOrder,
  'startAfterCreate': instance.startAfterCreate,
  'autoStart': instance.autoStart,
  'description': instance.description,
};

VMUpdate _$VMUpdateFromJson(Map<String, dynamic> json) => VMUpdate(
  taskID: json['taskID'] as String?,
  name: json['name'] as String,
  cpu: (json['cpu'] as num).toInt(),
  memory: (json['memory'] as num).toInt(),
  isoPaths: (json['isoPaths'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  network: json['network'] as String,
  bootOrder: json['bootOrder'] as String?,
  autoStart: json['autoStart'] as bool,
  description: json['description'] as String?,
);

Map<String, dynamic> _$VMUpdateToJson(VMUpdate instance) => <String, dynamic>{
  'taskID': instance.taskID,
  'name': instance.name,
  'cpu': instance.cpu,
  'memory': instance.memory,
  'isoPaths': instance.isoPaths,
  'network': instance.network,
  'bootOrder': instance.bootOrder,
  'autoStart': instance.autoStart,
  'description': instance.description,
};

VMOperate _$VMOperateFromJson(Map<String, dynamic> json) =>
    VMOperate(name: json['name'] as String, operate: json['operate'] as String);

Map<String, dynamic> _$VMOperateToJson(VMOperate instance) => <String, dynamic>{
  'name': instance.name,
  'operate': instance.operate,
};

VMRename _$VMRenameFromJson(Map<String, dynamic> json) => VMRename(
  taskID: json['taskID'] as String?,
  name: json['name'] as String,
  newName: json['newName'] as String,
);

Map<String, dynamic> _$VMRenameToJson(VMRename instance) => <String, dynamic>{
  'taskID': instance.taskID,
  'name': instance.name,
  'newName': instance.newName,
};

VMDiskResize _$VMDiskResizeFromJson(Map<String, dynamic> json) => VMDiskResize(
  taskID: json['taskID'] as String?,
  name: json['name'] as String,
  target: json['target'] as String,
  sizeGiB: (json['sizeGiB'] as num).toInt(),
);

Map<String, dynamic> _$VMDiskResizeToJson(VMDiskResize instance) =>
    <String, dynamic>{
      'taskID': instance.taskID,
      'name': instance.name,
      'target': instance.target,
      'sizeGiB': instance.sizeGiB,
    };

VMDelete _$VMDeleteFromJson(Map<String, dynamic> json) => VMDelete(
  taskID: json['taskID'] as String?,
  id: (json['id'] as num).toInt(),
  force: json['force'] as bool? ?? false,
);

Map<String, dynamic> _$VMDeleteToJson(VMDelete instance) => <String, dynamic>{
  'taskID': instance.taskID,
  'id': instance.id,
  'force': instance.force,
};

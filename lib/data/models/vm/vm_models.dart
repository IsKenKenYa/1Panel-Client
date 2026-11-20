import 'package:equatable/equatable.dart';

/// 虚拟机环境检测结果（GET /vms/environment）。
class VMEnvironment extends Equatable {
  final String arch;
  final bool archSupported;
  final bool ready;
  final bool helperExist;
  final String helperMessage;
  final bool kvmExist;
  final String kvmMessage;
  final bool libvirtExist;
  final bool libvirtActive;
  final String libvirtMessage;
  final bool storageExist;
  final String storageMessage;

  const VMEnvironment({
    this.arch = '',
    this.archSupported = false,
    this.ready = false,
    this.helperExist = false,
    this.helperMessage = '',
    this.kvmExist = false,
    this.kvmMessage = '',
    this.libvirtExist = false,
    this.libvirtActive = false,
    this.libvirtMessage = '',
    this.storageExist = false,
    this.storageMessage = '',
  });

  factory VMEnvironment.fromJson(Map<String, dynamic> json) {
    return VMEnvironment(
      arch: json['arch'] as String? ?? '',
      archSupported: json['archSupported'] as bool? ?? false,
      ready: json['ready'] as bool? ?? false,
      helperExist: json['helperExist'] as bool? ?? false,
      helperMessage: json['helperMessage'] as String? ?? '',
      kvmExist: json['kvmExist'] as bool? ?? false,
      kvmMessage: json['kvmMessage'] as String? ?? '',
      libvirtExist: json['libvirtExist'] as bool? ?? false,
      libvirtActive: json['libvirtActive'] as bool? ?? false,
      libvirtMessage: json['libvirtMessage'] as String? ?? '',
      storageExist: json['storageExist'] as bool? ?? false,
      storageMessage: json['storageMessage'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[
        arch,
        archSupported,
        ready,
        helperExist,
        helperMessage,
        kvmExist,
        kvmMessage,
        libvirtExist,
        libvirtActive,
        libvirtMessage,
        storageExist,
        storageMessage,
      ];
}

/// 健康检查单项（POST /vms/health/check）。
///
/// level 取值：PASS / INFO / WARN / FAIL。
class VMHealthCheckItem extends Equatable {
  final String level;
  final String check;
  final String? reason;
  final Map<String, String> params;
  final String? detail;
  final String? fixCommand;

  const VMHealthCheckItem({
    required this.level,
    required this.check,
    this.reason,
    this.params = const <String, String>{},
    this.detail,
    this.fixCommand,
  });

  factory VMHealthCheckItem.fromJson(Map<String, dynamic> json) {
    return VMHealthCheckItem(
      level: json['level'] as String? ?? '',
      check: json['check'] as String? ?? '',
      reason: json['reason'] as String?,
      params: (json['params'] as Map?)
              ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
          const <String, String>{},
      detail: json['detail'] as String?,
      fixCommand: json['fixCommand'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[level, check, reason, params, detail, fixCommand];
}

/// 健康检查汇总（POST /vms/health/check）。
class VMHealthCheckResult extends Equatable {
  final int pass;
  final int warn;
  final int fail;
  final List<VMHealthCheckItem> items;

  const VMHealthCheckResult({
    this.pass = 0,
    this.warn = 0,
    this.fail = 0,
    this.items = const <VMHealthCheckItem>[],
  });

  factory VMHealthCheckResult.fromJson(Map<String, dynamic> json) {
    return VMHealthCheckResult(
      pass: json['pass'] as int? ?? 0,
      warn: json['warn'] as int? ?? 0,
      fail: json['fail'] as int? ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(VMHealthCheckItem.fromJson)
              .toList(growable: false) ??
          const <VMHealthCheckItem>[],
    );
  }

  @override
  List<Object?> get props => <Object?>[pass, warn, fail, items];
}

/// 虚拟机磁盘（dto.VMDisk）。
class VMDisk extends Equatable {
  final int capacity;
  final String format;
  final bool readOnly;
  final bool shareable;
  final String resizeBlocked;
  final String device;
  final String type;
  final String source;
  final String target;
  final String bus;

  const VMDisk({
    this.capacity = 0,
    this.format = '',
    this.readOnly = false,
    this.shareable = false,
    this.resizeBlocked = '',
    this.device = '',
    this.type = '',
    this.source = '',
    this.target = '',
    this.bus = '',
  });

  factory VMDisk.fromJson(Map<String, dynamic> json) {
    return VMDisk(
      capacity: json['capacity'] as int? ?? 0,
      format: json['format'] as String? ?? '',
      readOnly: json['readOnly'] as bool? ?? false,
      shareable: json['shareable'] as bool? ?? false,
      resizeBlocked: json['resizeBlocked'] as String? ?? '',
      device: json['device'] as String? ?? '',
      type: json['type'] as String? ?? '',
      source: json['source'] as String? ?? '',
      target: json['target'] as String? ?? '',
      bus: json['bus'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[
        capacity,
        format,
        readOnly,
        shareable,
        resizeBlocked,
        device,
        type,
        source,
        target,
        bus,
      ];
}

/// 虚拟机网络接口（dto.VMInterface）。
class VMInterface extends Equatable {
  final String type;
  final String source;
  final String model;
  final String mac;
  final String ip;

  const VMInterface({
    this.type = '',
    this.source = '',
    this.model = '',
    this.mac = '',
    this.ip = '',
  });

  factory VMInterface.fromJson(Map<String, dynamic> json) {
    return VMInterface(
      type: json['type'] as String? ?? '',
      source: json['source'] as String? ?? '',
      model: json['model'] as String? ?? '',
      mac: json['mac'] as String? ?? '',
      ip: json['ip'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[type, source, model, mac, ip];
}

/// 虚拟机图形控制台信息（dto.VMGraphics）。
class VMGraphics extends Equatable {
  final String type;
  final String port;
  final String listen;
  final String? url;

  const VMGraphics({
    this.type = '',
    this.port = '',
    this.listen = '',
    this.url,
  });

  factory VMGraphics.fromJson(Map<String, dynamic> json) {
    return VMGraphics(
      type: json['type'] as String? ?? '',
      port: json['port'] as String? ?? '',
      listen: json['listen'] as String? ?? '',
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'port': port,
        'listen': listen,
        if (url != null) 'url': url,
      };

  @override
  List<Object?> get props => <Object?>[type, port, listen, url];
}

/// 虚拟机内存统计（MiB/KiB 由服务端字段名标注）。
class VMMemoryStats extends Equatable {
  final int availableKiB;
  final int unusedKiB;
  final int usableKiB;
  final int rssKiB;
  final int actualKiB;

  const VMMemoryStats({
    this.availableKiB = 0,
    this.unusedKiB = 0,
    this.usableKiB = 0,
    this.rssKiB = 0,
    this.actualKiB = 0,
  });

  factory VMMemoryStats.fromJson(Map<String, dynamic> json) {
    return VMMemoryStats(
      availableKiB: json['availableKiB'] as int? ?? 0,
      unusedKiB: json['unusedKiB'] as int? ?? 0,
      usableKiB: json['usableKiB'] as int? ?? 0,
      rssKiB: json['rssKiB'] as int? ?? 0,
      actualKiB: json['actualKiB'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[availableKiB, unusedKiB, usableKiB, rssKiB, actualKiB];
}

/// 虚拟机磁盘统计。
class VMDiskStats extends Equatable {
  final int readBytes;
  final int writeBytes;
  final int readReqs;
  final int writeReqs;

  const VMDiskStats({
    this.readBytes = 0,
    this.writeBytes = 0,
    this.readReqs = 0,
    this.writeReqs = 0,
  });

  factory VMDiskStats.fromJson(Map<String, dynamic> json) {
    return VMDiskStats(
      readBytes: json['readBytes'] as int? ?? 0,
      writeBytes: json['writeBytes'] as int? ?? 0,
      readReqs: json['readReqs'] as int? ?? 0,
      writeReqs: json['writeReqs'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[readBytes, writeBytes, readReqs, writeReqs];
}

/// 虚拟机网络统计。
class VMNetworkStats extends Equatable {
  final int rxBytes;
  final int txBytes;
  final int rxPackets;
  final int txPackets;

  const VMNetworkStats({
    this.rxBytes = 0,
    this.txBytes = 0,
    this.rxPackets = 0,
    this.txPackets = 0,
  });

  factory VMNetworkStats.fromJson(Map<String, dynamic> json) {
    return VMNetworkStats(
      rxBytes: json['rxBytes'] as int? ?? 0,
      txBytes: json['txBytes'] as int? ?? 0,
      rxPackets: json['rxPackets'] as int? ?? 0,
      txPackets: json['txPackets'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[rxBytes, txBytes, rxPackets, txPackets];
}

/// 虚拟机实时统计（POST /vms/stats）。
class VMStats extends Equatable {
  final String name;
  final String status;
  final int timestamp;
  final int cpuTime;
  final int vcpu;
  final VMMemoryStats memory;
  final VMDiskStats disk;
  final VMNetworkStats network;

  const VMStats({
    this.name = '',
    this.status = '',
    this.timestamp = 0,
    this.cpuTime = 0,
    this.vcpu = 0,
    this.memory = const VMMemoryStats(),
    this.disk = const VMDiskStats(),
    this.network = const VMNetworkStats(),
  });

  factory VMStats.fromJson(Map<String, dynamic> json) {
    return VMStats(
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? 0,
      cpuTime: json['cpuTime'] as int? ?? 0,
      vcpu: json['vcpu'] as int? ?? 0,
      memory: json['memory'] is Map<String, dynamic>
          ? VMMemoryStats.fromJson(json['memory'] as Map<String, dynamic>)
          : const VMMemoryStats(),
      disk: json['disk'] is Map<String, dynamic>
          ? VMDiskStats.fromJson(json['disk'] as Map<String, dynamic>)
          : const VMDiskStats(),
      network: json['network'] is Map<String, dynamic>
          ? VMNetworkStats.fromJson(json['network'] as Map<String, dynamic>)
          : const VMNetworkStats(),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[name, status, timestamp, cpuTime, vcpu, memory, disk, network];
}

/// 虚拟机实例（dto.VMInfo；POST /vms/info）。
class VMItem extends Equatable {
  final int id;
  final String name;
  final String uuid;
  final int cpu;
  final int memory;
  final int diskSize;
  final String diskBus;
  final String diskPath;
  final String storagePool;
  final List<String> isoPaths;
  final String imagePath;
  final String network;
  final String bootOrder;
  final bool autoStart;
  final String status;
  final List<VMDisk> disks;
  final List<VMInterface> interfaces;
  final VMGraphics? graphics;
  final String taskID;
  final String createTaskID;
  final String description;

  const VMItem({
    this.id = 0,
    this.name = '',
    this.uuid = '',
    this.cpu = 0,
    this.memory = 0,
    this.diskSize = 0,
    this.diskBus = '',
    this.diskPath = '',
    this.storagePool = '',
    this.isoPaths = const <String>[],
    this.imagePath = '',
    this.network = '',
    this.bootOrder = '',
    this.autoStart = false,
    this.status = '',
    this.disks = const <VMDisk>[],
    this.interfaces = const <VMInterface>[],
    this.graphics,
    this.taskID = '',
    this.createTaskID = '',
    this.description = '',
  });

  factory VMItem.fromJson(Map<String, dynamic> json) {
    return VMItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      uuid: json['uuid'] as String? ?? '',
      cpu: json['cpu'] as int? ?? 0,
      memory: json['memory'] as int? ?? 0,
      diskSize: json['diskSize'] as int? ?? 0,
      diskBus: json['diskBus'] as String? ?? '',
      diskPath: json['diskPath'] as String? ?? '',
      storagePool: json['storagePool'] as String? ?? '',
      isoPaths: (json['isoPaths'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
      imagePath: json['imagePath'] as String? ?? '',
      network: json['network'] as String? ?? '',
      bootOrder: json['bootOrder'] as String? ?? '',
      autoStart: json['autoStart'] as bool? ?? false,
      status: json['status'] as String? ?? '',
      disks: (json['disks'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(VMDisk.fromJson)
              .toList(growable: false) ??
          const <VMDisk>[],
      interfaces: (json['interfaces'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(VMInterface.fromJson)
              .toList(growable: false) ??
          const <VMInterface>[],
      graphics: json['graphics'] is Map<String, dynamic>
          ? VMGraphics.fromJson(json['graphics'] as Map<String, dynamic>)
          : null,
      taskID: json['taskID'] as String? ?? '',
      createTaskID: json['createTaskID'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        uuid,
        cpu,
        memory,
        diskSize,
        diskBus,
        diskPath,
        storagePool,
        isoPaths,
        imagePath,
        network,
        bootOrder,
        autoStart,
        status,
        disks,
        interfaces,
        graphics,
        taskID,
        createTaskID,
        description,
      ];
}

/// 虚拟机分页结果（dto.VMSearchResult；POST /vms/search）。
///
/// limit 为目标节点允许的虚拟机数量上限，0 表示不限制。
class VMSearchResult extends Equatable {
  final List<VMItem> items;
  final int total;
  final int limit;

  const VMSearchResult({
    this.items = const <VMItem>[],
    this.total = 0,
    this.limit = 0,
  });

  factory VMSearchResult.fromJson(Map<String, dynamic> json) {
    return VMSearchResult(
      items: (json['items'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(VMItem.fromJson)
              .toList(growable: false) ??
          const <VMItem>[],
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => <Object?>[items, total, limit];
}

/// 异步任务句柄（dto.VMTaskResp）。
class VMTaskResp extends Equatable {
  final String taskID;

  const VMTaskResp({this.taskID = ''});

  factory VMTaskResp.fromJson(Map<String, dynamic> json) {
    return VMTaskResp(taskID: json['taskID'] as String? ?? '');
  }

  @override
  List<Object?> get props => <Object?>[taskID];
}

/// 虚拟机详情请求（dto.VMInfoReq）。
///
/// checkDisks 为 true 时服务端同步探测磁盘（上游前端 T_3M 长超时）。
class VMInfoReq extends Equatable {
  final String name;
  final bool checkDisks;

  const VMInfoReq({
    required this.name,
    this.checkDisks = false,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'checkDisks': checkDisks,
      };

  @override
  List<Object?> get props => <Object?>[name, checkDisks];
}

/// 创建虚拟机请求（dto.VMCreate）。memory 单位 MiB。
class VMCreate extends Equatable {
  final String? taskID;
  final String name;
  final int cpu;
  final int memory;
  final int diskSize;
  final String? osType;
  final String? diskBus;
  final int? templateID;
  final String? diskPath;
  final String? storagePool;
  final List<String> isoPaths;
  final String? imagePath;
  final String network;
  final String? bootOrder;
  final bool startAfterCreate;
  final bool autoStart;
  final String? description;

  const VMCreate({
    this.taskID,
    required this.name,
    required this.cpu,
    required this.memory,
    required this.diskSize,
    this.osType,
    this.diskBus,
    this.templateID,
    this.diskPath,
    this.storagePool,
    this.isoPaths = const <String>[],
    this.imagePath,
    required this.network,
    this.bootOrder,
    required this.startAfterCreate,
    required this.autoStart,
    this.description,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (taskID != null) 'taskID': taskID,
        'name': name,
        'cpu': cpu,
        'memory': memory,
        'diskSize': diskSize,
        if (osType != null) 'osType': osType,
        if (diskBus != null) 'diskBus': diskBus,
        if (templateID != null) 'templateID': templateID,
        if (diskPath != null) 'diskPath': diskPath,
        if (storagePool != null) 'storagePool': storagePool,
        'isoPaths': isoPaths,
        if (imagePath != null) 'imagePath': imagePath,
        'network': network,
        if (bootOrder != null) 'bootOrder': bootOrder,
        'startAfterCreate': startAfterCreate,
        'autoStart': autoStart,
        if (description != null) 'description': description,
      };

  @override
  List<Object?> get props => <Object?>[
        taskID,
        name,
        cpu,
        memory,
        diskSize,
        osType,
        diskBus,
        templateID,
        diskPath,
        storagePool,
        isoPaths,
        imagePath,
        network,
        bootOrder,
        startAfterCreate,
        autoStart,
        description,
      ];
}

/// 更新虚拟机请求（dto.VMUpdate）。memory 单位 MiB。
class VMUpdate extends Equatable {
  final String? taskID;
  final String name;
  final int cpu;
  final int memory;
  final List<String> isoPaths;
  final String network;
  final String? bootOrder;
  final bool autoStart;
  final String? description;

  const VMUpdate({
    this.taskID,
    required this.name,
    required this.cpu,
    required this.memory,
    required this.isoPaths,
    required this.network,
    this.bootOrder,
    required this.autoStart,
    this.description,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (taskID != null) 'taskID': taskID,
        'name': name,
        'cpu': cpu,
        'memory': memory,
        'isoPaths': isoPaths,
        'network': network,
        if (bootOrder != null) 'bootOrder': bootOrder,
        'autoStart': autoStart,
        if (description != null) 'description': description,
      };

  @override
  List<Object?> get props => <Object?>[
        taskID,
        name,
        cpu,
        memory,
        isoPaths,
        network,
        bootOrder,
        autoStart,
        description,
      ];
}

/// 虚拟机电源操作（dto.VMOperate）。
///
/// operate 取值：start / shutdown / reboot / destroy / suspend / resume。
class VMOperate extends Equatable {
  final String name;
  final String operate;

  const VMOperate({
    required this.name,
    required this.operate,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'operate': operate,
      };

  @override
  List<Object?> get props => <Object?>[name, operate];
}

/// 重命名虚拟机请求（dto.VMRename）。
class VMRename extends Equatable {
  final String? taskID;
  final String name;
  final String newName;

  const VMRename({
    this.taskID,
    required this.name,
    required this.newName,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (taskID != null) 'taskID': taskID,
        'name': name,
        'newName': newName,
      };

  @override
  List<Object?> get props => <Object?>[taskID, name, newName];
}

/// 磁盘扩容请求（dto.VMDiskResize）。sizeGiB 上限 8388607。
class VMDiskResize extends Equatable {
  final String? taskID;
  final String name;
  final String target;
  final int sizeGiB;

  const VMDiskResize({
    this.taskID,
    required this.name,
    required this.target,
    required this.sizeGiB,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (taskID != null) 'taskID': taskID,
        'name': name,
        'target': target,
        'sizeGiB': sizeGiB,
      };

  @override
  List<Object?> get props => <Object?>[taskID, name, target, sizeGiB];
}

/// 删除虚拟机请求（dto.VMDelete）。
class VMDelete extends Equatable {
  final String? taskID;
  final int id;
  final bool force;

  const VMDelete({
    this.taskID,
    required this.id,
    this.force = false,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (taskID != null) 'taskID': taskID,
        'id': id,
        'force': force,
      };

  @override
  List<Object?> get props => <Object?>[taskID, id, force];
}

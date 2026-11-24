import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vm_models.g.dart';

/// 虚拟机环境检测结果（dto.VMEnvironment；GET /vms/environment）。
///
/// 上游结构体全部为值类型字段，服务端一定返回这些键。
@JsonSerializable()
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
    required this.arch,
    required this.archSupported,
    required this.ready,
    required this.helperExist,
    required this.helperMessage,
    required this.kvmExist,
    required this.kvmMessage,
    required this.libvirtExist,
    required this.libvirtActive,
    required this.libvirtMessage,
    required this.storageExist,
    required this.storageMessage,
  });

  factory VMEnvironment.fromJson(Map<String, dynamic> json) =>
      _$VMEnvironmentFromJson(json);

  Map<String, dynamic> toJson() => _$VMEnvironmentToJson(this);

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

/// 健康检查单项（dto.VMHealthCheckItem；POST /vms/health/check）。
///
/// level 取值：PASS / INFO / WARN / FAIL。reason / params / detail / fixCommand
/// 在上游带 `omitempty`，只有该项有对应检查结果时才会出现。
@JsonSerializable()
class VMHealthCheckItem extends Equatable {
  final String level;
  final String check;
  final String? reason;
  final Map<String, String>? params;
  final String? detail;
  final String? fixCommand;

  const VMHealthCheckItem({
    required this.level,
    required this.check,
    this.reason,
    this.params,
    this.detail,
    this.fixCommand,
  });

  factory VMHealthCheckItem.fromJson(Map<String, dynamic> json) =>
      _$VMHealthCheckItemFromJson(json);

  Map<String, dynamic> toJson() => _$VMHealthCheckItemToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[level, check, reason, params, detail, fixCommand];
}

/// 健康检查汇总（dto.VMHealthCheckResult；POST /vms/health/check）。
@JsonSerializable()
class VMHealthCheckResult extends Equatable {
  final int pass;
  final int warn;
  final int fail;
  final List<VMHealthCheckItem> items;

  const VMHealthCheckResult({
    required this.pass,
    required this.warn,
    required this.fail,
    required this.items,
  });

  factory VMHealthCheckResult.fromJson(Map<String, dynamic> json) =>
      _$VMHealthCheckResultFromJson(json);

  Map<String, dynamic> toJson() => _$VMHealthCheckResultToJson(this);

  @override
  List<Object?> get props => <Object?>[pass, warn, fail, items];
}

/// 虚拟机磁盘（dto.VMDisk）。
@JsonSerializable()
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
    required this.capacity,
    required this.format,
    required this.readOnly,
    required this.shareable,
    required this.resizeBlocked,
    required this.device,
    required this.type,
    required this.source,
    required this.target,
    required this.bus,
  });

  factory VMDisk.fromJson(Map<String, dynamic> json) => _$VMDiskFromJson(json);

  Map<String, dynamic> toJson() => _$VMDiskToJson(this);

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
@JsonSerializable()
class VMInterface extends Equatable {
  final String type;
  final String source;
  final String model;
  final String mac;
  final String ip;

  const VMInterface({
    required this.type,
    required this.source,
    required this.model,
    required this.mac,
    required this.ip,
  });

  factory VMInterface.fromJson(Map<String, dynamic> json) =>
      _$VMInterfaceFromJson(json);

  Map<String, dynamic> toJson() => _$VMInterfaceToJson(this);

  @override
  List<Object?> get props => <Object?>[type, source, model, mac, ip];
}

/// 虚拟机图形控制台信息（dto.VMGraphics）。
///
/// 上游 dto.VMGraphics 只有 type / port / listen；`url` 由 core 侧
/// （`/vms/console`）在需要时补上，上游前端同样按可选字段读取。
@JsonSerializable()
class VMGraphics extends Equatable {
  final String type;
  final String port;
  final String listen;
  final String? url;

  const VMGraphics({
    required this.type,
    required this.port,
    required this.listen,
    this.url,
  });

  factory VMGraphics.fromJson(Map<String, dynamic> json) =>
      _$VMGraphicsFromJson(json);

  Map<String, dynamic> toJson() => _$VMGraphicsToJson(this);

  @override
  List<Object?> get props => <Object?>[type, port, listen, url];
}

/// 虚拟机内存统计（dto.VMMemoryStats；单位 KiB）。
@JsonSerializable()
class VMMemoryStats extends Equatable {
  final int availableKiB;
  final int unusedKiB;
  final int usableKiB;
  final int rssKiB;
  final int actualKiB;

  const VMMemoryStats({
    required this.availableKiB,
    required this.unusedKiB,
    required this.usableKiB,
    required this.rssKiB,
    required this.actualKiB,
  });

  factory VMMemoryStats.fromJson(Map<String, dynamic> json) =>
      _$VMMemoryStatsFromJson(json);

  Map<String, dynamic> toJson() => _$VMMemoryStatsToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[availableKiB, unusedKiB, usableKiB, rssKiB, actualKiB];
}

/// 虚拟机磁盘统计（dto.VMDiskStats）。
@JsonSerializable()
class VMDiskStats extends Equatable {
  final int readBytes;
  final int writeBytes;
  final int readReqs;
  final int writeReqs;

  const VMDiskStats({
    required this.readBytes,
    required this.writeBytes,
    required this.readReqs,
    required this.writeReqs,
  });

  factory VMDiskStats.fromJson(Map<String, dynamic> json) =>
      _$VMDiskStatsFromJson(json);

  Map<String, dynamic> toJson() => _$VMDiskStatsToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[readBytes, writeBytes, readReqs, writeReqs];
}

/// 虚拟机网络统计（dto.VMNetworkStats）。
@JsonSerializable()
class VMNetworkStats extends Equatable {
  final int rxBytes;
  final int txBytes;
  final int rxPackets;
  final int txPackets;

  const VMNetworkStats({
    required this.rxBytes,
    required this.txBytes,
    required this.rxPackets,
    required this.txPackets,
  });

  factory VMNetworkStats.fromJson(Map<String, dynamic> json) =>
      _$VMNetworkStatsFromJson(json);

  Map<String, dynamic> toJson() => _$VMNetworkStatsToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[rxBytes, txBytes, rxPackets, txPackets];
}

/// 虚拟机实时统计（dto.VMStats；POST /vms/stats）。
///
/// memory / disk / network 在上游是值类型结构体，服务端一定返回这三个键。
@JsonSerializable()
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
    required this.name,
    required this.status,
    required this.timestamp,
    required this.cpuTime,
    required this.vcpu,
    required this.memory,
    required this.disk,
    required this.network,
  });

  factory VMStats.fromJson(Map<String, dynamic> json) =>
      _$VMStatsFromJson(json);

  Map<String, dynamic> toJson() => _$VMStatsToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[name, status, timestamp, cpuTime, vcpu, memory, disk, network];
}

/// 虚拟机实例（dto.VMInfo；POST /vms/info 与 /vms/search 列表项）。
///
/// graphics 是上游唯一的指针字段，虚拟机没有图形设备时为 null。
@JsonSerializable()
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
    required this.id,
    required this.name,
    required this.uuid,
    required this.cpu,
    required this.memory,
    required this.diskSize,
    required this.diskBus,
    required this.diskPath,
    required this.storagePool,
    required this.isoPaths,
    required this.imagePath,
    required this.network,
    required this.bootOrder,
    required this.autoStart,
    required this.status,
    required this.disks,
    required this.interfaces,
    this.graphics,
    required this.taskID,
    required this.createTaskID,
    required this.description,
  });

  factory VMItem.fromJson(Map<String, dynamic> json) => _$VMItemFromJson(json);

  Map<String, dynamic> toJson() => _$VMItemToJson(this);

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
@JsonSerializable()
class VMSearchResult extends Equatable {
  final List<VMItem> items;
  final int total;
  final int limit;

  const VMSearchResult({
    required this.items,
    required this.total,
    required this.limit,
  });

  factory VMSearchResult.fromJson(Map<String, dynamic> json) =>
      _$VMSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$VMSearchResultToJson(this);

  @override
  List<Object?> get props => <Object?>[items, total, limit];
}

/// 异步任务句柄（dto.VMTaskResp）。
@JsonSerializable()
class VMTaskResp extends Equatable {
  final String taskID;

  const VMTaskResp({required this.taskID});

  factory VMTaskResp.fromJson(Map<String, dynamic> json) =>
      _$VMTaskRespFromJson(json);

  Map<String, dynamic> toJson() => _$VMTaskRespToJson(this);

  @override
  List<Object?> get props => <Object?>[taskID];
}

/// 虚拟机名称请求（dto.VMReq；POST /vms/console 与快照查询）。
@JsonSerializable()
class VMReq extends Equatable {
  final String name;

  const VMReq({required this.name});

  factory VMReq.fromJson(Map<String, dynamic> json) => _$VMReqFromJson(json);

  Map<String, dynamic> toJson() => _$VMReqToJson(this);

  @override
  List<Object?> get props => <Object?>[name];
}

/// 虚拟机详情请求（dto.VMInfoReq）。
///
/// checkDisks 为 true 时服务端同步探测磁盘（上游前端 T_3M 长超时）。
@JsonSerializable()
class VMInfoReq extends Equatable {
  final String name;
  final bool checkDisks;

  const VMInfoReq({
    required this.name,
    this.checkDisks = false,
  });

  factory VMInfoReq.fromJson(Map<String, dynamic> json) =>
      _$VMInfoReqFromJson(json);

  Map<String, dynamic> toJson() => _$VMInfoReqToJson(this);

  @override
  List<Object?> get props => <Object?>[name, checkDisks];
}

/// 创建虚拟机请求（dto.VMCreate）。memory 单位 MiB。
///
/// 上游的 network 带 required 校验，其余可选项按需发送。
@JsonSerializable()
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

  factory VMCreate.fromJson(Map<String, dynamic> json) =>
      _$VMCreateFromJson(json);

  Map<String, dynamic> toJson() => _$VMCreateToJson(this);

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
@JsonSerializable()
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

  factory VMUpdate.fromJson(Map<String, dynamic> json) =>
      _$VMUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$VMUpdateToJson(this);

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
@JsonSerializable()
class VMOperate extends Equatable {
  final String name;
  final String operate;

  const VMOperate({
    required this.name,
    required this.operate,
  });

  factory VMOperate.fromJson(Map<String, dynamic> json) =>
      _$VMOperateFromJson(json);

  Map<String, dynamic> toJson() => _$VMOperateToJson(this);

  @override
  List<Object?> get props => <Object?>[name, operate];
}

/// 重命名虚拟机请求（dto.VMRename）。
@JsonSerializable()
class VMRename extends Equatable {
  final String? taskID;
  final String name;
  final String newName;

  const VMRename({
    this.taskID,
    required this.name,
    required this.newName,
  });

  factory VMRename.fromJson(Map<String, dynamic> json) =>
      _$VMRenameFromJson(json);

  Map<String, dynamic> toJson() => _$VMRenameToJson(this);

  @override
  List<Object?> get props => <Object?>[taskID, name, newName];
}

/// 磁盘扩容请求（dto.VMDiskResize）。sizeGiB 上限 8388607。
@JsonSerializable()
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

  factory VMDiskResize.fromJson(Map<String, dynamic> json) =>
      _$VMDiskResizeFromJson(json);

  Map<String, dynamic> toJson() => _$VMDiskResizeToJson(this);

  @override
  List<Object?> get props => <Object?>[taskID, name, target, sizeGiB];
}

/// 删除虚拟机请求（dto.VMDelete）。
@JsonSerializable()
class VMDelete extends Equatable {
  final String? taskID;
  final int id;
  final bool force;

  const VMDelete({
    this.taskID,
    required this.id,
    this.force = false,
  });

  factory VMDelete.fromJson(Map<String, dynamic> json) =>
      _$VMDeleteFromJson(json);

  Map<String, dynamic> toJson() => _$VMDeleteToJson(this);

  @override
  List<Object?> get props => <Object?>[taskID, id, force];
}

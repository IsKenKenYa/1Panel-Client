import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vm_resource_models.g.dart';

/// 虚拟机模板（dto.VMTemplateInfo；POST /vms/templates/list）。
@JsonSerializable()
class VMTemplateItem extends Equatable {
  final int id;
  final String name;
  final String sourceVM;
  final int cpu;
  final int memory;
  final int diskSize;
  final String diskBus;
  final String diskPath;
  final String storagePool;
  final String network;
  final String bootOrder;
  final bool isExist;
  final int size;
  final String createdAt;
  final String description;

  const VMTemplateItem({
    required this.id,
    required this.name,
    required this.sourceVM,
    required this.cpu,
    required this.memory,
    required this.diskSize,
    required this.diskBus,
    required this.diskPath,
    required this.storagePool,
    required this.network,
    required this.bootOrder,
    required this.isExist,
    required this.size,
    required this.createdAt,
    required this.description,
  });

  factory VMTemplateItem.fromJson(Map<String, dynamic> json) =>
      _$VMTemplateItemFromJson(json);

  Map<String, dynamic> toJson() => _$VMTemplateItemToJson(this);

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        sourceVM,
        cpu,
        memory,
        diskSize,
        diskBus,
        diskPath,
        storagePool,
        network,
        bootOrder,
        isExist,
        size,
        createdAt,
        description,
      ];
}

/// 从虚拟机创建模板请求（dto.VMTemplateCreate）。
@JsonSerializable()
class VMTemplateCreate extends Equatable {
  final String? taskID;
  final String name;
  final String templateName;
  final String? storagePool;
  final String? description;

  const VMTemplateCreate({
    this.taskID,
    required this.name,
    required this.templateName,
    this.storagePool,
    this.description,
  });

  factory VMTemplateCreate.fromJson(Map<String, dynamic> json) =>
      _$VMTemplateCreateFromJson(json);

  Map<String, dynamic> toJson() => _$VMTemplateCreateToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[taskID, name, templateName, storagePool, description];
}

/// 删除模板请求（dto.VMTemplateDelete）。
@JsonSerializable()
class VMTemplateDelete extends Equatable {
  final String? taskID;
  final int id;
  final bool deleteDisk;

  const VMTemplateDelete({
    this.taskID,
    required this.id,
    this.deleteDisk = false,
  });

  factory VMTemplateDelete.fromJson(Map<String, dynamic> json) =>
      _$VMTemplateDeleteFromJson(json);

  Map<String, dynamic> toJson() => _$VMTemplateDeleteToJson(this);

  @override
  List<Object?> get props => <Object?>[taskID, id, deleteDisk];
}

/// ISO 镜像记录（dto.VMIsoInfo）。
@JsonSerializable()
class VMIsoItem extends Equatable {
  final int id;
  final String type;
  final String name;
  final String path;
  final bool isExist;
  final int size;
  final String status;
  final String error;
  final String tempFileID;
  final String tempFileType;
  final String createdAt;
  final String description;

  const VMIsoItem({
    required this.id,
    required this.type,
    required this.name,
    required this.path,
    required this.isExist,
    required this.size,
    required this.status,
    required this.error,
    required this.tempFileID,
    required this.tempFileType,
    required this.createdAt,
    required this.description,
  });

  factory VMIsoItem.fromJson(Map<String, dynamic> json) =>
      _$VMIsoItemFromJson(json);

  Map<String, dynamic> toJson() => _$VMIsoItemToJson(this);

  @override
  List<Object?> get props => <Object?>[
        id,
        type,
        name,
        path,
        isExist,
        size,
        status,
        error,
        tempFileID,
        tempFileType,
        createdAt,
        description,
      ];
}

/// 新建 ISO 记录请求（dto.VMIsoCreate）。
@JsonSerializable()
class VMIsoCreate extends Equatable {
  final String type;
  final String name;
  final String path;
  final String? description;

  const VMIsoCreate({
    required this.type,
    required this.name,
    required this.path,
    this.description,
  });

  factory VMIsoCreate.fromJson(Map<String, dynamic> json) =>
      _$VMIsoCreateFromJson(json);

  Map<String, dynamic> toJson() => _$VMIsoCreateToJson(this);

  @override
  List<Object?> get props => <Object?>[type, name, path, description];
}

/// 更新 ISO 记录请求（dto.VMIsoUpdate）。
@JsonSerializable()
class VMIsoUpdate extends Equatable {
  final int id;
  final String type;
  final String name;
  final String path;
  final String? description;

  const VMIsoUpdate({
    required this.id,
    required this.type,
    required this.name,
    required this.path,
    this.description,
  });

  factory VMIsoUpdate.fromJson(Map<String, dynamic> json) =>
      _$VMIsoUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$VMIsoUpdateToJson(this);

  @override
  List<Object?> get props => <Object?>[id, type, name, path, description];
}

/// 删除 ISO 请求（dto.VMIsoDelete）。
@JsonSerializable()
class VMIsoDelete extends Equatable {
  final int id;
  final bool deleteFile;

  const VMIsoDelete({
    required this.id,
    this.deleteFile = false,
  });

  factory VMIsoDelete.fromJson(Map<String, dynamic> json) =>
      _$VMIsoDeleteFromJson(json);

  Map<String, dynamic> toJson() => _$VMIsoDeleteToJson(this);

  @override
  List<Object?> get props => <Object?>[id, deleteFile];
}

/// ISO 导入启动请求（dto.VMIsoImportStart）。
///
/// status 取值：uploading / downloading。
@JsonSerializable()
class VMIsoImportStart extends Equatable {
  final String type;
  final String name;
  final String path;
  final String? description;
  final String status;
  final String? tempFileID;
  final String? tempFileType;

  const VMIsoImportStart({
    required this.type,
    required this.name,
    required this.path,
    this.description,
    required this.status,
    this.tempFileID,
    this.tempFileType,
  });

  factory VMIsoImportStart.fromJson(Map<String, dynamic> json) =>
      _$VMIsoImportStartFromJson(json);

  Map<String, dynamic> toJson() => _$VMIsoImportStartToJson(this);

  @override
  List<Object?> get props => <Object?>[
        type,
        name,
        path,
        description,
        status,
        tempFileID,
        tempFileType,
      ];
}

/// ISO 导入状态更新请求（dto.VMIsoImportUpdate）。
///
/// status 取值：uploading / downloading / ready / failed。
@JsonSerializable()
class VMIsoImportUpdate extends Equatable {
  final int id;
  final String status;
  final String? error;
  final String? tempFileID;
  final String? tempFileType;

  const VMIsoImportUpdate({
    required this.id,
    required this.status,
    this.error,
    this.tempFileID,
    this.tempFileType,
  });

  factory VMIsoImportUpdate.fromJson(Map<String, dynamic> json) =>
      _$VMIsoImportUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$VMIsoImportUpdateToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[id, status, error, tempFileID, tempFileType];
}

/// 网络与存储池删除请求（dto.VMResourceDelete）。
@JsonSerializable()
class VMResourceDelete extends Equatable {
  final int id;
  final bool force;

  const VMResourceDelete({
    required this.id,
    this.force = false,
  });

  factory VMResourceDelete.fromJson(Map<String, dynamic> json) =>
      _$VMResourceDeleteFromJson(json);

  Map<String, dynamic> toJson() => _$VMResourceDeleteToJson(this);

  @override
  List<Object?> get props => <Object?>[id, force];
}

/// 关联虚拟机引用（dto.VMResourceRef）。
@JsonSerializable()
class VMResourceRef extends Equatable {
  final int id;
  final String name;

  const VMResourceRef({required this.id, required this.name});

  factory VMResourceRef.fromJson(Map<String, dynamic> json) =>
      _$VMResourceRefFromJson(json);

  Map<String, dynamic> toJson() => _$VMResourceRefToJson(this);

  @override
  List<Object?> get props => <Object?>[id, name];
}

/// 网络上占用的 IP（dto.VMNetworkIPUsage）。
@JsonSerializable()
class VMNetworkIPUsage extends Equatable {
  final String ip;
  final String vmName;
  final String mac;
  final String source;

  const VMNetworkIPUsage({
    required this.ip,
    required this.vmName,
    required this.mac,
    required this.source,
  });

  factory VMNetworkIPUsage.fromJson(Map<String, dynamic> json) =>
      _$VMNetworkIPUsageFromJson(json);

  Map<String, dynamic> toJson() => _$VMNetworkIPUsageToJson(this);

  @override
  List<Object?> get props => <Object?>[ip, vmName, mac, source];
}

/// 虚拟机网络（dto.VMNetworkItem）。
///
/// 上游结构体的 error 是值类型字符串，没有错误时为空串。
@JsonSerializable()
class VMNetworkItem extends Equatable {
  final int id;
  final String name;
  final String type;
  final String bridgeName;
  final String sourceInterface;
  final String cidr;
  final String gateway;
  final String dhcpStart;
  final String dhcpEnd;
  final bool autoStart;
  final String description;
  final String createdAt;
  final String status;
  final String error;
  final int vmCount;
  final List<VMResourceRef> vms;
  final bool registered;
  final List<VMNetworkIPUsage> usedIPs;

  const VMNetworkItem({
    required this.id,
    required this.name,
    required this.type,
    required this.bridgeName,
    required this.sourceInterface,
    required this.cidr,
    required this.gateway,
    required this.dhcpStart,
    required this.dhcpEnd,
    required this.autoStart,
    required this.description,
    required this.createdAt,
    required this.status,
    required this.error,
    required this.vmCount,
    required this.vms,
    required this.registered,
    required this.usedIPs,
  });

  factory VMNetworkItem.fromJson(Map<String, dynamic> json) =>
      _$VMNetworkItemFromJson(json);

  Map<String, dynamic> toJson() => _$VMNetworkItemToJson(this);

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        type,
        bridgeName,
        sourceInterface,
        cidr,
        gateway,
        dhcpStart,
        dhcpEnd,
        autoStart,
        description,
        createdAt,
        status,
        error,
        vmCount,
        vms,
        registered,
        usedIPs,
      ];
}

/// 宿主机网络接口（dto.VMNetworkInterfaceItem；GET /vms/networks/interfaces）。
@JsonSerializable()
class VMNetworkInterfaceItem extends Equatable {
  final String name;
  final List<String> addresses;

  const VMNetworkInterfaceItem({
    required this.name,
    required this.addresses,
  });

  factory VMNetworkInterfaceItem.fromJson(Map<String, dynamic> json) =>
      _$VMNetworkInterfaceItemFromJson(json);

  Map<String, dynamic> toJson() => _$VMNetworkInterfaceItemToJson(this);

  @override
  List<Object?> get props => <Object?>[name, addresses];
}

/// 宿主机网桥（dto.VMNetworkBridgeItem；GET /vms/networks/bridges）。
@JsonSerializable()
class VMNetworkBridgeItem extends Equatable {
  final String name;
  final bool recommended;
  final String description;

  const VMNetworkBridgeItem({
    required this.name,
    required this.recommended,
    required this.description,
  });

  factory VMNetworkBridgeItem.fromJson(Map<String, dynamic> json) =>
      _$VMNetworkBridgeItemFromJson(json);

  Map<String, dynamic> toJson() => _$VMNetworkBridgeItemToJson(this);

  @override
  List<Object?> get props => <Object?>[name, recommended, description];
}

/// 创建网络请求（dto.VMNetworkCreate）。type 取值：nat / bridge / macvtap。
@JsonSerializable()
class VMNetworkCreate extends Equatable {
  final String name;
  final String type;
  final String? bridgeName;
  final String? sourceInterface;
  final String? cidr;
  final String? gateway;
  final String? dhcpStart;
  final String? dhcpEnd;
  final bool autoStart;
  final String? description;

  const VMNetworkCreate({
    required this.name,
    required this.type,
    this.bridgeName,
    this.sourceInterface,
    this.cidr,
    this.gateway,
    this.dhcpStart,
    this.dhcpEnd,
    required this.autoStart,
    this.description,
  });

  factory VMNetworkCreate.fromJson(Map<String, dynamic> json) =>
      _$VMNetworkCreateFromJson(json);

  Map<String, dynamic> toJson() => _$VMNetworkCreateToJson(this);

  @override
  List<Object?> get props => <Object?>[
        name,
        type,
        bridgeName,
        sourceInterface,
        cidr,
        gateway,
        dhcpStart,
        dhcpEnd,
        autoStart,
        description,
      ];
}

/// 更新网络请求（dto.VMNetworkUpdate）。
///
/// autoStart / status / description 在上游是指针，只有显式赋值才发送。
@JsonSerializable()
class VMNetworkUpdate extends Equatable {
  final int id;
  final bool? autoStart;
  final String? status;
  final String? description;

  const VMNetworkUpdate({
    required this.id,
    this.autoStart,
    this.status,
    this.description,
  });

  factory VMNetworkUpdate.fromJson(Map<String, dynamic> json) =>
      _$VMNetworkUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$VMNetworkUpdateToJson(this);

  @override
  List<Object?> get props => <Object?>[id, autoStart, status, description];
}

/// 虚拟机存储池（dto.VMStorageItem）。
///
/// 上游结构体没有 usedPercent 字段，使用率由 capacity 与 available 计算。
@JsonSerializable()
class VMStorageItem extends Equatable {
  final int id;
  final String name;
  final String type;
  final String path;
  final bool autoStart;
  final String description;
  final String createdAt;
  final String status;
  final String error;
  final int capacity;
  final int available;
  final int vmCount;
  final List<VMResourceRef> vms;

  const VMStorageItem({
    required this.id,
    required this.name,
    required this.type,
    required this.path,
    required this.autoStart,
    required this.description,
    required this.createdAt,
    required this.status,
    required this.error,
    required this.capacity,
    required this.available,
    required this.vmCount,
    required this.vms,
  });

  factory VMStorageItem.fromJson(Map<String, dynamic> json) =>
      _$VMStorageItemFromJson(json);

  Map<String, dynamic> toJson() => _$VMStorageItemToJson(this);

  /// 已用容量占比；capacity 为 0 时返回 0。
  double get usagePercent =>
      capacity > 0 ? (capacity - available) / capacity * 100 : 0.0;

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        type,
        path,
        autoStart,
        description,
        createdAt,
        status,
        error,
        capacity,
        available,
        vmCount,
        vms,
      ];
}

/// 创建存储池请求（dto.VMStorageCreate）。type 当前仅支持 dir。
@JsonSerializable()
class VMStorageCreate extends Equatable {
  final String name;
  final String type;
  final String path;
  final bool autoStart;
  final String? description;

  const VMStorageCreate({
    required this.name,
    required this.type,
    required this.path,
    required this.autoStart,
    this.description,
  });

  factory VMStorageCreate.fromJson(Map<String, dynamic> json) =>
      _$VMStorageCreateFromJson(json);

  Map<String, dynamic> toJson() => _$VMStorageCreateToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[name, type, path, autoStart, description];
}

/// 更新存储池请求（dto.VMStorageUpdate）。
///
/// name / path 在上游是值类型，autoStart / status / description 是指针。
@JsonSerializable()
class VMStorageUpdate extends Equatable {
  final int id;
  final String? name;
  final String? path;
  final bool? autoStart;
  final String? status;
  final String? description;

  const VMStorageUpdate({
    required this.id,
    this.name,
    this.path,
    this.autoStart,
    this.status,
    this.description,
  });

  factory VMStorageUpdate.fromJson(Map<String, dynamic> json) =>
      _$VMStorageUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$VMStorageUpdateToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[id, name, path, autoStart, status, description];
}

/// 虚拟机快照（dto.VMSnapshotInfo）。
@JsonSerializable()
class VMSnapshotItem extends Equatable {
  final String name;
  final String description;
  final int createdAt;
  final String state;
  final String parent;
  final String path;
  final int size;
  final bool current;
  final int children;

  const VMSnapshotItem({
    required this.name,
    required this.description,
    required this.createdAt,
    required this.state,
    required this.parent,
    required this.path,
    required this.size,
    required this.current,
    required this.children,
  });

  factory VMSnapshotItem.fromJson(Map<String, dynamic> json) =>
      _$VMSnapshotItemFromJson(json);

  Map<String, dynamic> toJson() => _$VMSnapshotItemToJson(this);

  @override
  List<Object?> get props => <Object?>[
        name,
        description,
        createdAt,
        state,
        parent,
        path,
        size,
        current,
        children,
      ];
}

/// 快照创建/恢复/删除请求（dto.VMSnapshotReq）。
@JsonSerializable()
class VMSnapshotReq extends Equatable {
  final String? taskID;
  final String name;
  final String snapshotName;
  final String? description;

  const VMSnapshotReq({
    this.taskID,
    required this.name,
    required this.snapshotName,
    this.description,
  });

  factory VMSnapshotReq.fromJson(Map<String, dynamic> json) =>
      _$VMSnapshotReqFromJson(json);

  Map<String, dynamic> toJson() => _$VMSnapshotReqToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[taskID, name, snapshotName, description];
}

/// 孤儿数据项（dto.VMOrphanItem）。
///
/// type 取值：orphan_domain_disk / orphan_snapshot / partial_file。
@JsonSerializable()
class VMOrphanItem extends Equatable {
  final String type;
  final String path;
  final int size;
  final int modifiedAt;

  const VMOrphanItem({
    required this.type,
    required this.path,
    required this.size,
    required this.modifiedAt,
  });

  factory VMOrphanItem.fromJson(Map<String, dynamic> json) =>
      _$VMOrphanItemFromJson(json);

  Map<String, dynamic> toJson() => _$VMOrphanItemToJson(this);

  @override
  List<Object?> get props => <Object?>[type, path, size, modifiedAt];
}

/// 孤儿数据清理请求（dto.VMOrphanClean）。
@JsonSerializable()
class VMOrphanClean extends Equatable {
  final List<VMOrphanItem> items;

  const VMOrphanClean({required this.items});

  factory VMOrphanClean.fromJson(Map<String, dynamic> json) =>
      _$VMOrphanCleanFromJson(json);

  Map<String, dynamic> toJson() => _$VMOrphanCleanToJson(this);

  @override
  List<Object?> get props => <Object?>[items];
}

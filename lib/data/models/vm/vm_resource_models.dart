import 'package:equatable/equatable.dart';

/// 虚拟机模板（dto.VMTemplateInfo；POST /vms/templates/list）。
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
  final String status;
  final String error;
  final String tempFileID;
  final String tempFileType;
  final String createdAt;
  final String description;

  const VMTemplateItem({
    this.id = 0,
    this.name = '',
    this.sourceVM = '',
    this.cpu = 0,
    this.memory = 0,
    this.diskSize = 0,
    this.diskBus = '',
    this.diskPath = '',
    this.storagePool = '',
    this.network = '',
    this.bootOrder = '',
    this.isExist = false,
    this.size = 0,
    this.status = '',
    this.error = '',
    this.tempFileID = '',
    this.tempFileType = '',
    this.createdAt = '',
    this.description = '',
  });

  factory VMTemplateItem.fromJson(Map<String, dynamic> json) {
    return VMTemplateItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      sourceVM: json['sourceVM'] as String? ?? '',
      cpu: json['cpu'] as int? ?? 0,
      memory: json['memory'] as int? ?? 0,
      diskSize: json['diskSize'] as int? ?? 0,
      diskBus: json['diskBus'] as String? ?? '',
      diskPath: json['diskPath'] as String? ?? '',
      storagePool: json['storagePool'] as String? ?? '',
      network: json['network'] as String? ?? '',
      bootOrder: json['bootOrder'] as String? ?? '',
      isExist: json['isExist'] as bool? ?? false,
      size: json['size'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      error: json['error'] as String? ?? '',
      tempFileID: json['tempFileID'] as String? ?? '',
      tempFileType: json['tempFileType'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

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
        status,
        error,
        tempFileID,
        tempFileType,
        createdAt,
        description,
      ];
}

/// 从虚拟机创建模板请求（dto.VMTemplateCreate）。
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (taskID != null) 'taskID': taskID,
        'name': name,
        'templateName': templateName,
        if (storagePool != null) 'storagePool': storagePool,
        if (description != null) 'description': description,
      };

  @override
  List<Object?> get props =>
      <Object?>[taskID, name, templateName, storagePool, description];
}

/// 删除模板请求（dto.VMTemplateDelete）。
class VMTemplateDelete extends Equatable {
  final String? taskID;
  final int id;
  final bool deleteDisk;

  const VMTemplateDelete({
    this.taskID,
    required this.id,
    this.deleteDisk = false,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (taskID != null) 'taskID': taskID,
        'id': id,
        'deleteDisk': deleteDisk,
      };

  @override
  List<Object?> get props => <Object?>[taskID, id, deleteDisk];
}

/// ISO 镜像记录（dto.VMIsoInfo）。
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
    this.id = 0,
    this.type = '',
    this.name = '',
    this.path = '',
    this.isExist = false,
    this.size = 0,
    this.status = '',
    this.error = '',
    this.tempFileID = '',
    this.tempFileType = '',
    this.createdAt = '',
    this.description = '',
  });

  factory VMIsoItem.fromJson(Map<String, dynamic> json) {
    return VMIsoItem(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      isExist: json['isExist'] as bool? ?? false,
      size: json['size'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      error: json['error'] as String? ?? '',
      tempFileID: json['tempFileID'] as String? ?? '',
      tempFileType: json['tempFileType'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'name': name,
        'path': path,
        if (description != null) 'description': description,
      };

  @override
  List<Object?> get props => <Object?>[type, name, path, description];
}

/// 更新 ISO 记录请求（dto.VMIsoUpdate）。
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'name': name,
        'path': path,
        if (description != null) 'description': description,
      };

  @override
  List<Object?> get props => <Object?>[id, type, name, path, description];
}

/// 删除 ISO 请求（dto.VMIsoDelete）。
class VMIsoDelete extends Equatable {
  final int id;
  final bool deleteFile;

  const VMIsoDelete({
    required this.id,
    this.deleteFile = false,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'deleteFile': deleteFile,
      };

  @override
  List<Object?> get props => <Object?>[id, deleteFile];
}

/// ISO 导入启动请求（dto.VMIsoImportStart）。
///
/// status 取值：uploading / downloading。
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'name': name,
        'path': path,
        if (description != null) 'description': description,
        'status': status,
        if (tempFileID != null) 'tempFileID': tempFileID,
        if (tempFileType != null) 'tempFileType': tempFileType,
      };

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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'status': status,
        if (error != null) 'error': error,
        if (tempFileID != null) 'tempFileID': tempFileID,
        if (tempFileType != null) 'tempFileType': tempFileType,
      };

  @override
  List<Object?> get props =>
      <Object?>[id, status, error, tempFileID, tempFileType];
}

/// 网络与存储池删除请求（dto.VMResourceDelete）。
class VMResourceDelete extends Equatable {
  final int id;
  final bool? force;

  const VMResourceDelete({
    required this.id,
    this.force,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        if (force != null) 'force': force,
      };

  @override
  List<Object?> get props => <Object?>[id, force];
}

/// 关联虚拟机引用（dto.VMResourceRef）。
class VMResourceRef extends Equatable {
  final int id;
  final String name;

  const VMResourceRef({this.id = 0, this.name = ''});

  factory VMResourceRef.fromJson(Map<String, dynamic> json) {
    return VMResourceRef(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[id, name];
}

/// 网络上占用的 IP（dto.VMNetworkIPUsage）。
class VMNetworkIPUsage extends Equatable {
  final String ip;
  final String vmName;
  final String mac;
  final String source;

  const VMNetworkIPUsage({
    this.ip = '',
    this.vmName = '',
    this.mac = '',
    this.source = '',
  });

  factory VMNetworkIPUsage.fromJson(Map<String, dynamic> json) {
    return VMNetworkIPUsage(
      ip: json['ip'] as String? ?? '',
      vmName: json['vmName'] as String? ?? '',
      mac: json['mac'] as String? ?? '',
      source: json['source'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[ip, vmName, mac, source];
}

/// 虚拟机网络（dto.VMNetworkItem）。
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
  final String? error;
  final int vmCount;
  final List<VMResourceRef> vms;
  final bool registered;
  final List<VMNetworkIPUsage> usedIPs;

  const VMNetworkItem({
    this.id = 0,
    this.name = '',
    this.type = '',
    this.bridgeName = '',
    this.sourceInterface = '',
    this.cidr = '',
    this.gateway = '',
    this.dhcpStart = '',
    this.dhcpEnd = '',
    this.autoStart = false,
    this.description = '',
    this.createdAt = '',
    this.status = '',
    this.error,
    this.vmCount = 0,
    this.vms = const <VMResourceRef>[],
    this.registered = false,
    this.usedIPs = const <VMNetworkIPUsage>[],
  });

  factory VMNetworkItem.fromJson(Map<String, dynamic> json) {
    return VMNetworkItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      bridgeName: json['bridgeName'] as String? ?? '',
      sourceInterface: json['sourceInterface'] as String? ?? '',
      cidr: json['cidr'] as String? ?? '',
      gateway: json['gateway'] as String? ?? '',
      dhcpStart: json['dhcpStart'] as String? ?? '',
      dhcpEnd: json['dhcpEnd'] as String? ?? '',
      autoStart: json['autoStart'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      status: json['status'] as String? ?? '',
      error: json['error'] as String?,
      vmCount: json['vmCount'] as int? ?? 0,
      vms: (json['vms'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(VMResourceRef.fromJson)
              .toList(growable: false) ??
          const <VMResourceRef>[],
      registered: json['registered'] as bool? ?? false,
      usedIPs: (json['usedIPs'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(VMNetworkIPUsage.fromJson)
              .toList(growable: false) ??
          const <VMNetworkIPUsage>[],
    );
  }

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
class VMNetworkInterfaceItem extends Equatable {
  final String name;
  final List<String> addresses;

  const VMNetworkInterfaceItem({
    this.name = '',
    this.addresses = const <String>[],
  });

  factory VMNetworkInterfaceItem.fromJson(Map<String, dynamic> json) {
    return VMNetworkInterfaceItem(
      name: json['name'] as String? ?? '',
      addresses: (json['addresses'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
    );
  }

  @override
  List<Object?> get props => <Object?>[name, addresses];
}

/// 宿主机网桥（dto.VMNetworkBridgeItem；GET /vms/networks/bridges）。
class VMNetworkBridgeItem extends Equatable {
  final String name;
  final bool recommended;
  final String description;

  const VMNetworkBridgeItem({
    this.name = '',
    this.recommended = false,
    this.description = '',
  });

  factory VMNetworkBridgeItem.fromJson(Map<String, dynamic> json) {
    return VMNetworkBridgeItem(
      name: json['name'] as String? ?? '',
      recommended: json['recommended'] as bool? ?? false,
      description: json['description'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[name, recommended, description];
}

/// 创建网络请求（dto.VMNetworkCreate）。type 取值：nat / bridge / macvtap。
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'type': type,
        if (bridgeName != null) 'bridgeName': bridgeName,
        if (sourceInterface != null) 'sourceInterface': sourceInterface,
        if (cidr != null) 'cidr': cidr,
        if (gateway != null) 'gateway': gateway,
        if (dhcpStart != null) 'dhcpStart': dhcpStart,
        if (dhcpEnd != null) 'dhcpEnd': dhcpEnd,
        'autoStart': autoStart,
        if (description != null) 'description': description,
      };

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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        if (autoStart != null) 'autoStart': autoStart,
        if (status != null) 'status': status,
        if (description != null) 'description': description,
      };

  @override
  List<Object?> get props => <Object?>[id, autoStart, status, description];
}

/// 虚拟机存储池（dto.VMStorageItem）。
class VMStorageItem extends Equatable {
  final int id;
  final String name;
  final String type;
  final String path;
  final bool autoStart;
  final String description;
  final String createdAt;
  final String status;
  final String? error;
  final int capacity;
  final int available;
  final double? usedPercent;
  final int vmCount;
  final List<VMResourceRef> vms;

  const VMStorageItem({
    this.id = 0,
    this.name = '',
    this.type = '',
    this.path = '',
    this.autoStart = false,
    this.description = '',
    this.createdAt = '',
    this.status = '',
    this.error,
    this.capacity = 0,
    this.available = 0,
    this.usedPercent,
    this.vmCount = 0,
    this.vms = const <VMResourceRef>[],
  });

  factory VMStorageItem.fromJson(Map<String, dynamic> json) {
    return VMStorageItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      path: json['path'] as String? ?? '',
      autoStart: json['autoStart'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      status: json['status'] as String? ?? '',
      error: json['error'] as String?,
      capacity: json['capacity'] as int? ?? 0,
      available: json['available'] as int? ?? 0,
      usedPercent: (json['usedPercent'] as num?)?.toDouble(),
      vmCount: json['vmCount'] as int? ?? 0,
      vms: (json['vms'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(VMResourceRef.fromJson)
              .toList(growable: false) ??
          const <VMResourceRef>[],
    );
  }

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
        usedPercent,
        vmCount,
        vms,
      ];
}

/// 创建存储池请求（dto.VMStorageCreate）。type 当前仅支持 dir。
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'type': type,
        'path': path,
        'autoStart': autoStart,
        if (description != null) 'description': description,
      };

  @override
  List<Object?> get props =>
      <Object?>[name, type, path, autoStart, description];
}

/// 更新存储池请求（dto.VMStorageUpdate）。
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        if (name != null) 'name': name,
        if (path != null) 'path': path,
        if (autoStart != null) 'autoStart': autoStart,
        if (status != null) 'status': status,
        if (description != null) 'description': description,
      };

  @override
  List<Object?> get props =>
      <Object?>[id, name, path, autoStart, status, description];
}

/// 虚拟机快照（dto.VMSnapshotInfo）。
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
    this.name = '',
    this.description = '',
    this.createdAt = 0,
    this.state = '',
    this.parent = '',
    this.path = '',
    this.size = 0,
    this.current = false,
    this.children = 0,
  });

  factory VMSnapshotItem.fromJson(Map<String, dynamic> json) {
    return VMSnapshotItem(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] as int? ?? 0,
      state: json['state'] as String? ?? '',
      parent: json['parent'] as String? ?? '',
      path: json['path'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      current: json['current'] as bool? ?? false,
      children: json['children'] as int? ?? 0,
    );
  }

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

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (taskID != null) 'taskID': taskID,
        'name': name,
        'snapshotName': snapshotName,
        if (description != null) 'description': description,
      };

  @override
  List<Object?> get props =>
      <Object?>[taskID, name, snapshotName, description];
}

/// 孤儿数据项（dto.VMOrphanItem）。
///
/// type 取值：orphan_domain_disk / orphan_snapshot / partial_file。
class VMOrphanItem extends Equatable {
  final String type;
  final String path;
  final int size;
  final int modifiedAt;

  const VMOrphanItem({
    required this.type,
    required this.path,
    this.size = 0,
    this.modifiedAt = 0,
  });

  factory VMOrphanItem.fromJson(Map<String, dynamic> json) {
    return VMOrphanItem(
      type: json['type'] as String? ?? '',
      path: json['path'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      modifiedAt: json['modifiedAt'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'path': path,
        'size': size,
        'modifiedAt': modifiedAt,
      };

  @override
  List<Object?> get props => <Object?>[type, path, size, modifiedAt];
}

/// 孤儿数据清理请求（dto.VMOrphanClean）。
class VMOrphanClean extends Equatable {
  final List<VMOrphanItem> items;

  const VMOrphanClean({required this.items});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'items': items.map((VMOrphanItem item) => item.toJson()).toList(),
      };

  @override
  List<Object?> get props => <Object?>[items];
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vm_resource_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VMTemplateItem _$VMTemplateItemFromJson(Map<String, dynamic> json) =>
    VMTemplateItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      sourceVM: json['sourceVM'] as String,
      cpu: (json['cpu'] as num).toInt(),
      memory: (json['memory'] as num).toInt(),
      diskSize: (json['diskSize'] as num).toInt(),
      diskBus: json['diskBus'] as String,
      diskPath: json['diskPath'] as String,
      storagePool: json['storagePool'] as String,
      network: json['network'] as String,
      bootOrder: json['bootOrder'] as String,
      isExist: json['isExist'] as bool,
      size: (json['size'] as num).toInt(),
      createdAt: json['createdAt'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$VMTemplateItemToJson(VMTemplateItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sourceVM': instance.sourceVM,
      'cpu': instance.cpu,
      'memory': instance.memory,
      'diskSize': instance.diskSize,
      'diskBus': instance.diskBus,
      'diskPath': instance.diskPath,
      'storagePool': instance.storagePool,
      'network': instance.network,
      'bootOrder': instance.bootOrder,
      'isExist': instance.isExist,
      'size': instance.size,
      'createdAt': instance.createdAt,
      'description': instance.description,
    };

VMTemplateCreate _$VMTemplateCreateFromJson(Map<String, dynamic> json) =>
    VMTemplateCreate(
      taskID: json['taskID'] as String?,
      name: json['name'] as String,
      templateName: json['templateName'] as String,
      storagePool: json['storagePool'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$VMTemplateCreateToJson(VMTemplateCreate instance) =>
    <String, dynamic>{
      'taskID': instance.taskID,
      'name': instance.name,
      'templateName': instance.templateName,
      'storagePool': instance.storagePool,
      'description': instance.description,
    };

VMTemplateDelete _$VMTemplateDeleteFromJson(Map<String, dynamic> json) =>
    VMTemplateDelete(
      taskID: json['taskID'] as String?,
      id: (json['id'] as num).toInt(),
      deleteDisk: json['deleteDisk'] as bool? ?? false,
    );

Map<String, dynamic> _$VMTemplateDeleteToJson(VMTemplateDelete instance) =>
    <String, dynamic>{
      'taskID': instance.taskID,
      'id': instance.id,
      'deleteDisk': instance.deleteDisk,
    };

VMIsoItem _$VMIsoItemFromJson(Map<String, dynamic> json) => VMIsoItem(
  id: (json['id'] as num).toInt(),
  type: json['type'] as String,
  name: json['name'] as String,
  path: json['path'] as String,
  isExist: json['isExist'] as bool,
  size: (json['size'] as num).toInt(),
  status: json['status'] as String,
  error: json['error'] as String,
  tempFileID: json['tempFileID'] as String,
  tempFileType: json['tempFileType'] as String,
  createdAt: json['createdAt'] as String,
  description: json['description'] as String,
);

Map<String, dynamic> _$VMIsoItemToJson(VMIsoItem instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'name': instance.name,
  'path': instance.path,
  'isExist': instance.isExist,
  'size': instance.size,
  'status': instance.status,
  'error': instance.error,
  'tempFileID': instance.tempFileID,
  'tempFileType': instance.tempFileType,
  'createdAt': instance.createdAt,
  'description': instance.description,
};

VMIsoCreate _$VMIsoCreateFromJson(Map<String, dynamic> json) => VMIsoCreate(
  type: json['type'] as String,
  name: json['name'] as String,
  path: json['path'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$VMIsoCreateToJson(VMIsoCreate instance) =>
    <String, dynamic>{
      'type': instance.type,
      'name': instance.name,
      'path': instance.path,
      'description': instance.description,
    };

VMIsoUpdate _$VMIsoUpdateFromJson(Map<String, dynamic> json) => VMIsoUpdate(
  id: (json['id'] as num).toInt(),
  type: json['type'] as String,
  name: json['name'] as String,
  path: json['path'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$VMIsoUpdateToJson(VMIsoUpdate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'name': instance.name,
      'path': instance.path,
      'description': instance.description,
    };

VMIsoDelete _$VMIsoDeleteFromJson(Map<String, dynamic> json) => VMIsoDelete(
  id: (json['id'] as num).toInt(),
  deleteFile: json['deleteFile'] as bool? ?? false,
);

Map<String, dynamic> _$VMIsoDeleteToJson(VMIsoDelete instance) =>
    <String, dynamic>{'id': instance.id, 'deleteFile': instance.deleteFile};

VMIsoImportStart _$VMIsoImportStartFromJson(Map<String, dynamic> json) =>
    VMIsoImportStart(
      type: json['type'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      tempFileID: json['tempFileID'] as String?,
      tempFileType: json['tempFileType'] as String?,
    );

Map<String, dynamic> _$VMIsoImportStartToJson(VMIsoImportStart instance) =>
    <String, dynamic>{
      'type': instance.type,
      'name': instance.name,
      'path': instance.path,
      'description': instance.description,
      'status': instance.status,
      'tempFileID': instance.tempFileID,
      'tempFileType': instance.tempFileType,
    };

VMIsoImportUpdate _$VMIsoImportUpdateFromJson(Map<String, dynamic> json) =>
    VMIsoImportUpdate(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String,
      error: json['error'] as String?,
      tempFileID: json['tempFileID'] as String?,
      tempFileType: json['tempFileType'] as String?,
    );

Map<String, dynamic> _$VMIsoImportUpdateToJson(VMIsoImportUpdate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'error': instance.error,
      'tempFileID': instance.tempFileID,
      'tempFileType': instance.tempFileType,
    };

VMResourceDelete _$VMResourceDeleteFromJson(Map<String, dynamic> json) =>
    VMResourceDelete(
      id: (json['id'] as num).toInt(),
      force: json['force'] as bool? ?? false,
    );

Map<String, dynamic> _$VMResourceDeleteToJson(VMResourceDelete instance) =>
    <String, dynamic>{'id': instance.id, 'force': instance.force};

VMResourceRef _$VMResourceRefFromJson(Map<String, dynamic> json) =>
    VMResourceRef(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$VMResourceRefToJson(VMResourceRef instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

VMNetworkIPUsage _$VMNetworkIPUsageFromJson(Map<String, dynamic> json) =>
    VMNetworkIPUsage(
      ip: json['ip'] as String,
      vmName: json['vmName'] as String,
      mac: json['mac'] as String,
      source: json['source'] as String,
    );

Map<String, dynamic> _$VMNetworkIPUsageToJson(VMNetworkIPUsage instance) =>
    <String, dynamic>{
      'ip': instance.ip,
      'vmName': instance.vmName,
      'mac': instance.mac,
      'source': instance.source,
    };

VMNetworkItem _$VMNetworkItemFromJson(Map<String, dynamic> json) =>
    VMNetworkItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String,
      bridgeName: json['bridgeName'] as String,
      sourceInterface: json['sourceInterface'] as String,
      cidr: json['cidr'] as String,
      gateway: json['gateway'] as String,
      dhcpStart: json['dhcpStart'] as String,
      dhcpEnd: json['dhcpEnd'] as String,
      autoStart: json['autoStart'] as bool,
      description: json['description'] as String,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String,
      error: json['error'] as String,
      vmCount: (json['vmCount'] as num).toInt(),
      vms: (json['vms'] as List<dynamic>)
          .map((e) => VMResourceRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      registered: json['registered'] as bool,
      usedIPs: (json['usedIPs'] as List<dynamic>)
          .map((e) => VMNetworkIPUsage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$VMNetworkItemToJson(VMNetworkItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'bridgeName': instance.bridgeName,
      'sourceInterface': instance.sourceInterface,
      'cidr': instance.cidr,
      'gateway': instance.gateway,
      'dhcpStart': instance.dhcpStart,
      'dhcpEnd': instance.dhcpEnd,
      'autoStart': instance.autoStart,
      'description': instance.description,
      'createdAt': instance.createdAt,
      'status': instance.status,
      'error': instance.error,
      'vmCount': instance.vmCount,
      'vms': instance.vms,
      'registered': instance.registered,
      'usedIPs': instance.usedIPs,
    };

VMNetworkInterfaceItem _$VMNetworkInterfaceItemFromJson(
  Map<String, dynamic> json,
) => VMNetworkInterfaceItem(
  name: json['name'] as String,
  addresses: (json['addresses'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$VMNetworkInterfaceItemToJson(
  VMNetworkInterfaceItem instance,
) => <String, dynamic>{'name': instance.name, 'addresses': instance.addresses};

VMNetworkBridgeItem _$VMNetworkBridgeItemFromJson(Map<String, dynamic> json) =>
    VMNetworkBridgeItem(
      name: json['name'] as String,
      recommended: json['recommended'] as bool,
      description: json['description'] as String,
    );

Map<String, dynamic> _$VMNetworkBridgeItemToJson(
  VMNetworkBridgeItem instance,
) => <String, dynamic>{
  'name': instance.name,
  'recommended': instance.recommended,
  'description': instance.description,
};

VMNetworkCreate _$VMNetworkCreateFromJson(Map<String, dynamic> json) =>
    VMNetworkCreate(
      name: json['name'] as String,
      type: json['type'] as String,
      bridgeName: json['bridgeName'] as String?,
      sourceInterface: json['sourceInterface'] as String?,
      cidr: json['cidr'] as String?,
      gateway: json['gateway'] as String?,
      dhcpStart: json['dhcpStart'] as String?,
      dhcpEnd: json['dhcpEnd'] as String?,
      autoStart: json['autoStart'] as bool,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$VMNetworkCreateToJson(VMNetworkCreate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'bridgeName': instance.bridgeName,
      'sourceInterface': instance.sourceInterface,
      'cidr': instance.cidr,
      'gateway': instance.gateway,
      'dhcpStart': instance.dhcpStart,
      'dhcpEnd': instance.dhcpEnd,
      'autoStart': instance.autoStart,
      'description': instance.description,
    };

VMNetworkUpdate _$VMNetworkUpdateFromJson(Map<String, dynamic> json) =>
    VMNetworkUpdate(
      id: (json['id'] as num).toInt(),
      autoStart: json['autoStart'] as bool?,
      status: json['status'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$VMNetworkUpdateToJson(VMNetworkUpdate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'autoStart': instance.autoStart,
      'status': instance.status,
      'description': instance.description,
    };

VMStorageItem _$VMStorageItemFromJson(Map<String, dynamic> json) =>
    VMStorageItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String,
      path: json['path'] as String,
      autoStart: json['autoStart'] as bool,
      description: json['description'] as String,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String,
      error: json['error'] as String,
      capacity: (json['capacity'] as num).toInt(),
      available: (json['available'] as num).toInt(),
      vmCount: (json['vmCount'] as num).toInt(),
      vms: (json['vms'] as List<dynamic>)
          .map((e) => VMResourceRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$VMStorageItemToJson(VMStorageItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'path': instance.path,
      'autoStart': instance.autoStart,
      'description': instance.description,
      'createdAt': instance.createdAt,
      'status': instance.status,
      'error': instance.error,
      'capacity': instance.capacity,
      'available': instance.available,
      'vmCount': instance.vmCount,
      'vms': instance.vms,
    };

VMStorageCreate _$VMStorageCreateFromJson(Map<String, dynamic> json) =>
    VMStorageCreate(
      name: json['name'] as String,
      type: json['type'] as String,
      path: json['path'] as String,
      autoStart: json['autoStart'] as bool,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$VMStorageCreateToJson(VMStorageCreate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'path': instance.path,
      'autoStart': instance.autoStart,
      'description': instance.description,
    };

VMStorageUpdate _$VMStorageUpdateFromJson(Map<String, dynamic> json) =>
    VMStorageUpdate(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      path: json['path'] as String?,
      autoStart: json['autoStart'] as bool?,
      status: json['status'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$VMStorageUpdateToJson(VMStorageUpdate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'path': instance.path,
      'autoStart': instance.autoStart,
      'status': instance.status,
      'description': instance.description,
    };

VMSnapshotItem _$VMSnapshotItemFromJson(Map<String, dynamic> json) =>
    VMSnapshotItem(
      name: json['name'] as String,
      description: json['description'] as String,
      createdAt: (json['createdAt'] as num).toInt(),
      state: json['state'] as String,
      parent: json['parent'] as String,
      path: json['path'] as String,
      size: (json['size'] as num).toInt(),
      current: json['current'] as bool,
      children: (json['children'] as num).toInt(),
    );

Map<String, dynamic> _$VMSnapshotItemToJson(VMSnapshotItem instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'createdAt': instance.createdAt,
      'state': instance.state,
      'parent': instance.parent,
      'path': instance.path,
      'size': instance.size,
      'current': instance.current,
      'children': instance.children,
    };

VMSnapshotReq _$VMSnapshotReqFromJson(Map<String, dynamic> json) =>
    VMSnapshotReq(
      taskID: json['taskID'] as String?,
      name: json['name'] as String,
      snapshotName: json['snapshotName'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$VMSnapshotReqToJson(VMSnapshotReq instance) =>
    <String, dynamic>{
      'taskID': instance.taskID,
      'name': instance.name,
      'snapshotName': instance.snapshotName,
      'description': instance.description,
    };

VMOrphanItem _$VMOrphanItemFromJson(Map<String, dynamic> json) => VMOrphanItem(
  type: json['type'] as String,
  path: json['path'] as String,
  size: (json['size'] as num).toInt(),
  modifiedAt: (json['modifiedAt'] as num).toInt(),
);

Map<String, dynamic> _$VMOrphanItemToJson(VMOrphanItem instance) =>
    <String, dynamic>{
      'type': instance.type,
      'path': instance.path,
      'size': instance.size,
      'modifiedAt': instance.modifiedAt,
    };

VMOrphanClean _$VMOrphanCleanFromJson(Map<String, dynamic> json) =>
    VMOrphanClean(
      items: (json['items'] as List<dynamic>)
          .map((e) => VMOrphanItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$VMOrphanCleanToJson(VMOrphanClean instance) =>
    <String, dynamic>{'items': instance.items};

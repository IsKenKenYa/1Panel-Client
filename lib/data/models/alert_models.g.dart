// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertInfo _$AlertInfoFromJson(Map<String, dynamic> json) => AlertInfo(
  id: (json['id'] as num).toInt(),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
  type: json['type'] as String,
  subType: json['subType'] as String,
  cycle: (json['cycle'] as num).toInt(),
  count: (json['count'] as num).toInt(),
  interval: (json['interval'] as num).toInt(),
  method: json['method'] as String,
  title: json['title'] as String,
  taskName: json['taskName'] as String?,
  project: json['project'] as String,
  status: json['status'] as String,
  sendCount: (json['sendCount'] as num).toInt(),
  sendMethod: (json['sendMethod'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  advancedParams: json['advancedParams'] as String,
  alertTriggerMode: json['alertTriggerMode'] as String?,
  createUser: json['createUser'] as String?,
  updateUser: json['updateUser'] as String?,
);

Map<String, dynamic> _$AlertInfoToJson(AlertInfo instance) => <String, dynamic>{
  'id': instance.id,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'type': instance.type,
  'subType': instance.subType,
  'cycle': instance.cycle,
  'count': instance.count,
  'interval': instance.interval,
  'method': instance.method,
  'title': instance.title,
  'taskName': instance.taskName,
  'project': instance.project,
  'status': instance.status,
  'sendCount': instance.sendCount,
  'sendMethod': instance.sendMethod,
  'advancedParams': instance.advancedParams,
  'alertTriggerMode': instance.alertTriggerMode,
  'createUser': instance.createUser,
  'updateUser': instance.updateUser,
};

AlertDetail _$AlertDetailFromJson(Map<String, dynamic> json) => AlertDetail(
  type: json['type'] as String,
  subType: json['subType'] as String?,
  licenseId: json['licenseId'] as String,
  title: json['title'] as String,
  project: json['project'] as String,
  method: json['method'] as String,
  params: json['params'],
);

Map<String, dynamic> _$AlertDetailToJson(AlertDetail instance) =>
    <String, dynamic>{
      'type': instance.type,
      'subType': instance.subType,
      'licenseId': instance.licenseId,
      'title': instance.title,
      'project': instance.project,
      'method': instance.method,
      'params': instance.params,
    };

AlertLog _$AlertLogFromJson(Map<String, dynamic> json) => AlertLog(
  id: (json['id'] as num).toInt(),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
  alertId: (json['alertId'] as num).toInt(),
  alertDetail: AlertDetail.fromJson(
    json['alertDetail'] as Map<String, dynamic>,
  ),
  alertRule: AlertInfo.fromJson(json['alertRule'] as Map<String, dynamic>),
  count: (json['count'] as num).toInt(),
  message: json['message'] as String,
  status: json['status'] as String,
  method: json['method'] as String,
);

Map<String, dynamic> _$AlertLogToJson(AlertLog instance) => <String, dynamic>{
  'id': instance.id,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'alertId': instance.alertId,
  'alertDetail': instance.alertDetail,
  'alertRule': instance.alertRule,
  'count': instance.count,
  'message': instance.message,
  'status': instance.status,
  'method': instance.method,
};

AlertDisk _$AlertDiskFromJson(Map<String, dynamic> json) => AlertDisk(
  path: json['path'] as String,
  type: json['type'] as String,
  device: json['device'] as String,
  total: (json['total'] as num).toInt(),
  free: (json['free'] as num).toInt(),
  used: (json['used'] as num).toInt(),
  usedPercent: (json['usedPercent'] as num).toDouble(),
  inodesTotal: (json['inodesTotal'] as num).toInt(),
  inodesUsed: (json['inodesUsed'] as num).toInt(),
  inodesFree: (json['inodesFree'] as num).toInt(),
  inodesUsedPercent: (json['inodesUsedPercent'] as num).toDouble(),
);

Map<String, dynamic> _$AlertDiskToJson(AlertDisk instance) => <String, dynamic>{
  'path': instance.path,
  'type': instance.type,
  'device': instance.device,
  'total': instance.total,
  'free': instance.free,
  'used': instance.used,
  'usedPercent': instance.usedPercent,
  'inodesTotal': instance.inodesTotal,
  'inodesUsed': instance.inodesUsed,
  'inodesFree': instance.inodesFree,
  'inodesUsedPercent': instance.inodesUsedPercent,
};

AlertClam _$AlertClamFromJson(Map<String, dynamic> json) => AlertClam(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  status: json['status'] as String,
  path: json['path'] as String,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$AlertClamToJson(AlertClam instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'status': instance.status,
  'path': instance.path,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

AlertCronJob _$AlertCronJobFromJson(Map<String, dynamic> json) => AlertCronJob(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  type: json['type'] as String,
  status: json['status'] as String,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$AlertCronJobToJson(AlertCronJob instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

AlertSearch _$AlertSearchFromJson(Map<String, dynamic> json) => AlertSearch(
  page: (json['page'] as num?)?.toInt() ?? 1,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
  type: json['type'] as String?,
  status: json['status'] as String?,
  method: json['method'] as String?,
  orderBy: json['orderBy'] as String,
  order: json['order'] as String,
);

Map<String, dynamic> _$AlertSearchToJson(AlertSearch instance) =>
    <String, dynamic>{
      'page': instance.page,
      'pageSize': instance.pageSize,
      'type': instance.type,
      'status': instance.status,
      'method': instance.method,
      'orderBy': instance.orderBy,
      'order': instance.order,
    };

AlertCreate _$AlertCreateFromJson(Map<String, dynamic> json) => AlertCreate(
  type: json['type'] as String,
  method: json['method'] as String,
  cycle: (json['cycle'] as num?)?.toInt(),
  count: (json['count'] as num?)?.toInt(),
  interval: (json['interval'] as num?)?.toInt(),
  project: json['project'] as String?,
  status: json['status'] as String?,
  title: json['title'] as String?,
  sendCount: (json['sendCount'] as num?)?.toInt(),
  advancedParams: json['advancedParams'] as String?,
);

Map<String, dynamic> _$AlertCreateToJson(AlertCreate instance) =>
    <String, dynamic>{
      'type': instance.type,
      'method': instance.method,
      'cycle': instance.cycle,
      'count': instance.count,
      'interval': instance.interval,
      'project': instance.project,
      'status': instance.status,
      'title': instance.title,
      'sendCount': instance.sendCount,
      'advancedParams': instance.advancedParams,
    };

AlertUpdate _$AlertUpdateFromJson(Map<String, dynamic> json) => AlertUpdate(
  id: (json['id'] as num).toInt(),
  type: json['type'] as String?,
  method: json['method'] as String?,
  cycle: (json['cycle'] as num?)?.toInt(),
  count: (json['count'] as num?)?.toInt(),
  interval: (json['interval'] as num?)?.toInt(),
  project: json['project'] as String?,
  status: json['status'] as String?,
  title: json['title'] as String?,
  sendCount: (json['sendCount'] as num?)?.toInt(),
  advancedParams: json['advancedParams'] as String?,
);

Map<String, dynamic> _$AlertUpdateToJson(AlertUpdate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'method': instance.method,
      'cycle': instance.cycle,
      'count': instance.count,
      'interval': instance.interval,
      'project': instance.project,
      'status': instance.status,
      'title': instance.title,
      'sendCount': instance.sendCount,
      'advancedParams': instance.advancedParams,
    };

AlertUpdateStatus _$AlertUpdateStatusFromJson(Map<String, dynamic> json) =>
    AlertUpdateStatus(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$AlertUpdateStatusToJson(AlertUpdateStatus instance) =>
    <String, dynamic>{'id': instance.id, 'status': instance.status};

AlertLogSearch _$AlertLogSearchFromJson(Map<String, dynamic> json) =>
    AlertLogSearch(
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      status: json['status'] as String?,
      count: (json['count'] as num?)?.toInt(),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
    );

Map<String, dynamic> _$AlertLogSearchToJson(AlertLogSearch instance) =>
    <String, dynamic>{
      'page': instance.page,
      'pageSize': instance.pageSize,
      'status': instance.status,
      'count': instance.count,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
    };

AlertCronJobReq _$AlertCronJobReqFromJson(Map<String, dynamic> json) =>
    AlertCronJobReq(
      name: json['name'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$AlertCronJobReqToJson(AlertCronJobReq instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'status': instance.status,
    };

AlertConfigInfo _$AlertConfigInfoFromJson(Map<String, dynamic> json) =>
    AlertConfigInfo(
      id: (json['id'] as num).toInt(),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      config: json['config'] as String,
      status: json['status'] as String,
      createUser: json['createUser'] as String?,
      updateUser: json['updateUser'] as String?,
    );

Map<String, dynamic> _$AlertConfigInfoToJson(AlertConfigInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'type': instance.type,
      'title': instance.title,
      'config': instance.config,
      'status': instance.status,
      'createUser': instance.createUser,
      'updateUser': instance.updateUser,
    };

AlertConfigFilterReq _$AlertConfigFilterReqFromJson(
  Map<String, dynamic> json,
) => AlertConfigFilterReq(
  excludeTypes: (json['excludeTypes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$AlertConfigFilterReqToJson(
  AlertConfigFilterReq instance,
) => <String, dynamic>{'excludeTypes': instance.excludeTypes};

AlertConfigPageReq _$AlertConfigPageReqFromJson(Map<String, dynamic> json) =>
    AlertConfigPageReq(
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      excludeTypes: (json['excludeTypes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AlertConfigPageReqToJson(AlertConfigPageReq instance) =>
    <String, dynamic>{
      'page': instance.page,
      'pageSize': instance.pageSize,
      'excludeTypes': instance.excludeTypes,
    };

AlertConfigUpdate _$AlertConfigUpdateFromJson(Map<String, dynamic> json) =>
    AlertConfigUpdate(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String?,
      title: json['title'] as String?,
      config: json['config'] as String?,
      status: json['status'] as String?,
      displayName: json['displayName'] as String?,
      revision: json['revision'] as String?,
    );

Map<String, dynamic> _$AlertConfigUpdateToJson(AlertConfigUpdate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'config': instance.config,
      'status': instance.status,
      'displayName': instance.displayName,
      'revision': ?instance.revision,
    };

AlertConfigTest _$AlertConfigTestFromJson(Map<String, dynamic> json) =>
    AlertConfigTest(
      type: json['type'] as String?,
      config: json['config'] as String?,
      id: (json['id'] as num?)?.toInt(),
      displayName: json['displayName'] as String?,
      encryption: json['encryption'] as String?,
      host: json['host'] as String?,
      password: json['password'] as String?,
      port: (json['port'] as num?)?.toInt(),
      recipient: json['recipient'] as String?,
      sender: json['sender'] as String?,
      userName: json['userName'] as String?,
    );

Map<String, dynamic> _$AlertConfigTestToJson(AlertConfigTest instance) =>
    <String, dynamic>{
      'type': instance.type,
      'config': instance.config,
      'id': instance.id,
      'displayName': instance.displayName,
      'encryption': instance.encryption,
      'host': instance.host,
      'password': instance.password,
      'port': instance.port,
      'recipient': instance.recipient,
      'sender': instance.sender,
      'userName': instance.userName,
    };

AlertConfigTestResult _$AlertConfigTestResultFromJson(
  Map<String, dynamic> json,
) => AlertConfigTestResult(
  success: json['success'] as bool,
  statusCode: (json['statusCode'] as num?)?.toInt(),
  duration: (json['duration'] as num?)?.toInt(),
  message: json['message'] as String?,
  response: json['response'] as String?,
);

Map<String, dynamic> _$AlertConfigTestResultToJson(
  AlertConfigTestResult instance,
) => <String, dynamic>{
  'success': instance.success,
  'statusCode': instance.statusCode,
  'duration': instance.duration,
  'message': instance.message,
  'response': instance.response,
};

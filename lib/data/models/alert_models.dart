import 'package:equatable/equatable.dart';

/// 告警规则（dto.AlertInfo 语义；POST /alert/search 列表项）。
class AlertInfo extends Equatable {
  final int id;
  final String createdAt;
  final String updatedAt;
  final String type;
  final String subType;
  final int cycle;
  final int count;
  final int interval;
  final String method;
  final String title;
  final String? taskName;
  final String project;
  final String status;
  final int sendCount;
  final List<String> sendMethod;
  final String advancedParams;
  final String? alertTriggerMode;
  final String? createUser;
  final String? updateUser;

  const AlertInfo({
    this.id = 0,
    this.createdAt = '',
    this.updatedAt = '',
    this.type = '',
    this.subType = '',
    this.cycle = 0,
    this.count = 0,
    this.interval = 0,
    this.method = '',
    this.title = '',
    this.taskName,
    this.project = '',
    this.status = '',
    this.sendCount = 0,
    this.sendMethod = const <String>[],
    this.advancedParams = '',
    this.alertTriggerMode,
    this.createUser,
    this.updateUser,
  });

  factory AlertInfo.fromJson(Map<String, dynamic> json) {
    return AlertInfo(
      id: json['id'] as int? ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      type: json['type'] as String? ?? '',
      subType: json['subType'] as String? ?? '',
      cycle: json['cycle'] as int? ?? 0,
      count: json['count'] as int? ?? 0,
      interval: json['interval'] as int? ?? 0,
      method: json['method'] as String? ?? '',
      title: json['title'] as String? ?? '',
      taskName: json['taskName'] as String?,
      project: json['project'] as String? ?? '',
      status: json['status'] as String? ?? '',
      sendCount: json['sendCount'] as int? ?? 0,
      sendMethod: (json['sendMethod'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
      advancedParams: json['advancedParams'] as String? ?? '',
      alertTriggerMode: json['alertTriggerMode'] as String?,
      createUser: json['createUser'] as String?,
      updateUser: json['updateUser'] as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        createdAt,
        updatedAt,
        type,
        subType,
        cycle,
        count,
        interval,
        method,
        title,
        taskName,
        project,
        status,
        sendCount,
        sendMethod,
        advancedParams,
        alertTriggerMode,
        createUser,
        updateUser,
      ];
}

/// 告警日志中的规则详情（上游 Alert.AlertDetail）。
///
/// params 在上游为字符串或 {index,key,value} 列表两种形态，原样保留。
class AlertDetail extends Equatable {
  final String type;
  final String? subType;
  final String licenseId;
  final String title;
  final String project;
  final String method;
  final Object? params;

  const AlertDetail({
    this.type = '',
    this.subType,
    this.licenseId = '',
    this.title = '',
    this.project = '',
    this.method = '',
    this.params,
  });

  factory AlertDetail.fromJson(Map<String, dynamic> json) {
    return AlertDetail(
      type: json['type'] as String? ?? '',
      subType: json['subType'] as String?,
      licenseId: json['licenseId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      project: json['project'] as String? ?? '',
      method: json['method'] as String? ?? '',
      params: json['params'],
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[type, subType, licenseId, title, project, method, params];
}

/// 告警日志（POST /alert/logs/search 列表项）。
class AlertLog extends Equatable {
  final int id;
  final String createdAt;
  final String updatedAt;
  final int alertId;
  final AlertDetail alertDetail;
  final AlertInfo alertRule;
  final int count;
  final String message;
  final String status;
  final String method;

  const AlertLog({
    this.id = 0,
    this.createdAt = '',
    this.updatedAt = '',
    this.alertId = 0,
    this.alertDetail = const AlertDetail(),
    this.alertRule = const AlertInfo(),
    this.count = 0,
    this.message = '',
    this.status = '',
    this.method = '',
  });

  factory AlertLog.fromJson(Map<String, dynamic> json) {
    return AlertLog(
      id: json['id'] as int? ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      alertId: json['alertId'] as int? ?? 0,
      alertDetail: json['alertDetail'] is Map<String, dynamic>
          ? AlertDetail.fromJson(json['alertDetail'] as Map<String, dynamic>)
          : const AlertDetail(),
      alertRule: json['alertRule'] is Map<String, dynamic>
          ? AlertInfo.fromJson(json['alertRule'] as Map<String, dynamic>)
          : const AlertInfo(),
      count: json['count'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? '',
      method: json['method'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        createdAt,
        updatedAt,
        alertId,
        alertDetail,
        alertRule,
        count,
        message,
        status,
        method,
      ];
}

/// 磁盘信息（GET /alert/disks/list；告警目标选择）。
class AlertDisk extends Equatable {
  final String path;
  final String type;
  final String device;
  final int total;
  final int free;
  final int used;
  final double usedPercent;
  final int inodesTotal;
  final int inodesUsed;
  final int inodesFree;
  final double inodesUsedPercent;

  const AlertDisk({
    this.path = '',
    this.type = '',
    this.device = '',
    this.total = 0,
    this.free = 0,
    this.used = 0,
    this.usedPercent = 0,
    this.inodesTotal = 0,
    this.inodesUsed = 0,
    this.inodesFree = 0,
    this.inodesUsedPercent = 0,
  });

  factory AlertDisk.fromJson(Map<String, dynamic> json) {
    return AlertDisk(
      path: json['path'] as String? ?? '',
      type: json['type'] as String? ?? '',
      device: json['device'] as String? ?? '',
      total: json['total'] as int? ?? 0,
      free: json['free'] as int? ?? 0,
      used: json['used'] as int? ?? 0,
      usedPercent: (json['usedPercent'] as num?)?.toDouble() ?? 0,
      inodesTotal: json['inodesTotal'] as int? ?? 0,
      inodesUsed: json['inodesUsed'] as int? ?? 0,
      inodesFree: json['inodesFree'] as int? ?? 0,
      inodesUsedPercent:
          (json['inodesUsedPercent'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        path,
        type,
        device,
        total,
        free,
        used,
        usedPercent,
        inodesTotal,
        inodesUsed,
        inodesFree,
        inodesUsedPercent,
      ];
}

/// 杀毒扫描目标（GET /alert/clams/list）。
class AlertClam extends Equatable {
  final int id;
  final String name;
  final String status;
  final String path;
  final String createdAt;
  final String updatedAt;

  const AlertClam({
    this.id = 0,
    this.name = '',
    this.status = '',
    this.path = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory AlertClam.fromJson(Map<String, dynamic> json) {
    return AlertClam(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      path: json['path'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[id, name, status, path, createdAt, updatedAt];
}

/// 计划任务选项（POST /alert/cronjob/list）。
class AlertCronJob extends Equatable {
  final int id;
  final String name;
  final String type;
  final String status;
  final String createdAt;
  final String updatedAt;

  const AlertCronJob({
    this.id = 0,
    this.name = '',
    this.type = '',
    this.status = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory AlertCronJob.fromJson(Map<String, dynamic> json) {
    return AlertCronJob(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[id, name, type, status, createdAt, updatedAt];
}

/// 告警规则搜索请求（dto.AlertSearch）。
///
/// orderBy 当前仅 created_at；order 取值 ascending / descending。
class AlertSearch extends Equatable {
  final int page;
  final int pageSize;
  final String? type;
  final String? status;
  final String? method;
  final String? orderBy;
  final String? order;

  const AlertSearch({
    this.page = 1,
    this.pageSize = 20,
    this.type,
    this.status,
    this.method,
    this.orderBy,
    this.order,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        if (method != null) 'method': method,
        if (orderBy != null) 'orderBy': orderBy,
        if (order != null) 'order': order,
      };

  @override
  List<Object?> get props =>
      <Object?>[page, pageSize, type, status, method, orderBy, order];
}

/// 创建告警规则请求（dto.AlertCreate）。
class AlertCreate extends Equatable {
  final String type;
  final String method;
  final int? cycle;
  final int? count;
  final int? interval;
  final String? project;
  final String? status;
  final String? title;
  final int? sendCount;
  final String? advancedParams;

  const AlertCreate({
    required this.type,
    required this.method,
    this.cycle,
    this.count,
    this.interval,
    this.project,
    this.status,
    this.title,
    this.sendCount,
    this.advancedParams,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'method': method,
        if (cycle != null) 'cycle': cycle,
        if (count != null) 'count': count,
        if (interval != null) 'interval': interval,
        if (project != null) 'project': project,
        if (status != null) 'status': status,
        if (title != null) 'title': title,
        if (sendCount != null) 'sendCount': sendCount,
        if (advancedParams != null) 'advancedParams': advancedParams,
      };

  @override
  List<Object?> get props => <Object?>[
        type,
        method,
        cycle,
        count,
        interval,
        project,
        status,
        title,
        sendCount,
        advancedParams,
      ];
}

/// 更新告警规则请求（dto.AlertUpdate）。
class AlertUpdate extends Equatable {
  final int id;
  final String? type;
  final String? method;
  final int? cycle;
  final int? count;
  final int? interval;
  final String? project;
  final String? status;
  final String? title;
  final int? sendCount;
  final String? advancedParams;

  const AlertUpdate({
    required this.id,
    this.type,
    this.method,
    this.cycle,
    this.count,
    this.interval,
    this.project,
    this.status,
    this.title,
    this.sendCount,
    this.advancedParams,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        if (type != null) 'type': type,
        if (method != null) 'method': method,
        if (cycle != null) 'cycle': cycle,
        if (count != null) 'count': count,
        if (interval != null) 'interval': interval,
        if (project != null) 'project': project,
        if (status != null) 'status': status,
        if (title != null) 'title': title,
        if (sendCount != null) 'sendCount': sendCount,
        if (advancedParams != null) 'advancedParams': advancedParams,
      };

  @override
  List<Object?> get props => <Object?>[
        id,
        type,
        method,
        cycle,
        count,
        interval,
        project,
        status,
        title,
        sendCount,
        advancedParams,
      ];
}

/// 告警状态更新请求（dto.AlertUpdateStatus）。
class AlertUpdateStatus extends Equatable {
  final int id;
  final String status;

  const AlertUpdateStatus({
    required this.id,
    required this.status,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'status': status,
      };

  @override
  List<Object?> get props => <Object?>[id, status];
}

/// 告警日志搜索请求（dto.AlertLogSearch）。
class AlertLogSearch extends Equatable {
  final int page;
  final int pageSize;
  final String? status;
  final int? count;
  final String? startTime;
  final String? endTime;

  const AlertLogSearch({
    this.page = 1,
    this.pageSize = 20,
    this.status,
    this.count,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (status != null) 'status': status,
        if (count != null) 'count': count,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
      };

  @override
  List<Object?> get props =>
      <Object?>[page, pageSize, status, count, startTime, endTime];
}

/// 计划任务选项过滤请求（dto.CronJobReq）。
class AlertCronJobReq extends Equatable {
  final String? name;
  final String? type;
  final String? status;

  const AlertCronJobReq({this.name, this.type, this.status});

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (name != null) 'name': name,
        if (type != null) 'type': type,
        if (status != null) 'status': status,
      };

  @override
  List<Object?> get props => <Object?>[name, type, status];
}

/// 告警配置（POST /alert/config/info 与 /alert/config/search 列表项）。
class AlertConfigInfo extends Equatable {
  final int id;
  final String createdAt;
  final String updatedAt;
  final String type;
  final String title;
  final String config;
  final String status;
  final String? createUser;
  final String? updateUser;

  const AlertConfigInfo({
    this.id = 0,
    this.createdAt = '',
    this.updatedAt = '',
    this.type = '',
    this.title = '',
    this.config = '',
    this.status = '',
    this.createUser,
    this.updateUser,
  });

  factory AlertConfigInfo.fromJson(Map<String, dynamic> json) {
    return AlertConfigInfo(
      id: json['id'] as int? ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      config: json['config'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createUser: json['createUser'] as String?,
      updateUser: json['updateUser'] as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        createdAt,
        updatedAt,
        type,
        title,
        config,
        status,
        createUser,
        updateUser,
      ];
}

/// 配置过滤请求（dto.AlertConfigFilterReq）。
class AlertConfigFilterReq extends Equatable {
  final List<String>? excludeTypes;

  const AlertConfigFilterReq({this.excludeTypes});

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (excludeTypes != null) 'excludeTypes': excludeTypes,
      };

  @override
  List<Object?> get props => <Object?>[excludeTypes];
}

/// 配置分页请求（dto.AlertConfigPageReq）。
class AlertConfigPageReq extends Equatable {
  final int page;
  final int pageSize;
  final List<String>? excludeTypes;

  const AlertConfigPageReq({
    this.page = 1,
    this.pageSize = 20,
    this.excludeTypes,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (excludeTypes != null) 'excludeTypes': excludeTypes,
      };

  @override
  List<Object?> get props => <Object?>[page, pageSize, excludeTypes];
}

/// 更新告警配置请求（dto.AlertConfigUpdate）。
class AlertConfigUpdate extends Equatable {
  final int id;
  final String? type;
  final String? title;
  final String? config;
  final String? status;
  final String? displayName;

  const AlertConfigUpdate({
    required this.id,
    this.type,
    this.title,
    this.config,
    this.status,
    this.displayName,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        if (type != null) 'type': type,
        if (title != null) 'title': title,
        if (config != null) 'config': config,
        if (status != null) 'status': status,
        if (displayName != null) 'displayName': displayName,
      };

  @override
  List<Object?> get props =>
      <Object?>[id, type, title, config, status, displayName];
}

/// 告警配置测试请求（dto.AlertConfigTest）。
///
/// swagger 字段为邮箱测试形态；type/config/id 来自上游前端调用链路
/// （type=email 邮箱测试、type=custom 自定义 webhook 测试）。
class AlertConfigTest extends Equatable {
  final String? type;
  final String? config;
  final int? id;
  final String? displayName;
  final String? encryption;
  final String? host;
  final String? password;
  final int? port;
  final String? recipient;
  final String? sender;
  final String? userName;

  const AlertConfigTest({
    this.type,
    this.config,
    this.id,
    this.displayName,
    this.encryption,
    this.host,
    this.password,
    this.port,
    this.recipient,
    this.sender,
    this.userName,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (type != null) 'type': type,
        if (config != null) 'config': config,
        if (id != null) 'id': id,
        if (displayName != null) 'displayName': displayName,
        if (encryption != null) 'encryption': encryption,
        if (host != null) 'host': host,
        if (password != null) 'password': password,
        if (port != null) 'port': port,
        if (recipient != null) 'recipient': recipient,
        if (sender != null) 'sender': sender,
        if (userName != null) 'userName': userName,
      };

  @override
  List<Object?> get props => <Object?>[
        type,
        config,
        id,
        displayName,
        encryption,
        host,
        password,
        port,
        recipient,
        sender,
        userName,
      ];
}

/// 告警配置测试结果（上游 Alert.AlertConfigCustomTestResult）。
class AlertConfigTestResult extends Equatable {
  final bool success;
  final int? statusCode;
  final int? duration;
  final String? message;
  final String? response;

  const AlertConfigTestResult({
    this.success = false,
    this.statusCode,
    this.duration,
    this.message,
    this.response,
  });

  factory AlertConfigTestResult.fromJson(Map<String, dynamic> json) {
    return AlertConfigTestResult(
      success: json['success'] as bool? ?? false,
      statusCode: json['statusCode'] as int?,
      duration: json['duration'] as int?,
      message: json['message'] as String?,
      response: json['response'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[success, statusCode, duration, message, response];
}

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'alert_models.g.dart';

/// 告警规则（上游 Alert.AlertDetail 与 dto.AlertDTO；POST /alert/search 列表项）。
///
/// taskName / alertTriggerMode / createUser / updateUser 只在对应类型或
/// 有操作记录时出现，上游对 taskName 声明了 omitempty。
@JsonSerializable()
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
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    required this.subType,
    required this.cycle,
    required this.count,
    required this.interval,
    required this.method,
    required this.title,
    this.taskName,
    required this.project,
    required this.status,
    required this.sendCount,
    required this.sendMethod,
    required this.advancedParams,
    this.alertTriggerMode,
    this.createUser,
    this.updateUser,
  });

  factory AlertInfo.fromJson(Map<String, dynamic> json) =>
      _$AlertInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AlertInfoToJson(this);

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
@JsonSerializable()
class AlertDetail extends Equatable {
  final String type;
  final String? subType;
  final String licenseId;
  final String title;
  final String project;
  final String method;
  final Object? params;

  const AlertDetail({
    required this.type,
    this.subType,
    required this.licenseId,
    required this.title,
    required this.project,
    required this.method,
    this.params,
  });

  factory AlertDetail.fromJson(Map<String, dynamic> json) =>
      _$AlertDetailFromJson(json);

  Map<String, dynamic> toJson() => _$AlertDetailToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[type, subType, licenseId, title, project, method, params];
}

/// 告警日志（POST /alert/logs/search 列表项）。
///
/// 上游前端把 alertDetail 与 alertRule 都声明为必填对象。
@JsonSerializable()
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
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.alertId,
    required this.alertDetail,
    required this.alertRule,
    required this.count,
    required this.message,
    required this.status,
    required this.method,
  });

  factory AlertLog.fromJson(Map<String, dynamic> json) =>
      _$AlertLogFromJson(json);

  Map<String, dynamic> toJson() => _$AlertLogToJson(this);

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

/// 磁盘信息（dto.DiskDTO；GET /alert/disks/list）。
@JsonSerializable()
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
    required this.path,
    required this.type,
    required this.device,
    required this.total,
    required this.free,
    required this.used,
    required this.usedPercent,
    required this.inodesTotal,
    required this.inodesUsed,
    required this.inodesFree,
    required this.inodesUsedPercent,
  });

  factory AlertDisk.fromJson(Map<String, dynamic> json) =>
      _$AlertDiskFromJson(json);

  Map<String, dynamic> toJson() => _$AlertDiskToJson(this);

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
@JsonSerializable()
class AlertClam extends Equatable {
  final int id;
  final String name;
  final String status;
  final String path;
  final String createdAt;
  final String updatedAt;

  const AlertClam({
    required this.id,
    required this.name,
    required this.status,
    required this.path,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AlertClam.fromJson(Map<String, dynamic> json) =>
      _$AlertClamFromJson(json);

  Map<String, dynamic> toJson() => _$AlertClamToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[id, name, status, path, createdAt, updatedAt];
}

/// 计划任务选项（POST /alert/cronjob/list）。
@JsonSerializable()
class AlertCronJob extends Equatable {
  final int id;
  final String name;
  final String type;
  final String status;
  final String createdAt;
  final String updatedAt;

  const AlertCronJob({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AlertCronJob.fromJson(Map<String, dynamic> json) =>
      _$AlertCronJobFromJson(json);

  Map<String, dynamic> toJson() => _$AlertCronJobToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[id, name, type, status, createdAt, updatedAt];
}

/// 告警规则搜索请求（dto.AlertSearch）。
///
/// 服务端把 `orderBy` 与 `order` 声明为必填，缺失时返回参数错误；
/// `orderBy` 当前仅 `created_at`，`order` 取值 `ascending` / `descending`。
@JsonSerializable()
class AlertSearch extends Equatable {
  final int page;
  final int pageSize;
  final String? type;
  final String? status;
  final String? method;
  final String orderBy;
  final String order;

  const AlertSearch({
    this.page = 1,
    this.pageSize = 20,
    this.type,
    this.status,
    this.method,
    required this.orderBy,
    required this.order,
  });

  factory AlertSearch.fromJson(Map<String, dynamic> json) =>
      _$AlertSearchFromJson(json);

  Map<String, dynamic> toJson() => _$AlertSearchToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[page, pageSize, type, status, method, orderBy, order];
}

/// 创建告警规则请求（dto.AlertCreate）。
@JsonSerializable()
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

  factory AlertCreate.fromJson(Map<String, dynamic> json) =>
      _$AlertCreateFromJson(json);

  Map<String, dynamic> toJson() => _$AlertCreateToJson(this);

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
@JsonSerializable()
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

  factory AlertUpdate.fromJson(Map<String, dynamic> json) =>
      _$AlertUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$AlertUpdateToJson(this);

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
@JsonSerializable()
class AlertUpdateStatus extends Equatable {
  final int id;
  final String status;

  const AlertUpdateStatus({
    required this.id,
    required this.status,
  });

  factory AlertUpdateStatus.fromJson(Map<String, dynamic> json) =>
      _$AlertUpdateStatusFromJson(json);

  Map<String, dynamic> toJson() => _$AlertUpdateStatusToJson(this);

  @override
  List<Object?> get props => <Object?>[id, status];
}

/// 告警日志搜索请求（dto.AlertLogSearch）。
@JsonSerializable()
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

  factory AlertLogSearch.fromJson(Map<String, dynamic> json) =>
      _$AlertLogSearchFromJson(json);

  Map<String, dynamic> toJson() => _$AlertLogSearchToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[page, pageSize, status, count, startTime, endTime];
}

/// 计划任务选项过滤请求（dto.CronJobReq）。
@JsonSerializable()
class AlertCronJobReq extends Equatable {
  final String? name;
  final String? type;
  final String? status;

  const AlertCronJobReq({this.name, this.type, this.status});

  factory AlertCronJobReq.fromJson(Map<String, dynamic> json) =>
      _$AlertCronJobReqFromJson(json);

  Map<String, dynamic> toJson() => _$AlertCronJobReqToJson(this);

  @override
  List<Object?> get props => <Object?>[name, type, status];
}

/// 告警配置（POST /alert/config/info 与 /alert/config/search 列表项）。
@JsonSerializable()
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
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    required this.title,
    required this.config,
    required this.status,
    this.createUser,
    this.updateUser,
  });

  factory AlertConfigInfo.fromJson(Map<String, dynamic> json) =>
      _$AlertConfigInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AlertConfigInfoToJson(this);

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

/// 配置过滤请求（dto.AlertConfigQuery）。
@JsonSerializable()
class AlertConfigFilterReq extends Equatable {
  final List<String>? excludeTypes;

  const AlertConfigFilterReq({this.excludeTypes});

  factory AlertConfigFilterReq.fromJson(Map<String, dynamic> json) =>
      _$AlertConfigFilterReqFromJson(json);

  Map<String, dynamic> toJson() => _$AlertConfigFilterReqToJson(this);

  @override
  List<Object?> get props => <Object?>[excludeTypes];
}

/// 配置分页请求（dto.AlertConfigPageReq）。
@JsonSerializable()
class AlertConfigPageReq extends Equatable {
  final int page;
  final int pageSize;
  final List<String>? excludeTypes;

  const AlertConfigPageReq({
    this.page = 1,
    this.pageSize = 20,
    this.excludeTypes,
  });

  factory AlertConfigPageReq.fromJson(Map<String, dynamic> json) =>
      _$AlertConfigPageReqFromJson(json);

  Map<String, dynamic> toJson() => _$AlertConfigPageReqToJson(this);

  @override
  List<Object?> get props => <Object?>[page, pageSize, excludeTypes];
}

/// 更新告警配置请求（dto.AlertConfigUpdate）。
@JsonSerializable()
class AlertConfigUpdate extends Equatable {
  final int id;
  final String? type;
  final String? title;
  final String? config;
  final String? status;
  final String? displayName;
  @JsonKey(includeIfNull: false)
  final String? revision;

  const AlertConfigUpdate({
    required this.id,
    this.type,
    this.title,
    this.config,
    this.status,
    this.displayName,
    this.revision,
  });

  factory AlertConfigUpdate.fromJson(Map<String, dynamic> json) =>
      _$AlertConfigUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$AlertConfigUpdateToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[id, type, title, config, status, displayName, revision];
}

/// 告警配置测试请求（dto.AlertConfigTest）。
///
/// swagger 字段为邮箱测试形态；type/config/id 来自上游前端调用链路
/// （type=email 邮箱测试、type=custom 自定义 webhook 测试）。
@JsonSerializable()
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

  factory AlertConfigTest.fromJson(Map<String, dynamic> json) =>
      _$AlertConfigTestFromJson(json);

  Map<String, dynamic> toJson() => _$AlertConfigTestToJson(this);

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
@JsonSerializable()
class AlertConfigTestResult extends Equatable {
  final bool success;
  final int? statusCode;
  final int? duration;
  final String? message;
  final String? response;

  const AlertConfigTestResult({
    required this.success,
    this.statusCode,
    this.duration,
    this.message,
    this.response,
  });

  factory AlertConfigTestResult.fromJson(Map<String, dynamic> json) =>
      _$AlertConfigTestResultFromJson(json);

  Map<String, dynamic> toJson() => _$AlertConfigTestResultToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[success, statusCode, duration, message, response];
}

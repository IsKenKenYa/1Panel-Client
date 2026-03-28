import 'package:equatable/equatable.dart';

/// Cron job type enumeration
enum CronJobType {
  shell('shell'),
  website('website'),
  database('database'),
  backup('backup'),
  cleanup('cleanup');

  const CronJobType(this.value);
  final String value;

  static CronJobType fromString(String value) {
    return CronJobType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CronJobType.shell,
    );
  }
}

/// Cron job status enumeration
enum CronJobStatus {
  enabled('enabled'),
  disabled('disabled'),
  running('running'),
  failed('failed');

  const CronJobStatus(this.value);
  final String value;

  static CronJobStatus fromString(String value) {
    return CronJobStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CronJobStatus.disabled,
    );
  }
}

/// Cron job creation request model
class CronJobCreate extends Equatable {
  final String name;
  final String type;
  final String? cronExpression;
  final String? command;
  final String? script;
  final int? websiteId;
  final int? databaseId;
  final String? backupType;
  final Map<String, dynamic>? parameters;
  final bool? enable;

  const CronJobCreate({
    required this.name,
    required this.type,
    this.cronExpression,
    this.command,
    this.script,
    this.websiteId,
    this.databaseId,
    this.backupType,
    this.parameters,
    this.enable,
  });

  factory CronJobCreate.fromJson(Map<String, dynamic> json) {
    return CronJobCreate(
      name: json['name'] as String,
      type: json['type'] as String,
      cronExpression: json['cronExpression'] as String?,
      command: json['command'] as String?,
      script: json['script'] as String?,
      websiteId: json['websiteId'] as int?,
      databaseId: json['databaseId'] as int?,
      backupType: json['backupType'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>?,
      enable: json['enable'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'cronExpression': cronExpression,
      'command': command,
      'script': script,
      'websiteId': websiteId,
      'databaseId': databaseId,
      'backupType': backupType,
      'parameters': parameters,
      'enable': enable,
    };
  }

  @override
  List<Object?> get props => [
        name,
        type,
        cronExpression,
        command,
        script,
        websiteId,
        databaseId,
        backupType,
        parameters,
        enable
      ];
}

/// Cron job information model
class CronJobInfo extends Equatable {
  final int? id;
  final String? name;
  final String? type;
  final String? cronExpression;
  final String? command;
  final String? script;
  final int? websiteId;
  final String? websiteName;
  final int? databaseId;
  final String? databaseName;
  final String? backupType;
  final Map<String, dynamic>? parameters;
  final CronJobStatus? status;
  final String? lastExecutionTime;
  final String? nextExecutionTime;
  final int? executionCount;
  final int? successCount;
  final int? failureCount;
  final String? createTime;
  final String? updateTime;

  const CronJobInfo({
    this.id,
    this.name,
    this.type,
    this.cronExpression,
    this.command,
    this.script,
    this.websiteId,
    this.websiteName,
    this.databaseId,
    this.databaseName,
    this.backupType,
    this.parameters,
    this.status,
    this.lastExecutionTime,
    this.nextExecutionTime,
    this.executionCount,
    this.successCount,
    this.failureCount,
    this.createTime,
    this.updateTime,
  });

  factory CronJobInfo.fromJson(Map<String, dynamic> json) {
    return CronJobInfo(
      id: json['id'] as int?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      cronExpression: json['cronExpression'] as String?,
      command: json['command'] as String?,
      script: json['script'] as String?,
      websiteId: json['websiteId'] as int?,
      websiteName: json['websiteName'] as String?,
      databaseId: json['databaseId'] as int?,
      databaseName: json['databaseName'] as String?,
      backupType: json['backupType'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>?,
      status: json['status'] != null
          ? CronJobStatus.fromString(json['status'] as String)
          : null,
      lastExecutionTime: json['lastExecutionTime'] as String?,
      nextExecutionTime: json['nextExecutionTime'] as String?,
      executionCount: json['executionCount'] as int?,
      successCount: json['successCount'] as int?,
      failureCount: json['failureCount'] as int?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'cronExpression': cronExpression,
      'command': command,
      'script': script,
      'websiteId': websiteId,
      'websiteName': websiteName,
      'databaseId': databaseId,
      'databaseName': databaseName,
      'backupType': backupType,
      'parameters': parameters,
      'status': status?.value,
      'lastExecutionTime': lastExecutionTime,
      'nextExecutionTime': nextExecutionTime,
      'executionCount': executionCount,
      'successCount': successCount,
      'failureCount': failureCount,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        cronExpression,
        command,
        script,
        websiteId,
        websiteName,
        databaseId,
        databaseName,
        backupType,
        parameters,
        status,
        lastExecutionTime,
        nextExecutionTime,
        executionCount,
        successCount,
        failureCount,
        createTime,
        updateTime
      ];
}

/// Cron job search request model
class CronJobSearch extends Equatable {
  final int? page;
  final int? pageSize;
  final String? search;
  final String? type;
  final CronJobStatus? status;

  const CronJobSearch({
    this.page,
    this.pageSize,
    this.search,
    this.type,
    this.status,
  });

  factory CronJobSearch.fromJson(Map<String, dynamic> json) {
    return CronJobSearch(
      page: json['page'] as int?,
      pageSize: json['pageSize'] as int?,
      search: json['search'] as String?,
      type: json['type'] as String?,
      status: json['status'] != null
          ? CronJobStatus.fromString(json['status'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'search': search,
      'type': type,
      'status': status?.value,
    };
  }

  @override
  List<Object?> get props => [page, pageSize, search, type, status];
}

/// Cron job update request model
class CronJobUpdate extends Equatable {
  final int id;
  final String? name;
  final String? cronExpression;
  final String? command;
  final String? script;
  final Map<String, dynamic>? parameters;
  final bool? enable;

  const CronJobUpdate({
    required this.id,
    this.name,
    this.cronExpression,
    this.command,
    this.script,
    this.parameters,
    this.enable,
  });

  factory CronJobUpdate.fromJson(Map<String, dynamic> json) {
    return CronJobUpdate(
      id: json['id'] as int,
      name: json['name'] as String?,
      cronExpression: json['cronExpression'] as String?,
      command: json['command'] as String?,
      script: json['script'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>?,
      enable: json['enable'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cronExpression': cronExpression,
      'command': command,
      'script': script,
      'parameters': parameters,
      'enable': enable,
    };
  }

  @override
  List<Object?> get props =>
      [id, name, cronExpression, command, script, parameters, enable];
}

/// Cron job operation model
class CronJobOperate extends Equatable {
  final List<int> ids;
  final String operation;

  const CronJobOperate({
    required this.ids,
    required this.operation,
  });

  factory CronJobOperate.fromJson(Map<String, dynamic> json) {
    return CronJobOperate(
      ids: (json['ids'] as List?)?.map((e) => e as int).toList() ?? [],
      operation: json['operation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ids': ids,
      'operation': operation,
    };
  }

  @override
  List<Object?> get props => [ids, operation];
}

/// Cron job execution log model
class CronJobLog extends Equatable {
  final int? id;
  final int? cronJobId;
  final String? cronJobName;
  final String? status;
  final String? startTime;
  final String? endTime;
  final int? duration;
  final String? output;
  final String? error;
  final int? exitCode;

  const CronJobLog({
    this.id,
    this.cronJobId,
    this.cronJobName,
    this.status,
    this.startTime,
    this.endTime,
    this.duration,
    this.output,
    this.error,
    this.exitCode,
  });

  factory CronJobLog.fromJson(Map<String, dynamic> json) {
    return CronJobLog(
      id: json['id'] as int?,
      cronJobId: json['cronJobId'] as int?,
      cronJobName: json['cronJobName'] as String?,
      status: json['status'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      duration: json['duration'] as int?,
      output: json['output'] as String?,
      error: json['error'] as String?,
      exitCode: json['exitCode'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cronJobId': cronJobId,
      'cronJobName': cronJobName,
      'status': status,
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
      'output': output,
      'error': error,
      'exitCode': exitCode,
    };
  }

  @override
  List<Object?> get props => [
        id,
        cronJobId,
        cronJobName,
        status,
        startTime,
        endTime,
        duration,
        output,
        error,
        exitCode
      ];
}

/// Cron job statistics model
class CronJobStats extends Equatable {
  final int? totalJobs;
  final int? enabledJobs;
  final int? disabledJobs;
  final int? runningJobs;
  final int? failedJobs;
  final int? todayExecutions;
  final int? weekExecutions;
  final int? monthExecutions;

  const CronJobStats({
    this.totalJobs,
    this.enabledJobs,
    this.disabledJobs,
    this.runningJobs,
    this.failedJobs,
    this.todayExecutions,
    this.weekExecutions,
    this.monthExecutions,
  });

  factory CronJobStats.fromJson(Map<String, dynamic> json) {
    return CronJobStats(
      totalJobs: json['totalJobs'] as int?,
      enabledJobs: json['enabledJobs'] as int?,
      disabledJobs: json['disabledJobs'] as int?,
      runningJobs: json['runningJobs'] as int?,
      failedJobs: json['failedJobs'] as int?,
      todayExecutions: json['todayExecutions'] as int?,
      weekExecutions: json['weekExecutions'] as int?,
      monthExecutions: json['monthExecutions'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalJobs': totalJobs,
      'enabledJobs': enabledJobs,
      'disabledJobs': disabledJobs,
      'runningJobs': runningJobs,
      'failedJobs': failedJobs,
      'todayExecutions': todayExecutions,
      'weekExecutions': weekExecutions,
      'monthExecutions': monthExecutions,
    };
  }

  @override
  List<Object?> get props => [
        totalJobs,
        enabledJobs,
        disabledJobs,
        runningJobs,
        failedJobs,
        todayExecutions,
        weekExecutions,
        monthExecutions
      ];
}

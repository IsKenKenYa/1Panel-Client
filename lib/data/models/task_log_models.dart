import 'package:equatable/equatable.dart';

/// Task log model
class TaskLog extends Equatable {
  final String? id;
  final String? name;
  final String? type;
  final String? logFile;
  final String? status;
  final String? errorMsg;
  final int? operationLogId;
  final int? resourceId;
  final String? currentStep;
  final String? endAt;
  final String? createdAt;

  const TaskLog({
    this.id,
    this.name,
    this.type,
    this.logFile,
    this.status,
    this.errorMsg,
    this.operationLogId,
    this.resourceId,
    this.currentStep,
    this.endAt,
    this.createdAt,
  });

  factory TaskLog.fromJson(Map<String, dynamic> json) {
    return TaskLog(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      type: json['type'] as String?,
      logFile: json['logFile'] as String?,
      status: json['status'] as String?,
      errorMsg: json['errorMsg'] as String?,
      operationLogId: json['operationLogID'] as int?,
      resourceId: json['resourceID'] as int?,
      currentStep: json['currentStep'] as String?,
      endAt: json['endAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'logFile': logFile,
      'status': status,
      'errorMsg': errorMsg,
      'operationLogID': operationLogId,
      'resourceID': resourceId,
      'currentStep': currentStep,
      'endAt': endAt,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        logFile,
        status,
        errorMsg,
        operationLogId,
        resourceId,
        currentStep,
        endAt,
        createdAt,
      ];
}

/// Task log search model
class TaskLogSearch extends Equatable {
  final String? type;
  final String? status;
  final int page;
  final int pageSize;

  const TaskLogSearch({
    this.type,
    this.status,
    this.page = 1,
    this.pageSize = 20,
  });

  factory TaskLogSearch.fromJson(Map<String, dynamic> json) {
    return TaskLogSearch(
      type: json['type'] as String? ?? json['taskType'] as String?,
      status: json['status'] as String?,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type ?? '',
      'status': status ?? '',
      'page': page,
      'pageSize': pageSize,
    };
  }

  @override
  List<Object?> get props => [type, status, page, pageSize];
}

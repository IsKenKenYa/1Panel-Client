import 'package:equatable/equatable.dart';

class CronjobRecordQuery extends Equatable {
  const CronjobRecordQuery({
    required this.cronjobId,
    this.page = 1,
    this.pageSize = 20,
    this.status = '',
  });

  final int cronjobId;
  final int page;
  final int pageSize;
  final String status;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'cronjobID': cronjobId,
        'page': page,
        'pageSize': pageSize,
        'status': status,
      };

  @override
  List<Object?> get props => <Object?>[cronjobId, page, pageSize, status];
}

class CronjobRecordInfo extends Equatable {
  const CronjobRecordInfo({
    required this.id,
    required this.taskId,
    required this.startTime,
    required this.status,
    required this.message,
    required this.targetPath,
    required this.interval,
    required this.file,
  });

  final int id;
  final String taskId;
  final String startTime;
  final String status;
  final String message;
  final String targetPath;
  final int interval;
  final String file;

  factory CronjobRecordInfo.fromJson(Map<String, dynamic> json) {
    return CronjobRecordInfo(
      id: json['id'] as int? ?? 0,
      taskId: json['taskID'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
      targetPath: json['targetPath'] as String? ?? '',
      interval: json['interval'] as int? ?? 0,
      file: json['file'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        taskId,
        startTime,
        status,
        message,
        targetPath,
        interval,
        file,
      ];
}

class CronjobRecordCleanRequest extends Equatable {
  const CronjobRecordCleanRequest({
    required this.cronjobId,
    this.cleanData = false,
    this.cleanRemoteData = false,
  });

  final int cronjobId;
  final bool cleanData;
  final bool cleanRemoteData;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'cronjobID': cronjobId,
        'cleanData': cleanData,
        'cleanRemoteData': cleanRemoteData,
      };

  @override
  List<Object?> get props => <Object?>[cronjobId, cleanData, cleanRemoteData];
}

class CronjobScriptOption extends Equatable {
  const CronjobScriptOption({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory CronjobScriptOption.fromJson(Map<String, dynamic> json) {
    return CronjobScriptOption(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[id, name];
}

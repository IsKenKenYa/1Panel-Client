import 'package:equatable/equatable.dart';

class FileReadByLineRequest extends Equatable {
  const FileReadByLineRequest({
    required this.type,
    this.id,
    this.name,
    this.page = 1,
    this.pageSize = 200,
    this.latest = false,
    this.taskId,
    this.taskType,
    this.taskOperate,
    this.resourceId,
  });

  final String type;
  final int? id;
  final String? name;
  final int page;
  final int pageSize;
  final bool latest;
  final String? taskId;
  final String? taskType;
  final String? taskOperate;
  final int? resourceId;

  factory FileReadByLineRequest.fromJson(Map<String, dynamic> json) {
    return FileReadByLineRequest(
      type: json['type'] as String? ?? '',
      id: json['ID'] as int? ?? json['id'] as int?,
      name: json['name'] as String?,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 200,
      latest: json['latest'] as bool? ?? false,
      taskId: json['taskID'] as String?,
      taskType: json['taskType'] as String?,
      taskOperate: json['taskOperate'] as String?,
      resourceId: json['resourceID'] as int?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'ID': id ?? 0,
        'name': name ?? '',
        'page': page,
        'pageSize': pageSize,
        'latest': latest,
        'taskID': taskId ?? '',
        'taskType': taskType ?? '',
        'taskOperate': taskOperate ?? '',
        'resourceID': resourceId ?? 0,
      };

  @override
  List<Object?> get props => <Object?>[
        type,
        id,
        name,
        page,
        pageSize,
        latest,
        taskId,
        taskType,
        taskOperate,
        resourceId,
      ];
}

class FileReadByLineResponse extends Equatable {
  const FileReadByLineResponse({
    this.end = false,
    this.path = '',
    this.total = 0,
    this.totalLines = 0,
    this.taskStatus,
    this.scope,
    this.lines = const <String>[],
  });

  final bool end;
  final String path;
  final int total;
  final int totalLines;
  final String? taskStatus;
  final String? scope;
  final List<String> lines;

  factory FileReadByLineResponse.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? const <dynamic>[];
    return FileReadByLineResponse(
      end: json['end'] as bool? ?? false,
      path: json['path'] as String? ?? '',
      total: json['total'] as int? ?? 0,
      totalLines: json['totalLines'] as int? ?? 0,
      taskStatus: json['taskStatus'] as String?,
      scope: json['scope'] as String?,
      lines: rawLines.map((dynamic item) => item.toString()).toList(
            growable: false,
          ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'end': end,
        'path': path,
        'total': total,
        'totalLines': totalLines,
        'taskStatus': taskStatus,
        'scope': scope,
        'lines': lines,
      };

  @override
  List<Object?> get props => <Object?>[
        end,
        path,
        total,
        totalLines,
        taskStatus,
        scope,
        lines,
      ];
}

import 'package:equatable/equatable.dart';

class ScriptLibraryQuery extends Equatable {
  const ScriptLibraryQuery({
    this.page = 1,
    this.pageSize = 20,
    this.groupId,
    this.info,
  });

  final int page;
  final int pageSize;
  final int? groupId;
  final String? info;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        'groupID': groupId ?? 0,
        'info': info ?? '',
      };

  @override
  List<Object?> get props => <Object?>[page, pageSize, groupId, info];
}

class ScriptLibraryInfo extends Equatable {
  const ScriptLibraryInfo({
    required this.id,
    required this.name,
    required this.isInteractive,
    required this.label,
    required this.script,
    required this.groupList,
    required this.groupBelong,
    required this.isSystem,
    required this.description,
    required this.createdAt,
  });

  final int id;
  final String name;
  final bool isInteractive;
  final String label;
  final String script;
  final List<int> groupList;
  final List<String> groupBelong;
  final bool isSystem;
  final String description;
  final DateTime? createdAt;

  factory ScriptLibraryInfo.fromJson(Map<String, dynamic> json) {
    return ScriptLibraryInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      isInteractive: json['isInteractive'] as bool? ?? false,
      label: json['lable'] as String? ?? '',
      script: json['script'] as String? ?? '',
      groupList: (json['groupList'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item as int)
          .toList(growable: false),
      groupBelong: (json['groupBelong'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
      isSystem: json['isSystem'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        isInteractive,
        label,
        script,
        groupList,
        groupBelong,
        isSystem,
        description,
        createdAt,
      ];
}

class ScriptDeleteRequest extends Equatable {
  const ScriptDeleteRequest({required this.ids});

  final List<int> ids;

  Map<String, dynamic> toJson() => <String, dynamic>{'ids': ids};

  @override
  List<Object?> get props => <Object?>[ids];
}

class ScriptSyncState extends Equatable {
  const ScriptSyncState({
    required this.taskId,
    this.isRunning = false,
  });

  final String taskId;
  final bool isRunning;

  @override
  List<Object?> get props => <Object?>[taskId, isRunning];
}

class ScriptRunRequest extends Equatable {
  const ScriptRunRequest({
    required this.scriptId,
    this.cols = 80,
    this.rows = 40,
    this.operateNode = 'local',
  });

  final int scriptId;
  final int cols;
  final int rows;
  final String operateNode;

  @override
  List<Object?> get props => <Object?>[scriptId, cols, rows, operateNode];
}

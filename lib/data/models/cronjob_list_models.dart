import 'package:equatable/equatable.dart';

class CronjobListQuery extends Equatable {
  const CronjobListQuery({
    this.page = 1,
    this.pageSize = 20,
    this.info,
    this.groupIds = const <int>[],
    this.orderBy = 'createdAt',
    this.order = 'descending',
  });

  final int page;
  final int pageSize;
  final String? info;
  final List<int> groupIds;
  final String orderBy;
  final String order;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        'info': info ?? '',
        'groupIDs': groupIds,
        'orderBy': orderBy,
        'order': order,
      };

  @override
  List<Object?> get props => <Object?>[
        page,
        pageSize,
        info,
        groupIds,
        orderBy,
        order,
      ];
}

class CronjobStatusUpdate extends Equatable {
  const CronjobStatusUpdate({
    required this.id,
    required this.status,
  });

  final int id;
  final String status;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'status': status,
      };

  @override
  List<Object?> get props => <Object?>[id, status];
}

class CronjobHandleRequest extends Equatable {
  const CronjobHandleRequest({required this.id});

  final int id;

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id};

  @override
  List<Object?> get props => <Object?>[id];
}

class CronjobSummary extends Equatable {
  const CronjobSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.groupId,
    required this.groupBelong,
    required this.spec,
    required this.specCustom,
    required this.status,
    required this.lastRecordStatus,
    required this.lastRecordTime,
    required this.retainCopies,
    required this.scriptMode,
    required this.command,
    required this.executor,
    this.nextHandlePreview,
  });

  final int id;
  final String name;
  final String type;
  final int groupId;
  final String groupBelong;
  final String spec;
  final bool specCustom;
  final String status;
  final String lastRecordStatus;
  final String lastRecordTime;
  final int retainCopies;
  final String scriptMode;
  final String command;
  final String executor;
  final String? nextHandlePreview;

  factory CronjobSummary.fromJson(Map<String, dynamic> json) {
    return CronjobSummary(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      groupId: json['groupID'] as int? ?? 0,
      groupBelong: json['groupBelong'] as String? ?? '',
      spec: json['spec'] as String? ?? '',
      specCustom: json['specCustom'] as bool? ?? false,
      status: json['status'] as String? ?? '',
      lastRecordStatus: json['lastRecordStatus'] as String? ?? '',
      lastRecordTime: json['lastRecordTime'] as String? ?? '',
      retainCopies: json['retainCopies'] as int? ?? 0,
      scriptMode: json['scriptMode'] as String? ?? '',
      command: json['command'] as String? ?? '',
      executor: json['executor'] as String? ?? '',
      nextHandlePreview: json['nextHandlePreview'] as String?,
    );
  }

  CronjobSummary copyWith({
    String? nextHandlePreview,
  }) {
    return CronjobSummary(
      id: id,
      name: name,
      type: type,
      groupId: groupId,
      groupBelong: groupBelong,
      spec: spec,
      specCustom: specCustom,
      status: status,
      lastRecordStatus: lastRecordStatus,
      lastRecordTime: lastRecordTime,
      retainCopies: retainCopies,
      scriptMode: scriptMode,
      command: command,
      executor: executor,
      nextHandlePreview: nextHandlePreview ?? this.nextHandlePreview,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        type,
        groupId,
        groupBelong,
        spec,
        specCustom,
        status,
        lastRecordStatus,
        lastRecordTime,
        retainCopies,
        scriptMode,
        command,
        executor,
        nextHandlePreview,
      ];
}

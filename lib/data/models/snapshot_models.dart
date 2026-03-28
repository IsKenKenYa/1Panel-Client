import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'snapshot_models.g.dart';

/// 快照操作模型
@JsonSerializable()
class SnapshotOperate extends Equatable {
  final int? id;
  final String operate;

  const SnapshotOperate({
    this.id,
    required this.operate,
  });

  factory SnapshotOperate.fromJson(Map<String, dynamic> json) =>
      _$SnapshotOperateFromJson(json);
  Map<String, dynamic> toJson() => _$SnapshotOperateToJson(this);

  @override
  List<Object?> get props => [id, operate];
}

/// 快照操作请求
@JsonSerializable()
class SnapshotOperateRequest extends Equatable {
  final List<int> ids;
  final String operate;

  const SnapshotOperateRequest({
    required this.ids,
    required this.operate,
  });

  factory SnapshotOperateRequest.fromJson(Map<String, dynamic> json) =>
      _$SnapshotOperateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SnapshotOperateRequestToJson(this);

  @override
  List<Object?> get props => [ids, operate];
}

/// 快照信息
@JsonSerializable()
class SnapshotInfo extends Equatable {
  final int? id;
  final String? name;
  final String? description;
  final String? createTime;
  final String? status;
  final String? path;
  final String? size;
  final String? version;
  final bool? isDefault;
  final int? appCount;

  const SnapshotInfo({
    this.id,
    this.name,
    this.description,
    this.createTime,
    this.status,
    this.path,
    this.size,
    this.version,
    this.isDefault,
    this.appCount,
  });

  factory SnapshotInfo.fromJson(Map<String, dynamic> json) =>
      _$SnapshotInfoFromJson(json);
  Map<String, dynamic> toJson() => _$SnapshotInfoToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        createTime,
        status,
        path,
        size,
        version,
        isDefault,
        appCount
      ];
}

/// 快照创建请求
@JsonSerializable()
class SnapshotCreateRequest extends Equatable {
  final String? name;
  final String? description;
  final String? source;
  final List<String>? ignoreApps;
  final List<String>? ignoreDatabases;
  final List<String>? ignoreDirectories;
  final bool? encryptConfig;
  final bool? encryptApp;
  final bool? encryptDatabase;

  const SnapshotCreateRequest({
    this.name,
    this.description,
    this.source,
    this.ignoreApps,
    this.ignoreDatabases,
    this.ignoreDirectories,
    this.encryptConfig,
    this.encryptApp,
    this.encryptDatabase,
  });

  factory SnapshotCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$SnapshotCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SnapshotCreateRequestToJson(this);

  @override
  List<Object?> get props => [
        name,
        description,
        source,
        ignoreApps,
        ignoreDatabases,
        ignoreDirectories,
        encryptConfig,
        encryptApp,
        encryptDatabase
      ];
}

/// 快照创建结果
@JsonSerializable()
class SnapshotCreateResult extends Equatable {
  final bool? success;
  final String? message;
  final int? snapshotId;

  const SnapshotCreateResult({
    this.success,
    this.message,
    this.snapshotId,
  });

  factory SnapshotCreateResult.fromJson(Map<String, dynamic> json) =>
      _$SnapshotCreateResultFromJson(json);
  Map<String, dynamic> toJson() => _$SnapshotCreateResultToJson(this);

  @override
  List<Object?> get props => [success, message, snapshotId];
}

/// 快照恢复请求
@JsonSerializable()
class SnapshotRecoverRequest extends Equatable {
  final int? id;
  final bool? deleteLocal;
  final String? encryptionPassword;

  const SnapshotRecoverRequest({
    this.id,
    this.deleteLocal,
    this.encryptionPassword,
  });

  factory SnapshotRecoverRequest.fromJson(Map<String, dynamic> json) =>
      _$SnapshotRecoverRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SnapshotRecoverRequestToJson(this);

  @override
  List<Object?> get props => [id, deleteLocal, encryptionPassword];
}

/// 快照恢复结果
@JsonSerializable()
class SnapshotRecoverResult extends Equatable {
  final bool? success;
  final String? message;
  final SnapshotInfo? snapshotInfo;

  const SnapshotRecoverResult({
    this.success,
    this.message,
    this.snapshotInfo,
  });

  factory SnapshotRecoverResult.fromJson(Map<String, dynamic> json) =>
      _$SnapshotRecoverResultFromJson(json);
  Map<String, dynamic> toJson() => _$SnapshotRecoverResultToJson(this);

  @override
  List<Object?> get props => [success, message, snapshotInfo];
}

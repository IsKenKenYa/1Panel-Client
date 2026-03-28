import 'package:equatable/equatable.dart';

/// 通过ID操作模型
class OperateByID extends Equatable {
  final int id;

  const OperateByID({
    required this.id,
  });

  factory OperateByID.fromJson(Map<String, dynamic> json) {
    return OperateByID(
      id: json['id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }

  @override
  List<Object?> get props => [id];
}

/// 通过类型操作模型
class OperateByType extends Equatable {
  final int? id;
  final String name;
  final String type;

  const OperateByType({
    this.id,
    required this.name,
    required this.type,
  });

  factory OperateByType.fromJson(Map<String, dynamic> json) {
    return OperateByType(
      id: json['id'] as int?,
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [id, name, type];
}

/// 分页请求模型
class PageRequest extends Equatable {
  final int page;
  final int pageSize;

  const PageRequest({
    this.page = 1,
    this.pageSize = 20,
  });

  factory PageRequest.fromJson(Map<String, dynamic> json) {
    return PageRequest(
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
    };
  }

  @override
  List<Object?> get props => [page, pageSize];
}

/// 分页结果模型
class PageResult<T> extends Equatable {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const PageResult({
    required this.items,
    required this.total,
    this.page = 1,
    this.pageSize = 20,
    this.totalPages = 1,
  });

  factory PageResult.fromJson(
      Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    var itemsJson = json['items'];
    List<T> itemsList = [];

    if (itemsJson is List) {
      itemsList = itemsJson.map((item) => fromJsonT(item)).toList();
    } else if (itemsJson is Map) {
      // Handle case where items is a Map (e.g. empty map or associative array)
      // For now, treat as empty list to avoid crash, as we expect a List
      itemsList = [];
    }

    return PageResult(
      items: itemsList,
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [items, total, page, pageSize, totalPages];
}

/// 通用搜索模型
class SearchRequest extends PageRequest {
  final String? info;

  const SearchRequest({
    this.info,
    super.page,
    super.pageSize,
  });

  factory SearchRequest.fromJson(Map<String, dynamic> json) {
    return SearchRequest(
      info: json['info'] as String?,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (info != null) json['info'] = info;
    return json;
  }

  @override
  List<Object?> get props => [...super.props, info];
}

/// 带分页的搜索请求
class SearchWithPage extends PageRequest {
  final String? info;

  const SearchWithPage({
    this.info,
    super.page,
    super.pageSize,
  });

  factory SearchWithPage.fromJson(Map<String, dynamic> json) {
    return SearchWithPage(
      info: json['info'] as String?,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (info != null) json['info'] = info;
    return json;
  }

  @override
  List<Object?> get props => [...super.props, info];
}

/// 通用响应模型
class CommonResponse<T> extends Equatable {
  final bool success;
  final String message;
  final T? data;
  final String? code;
  final int? timestamp;

  const CommonResponse({
    required this.success,
    required this.message,
    this.data,
    this.code,
    this.timestamp,
  });

  factory CommonResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return CommonResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      code: json['code'] as String?,
      timestamp: json['timestamp'] as int?,
    );
  }

  @override
  List<Object?> get props => [success, message, data, code, timestamp];
}

/// 批量删除模型
class BatchDelete extends Equatable {
  final List<int> ids;

  const BatchDelete({
    required this.ids,
  });

  factory BatchDelete.fromJson(Map<String, dynamic> json) {
    return BatchDelete(
      ids: (json['ids'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ids': ids,
    };
  }

  @override
  List<Object?> get props => [ids];
}

/// 强制删除模型
class ForceDelete extends Equatable {
  final List<int> ids;
  final bool forceDelete;

  const ForceDelete({
    required this.ids,
    this.forceDelete = false,
  });

  factory ForceDelete.fromJson(Map<String, dynamic> json) {
    return ForceDelete(
      ids: (json['ids'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      forceDelete: json['forceDelete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ids': ids,
      'forceDelete': forceDelete,
    };
  }

  @override
  List<Object?> get props => [ids, forceDelete];
}

/// 按名称操作模型
class OperationWithName extends Equatable {
  final String name;
  final String? operation;

  const OperationWithName({
    required this.name,
    this.operation,
  });

  factory OperationWithName.fromJson(Map<String, dynamic> json) {
    return OperationWithName(
      name: json['name'] as String,
      operation: json['operation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (operation != null) 'operation': operation,
    };
  }

  @override
  List<Object?> get props => [name, operation];
}

/// 记录搜索模型
class RecordSearch extends PageRequest {
  final String? info;
  final String? startTime;
  final String? endTime;

  const RecordSearch({
    this.info,
    this.startTime,
    this.endTime,
    super.page,
    super.pageSize,
  });

  factory RecordSearch.fromJson(Map<String, dynamic> json) {
    return RecordSearch(
      info: json['info'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (info != null) json['info'] = info;
    if (startTime != null) json['startTime'] = startTime;
    if (endTime != null) json['endTime'] = endTime;
    return json;
  }

  @override
  List<Object?> get props => [...super.props, info, startTime, endTime];
}

/// 分组创建模型
class GroupCreate extends Equatable {
  final int? id;
  final String name;
  final String type;

  const GroupCreate({
    this.id,
    required this.name,
    required this.type,
  });

  factory GroupCreate.fromJson(Map<String, dynamic> json) {
    return GroupCreate(
      id: json['id'] as int?,
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [id, name, type];
}

/// 分组更新模型
class GroupUpdate extends Equatable {
  final int id;
  final String name;
  final String type;

  const GroupUpdate({
    required this.id,
    required this.name,
    required this.type,
  });

  factory GroupUpdate.fromJson(Map<String, dynamic> json) {
    return GroupUpdate(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [id, name, type];
}

/// 分组搜索模型
class GroupSearch extends Equatable {
  final String? type;

  const GroupSearch({
    this.type,
  });

  factory GroupSearch.fromJson(Map<String, dynamic> json) {
    return GroupSearch(
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (type != null) 'type': type,
    };
  }

  @override
  List<Object?> get props => [type];
}

/// 通用备份模型
class CommonBackup extends Equatable {
  final String type;
  final String name;
  final String? detailName;
  final String? secret;

  const CommonBackup({
    required this.type,
    required this.name,
    this.detailName,
    this.secret,
  });

  factory CommonBackup.fromJson(Map<String, dynamic> json) {
    return CommonBackup(
      type: json['type'] as String,
      name: json['name'] as String,
      detailName: json['detailName'] as String?,
      secret: json['secret'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      if (detailName != null) 'detailName': detailName,
      if (secret != null) 'secret': secret,
    };
  }

  @override
  List<Object?> get props => [type, name, detailName, secret];
}

/// 通用恢复模型
class CommonRecover extends Equatable {
  final String type;
  final String name;
  final String? detailName;
  final String? secret;
  final String? file;

  const CommonRecover({
    required this.type,
    required this.name,
    this.detailName,
    this.secret,
    this.file,
  });

  factory CommonRecover.fromJson(Map<String, dynamic> json) {
    return CommonRecover(
      type: json['type'] as String,
      name: json['name'] as String,
      detailName: json['detailName'] as String?,
      secret: json['secret'] as String?,
      file: json['file'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      if (detailName != null) 'detailName': detailName,
      if (secret != null) 'secret': secret,
      if (file != null) 'file': file,
    };
  }

  @override
  List<Object?> get props => [type, name, detailName, secret, file];
}

/// 状态枚举
class Status {
  static const String enabled = 'Enabled';
  static const String disabled = 'Disabled';
  static const String running = 'Running';
  static const String stopped = 'Stopped';
  static const String error = 'Error';
  static const String pending = 'Pending';
  static const String creating = 'Creating';
  static const String deleting = 'Deleting';
  static const String updating = 'Updating';
}

/// 排序方向枚举
enum SortDirection {
  asc('asc', '升序'),
  desc('desc', '降序');

  const SortDirection(this.value, this.displayName);

  final String value;
  final String displayName;

  static SortDirection fromString(String value) {
    return SortDirection.values.firstWhere(
      (direction) => direction.value == value,
      orElse: () => SortDirection.desc,
    );
  }
}

/// 系统信息模型
class SystemInfo extends Equatable {
  final String? hostname;
  final String? os;
  final String? osVersion;
  final String? platform;
  final String? platformVersion;
  final String? kernelVersion;
  final String? architecture;
  final int? cpuCores;
  final double? cpuUsage;
  final int? totalMemory;
  final int? usedMemory;
  final double? memoryUsage;
  final int? totalDisk;
  final int? usedDisk;
  final double? diskUsage;
  final String? uptime;
  final int? loadAverage1m;
  final int? loadAverage5m;
  final int? loadAverage15m;
  final String? panelVersion;
  final String? panelStatus;
  final int? appCount;
  final int? containerCount;
  final int? websiteCount;
  final int? databaseCount;

  const SystemInfo({
    this.hostname,
    this.os,
    this.osVersion,
    this.platform,
    this.platformVersion,
    this.kernelVersion,
    this.architecture,
    this.cpuCores,
    this.cpuUsage,
    this.totalMemory,
    this.usedMemory,
    this.memoryUsage,
    this.totalDisk,
    this.usedDisk,
    this.diskUsage,
    this.uptime,
    this.loadAverage1m,
    this.loadAverage5m,
    this.loadAverage15m,
    this.panelVersion,
    this.panelStatus,
    this.appCount,
    this.containerCount,
    this.websiteCount,
    this.databaseCount,
  });

  factory SystemInfo.fromJson(Map<String, dynamic> json) {
    return SystemInfo(
      hostname: json['hostname'] as String?,
      os: json['os'] as String?,
      osVersion: json['osVersion'] as String?,
      platform: json['platform'] as String?,
      platformVersion: json['platformVersion'] as String?,
      kernelVersion: json['kernelVersion'] as String?,
      architecture: json['architecture'] as String?,
      cpuCores: json['cpuCores'] as int?,
      cpuUsage: (json['cpuUsage'] as num?)?.toDouble(),
      totalMemory: json['totalMemory'] as int?,
      usedMemory: json['usedMemory'] as int?,
      memoryUsage: (json['memoryUsage'] as num?)?.toDouble(),
      totalDisk: json['totalDisk'] as int?,
      usedDisk: json['usedDisk'] as int?,
      diskUsage: (json['diskUsage'] as num?)?.toDouble(),
      uptime: json['uptime'] as String?,
      loadAverage1m: json['loadAverage1m'] as int?,
      loadAverage5m: json['loadAverage5m'] as int?,
      loadAverage15m: json['loadAverage15m'] as int?,
      panelVersion: json['panelVersion'] as String?,
      panelStatus: json['panelStatus'] as String?,
      appCount: json['appCount'] as int?,
      containerCount: json['containerCount'] as int?,
      websiteCount: json['websiteCount'] as int?,
      databaseCount: json['databaseCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hostname': hostname,
      'os': os,
      'osVersion': osVersion,
      'platform': platform,
      'platformVersion': platformVersion,
      'kernelVersion': kernelVersion,
      'architecture': architecture,
      'cpuCores': cpuCores,
      'cpuUsage': cpuUsage,
      'totalMemory': totalMemory,
      'usedMemory': usedMemory,
      'memoryUsage': memoryUsage,
      'totalDisk': totalDisk,
      'usedDisk': usedDisk,
      'diskUsage': diskUsage,
      'uptime': uptime,
      'loadAverage1m': loadAverage1m,
      'loadAverage5m': loadAverage5m,
      'loadAverage15m': loadAverage15m,
      'panelVersion': panelVersion,
      'panelStatus': panelStatus,
      'appCount': appCount,
      'containerCount': containerCount,
      'websiteCount': websiteCount,
      'databaseCount': databaseCount,
    };
  }

  @override
  List<Object?> get props => [
        hostname,
        os,
        osVersion,
        platform,
        platformVersion,
        kernelVersion,
        architecture,
        cpuCores,
        cpuUsage,
        totalMemory,
        usedMemory,
        memoryUsage,
        totalDisk,
        usedDisk,
        diskUsage,
        uptime,
        loadAverage1m,
        loadAverage5m,
        loadAverage15m,
        panelVersion,
        panelStatus,
        appCount,
        containerCount,
        websiteCount,
        databaseCount,
      ];
}

/// 命令信息模型
class CommandInfo extends Equatable {
  final String? command;
  final String? groupBelong;
  final int? groupID;
  final int? id;
  final String? name;
  final String? type;

  const CommandInfo({
    this.command,
    this.groupBelong,
    this.groupID,
    this.id,
    this.name,
    this.type,
  });

  factory CommandInfo.fromJson(Map<String, dynamic> json) {
    return CommandInfo(
      command: json['command'] as String?,
      groupBelong: json['groupBelong'] as String?,
      groupID: json['groupID'] as int?,
      id: json['id'] as int?,
      name: json['name'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'command': command,
      'groupBelong': groupBelong,
      'groupID': groupID,
      'id': id,
      'name': name,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [command, groupBelong, groupID, id, name, type];
}

/// 命令操作模型
class CommandOperate extends Equatable {
  final String command;
  final String? groupBelong;
  final int? groupID;
  final int? id;
  final String name;
  final String? type;

  const CommandOperate({
    required this.command,
    this.groupBelong,
    this.groupID,
    this.id,
    required this.name,
    this.type,
  });

  factory CommandOperate.fromJson(Map<String, dynamic> json) {
    return CommandOperate(
      command: json['command'] as String,
      groupBelong: json['groupBelong'] as String?,
      groupID: json['groupID'] as int?,
      id: json['id'] as int?,
      name: json['name'] as String,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'command': command,
      'groupBelong': groupBelong,
      'groupID': groupID,
      'id': id,
      'name': name,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [command, groupBelong, groupID, id, name, type];
}

/// 命令树形模型
class CommandTree extends Equatable {
  final List<CommandTree>? children;
  final String? label;
  final String? value;

  const CommandTree({
    this.children,
    this.label,
    this.value,
  });

  factory CommandTree.fromJson(Map<String, dynamic> json) {
    return CommandTree(
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => CommandTree.fromJson(e as Map<String, dynamic>))
          .toList(),
      label: json['label'] as String?,
      value: json['value'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'children': children?.map((e) => e.toJson()).toList(),
      'label': label,
      'value': value,
    };
  }

  @override
  List<Object?> get props => [children, label, value];
}

/// 脚本操作模型
class ScriptOperate extends Equatable {
  final String? description;
  final String? groups;
  final int? id;
  final bool? isInteractive;
  final String? name;
  final String? script;

  const ScriptOperate({
    this.description,
    this.groups,
    this.id,
    this.isInteractive,
    this.name,
    this.script,
  });

  factory ScriptOperate.fromJson(Map<String, dynamic> json) {
    return ScriptOperate(
      description: json['description'] as String?,
      groups: json['groups'] as String?,
      id: json['id'] as int?,
      isInteractive: json['isInteractive'] as bool?,
      name: json['name'] as String?,
      script: json['script'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'groups': groups,
      'id': id,
      'isInteractive': isInteractive,
      'name': name,
      'script': script,
    };
  }

  @override
  List<Object?> get props =>
      [description, groups, id, isInteractive, name, script];
}

/// 脚本选项模型
class ScriptOptions extends Equatable {
  final int? id;
  final String? name;

  const ScriptOptions({
    this.id,
    this.name,
  });

  factory ScriptOptions.fromJson(Map<String, dynamic> json) {
    return ScriptOptions(
      id: json['id'] as int?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  List<Object?> get props => [id, name];
}

/// 通过IDs操作模型
class OperateByIDs extends Equatable {
  final List<int> ids;

  const OperateByIDs({
    required this.ids,
  });

  factory OperateByIDs.fromJson(Map<String, dynamic> json) {
    return OperateByIDs(
      ids: (json['ids'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ids': ids,
    };
  }

  @override
  List<Object?> get props => [ids];
}

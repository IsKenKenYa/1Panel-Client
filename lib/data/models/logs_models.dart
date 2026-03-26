import 'package:equatable/equatable.dart';

class OperationLogSearchRequest extends Equatable {
  final int page;
  final int pageSize;
  final String? source;
  final String? status;
  final String? node;
  final String? operation;

  const OperationLogSearchRequest({
    this.page = 1,
    this.pageSize = 20,
    this.source,
    this.status,
    this.node,
    this.operation,
  });

  factory OperationLogSearchRequest.fromJson(Map<String, dynamic> json) {
    return OperationLogSearchRequest(
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      source: json['source'] as String?,
      status: json['status'] as String?,
      node: json['node'] as String?,
      operation: json['operation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'source': source,
      'status': status,
      'node': node,
      'operation': operation,
    };
  }

  @override
  List<Object?> get props => [page, pageSize, source, status, node, operation];
}

class LoginLogSearchRequest extends Equatable {
  final int page;
  final int pageSize;
  final String? ip;
  final String? status;

  const LoginLogSearchRequest({
    this.page = 1,
    this.pageSize = 20,
    this.ip,
    this.status,
  });

  factory LoginLogSearchRequest.fromJson(Map<String, dynamic> json) {
    return LoginLogSearchRequest(
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      ip: json['ip'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'ip': ip,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [page, pageSize, ip, status];
}

class LogsCleanRequest extends Equatable {
  final String logType;

  const LogsCleanRequest({
    required this.logType,
  });

  factory LogsCleanRequest.fromJson(Map<String, dynamic> json) {
    return LogsCleanRequest(
      logType: json['logType'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'logType': logType,
      };

  @override
  List<Object?> get props => [logType];
}

class OperationLogEntry extends Equatable {
  final int? id;
  final String? source;
  final String? node;
  final String? ip;
  final String? path;
  final String? method;
  final String? userAgent;
  final String? status;
  final String? message;
  final String? detailZh;
  final String? detailEn;
  final String? createdAt;
  final dynamic latency;

  const OperationLogEntry({
    this.id,
    this.source,
    this.node,
    this.ip,
    this.path,
    this.method,
    this.userAgent,
    this.status,
    this.message,
    this.detailZh,
    this.detailEn,
    this.createdAt,
    this.latency,
  });

  factory OperationLogEntry.fromJson(Map<String, dynamic> json) {
    return OperationLogEntry(
      id: json['id'] as int?,
      source: json['source'] as String?,
      node: json['node'] as String?,
      ip: json['ip'] as String?,
      path: json['path'] as String?,
      method: json['method'] as String?,
      userAgent: json['userAgent'] as String?,
      status: json['status']?.toString(),
      message: json['message'] as String?,
      detailZh: json['detailZH'] as String?,
      detailEn: json['detailEN'] as String?,
      createdAt: json['createdAt']?.toString(),
      latency: json['latency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'node': node,
      'ip': ip,
      'path': path,
      'method': method,
      'userAgent': userAgent,
      'status': status,
      'message': message,
      'detailZH': detailZh,
      'detailEN': detailEn,
      'createdAt': createdAt,
      'latency': latency,
    };
  }

  @override
  List<Object?> get props => [
        id,
        source,
        node,
        ip,
        path,
        method,
        userAgent,
        status,
        message,
        detailZh,
        detailEn,
        createdAt,
        latency,
      ];
}

class LoginLogEntry extends Equatable {
  final int? id;
  final String? ip;
  final String? address;
  final String? agent;
  final String? status;
  final String? message;
  final String? createdAt;

  const LoginLogEntry({
    this.id,
    this.ip,
    this.address,
    this.agent,
    this.status,
    this.message,
    this.createdAt,
  });

  factory LoginLogEntry.fromJson(Map<String, dynamic> json) {
    return LoginLogEntry(
      id: json['id'] as int?,
      ip: json['ip'] as String?,
      address: json['address'] as String?,
      agent: json['agent'] as String?,
      status: json['status'] as String?,
      message: json['message'] as String?,
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ip': ip,
      'address': address,
      'agent': agent,
      'status': status,
      'message': message,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [id, ip, address, agent, status, message, createdAt];
}

/// 日志搜索模型
class LogSearch extends Equatable {
  final String? search;
  final String? level;
  final String? type;
  final String? appName;
  final String? user;
  final String? ip;
  final String? startTime;
  final String? endTime;
  final int page;
  final int pageSize;

  const LogSearch({
    this.search,
    this.level,
    this.type,
    this.appName,
    this.user,
    this.ip,
    this.startTime,
    this.endTime,
    this.page = 1,
    this.pageSize = 20,
  });

  factory LogSearch.fromJson(Map<String, dynamic> json) {
    return LogSearch(
      search: json['search'] as String?,
      level: json['level'] as String?,
      type: json['type'] as String?,
      appName: json['appName'] as String?,
      user: json['user'] as String?,
      ip: json['ip'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'search': search,
      'level': level,
      'type': type,
      'appName': appName,
      'user': user,
      'ip': ip,
      'startTime': startTime,
      'endTime': endTime,
      'page': page,
      'pageSize': pageSize,
    };
  }

  @override
  List<Object?> get props => [
        search,
        level,
        type,
        appName,
        user,
        ip,
        startTime,
        endTime,
        page,
        pageSize,
      ];
}

/// 日志信息模型
class LogInfo extends Equatable {
  final int id;
  final String type;
  final String level;
  final String message;
  final String? source;
  final String? appName;
  final String? user;
  final String? ip;
  final DateTime? timestamp;
  final Map<String, dynamic>? details;
  final String? hostname;

  const LogInfo({
    required this.id,
    required this.type,
    required this.level,
    required this.message,
    this.source,
    this.appName,
    this.user,
    this.ip,
    this.timestamp,
    this.details,
    this.hostname,
  });

  factory LogInfo.fromJson(Map<String, dynamic> json) {
    return LogInfo(
      id: json['id'] as int,
      type: json['type'] as String,
      level: json['level'] as String,
      message: json['message'] as String,
      source: json['source'] as String?,
      appName: json['appName'] as String?,
      user: json['user'] as String?,
      ip: json['ip'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      details: json['details'] as Map<String, dynamic>?,
      hostname: json['hostname'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'level': level,
      'message': message,
      'source': source,
      'appName': appName,
      'user': user,
      'ip': ip,
      'timestamp': timestamp?.toIso8601String(),
      'details': details,
      'hostname': hostname,
    };
  }

  @override
  List<Object?> get props => [
        id,
        type,
        level,
        message,
        source,
        appName,
        user,
        ip,
        timestamp,
        details,
        hostname,
      ];
}

/// 日志文件信息模型
class LogFileInfo extends Equatable {
  final String filename;
  final String path;
  final int size;
  final DateTime? modifiedAt;
  final String? type;

  const LogFileInfo({
    required this.filename,
    required this.path,
    required this.size,
    this.modifiedAt,
    this.type,
  });

  factory LogFileInfo.fromJson(Map<String, dynamic> json) {
    return LogFileInfo(
      filename: json['filename'] as String,
      path: json['path'] as String,
      size: json['size'] as int,
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'path': path,
      'size': size,
      'modifiedAt': modifiedAt?.toIso8601String(),
      'type': type,
    };
  }

  @override
  List<Object?> get props => [filename, path, size, modifiedAt, type];
}

/// 日志文件内容请求模型
class LogFileContent extends Equatable {
  final String filename;
  final int lines;
  final String? search;
  final String? level;
  final String? startTime;
  final String? endTime;

  const LogFileContent({
    required this.filename,
    this.lines = 100,
    this.search,
    this.level,
    this.startTime,
    this.endTime,
  });

  factory LogFileContent.fromJson(Map<String, dynamic> json) {
    return LogFileContent(
      filename: json['filename'] as String,
      lines: json['lines'] as int? ?? 100,
      search: json['search'] as String?,
      level: json['level'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'lines': lines,
      'search': search,
      'level': level,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  @override
  List<Object?> get props => [
        filename,
        lines,
        search,
        level,
        startTime,
        endTime,
      ];
}

/// 日志统计模型
class LogStats extends Equatable {
  final String type;
  final int total;
  final int error;
  final int warning;
  final int info;
  final int debug;
  final DateTime? lastUpdated;

  const LogStats({
    required this.type,
    required this.total,
    required this.error,
    required this.warning,
    required this.info,
    required this.debug,
    this.lastUpdated,
  });

  factory LogStats.fromJson(Map<String, dynamic> json) {
    return LogStats(
      type: json['type'] as String,
      total: json['total'] as int,
      error: json['error'] as int,
      warning: json['warning'] as int,
      info: json['info'] as int,
      debug: json['debug'] as int,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'total': total,
      'error': error,
      'warning': warning,
      'info': info,
      'debug': debug,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        type,
        total,
        error,
        warning,
        info,
        debug,
        lastUpdated,
      ];
}

/// 日志清理模型
class LogClean extends Equatable {
  final String type;
  final int days;
  final bool? force;

  const LogClean({
    required this.type,
    required this.days,
    this.force,
  });

  factory LogClean.fromJson(Map<String, dynamic> json) {
    return LogClean(
      type: json['type'] as String,
      days: json['days'] as int,
      force: json['force'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'days': days,
      'force': force,
    };
  }

  @override
  List<Object?> get props => [type, days, force];
}

/// 日志导出模型
class LogExport extends Equatable {
  final String type;
  final String? search;
  final String? level;
  final String? startTime;
  final String? endTime;
  final String format;

  const LogExport({
    required this.type,
    this.search,
    this.level,
    this.startTime,
    this.endTime,
    this.format = 'json',
  });

  factory LogExport.fromJson(Map<String, dynamic> json) {
    return LogExport(
      type: json['type'] as String,
      search: json['search'] as String?,
      level: json['level'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      format: json['format'] as String? ?? 'json',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'search': search,
      'level': level,
      'startTime': startTime,
      'endTime': endTime,
      'format': format,
    };
  }

  @override
  List<Object?> get props => [
        type,
        search,
        level,
        startTime,
        endTime,
        format,
      ];
}

/// 日志级别枚举
enum LogLevel {
  debug('debug', '调试'),
  info('info', '信息'),
  warning('warning', '警告'),
  error('error', '错误'),
  fatal('fatal', '致命错误');

  const LogLevel(this.value, this.displayName);

  final String value;
  final String displayName;

  static LogLevel fromString(String value) {
    return LogLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => LogLevel.info,
    );
  }
}

/// 日志类型枚举
enum LogType {
  system('system', '系统日志'),
  application('application', '应用日志'),
  security('security', '安全日志'),
  operation('operation', '操作日志'),
  access('access', '访问日志'),
  error('error', '错误日志'),
  audit('audit', '审计日志'),
  database('database', '数据库日志');

  const LogType(this.value, this.displayName);

  final String value;
  final String displayName;

  static LogType fromString(String value) {
    return LogType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => LogType.system,
    );
  }
}

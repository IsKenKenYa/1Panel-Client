import 'package:equatable/equatable.dart';

/// Terminal session create request model
class TerminalSessionCreate extends Equatable {
  final String? containerId;
  final String? command;
  final String? user;
  final String? workDir;

  const TerminalSessionCreate({
    this.containerId,
    this.command,
    this.user,
    this.workDir,
  });

  factory TerminalSessionCreate.fromJson(Map<String, dynamic> json) {
    return TerminalSessionCreate(
      containerId: json['containerId'] as String?,
      command: json['command'] as String?,
      user: json['user'] as String?,
      workDir: json['workDir'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'containerId': containerId,
      'command': command,
      'user': user,
      'workDir': workDir,
    };
  }

  @override
  List<Object?> get props => [containerId, command, user, workDir];
}

/// Terminal session operate model
class TerminalSessionOperate extends Equatable {
  final String sessionId;
  final String operation;
  final String? data;

  const TerminalSessionOperate({
    required this.sessionId,
    required this.operation,
    this.data,
  });

  factory TerminalSessionOperate.fromJson(Map<String, dynamic> json) {
    return TerminalSessionOperate(
      sessionId: json['sessionId'] as String,
      operation: json['operation'] as String,
      data: json['data'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'operation': operation,
      'data': data,
    };
  }

  @override
  List<Object?> get props => [sessionId, operation, data];
}

/// Terminal command execute model
class TerminalCommandExecute extends Equatable {
  final String command;
  final String? containerId;
  final String? user;
  final String? workDir;
  final int? timeout;

  const TerminalCommandExecute({
    required this.command,
    this.containerId,
    this.user,
    this.workDir,
    this.timeout,
  });

  factory TerminalCommandExecute.fromJson(Map<String, dynamic> json) {
    return TerminalCommandExecute(
      command: json['command'] as String,
      containerId: json['containerId'] as String?,
      user: json['user'] as String?,
      workDir: json['workDir'] as String?,
      timeout: json['timeout'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'command': command,
      'containerId': containerId,
      'user': user,
      'workDir': workDir,
      'timeout': timeout,
    };
  }

  @override
  List<Object?> get props => [command, containerId, user, workDir, timeout];
}

/// Terminal command result model
class TerminalCommandResult extends Equatable {
  final String? output;
  final String? error;
  final int? exitCode;
  final bool? success;

  const TerminalCommandResult({
    this.output,
    this.error,
    this.exitCode,
    this.success,
  });

  factory TerminalCommandResult.fromJson(Map<String, dynamic> json) {
    return TerminalCommandResult(
      output: json['output'] as String?,
      error: json['error'] as String?,
      exitCode: json['exitCode'] as int?,
      success: json['success'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'output': output,
      'error': error,
      'exitCode': exitCode,
      'success': success,
    };
  }

  @override
  List<Object?> get props => [output, error, exitCode, success];
}

/// Terminal session info model
class TerminalSessionInfo extends Equatable {
  final String? sessionId;
  final String? status;
  final String? containerId;
  final String? createTime;
  final String? lastActivityTime;

  const TerminalSessionInfo({
    this.sessionId,
    this.status,
    this.containerId,
    this.createTime,
    this.lastActivityTime,
  });

  factory TerminalSessionInfo.fromJson(Map<String, dynamic> json) {
    return TerminalSessionInfo(
      sessionId: json['sessionId'] as String?,
      status: json['status'] as String?,
      containerId: json['containerId'] as String?,
      createTime: json['createTime'] as String?,
      lastActivityTime: json['lastActivityTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'status': status,
      'containerId': containerId,
      'createTime': createTime,
      'lastActivityTime': lastActivityTime,
    };
  }

  @override
  List<Object?> get props =>
      [sessionId, status, containerId, createTime, lastActivityTime];
}

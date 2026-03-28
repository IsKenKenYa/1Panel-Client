import 'package:equatable/equatable.dart';

class HostToolRequest extends Equatable {
  const HostToolRequest({
    this.type = 'supervisord',
    this.operate,
  });

  final String type;
  final String? operate;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        if (operate != null) 'operate': operate,
      };

  @override
  List<Object?> get props => <Object?>[type, operate];
}

class HostToolConfigRequest extends Equatable {
  const HostToolConfigRequest({
    this.type = 'supervisord',
    required this.operate,
    this.content = '',
  });

  final String type;
  final String operate;
  final String content;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'operate': operate,
        'content': content,
      };

  @override
  List<Object?> get props => <Object?>[type, operate, content];
}

class HostToolCreateRequest extends Equatable {
  const HostToolCreateRequest({
    this.type = 'supervisord',
    this.configPath = '',
    this.serviceName = '',
  });

  final String type;
  final String configPath;
  final String serviceName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'configPath': configPath,
        'serviceName': serviceName,
      };

  @override
  List<Object?> get props => <Object?>[type, configPath, serviceName];
}

class SupervisorServiceInfo extends Equatable {
  const SupervisorServiceInfo({
    this.configPath = '',
    this.includeDir = '',
    this.logPath = '',
    this.isExist = false,
    this.init = false,
    this.msg = '',
    this.version = '',
    this.status = '',
    this.ctlExist = false,
    this.serviceName = '',
  });

  final String configPath;
  final String includeDir;
  final String logPath;
  final bool isExist;
  final bool init;
  final String msg;
  final String version;
  final String status;
  final bool ctlExist;
  final String serviceName;

  factory SupervisorServiceInfo.fromJson(Map<String, dynamic> json) {
    return SupervisorServiceInfo(
      configPath: json['configPath'] as String? ?? '',
      includeDir: json['includeDir'] as String? ?? '',
      logPath: json['logPath'] as String? ?? '',
      isExist: json['isExist'] as bool? ?? false,
      init: json['init'] as bool? ?? false,
      msg: json['msg'] as String? ?? '',
      version: json['version'] as String? ?? '',
      status: json['status'] as String? ?? '',
      ctlExist: json['ctlExist'] as bool? ?? false,
      serviceName: json['serviceName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'configPath': configPath,
        'includeDir': includeDir,
        'logPath': logPath,
        'isExist': isExist,
        'init': init,
        'msg': msg,
        'version': version,
        'status': status,
        'ctlExist': ctlExist,
        'serviceName': serviceName,
      };

  @override
  List<Object?> get props => <Object?>[
        configPath,
        includeDir,
        logPath,
        isExist,
        init,
        msg,
        version,
        status,
        ctlExist,
        serviceName,
      ];
}

class HostToolStatusResponse extends Equatable {
  const HostToolStatusResponse({
    this.type = '',
    this.config = const SupervisorServiceInfo(),
  });

  final String type;
  final SupervisorServiceInfo config;

  factory HostToolStatusResponse.fromJson(Map<String, dynamic> json) {
    final rawConfig = json['config'];
    return HostToolStatusResponse(
      type: json['type'] as String? ?? '',
      config: rawConfig is Map<String, dynamic>
          ? SupervisorServiceInfo.fromJson(rawConfig)
          : const SupervisorServiceInfo(),
    );
  }

  @override
  List<Object?> get props => <Object?>[type, config];
}

class HostToolConfigResponse extends Equatable {
  const HostToolConfigResponse({
    this.type = '',
    this.content = '',
  });

  final String type;
  final String content;

  factory HostToolConfigResponse.fromJson(Map<String, dynamic> json) {
    return HostToolConfigResponse(
      type: json['type'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[type, content];
}

class HostToolProcessStatus extends Equatable {
  const HostToolProcessStatus({
    this.pid = '',
    this.status = '',
    this.uptime = '',
    this.name = '',
    this.msg = '',
  });

  final String pid;
  final String status;
  final String uptime;
  final String name;
  final String msg;

  factory HostToolProcessStatus.fromJson(Map<String, dynamic> json) {
    return HostToolProcessStatus(
      pid: json['pid'] as String? ?? json['PID'] as String? ?? '',
      status: json['status'] as String? ?? '',
      uptime: json['uptime'] as String? ?? '',
      name: json['name'] as String? ?? '',
      msg: json['msg'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'PID': pid,
        'status': status,
        'uptime': uptime,
        'name': name,
        'msg': msg,
      };

  @override
  List<Object?> get props => <Object?>[pid, status, uptime, name, msg];
}

class HostToolProcessConfig extends Equatable {
  const HostToolProcessConfig({
    this.name = '',
    this.command = '',
    this.user = '',
    this.dir = '',
    this.numprocs = '',
    this.msg = '',
    this.environment = '',
    this.autoRestart = '',
    this.autoStart = '',
    this.status = const <HostToolProcessStatus>[],
  });

  final String name;
  final String command;
  final String user;
  final String dir;
  final String numprocs;
  final String msg;
  final String environment;
  final String autoRestart;
  final String autoStart;
  final List<HostToolProcessStatus> status;

  factory HostToolProcessConfig.fromJson(Map<String, dynamic> json) {
    return HostToolProcessConfig(
      name: json['name'] as String? ?? '',
      command: json['command'] as String? ?? '',
      user: json['user'] as String? ?? '',
      dir: json['dir'] as String? ?? '',
      numprocs: json['numprocs']?.toString() ?? '',
      msg: json['msg'] as String? ?? '',
      environment: json['environment'] as String? ?? '',
      autoRestart: json['autoRestart'] as String? ?? '',
      autoStart: json['autoStart'] as String? ?? '',
      status: (json['status'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(HostToolProcessStatus.fromJson)
              .toList(growable: false) ??
          const <HostToolProcessStatus>[],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'command': command,
        'user': user,
        'dir': dir,
        'numprocs': numprocs,
        'msg': msg,
        'environment': environment,
        'autoRestart': autoRestart,
        'autoStart': autoStart,
        'status':
            status.map((HostToolProcessStatus item) => item.toJson()).toList(),
      };

  @override
  List<Object?> get props => <Object?>[
        name,
        command,
        user,
        dir,
        numprocs,
        msg,
        environment,
        autoRestart,
        autoStart,
        status,
      ];
}

class HostToolProcessConfigRequest extends Equatable {
  const HostToolProcessConfigRequest({
    required this.name,
    required this.operate,
    required this.command,
    required this.user,
    required this.dir,
    required this.numprocs,
    required this.autoRestart,
    required this.autoStart,
    this.environment = '',
  });

  final String name;
  final String operate;
  final String command;
  final String user;
  final String dir;
  final String numprocs;
  final String autoRestart;
  final String autoStart;
  final String environment;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'operate': operate,
        'command': command,
        'user': user,
        'dir': dir,
        'numprocs': numprocs,
        'autoRestart': autoRestart,
        'autoStart': autoStart,
        'environment': environment,
      };

  @override
  List<Object?> get props => <Object?>[
        name,
        operate,
        command,
        user,
        dir,
        numprocs,
        autoRestart,
        autoStart,
        environment,
      ];
}

class HostToolProcessOperateRequest extends Equatable {
  const HostToolProcessOperateRequest({
    required this.name,
    required this.operate,
  });

  final String name;
  final String operate;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'operate': operate,
      };

  @override
  List<Object?> get props => <Object?>[name, operate];
}

class HostToolProcessFileRequest extends Equatable {
  const HostToolProcessFileRequest({
    required this.name,
    required this.operate,
    required this.file,
    this.content = '',
  });

  final String name;
  final String operate;
  final String file;
  final String content;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'operate': operate,
        'file': file,
        'content': content,
      };

  @override
  List<Object?> get props => <Object?>[name, operate, file, content];
}

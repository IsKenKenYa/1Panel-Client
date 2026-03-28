part of '../runtime_models.dart';

class SupervisorProcessStatus extends Equatable {
  final String pid;
  final String status;
  final String uptime;
  final String name;

  const SupervisorProcessStatus({
    this.pid = '',
    this.status = '',
    this.uptime = '',
    this.name = '',
  });

  factory SupervisorProcessStatus.fromJson(Map<String, dynamic> json) {
    return SupervisorProcessStatus(
      pid: json['pid'] as String? ?? json['PID'] as String? ?? '',
      status: json['status'] as String? ?? '',
      uptime: json['uptime'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'PID': pid,
        'status': status,
        'uptime': uptime,
        'name': name,
      };

  @override
  List<Object?> get props => [pid, status, uptime, name];
}

class SupervisorProcessInfo extends Equatable {
  final String name;
  final String command;
  final String user;
  final String dir;
  final String numprocs;
  final String environment;
  final String autoStart;
  final String autoRestart;
  final List<SupervisorProcessStatus> status;

  const SupervisorProcessInfo({
    required this.name,
    this.command = '',
    this.user = '',
    this.dir = '',
    this.numprocs = '',
    this.environment = '',
    this.autoStart = '',
    this.autoRestart = '',
    this.status = const <SupervisorProcessStatus>[],
  });

  factory SupervisorProcessInfo.fromJson(Map<String, dynamic> json) {
    return SupervisorProcessInfo(
      name: json['name'] as String? ?? '',
      command: json['command'] as String? ?? '',
      user: json['user'] as String? ?? '',
      dir: json['dir'] as String? ?? '',
      numprocs: json['numprocs']?.toString() ?? '',
      environment: json['environment'] as String? ?? '',
      autoStart: json['autoStart'] as String? ?? '',
      autoRestart: json['autoRestart'] as String? ?? '',
      status: (json['status'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(SupervisorProcessStatus.fromJson)
              .toList(growable: false) ??
          const <SupervisorProcessStatus>[],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'command': command,
        'user': user,
        'dir': dir,
        'numprocs': numprocs,
        'environment': environment,
        'autoStart': autoStart,
        'autoRestart': autoRestart,
        'status': status.map((item) => item.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        name,
        command,
        user,
        dir,
        numprocs,
        environment,
        autoStart,
        autoRestart,
        status,
      ];
}

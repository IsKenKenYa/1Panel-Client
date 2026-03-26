import 'package:equatable/equatable.dart';

class ProcessAddress extends Equatable {
  const ProcessAddress({
    required this.ip,
    required this.port,
  });

  final String ip;
  final int port;

  factory ProcessAddress.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return ProcessAddress(
        ip: json['ip'] as String? ?? '',
        port: json['port'] as int? ?? 0,
      );
    }
    return const ProcessAddress(ip: '', port: 0);
  }

  @override
  List<Object?> get props => <Object?>[ip, port];
}

class ProcessConnection extends Equatable {
  const ProcessConnection({
    required this.type,
    required this.status,
    required this.localAddress,
    required this.remoteAddress,
  });

  final String type;
  final String status;
  final ProcessAddress localAddress;
  final ProcessAddress remoteAddress;

  factory ProcessConnection.fromJson(Map<String, dynamic> json) {
    return ProcessConnection(
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      localAddress: ProcessAddress.fromJson(json['localaddr']),
      remoteAddress: ProcessAddress.fromJson(json['remoteaddr']),
    );
  }

  @override
  List<Object?> get props => <Object?>[type, status, localAddress, remoteAddress];
}

class ProcessOpenFile extends Equatable {
  const ProcessOpenFile({
    required this.path,
    required this.fd,
  });

  final String path;
  final int fd;

  factory ProcessOpenFile.fromJson(Map<String, dynamic> json) {
    return ProcessOpenFile(
      path: json['path'] as String? ?? '',
      fd: json['fd'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => <Object?>[path, fd];
}

class ProcessDetail extends Equatable {
  const ProcessDetail({
    required this.pid,
    required this.name,
    required this.parentPid,
    required this.username,
    required this.status,
    required this.startTime,
    required this.numThreads,
    required this.numConnections,
    required this.diskRead,
    required this.diskWrite,
    required this.cmdLine,
    required this.rss,
    required this.pss,
    required this.uss,
    required this.swap,
    required this.shared,
    required this.vms,
    required this.hwm,
    required this.data,
    required this.stack,
    required this.locked,
    required this.text,
    required this.dirty,
    required this.envs,
    required this.openFiles,
    required this.connections,
  });

  final int pid;
  final String name;
  final int parentPid;
  final String username;
  final String status;
  final String startTime;
  final int numThreads;
  final int numConnections;
  final String diskRead;
  final String diskWrite;
  final String cmdLine;
  final String rss;
  final String pss;
  final String uss;
  final String swap;
  final String shared;
  final String vms;
  final String hwm;
  final String data;
  final String stack;
  final String locked;
  final String text;
  final String dirty;
  final List<String> envs;
  final List<ProcessOpenFile> openFiles;
  final List<ProcessConnection> connections;

  factory ProcessDetail.fromJson(Map<String, dynamic> json) {
    return ProcessDetail(
      pid: json['PID'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      parentPid: json['PPID'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      status: json['status'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      numThreads: json['numThreads'] as int? ?? 0,
      numConnections: json['numConnections'] as int? ?? 0,
      diskRead: json['diskRead'] as String? ?? '',
      diskWrite: json['diskWrite'] as String? ?? '',
      cmdLine: json['cmdLine'] as String? ?? '',
      rss: json['rss'] as String? ?? '',
      pss: json['pss'] as String? ?? '',
      uss: json['uss'] as String? ?? '',
      swap: json['swap'] as String? ?? '',
      shared: json['shared'] as String? ?? '',
      vms: json['vms'] as String? ?? '',
      hwm: json['hwm'] as String? ?? '',
      data: json['data'] as String? ?? '',
      stack: json['stack'] as String? ?? '',
      locked: json['locked'] as String? ?? '',
      text: json['text'] as String? ?? '',
      dirty: json['dirty'] as String? ?? '',
      envs: (json['envs'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      openFiles: (json['openFiles'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ProcessOpenFile.fromJson)
          .toList(),
      connections: (json['connects'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ProcessConnection.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        pid,
        name,
        parentPid,
        username,
        status,
        startTime,
        numThreads,
        numConnections,
        diskRead,
        diskWrite,
        cmdLine,
        rss,
        pss,
        uss,
        swap,
        shared,
        vms,
        hwm,
        data,
        stack,
        locked,
        text,
        dirty,
        envs,
        openFiles,
        connections,
      ];
}

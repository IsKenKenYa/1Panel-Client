import 'package:equatable/equatable.dart';

class ProcessStopRequest extends Equatable {
  const ProcessStopRequest({required this.pid});

  final int pid;

  Map<String, dynamic> toJson() => <String, dynamic>{'PID': pid};

  @override
  List<Object?> get props => <Object?>[pid];
}

class ProcessListQuery extends Equatable {
  const ProcessListQuery({
    this.pid,
    this.name = '',
    this.username = '',
    this.statuses = const <String>[],
  });

  final int? pid;
  final String name;
  final String username;
  final List<String> statuses;

  @override
  List<Object?> get props => <Object?>[pid, name, username, statuses];
}

class ProcessSummary extends Equatable {
  const ProcessSummary({
    required this.pid,
    required this.name,
    required this.parentPid,
    required this.username,
    required this.status,
    required this.startTime,
    required this.numThreads,
    required this.numConnections,
    required this.cpuPercent,
    required this.cpuValue,
    required this.memoryText,
    required this.memoryValue,
    this.listeningPorts = const <int>[],
  });

  final int pid;
  final String name;
  final int parentPid;
  final String username;
  final String status;
  final String startTime;
  final int numThreads;
  final int numConnections;
  final String cpuPercent;
  final double cpuValue;
  final String memoryText;
  final int memoryValue;
  final List<int> listeningPorts;

  factory ProcessSummary.fromJson(Map<String, dynamic> json) {
    return ProcessSummary(
      pid: json['PID'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      parentPid: json['PPID'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      status: json['status'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      numThreads: json['numThreads'] as int? ?? 0,
      numConnections: json['numConnections'] as int? ?? 0,
      cpuPercent: json['cpuPercent'] as String? ?? '',
      cpuValue: (json['cpuValue'] as num?)?.toDouble() ?? 0,
      memoryText: json['rss'] as String? ?? '',
      memoryValue: json['rssValue'] as int? ?? 0,
    );
  }

  ProcessSummary copyWith({
    List<int>? listeningPorts,
  }) {
    return ProcessSummary(
      pid: pid,
      name: name,
      parentPid: parentPid,
      username: username,
      status: status,
      startTime: startTime,
      numThreads: numThreads,
      numConnections: numConnections,
      cpuPercent: cpuPercent,
      cpuValue: cpuValue,
      memoryText: memoryText,
      memoryValue: memoryValue,
      listeningPorts: listeningPorts ?? this.listeningPorts,
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
        cpuPercent,
        cpuValue,
        memoryText,
        memoryValue,
        listeningPorts,
      ];
}

class ListeningProcess extends Equatable {
  const ListeningProcess({
    required this.pid,
    required this.protocol,
    required this.name,
    required this.ports,
  });

  final int pid;
  final int protocol;
  final String name;
  final List<int> ports;

  factory ListeningProcess.fromJson(Map<String, dynamic> json) {
    final rawPorts = json['Port'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return ListeningProcess(
      pid: json['PID'] as int? ?? 0,
      protocol: json['Protocol'] as int? ?? 0,
      name: json['Name'] as String? ?? '',
      ports: rawPorts.keys.map(int.tryParse).whereType<int>().toList()..sort(),
    );
  }

  @override
  List<Object?> get props => <Object?>[pid, protocol, name, ports];
}

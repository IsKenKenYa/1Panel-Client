import 'package:equatable/equatable.dart';

class ProcessInfo extends Equatable {
  final int pid;
  final String name;
  final double cpuPercent;
  final double memoryPercent;
  final String? user;

  const ProcessInfo({
    required this.pid,
    required this.name,
    required this.cpuPercent,
    required this.memoryPercent,
    this.user,
  });

  factory ProcessInfo.fromJson(Map<String, dynamic> json) {
    return ProcessInfo(
      pid: json['pid'] as int? ?? 0,
      name: json['name'] as String? ?? json['cmd'] as String? ?? '',
      cpuPercent: (json['percent'] as num? ??
                  json['cpuPercent'] as num? ??
                  json['cpu'] as num?)
              ?.toDouble() ??
          0.0,
      memoryPercent: (json['memoryPercent'] as num? ??
                  json['mem'] as num? ??
                  json['memory'] as num?)
              ?.toDouble() ??
          0.0,
      user: json['user'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pid': pid,
      'name': name,
      'cpuPercent': cpuPercent,
      'memoryPercent': memoryPercent,
      'user': user,
    };
  }

  @override
  List<Object?> get props => [pid, name, cpuPercent, memoryPercent, user];
}

class DashboardMetrics extends Equatable {
  final double? cpuPercent;
  final double? memoryPercent;
  final double? diskPercent;
  final int? memoryUsed;
  final int? memoryTotal;
  final int? diskUsed;
  final int? diskTotal;
  final String? uptime;
  final int? cpuCores;
  final String? hostname;
  final String? os;
  final String? kernelVersion;

  const DashboardMetrics({
    this.cpuPercent,
    this.memoryPercent,
    this.diskPercent,
    this.memoryUsed,
    this.memoryTotal,
    this.diskUsed,
    this.diskTotal,
    this.uptime,
    this.cpuCores,
    this.hostname,
    this.os,
    this.kernelVersion,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      cpuPercent: (json['cpuPercent'] as num?)?.toDouble(),
      memoryPercent: (json['memoryPercent'] as num?)?.toDouble(),
      diskPercent: (json['diskPercent'] as num?)?.toDouble(),
      memoryUsed: json['memoryUsed'] as int?,
      memoryTotal: json['memoryTotal'] as int?,
      diskUsed: json['diskUsed'] as int?,
      diskTotal: json['diskTotal'] as int?,
      uptime: json['uptime']?.toString(),
      cpuCores: json['cpuCores'] as int?,
      hostname: json['hostname'] as String?,
      os: json['os'] as String?,
      kernelVersion: json['kernelVersion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cpuPercent': cpuPercent,
      'memoryPercent': memoryPercent,
      'diskPercent': diskPercent,
      'memoryUsed': memoryUsed,
      'memoryTotal': memoryTotal,
      'diskUsed': diskUsed,
      'diskTotal': diskTotal,
      'uptime': uptime,
      'cpuCores': cpuCores,
      'hostname': hostname,
      'os': os,
      'kernelVersion': kernelVersion,
    };
  }

  @override
  List<Object?> get props => [
        cpuPercent,
        memoryPercent,
        diskPercent,
        memoryUsed,
        memoryTotal,
        diskUsed,
        diskTotal,
        uptime,
        cpuCores,
        hostname,
        os,
        kernelVersion,
      ];
}

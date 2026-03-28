part of '../runtime_models.dart';

class RuntimeExposedPort extends Equatable {
  final int hostPort;
  final int containerPort;
  final String? hostIP;

  const RuntimeExposedPort({
    required this.hostPort,
    required this.containerPort,
    this.hostIP,
  });

  factory RuntimeExposedPort.fromJson(Map<String, dynamic> json) {
    return RuntimeExposedPort(
      hostPort: json['hostPort'] as int? ?? 0,
      containerPort: json['containerPort'] as int? ?? 0,
      hostIP: json['hostIP'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'hostPort': hostPort,
        'containerPort': containerPort,
        'hostIP': hostIP,
      };

  @override
  List<Object?> get props => [hostPort, containerPort, hostIP];
}

class RuntimeEnvironment extends Equatable {
  final String key;
  final String value;

  const RuntimeEnvironment({
    required this.key,
    required this.value,
  });

  factory RuntimeEnvironment.fromJson(Map<String, dynamic> json) {
    return RuntimeEnvironment(
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
      };

  @override
  List<Object?> get props => [key, value];
}

class RuntimeVolume extends Equatable {
  final String source;
  final String target;

  const RuntimeVolume({
    required this.source,
    required this.target,
  });

  factory RuntimeVolume.fromJson(Map<String, dynamic> json) {
    return RuntimeVolume(
      source: json['source'] as String? ?? '',
      target: json['target'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'source': source,
        'target': target,
      };

  @override
  List<Object?> get props => [source, target];
}

class RuntimeExtraHost extends Equatable {
  final String hostname;
  final String ip;

  const RuntimeExtraHost({
    required this.hostname,
    required this.ip,
  });

  factory RuntimeExtraHost.fromJson(Map<String, dynamic> json) {
    return RuntimeExtraHost(
      hostname: json['hostname'] as String? ?? '',
      ip: json['ip'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'hostname': hostname,
        'ip': ip,
      };

  @override
  List<Object?> get props => [hostname, ip];
}

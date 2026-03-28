part of '../runtime_models.dart';

class PhpContainerEnvironment extends Equatable {
  final String? key;
  final String? value;

  const PhpContainerEnvironment({this.key, this.value});

  factory PhpContainerEnvironment.fromJson(Map<String, dynamic> json) {
    return PhpContainerEnvironment(
      key: json['key'] as String?,
      value: json['value'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (key != null) 'key': key,
        if (value != null) 'value': value,
      };

  PhpContainerEnvironment copyWith({
    String? key,
    String? value,
  }) {
    return PhpContainerEnvironment(
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  List<Object?> get props => [key, value];
}

class PhpContainerExposedPort extends Equatable {
  final int? containerPort;
  final String? hostIP;
  final int? hostPort;

  const PhpContainerExposedPort({
    this.containerPort,
    this.hostIP,
    this.hostPort,
  });

  factory PhpContainerExposedPort.fromJson(Map<String, dynamic> json) {
    return PhpContainerExposedPort(
      containerPort: json['containerPort'] as int?,
      hostIP: json['hostIP'] as String?,
      hostPort: json['hostPort'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (containerPort != null) 'containerPort': containerPort,
        if (hostIP != null) 'hostIP': hostIP,
        if (hostPort != null) 'hostPort': hostPort,
      };

  PhpContainerExposedPort copyWith({
    int? containerPort,
    String? hostIP,
    int? hostPort,
  }) {
    return PhpContainerExposedPort(
      containerPort: containerPort ?? this.containerPort,
      hostIP: hostIP ?? this.hostIP,
      hostPort: hostPort ?? this.hostPort,
    );
  }

  @override
  List<Object?> get props => [containerPort, hostIP, hostPort];
}

class PhpContainerExtraHost extends Equatable {
  final String? hostname;
  final String? ip;

  const PhpContainerExtraHost({
    this.hostname,
    this.ip,
  });

  factory PhpContainerExtraHost.fromJson(Map<String, dynamic> json) {
    return PhpContainerExtraHost(
      hostname: json['hostname'] as String?,
      ip: json['ip'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (hostname != null) 'hostname': hostname,
        if (ip != null) 'ip': ip,
      };

  PhpContainerExtraHost copyWith({
    String? hostname,
    String? ip,
  }) {
    return PhpContainerExtraHost(
      hostname: hostname ?? this.hostname,
      ip: ip ?? this.ip,
    );
  }

  @override
  List<Object?> get props => [hostname, ip];
}

class PhpContainerVolume extends Equatable {
  final String? source;
  final String? target;

  const PhpContainerVolume({
    this.source,
    this.target,
  });

  factory PhpContainerVolume.fromJson(Map<String, dynamic> json) {
    return PhpContainerVolume(
      source: json['source'] as String?,
      target: json['target'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (source != null) 'source': source,
        if (target != null) 'target': target,
      };

  PhpContainerVolume copyWith({
    String? source,
    String? target,
  }) {
    return PhpContainerVolume(
      source: source ?? this.source,
      target: target ?? this.target,
    );
  }

  @override
  List<Object?> get props => [source, target];
}

/// Runtime package model

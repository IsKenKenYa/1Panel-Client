part of '../runtime_models.dart';

class PHPContainerConfig extends Equatable {
  final int id;
  final String? containerName;
  final List<PhpContainerEnvironment>? environments;
  final List<PhpContainerExposedPort>? exposedPorts;
  final List<PhpContainerExtraHost>? extraHosts;
  final List<PhpContainerVolume>? volumes;

  const PHPContainerConfig({
    required this.id,
    this.containerName,
    this.environments,
    this.exposedPorts,
    this.extraHosts,
    this.volumes,
  });

  factory PHPContainerConfig.fromJson(Map<String, dynamic> json) {
    return PHPContainerConfig(
      id: json['id'] as int? ?? 0,
      containerName: json['containerName'] as String?,
      environments: (json['environments'] as List?)
          ?.map((e) =>
              PhpContainerEnvironment.fromJson(e as Map<String, dynamic>))
          .toList(),
      exposedPorts: (json['exposedPorts'] as List?)
          ?.map((e) =>
              PhpContainerExposedPort.fromJson(e as Map<String, dynamic>))
          .toList(),
      extraHosts: (json['extraHosts'] as List?)
          ?.map(
              (e) => PhpContainerExtraHost.fromJson(e as Map<String, dynamic>))
          .toList(),
      volumes: (json['volumes'] as List?)
          ?.map((e) => PhpContainerVolume.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (containerName != null) 'containerName': containerName,
      if (environments != null)
        'environments': environments!.map((e) => e.toJson()).toList(),
      if (exposedPorts != null)
        'exposedPorts': exposedPorts!.map((e) => e.toJson()).toList(),
      if (extraHosts != null)
        'extraHosts': extraHosts!.map((e) => e.toJson()).toList(),
      if (volumes != null) 'volumes': volumes!.map((e) => e.toJson()).toList(),
    };
  }

  PHPContainerConfig copyWith({
    int? id,
    String? containerName,
    List<PhpContainerEnvironment>? environments,
    List<PhpContainerExposedPort>? exposedPorts,
    List<PhpContainerExtraHost>? extraHosts,
    List<PhpContainerVolume>? volumes,
  }) {
    return PHPContainerConfig(
      id: id ?? this.id,
      containerName: containerName ?? this.containerName,
      environments: environments ?? this.environments,
      exposedPorts: exposedPorts ?? this.exposedPorts,
      extraHosts: extraHosts ?? this.extraHosts,
      volumes: volumes ?? this.volumes,
    );
  }

  List<PhpContainerEnvironment> get safeEnvironments =>
      environments ?? const <PhpContainerEnvironment>[];

  List<PhpContainerExposedPort> get safeExposedPorts =>
      exposedPorts ?? const <PhpContainerExposedPort>[];

  List<PhpContainerExtraHost> get safeExtraHosts =>
      extraHosts ?? const <PhpContainerExtraHost>[];

  List<PhpContainerVolume> get safeVolumes =>
      volumes ?? const <PhpContainerVolume>[];

  @override
  List<Object?> get props =>
      [id, containerName, environments, exposedPorts, extraHosts, volumes];
}


part of '../runtime_models.dart';

class RuntimeCreate extends Equatable {
  final int? id;
  final int? appDetailId;
  final int? appId;
  final String name;
  final String resource;
  final String image;
  final String type;
  final String? version;
  final String? source;
  final String? codeDir;
  final int? port;
  final String? remark;
  final bool? rebuild;
  final Map<String, dynamic>? params;
  final bool? install;
  final bool? clean;
  final List<RuntimeExposedPort>? exposedPorts;
  final List<RuntimeEnvironment>? environments;
  final List<RuntimeVolume>? volumes;
  final List<RuntimeExtraHost>? extraHosts;

  const RuntimeCreate({
    this.id,
    this.appDetailId,
    this.appId,
    required this.name,
    required this.resource,
    required this.image,
    required this.type,
    this.version,
    this.source,
    this.codeDir,
    this.port,
    this.remark,
    this.rebuild,
    this.params,
    this.install,
    this.clean,
    this.exposedPorts,
    this.environments,
    this.volumes,
    this.extraHosts,
  });

  factory RuntimeCreate.fromJson(Map<String, dynamic> json) {
    return RuntimeCreate(
      id: json['id'] as int?,
      appDetailId: json['appDetailId'] as int? ?? json['appDetailID'] as int?,
      appId: json['appId'] as int? ?? json['appID'] as int?,
      name: json['name'] as String,
      resource: json['resource'] as String? ?? '',
      image: json['image'] as String? ?? '',
      type: json['type'] as String,
      version: json['version'] as String?,
      source: json['source'] as String?,
      codeDir: json['codeDir'] as String?,
      port: json['port'] as int?,
      remark: json['remark'] as String?,
      rebuild: json['rebuild'] as bool?,
      params: json['params'] as Map<String, dynamic>?,
      install: json['install'] as bool?,
      clean: json['clean'] as bool?,
      exposedPorts: (json['exposedPorts'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(RuntimeExposedPort.fromJson)
          .toList(),
      environments: (json['environments'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(RuntimeEnvironment.fromJson)
          .toList(),
      volumes: (json['volumes'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(RuntimeVolume.fromJson)
          .toList(),
      extraHosts: (json['extraHosts'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(RuntimeExtraHost.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appDetailId': appDetailId,
      'appID': appId,
      'name': name,
      'resource': resource,
      'image': image,
      'type': type,
      'version': version,
      'source': source,
      'codeDir': codeDir,
      'port': port,
      'remark': remark,
      'rebuild': rebuild,
      'params': params,
      'install': install,
      'clean': clean,
      'exposedPorts': exposedPorts?.map((item) => item.toJson()).toList(),
      'environments': environments?.map((item) => item.toJson()).toList(),
      'volumes': volumes?.map((item) => item.toJson()).toList(),
      'extraHosts': extraHosts?.map((item) => item.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        appDetailId,
        appId,
        name,
        resource,
        image,
        type,
        version,
        source,
        codeDir,
        port,
        remark,
        rebuild,
        params,
        install,
        clean,
        exposedPorts,
        environments,
        volumes,
        extraHosts,
      ];
}

/// Runtime information model

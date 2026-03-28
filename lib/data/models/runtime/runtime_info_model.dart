part of '../runtime_models.dart';

class RuntimeInfo extends Equatable {
  final int? id;
  final String? name;
  final String? resource;
  final int? appDetailId;
  final int? appId;
  final String? type;
  final String? image;
  final String? version;
  final String? source;
  final String? path;
  final String? status;
  final String? port;
  final Map<String, dynamic>? params;
  final String? message;
  final String? createdAt;
  final String? codeDir;
  final String? container;
  final String? containerStatus;
  final String? remark;
  final List<RuntimeExposedPort>? exposedPorts;
  final List<RuntimeEnvironment>? environments;
  final List<RuntimeVolume>? volumes;
  final List<RuntimeExtraHost>? extraHosts;

  const RuntimeInfo({
    this.id,
    this.name,
    this.resource,
    this.appDetailId,
    this.appId,
    this.type,
    this.image,
    this.version,
    this.source,
    this.path,
    this.status,
    this.port,
    this.params,
    this.message,
    this.createdAt,
    this.codeDir,
    this.container,
    this.containerStatus,
    this.remark,
    this.exposedPorts,
    this.environments,
    this.volumes,
    this.extraHosts,
  });

  factory RuntimeInfo.fromJson(Map<String, dynamic> json) {
    return RuntimeInfo(
      id: json['id'] as int?,
      name: json['name'] as String?,
      resource: json['resource'] as String?,
      appDetailId: json['appDetailId'] as int? ?? json['appDetailID'] as int?,
      appId: json['appId'] as int? ?? json['appID'] as int?,
      type: json['type'] as String?,
      image: json['image'] as String?,
      version: json['version'] as String?,
      source: json['source'] as String?,
      path: json['path'] as String?,
      status: json['status'] as String?,
      port: json['port'] as String?,
      params: json['params'] as Map<String, dynamic>?,
      message: json['message'] as String?,
      createdAt: json['createdAt']?.toString(),
      codeDir: json['codeDir'] as String?,
      container: json['container'] as String?,
      containerStatus: json['containerStatus'] as String?,
      remark: json['remark'] as String?,
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
      'name': name,
      'resource': resource,
      'appDetailId': appDetailId,
      'appId': appId,
      'type': type,
      'image': image,
      'version': version,
      'source': source,
      'path': path,
      'status': status,
      'port': port,
      'params': params,
      'message': message,
      'createdAt': createdAt,
      'codeDir': codeDir,
      'container': container,
      'containerStatus': containerStatus,
      'remark': remark,
      'exposedPorts': exposedPorts?.map((item) => item.toJson()).toList(),
      'environments': environments?.map((item) => item.toJson()).toList(),
      'volumes': volumes?.map((item) => item.toJson()).toList(),
      'extraHosts': extraHosts?.map((item) => item.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        resource,
        appDetailId,
        appId,
        type,
        image,
        version,
        source,
        path,
        status,
        port,
        params,
        message,
        createdAt,
        codeDir,
        container,
        containerStatus,
        remark,
        exposedPorts,
        environments,
        volumes,
        extraHosts,
      ];
}

/// Runtime search request model

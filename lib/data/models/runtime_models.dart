import 'package:equatable/equatable.dart';

/// Runtime type enumeration
enum RuntimeType {
  java('java'),
  node('node'),
  python('python'),
  go('go'),
  php('php'),
  dotnet('dotnet');

  const RuntimeType(this.value);
  final String value;

  static RuntimeType fromString(String value) {
    return RuntimeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RuntimeType.java,
    );
  }
}

/// Runtime creation request model
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
class RuntimeSearch extends Equatable {
  final int page;
  final int pageSize;
  final String? type;
  final String? name;
  final String? status;

  const RuntimeSearch({
    this.page = 1,
    this.pageSize = 20,
    this.type,
    this.name,
    this.status,
  });

  factory RuntimeSearch.fromJson(Map<String, dynamic> json) {
    return RuntimeSearch(
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      type: json['type'] as String?,
      name: json['name'] as String? ?? json['search'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'type': type,
      'name': name,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [page, pageSize, type, name, status];
}

/// Runtime operation model
class RuntimeOperate extends Equatable {
  final int id;
  final String operate;

  const RuntimeOperate({
    required this.id,
    required this.operate,
  });

  factory RuntimeOperate.fromJson(Map<String, dynamic> json) {
    return RuntimeOperate(
      id: json['ID'] as int? ?? json['id'] as int? ?? 0,
      operate: json['operate'] as String? ?? json['operation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'operate': operate,
    };
  }

  @override
  List<Object?> get props => [id, operate];
}

class RuntimeDelete extends Equatable {
  final int id;
  final bool forceDelete;

  const RuntimeDelete({
    required this.id,
    this.forceDelete = false,
  });

  factory RuntimeDelete.fromJson(Map<String, dynamic> json) {
    return RuntimeDelete(
      id: json['id'] as int? ?? 0,
      forceDelete: json['forceDelete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'forceDelete': forceDelete,
      };

  @override
  List<Object?> get props => [id, forceDelete];
}

/// Runtime update request model
class RuntimeUpdate extends Equatable {
  final int id;
  final int? appDetailId;
  final int? appId;
  final String name;
  final String? resource;
  final String? type;
  final String? image;
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

  const RuntimeUpdate({
    required this.id,
    this.appDetailId,
    this.appId,
    required this.name,
    this.resource,
    this.type,
    this.image,
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

  factory RuntimeUpdate.fromJson(Map<String, dynamic> json) {
    return RuntimeUpdate(
      id: json['id'] as int,
      appDetailId: json['appDetailId'] as int? ?? json['appDetailID'] as int?,
      appId: json['appId'] as int? ?? json['appID'] as int?,
      name: json['name'] as String? ?? '',
      resource: json['resource'] as String?,
      type: json['type'] as String?,
      image: json['image'] as String?,
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
      'type': type,
      'image': image,
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
        type,
        image,
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

class PHPExtensionSupport extends Equatable {
  final String name;
  final String? description;
  final bool installed;
  final String? check;
  final List<String> versions;
  final String? file;

  const PHPExtensionSupport({
    required this.name,
    this.description,
    this.installed = false,
    this.check,
    this.versions = const <String>[],
    this.file,
  });

  factory PHPExtensionSupport.fromJson(Map<String, dynamic> json) {
    return PHPExtensionSupport(
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      installed: json['installed'] as bool? ?? false,
      check: json['check'] as String?,
      versions: (json['versions'] as List<dynamic>?)?.cast<String>() ??
          const <String>[],
      file: json['file'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'installed': installed,
        'check': check,
        'versions': versions,
        'file': file,
      };

  @override
  List<Object?> get props =>
      [name, description, installed, check, versions, file];
}

class PHPExtensionsRes extends Equatable {
  final List<String> extensions;
  final List<PHPExtensionSupport> supportExtensions;

  const PHPExtensionsRes({
    this.extensions = const <String>[],
    this.supportExtensions = const <PHPExtensionSupport>[],
  });

  factory PHPExtensionsRes.fromJson(Map<String, dynamic> json) {
    return PHPExtensionsRes(
      extensions: (json['extensions'] as List<dynamic>?)?.cast<String>() ??
          const <String>[],
      supportExtensions: (json['supportExtensions'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(PHPExtensionSupport.fromJson)
              .toList() ??
          const <PHPExtensionSupport>[],
    );
  }

  Map<String, dynamic> toJson() => {
        'extensions': extensions,
        'supportExtensions':
            supportExtensions.map((item) => item.toJson()).toList(),
      };

  @override
  List<Object?> get props => [extensions, supportExtensions];
}

class PHPConfig extends Equatable {
  final Map<String, String>? params;
  final List<String> disableFunctions;
  final String? uploadMaxSize;
  final String? maxExecutionTime;

  const PHPConfig({
    this.params,
    this.disableFunctions = const <String>[],
    this.uploadMaxSize,
    this.maxExecutionTime,
  });

  factory PHPConfig.fromJson(Map<String, dynamic> json) {
    return PHPConfig(
      params: (json['params'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      disableFunctions:
          (json['disableFunctions'] as List<dynamic>?)?.cast<String>() ??
              const <String>[],
      uploadMaxSize: json['uploadMaxSize'] as String?,
      maxExecutionTime: json['maxExecutionTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'params': params,
        'disableFunctions': disableFunctions,
        'uploadMaxSize': uploadMaxSize,
        'maxExecutionTime': maxExecutionTime,
      };

  @override
  List<Object?> get props => [
        params,
        disableFunctions,
        uploadMaxSize,
        maxExecutionTime,
      ];
}

class PHPConfigUpdate extends Equatable {
  final int id;
  final String scope;
  final Map<String, String>? params;
  final List<String>? disableFunctions;
  final String? uploadMaxSize;
  final String? maxExecutionTime;

  const PHPConfigUpdate({
    required this.id,
    required this.scope,
    this.params,
    this.disableFunctions,
    this.uploadMaxSize,
    this.maxExecutionTime,
  });

  factory PHPConfigUpdate.fromJson(Map<String, dynamic> json) {
    return PHPConfigUpdate(
      id: json['id'] as int? ?? 0,
      scope: json['scope'] as String? ?? '',
      params: (json['params'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      disableFunctions:
          (json['disableFunctions'] as List<dynamic>?)?.cast<String>(),
      uploadMaxSize: json['uploadMaxSize'] as String?,
      maxExecutionTime: json['maxExecutionTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scope': scope,
        'params': params,
        'disableFunctions': disableFunctions,
        'uploadMaxSize': uploadMaxSize,
        'maxExecutionTime': maxExecutionTime,
      };

  @override
  List<Object?> get props => [
        id,
        scope,
        params,
        disableFunctions,
        uploadMaxSize,
        maxExecutionTime,
      ];
}

class PHPExtensionInstallRequest extends Equatable {
  final int id;
  final String name;
  final String taskId;

  const PHPExtensionInstallRequest({
    required this.id,
    required this.name,
    this.taskId = '',
  });

  factory PHPExtensionInstallRequest.fromJson(Map<String, dynamic> json) {
    return PHPExtensionInstallRequest(
      id: json['id'] as int? ?? json['ID'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      taskId: json['taskId'] as String? ?? json['taskID'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (taskId.isNotEmpty) 'taskID': taskId,
      };

  @override
  List<Object?> get props => [id, name, taskId];
}

class NodeModuleRequest extends Equatable {
  final int id;
  final String operate;
  final String module;
  final String packageManager;

  const NodeModuleRequest({
    required this.id,
    this.operate = '',
    this.module = '',
    this.packageManager = '',
  });

  factory NodeModuleRequest.fromJson(Map<String, dynamic> json) {
    return NodeModuleRequest(
      id: json['id'] as int? ?? json['ID'] as int? ?? 0,
      operate: json['operate'] as String? ?? json['Operate'] as String? ?? '',
      module: json['module'] as String? ?? json['Module'] as String? ?? '',
      packageManager: json['pkgManager'] as String? ??
          json['PkgManager'] as String? ??
          json['packageManager'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toJson() => {
        'ID': id,
        if (operate.isNotEmpty) 'Operate': operate,
        if (module.isNotEmpty) 'Module': module,
        if (packageManager.isNotEmpty) 'PkgManager': packageManager,
      };

  @override
  List<Object?> get props => [id, operate, module, packageManager];
}

class NodePackageRequest extends Equatable {
  final String codeDir;

  const NodePackageRequest({
    required this.codeDir,
  });

  factory NodePackageRequest.fromJson(Map<String, dynamic> json) {
    return NodePackageRequest(
      codeDir: json['codeDir'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'codeDir': codeDir,
      };

  @override
  List<Object?> get props => [codeDir];
}

class NodeModuleInfo extends Equatable {
  final String name;
  final String version;
  final String description;

  const NodeModuleInfo({
    required this.name,
    this.version = '',
    this.description = '',
  });

  factory NodeModuleInfo.fromJson(Map<String, dynamic> json) {
    return NodeModuleInfo(
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'description': description,
      };

  @override
  List<Object?> get props => [name, version, description];
}

class NodeScriptInfo extends Equatable {
  final String name;
  final String script;

  const NodeScriptInfo({
    required this.name,
    required this.script,
  });

  factory NodeScriptInfo.fromJson(Map<String, dynamic> json) {
    return NodeScriptInfo(
      name: json['name'] as String? ?? '',
      script: json['script'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'script': script,
      };

  @override
  List<Object?> get props => [name, script];
}

class RuntimeRemarkUpdate extends Equatable {
  final int id;
  final String remark;

  const RuntimeRemarkUpdate({
    required this.id,
    required this.remark,
  });

  factory RuntimeRemarkUpdate.fromJson(Map<String, dynamic> json) {
    return RuntimeRemarkUpdate(
      id: json['id'] as int? ?? 0,
      remark: json['remark'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'remark': remark,
      };

  @override
  List<Object?> get props => [id, remark];
}

class FpmStatusItem extends Equatable {
  final String key;
  final dynamic value;

  const FpmStatusItem({
    required this.key,
    this.value,
  });

  factory FpmStatusItem.fromJson(Map<String, dynamic> json) {
    return FpmStatusItem(
      key: json['key'] as String? ?? '',
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
      };

  @override
  List<Object?> get props => [key, value];
}

/// Java runtime specific model
class JavaRuntime extends Equatable {
  final int? id;
  final String? name;
  final String? version;
  final String? jdkHome;
  final String? javaHome;
  final String? classpath;
  final Map<String, String>? environmentVariables;
  final String? status;

  const JavaRuntime({
    this.id,
    this.name,
    this.version,
    this.jdkHome,
    this.javaHome,
    this.classpath,
    this.environmentVariables,
    this.status,
  });

  factory JavaRuntime.fromJson(Map<String, dynamic> json) {
    return JavaRuntime(
      id: json['id'] as int?,
      name: json['name'] as String?,
      version: json['version'] as String?,
      jdkHome: json['jdkHome'] as String?,
      javaHome: json['javaHome'] as String?,
      classpath: json['classpath'] as String?,
      environmentVariables:
          (json['environmentVariables'] as Map<String, dynamic>?)
              ?.cast<String, String>(),
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'jdkHome': jdkHome,
      'javaHome': javaHome,
      'classpath': classpath,
      'environmentVariables': environmentVariables,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        version,
        jdkHome,
        javaHome,
        classpath,
        environmentVariables,
        status
      ];
}

/// Node.js runtime specific model
class NodeRuntime extends Equatable {
  final int? id;
  final String? name;
  final String? version;
  final String? nodeHome;
  final String? npmHome;
  final String? packageManager;
  final Map<String, String>? environmentVariables;
  final String? status;

  const NodeRuntime({
    this.id,
    this.name,
    this.version,
    this.nodeHome,
    this.npmHome,
    this.packageManager,
    this.environmentVariables,
    this.status,
  });

  factory NodeRuntime.fromJson(Map<String, dynamic> json) {
    return NodeRuntime(
      id: json['id'] as int?,
      name: json['name'] as String?,
      version: json['version'] as String?,
      nodeHome: json['nodeHome'] as String?,
      npmHome: json['npmHome'] as String?,
      packageManager: json['packageManager'] as String?,
      environmentVariables:
          (json['environmentVariables'] as Map<String, dynamic>?)
              ?.cast<String, String>(),
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'nodeHome': nodeHome,
      'npmHome': npmHome,
      'packageManager': packageManager,
      'environmentVariables': environmentVariables,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        version,
        nodeHome,
        npmHome,
        packageManager,
        environmentVariables,
        status
      ];
}

/// Python runtime specific model
class PythonRuntime extends Equatable {
  final int? id;
  final String? name;
  final String? version;
  final String? pythonHome;
  final String? pipHome;
  final String? virtualenvPath;
  final Map<String, String>? environmentVariables;
  final String? status;

  const PythonRuntime({
    this.id,
    this.name,
    this.version,
    this.pythonHome,
    this.pipHome,
    this.virtualenvPath,
    this.environmentVariables,
    this.status,
  });

  factory PythonRuntime.fromJson(Map<String, dynamic> json) {
    return PythonRuntime(
      id: json['id'] as int?,
      name: json['name'] as String?,
      version: json['version'] as String?,
      pythonHome: json['pythonHome'] as String?,
      pipHome: json['pipHome'] as String?,
      virtualenvPath: json['virtualenvPath'] as String?,
      environmentVariables:
          (json['environmentVariables'] as Map<String, dynamic>?)
              ?.cast<String, String>(),
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'pythonHome': pythonHome,
      'pipHome': pipHome,
      'virtualenvPath': virtualenvPath,
      'environmentVariables': environmentVariables,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        version,
        pythonHome,
        pipHome,
        virtualenvPath,
        environmentVariables,
        status
      ];
}

/// Go runtime specific model
class GoRuntime extends Equatable {
  final int? id;
  final String? name;
  final String? version;
  final String? goHome;
  final String? gopath;
  final String? gocache;
  final Map<String, String>? environmentVariables;
  final String? status;

  const GoRuntime({
    this.id,
    this.name,
    this.version,
    this.goHome,
    this.gopath,
    this.gocache,
    this.environmentVariables,
    this.status,
  });

  factory GoRuntime.fromJson(Map<String, dynamic> json) {
    return GoRuntime(
      id: json['id'] as int?,
      name: json['name'] as String?,
      version: json['version'] as String?,
      goHome: json['goHome'] as String?,
      gopath: json['gopath'] as String?,
      gocache: json['gocache'] as String?,
      environmentVariables:
          (json['environmentVariables'] as Map<String, dynamic>?)
              ?.cast<String, String>(),
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'goHome': goHome,
      'gopath': gopath,
      'gocache': gocache,
      'environmentVariables': environmentVariables,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        version,
        goHome,
        gopath,
        gocache,
        environmentVariables,
        status
      ];
}

/// PHP runtime specific model
class PHPRuntime extends Equatable {
  final int? id;
  final String? name;
  final String? version;
  final String? phpHome;
  final String? phpIniPath;
  final String? extensionDir;
  final Map<String, String>? environmentVariables;
  final String? status;

  const PHPRuntime({
    this.id,
    this.name,
    this.version,
    this.phpHome,
    this.phpIniPath,
    this.extensionDir,
    this.environmentVariables,
    this.status,
  });

  factory PHPRuntime.fromJson(Map<String, dynamic> json) {
    return PHPRuntime(
      id: json['id'] as int?,
      name: json['name'] as String?,
      version: json['version'] as String?,
      phpHome: json['phpHome'] as String?,
      phpIniPath: json['phpIniPath'] as String?,
      extensionDir: json['extensionDir'] as String?,
      environmentVariables:
          (json['environmentVariables'] as Map<String, dynamic>?)
              ?.cast<String, String>(),
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'phpHome': phpHome,
      'phpIniPath': phpIniPath,
      'extensionDir': extensionDir,
      'environmentVariables': environmentVariables,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        version,
        phpHome,
        phpIniPath,
        extensionDir,
        environmentVariables,
        status
      ];
}

/// PHP 容器配置模型（runtime/php/container）
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

  @override
  List<Object?> get props =>
      [id, containerName, environments, exposedPorts, extraHosts, volumes];
}

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

  @override
  List<Object?> get props => [source, target];
}

/// Runtime package model
class RuntimePackage extends Equatable {
  final int? id;
  final String? name;
  final String? version;
  final String? type;
  final int? runtimeId;
  final String? description;
  final String? status;

  const RuntimePackage({
    this.id,
    this.name,
    this.version,
    this.type,
    this.runtimeId,
    this.description,
    this.status,
  });

  factory RuntimePackage.fromJson(Map<String, dynamic> json) {
    return RuntimePackage(
      id: json['id'] as int?,
      name: json['name'] as String?,
      version: json['version'] as String?,
      type: json['type'] as String? ?? json['runtimeType'] as String?,
      runtimeId: json['runtimeId'] as int?,
      description: json['description'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'type': type,
      'runtimeId': runtimeId,
      'description': description,
      'status': status,
    };
  }

  @override
  List<Object?> get props =>
      [id, name, version, type, runtimeId, description, status];
}

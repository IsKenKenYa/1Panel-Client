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
  final String name;
  final String type;
  final String? version;
  final String? source;
  final String? path;
  final Map<String, dynamic>? params;

  const RuntimeCreate({
    required this.name,
    required this.type,
    this.version,
    this.source,
    this.path,
    this.params,
  });

  factory RuntimeCreate.fromJson(Map<String, dynamic> json) {
    return RuntimeCreate(
      name: json['name'] as String,
      type: json['type'] as String,
      version: json['version'] as String?,
      source: json['source'] as String?,
      path: json['path'] as String?,
      params: json['params'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'version': version,
      'source': source,
      'path': path,
      'params': params,
    };
  }

  @override
  List<Object?> get props => [name, type, version, source, path, params];
}

/// Runtime information model
class RuntimeInfo extends Equatable {
  final int? id;
  final String? name;
  final String? type;
  final String? version;
  final String? source;
  final String? path;
  final String? status;
  final String? port;
  final Map<String, dynamic>? params;
  final String? createTime;
  final String? updateTime;

  const RuntimeInfo({
    this.id,
    this.name,
    this.type,
    this.version,
    this.source,
    this.path,
    this.status,
    this.port,
    this.params,
    this.createTime,
    this.updateTime,
  });

  factory RuntimeInfo.fromJson(Map<String, dynamic> json) {
    return RuntimeInfo(
      id: json['id'] as int?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      version: json['version'] as String?,
      source: json['source'] as String?,
      path: json['path'] as String?,
      status: json['status'] as String?,
      port: json['port'] as String?,
      params: json['params'] as Map<String, dynamic>?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'version': version,
      'source': source,
      'path': path,
      'status': status,
      'port': port,
      'params': params,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [id, name, type, version, source, path, status, port, params, createTime, updateTime];
}

/// Runtime search request model
class RuntimeSearch extends Equatable {
  final int? page;
  final int? pageSize;
  final String? search;
  final String? type;
  final String? status;

  const RuntimeSearch({
    this.page,
    this.pageSize,
    this.search,
    this.type,
    this.status,
  });

  factory RuntimeSearch.fromJson(Map<String, dynamic> json) {
    return RuntimeSearch(
      page: json['page'] as int?,
      pageSize: json['pageSize'] as int?,
      search: json['search'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'search': search,
      'type': type,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [page, pageSize, search, type, status];
}

/// Runtime operation model
class RuntimeOperate extends Equatable {
  final List<int> ids;
  final String operation;

  const RuntimeOperate({
    required this.ids,
    required this.operation,
  });

  factory RuntimeOperate.fromJson(Map<String, dynamic> json) {
    return RuntimeOperate(
      ids: (json['ids'] as List?)?.map((e) => e as int).toList() ?? [],
      operation: json['operation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ids': ids,
      'operation': operation,
    };
  }

  @override
  List<Object?> get props => [ids, operation];
}

/// Runtime update request model
class RuntimeUpdate extends Equatable {
  final int id;
  final String? name;
  final String? version;
  final String? source;
  final String? path;
  final Map<String, dynamic>? params;

  const RuntimeUpdate({
    required this.id,
    this.name,
    this.version,
    this.source,
    this.path,
    this.params,
  });

  factory RuntimeUpdate.fromJson(Map<String, dynamic> json) {
    return RuntimeUpdate(
      id: json['id'] as int,
      name: json['name'] as String?,
      version: json['version'] as String?,
      source: json['source'] as String?,
      path: json['path'] as String?,
      params: json['params'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'source': source,
      'path': path,
      'params': params,
    };
  }

  @override
  List<Object?> get props => [id, name, version, source, path, params];
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
      environmentVariables: (json['environmentVariables'] as Map<String, dynamic>?)?.cast<String, String>(),
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
  List<Object?> get props => [id, name, version, jdkHome, javaHome, classpath, environmentVariables, status];
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
      environmentVariables: (json['environmentVariables'] as Map<String, dynamic>?)?.cast<String, String>(),
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
  List<Object?> get props => [id, name, version, nodeHome, npmHome, packageManager, environmentVariables, status];
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
      environmentVariables: (json['environmentVariables'] as Map<String, dynamic>?)?.cast<String, String>(),
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
  List<Object?> get props => [id, name, version, pythonHome, pipHome, virtualenvPath, environmentVariables, status];
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
      environmentVariables: (json['environmentVariables'] as Map<String, dynamic>?)?.cast<String, String>(),
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
  List<Object?> get props => [id, name, version, goHome, gopath, gocache, environmentVariables, status];
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
      environmentVariables: (json['environmentVariables'] as Map<String, dynamic>?)?.cast<String, String>(),
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
  List<Object?> get props => [id, name, version, phpHome, phpIniPath, extensionDir, environmentVariables, status];
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
          ?.map((e) => PhpContainerEnvironment.fromJson(e as Map<String, dynamic>))
          .toList(),
      exposedPorts: (json['exposedPorts'] as List?)
          ?.map((e) => PhpContainerExposedPort.fromJson(e as Map<String, dynamic>))
          .toList(),
      extraHosts: (json['extraHosts'] as List?)
          ?.map((e) => PhpContainerExtraHost.fromJson(e as Map<String, dynamic>))
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
      if (environments != null) 'environments': environments!.map((e) => e.toJson()).toList(),
      if (exposedPorts != null) 'exposedPorts': exposedPorts!.map((e) => e.toJson()).toList(),
      if (extraHosts != null) 'extraHosts': extraHosts!.map((e) => e.toJson()).toList(),
      if (volumes != null) 'volumes': volumes!.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, containerName, environments, exposedPorts, extraHosts, volumes];
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
  List<Object?> get props => [id, name, version, type, runtimeId, description, status];
}

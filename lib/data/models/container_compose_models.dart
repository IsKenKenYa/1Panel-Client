import 'package:equatable/equatable.dart';

class ComposePin extends Equatable {
  final String name;
  final bool? isPinned;

  const ComposePin({required this.name, this.isPinned});

  factory ComposePin.fromJson(Map<String, dynamic> json) {
    return ComposePin(
      name: json['name'] as String? ?? '',
      isPinned: json['isPinned'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'name': name};
    if (isPinned != null) json['isPinned'] = isPinned;
    return json;
  }

  @override
  List<Object?> get props => [name, isPinned];
}

class ContainerCompose extends Equatable {
  final String id;
  final String name;
  final String? path;
  final String? version;
  final String? status;
  final String? createTime;
  final String? updateTime;
  final List<String>? networks;
  final List<String>? volumes;
  final List<String>? services;
  final int? containerCount;
  final int? runningCount;

  const ContainerCompose({
    required this.id,
    required this.name,
    this.path,
    this.version,
    this.status,
    this.createTime,
    this.updateTime,
    this.networks,
    this.volumes,
    this.services,
    this.containerCount,
    this.runningCount,
  });

  factory ContainerCompose.fromJson(Map<String, dynamic> json) {
    List<String>? parseStringList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return null;
    }

    return ContainerCompose(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      path: json['path']?.toString(),
      version: json['version']?.toString(),
      status: json['status']?.toString(),
      // API uses 'createTime' in compose-list but 'createdAt' in detail responses
      createTime: json['createTime']?.toString() ??
          json['createdAt']?.toString(),
      // API uses 'updateTime' in compose-list but 'updatedAt' in detail responses
      updateTime: json['updateTime']?.toString() ??
          json['updatedAt']?.toString(),
      networks: parseStringList(json['networks']),
      volumes: parseStringList(json['volumes']),
      services: parseStringList(json['services']),
      containerCount: (json['containerCount'] as num?)?.toInt(),
      runningCount: (json['runningCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'version': version,
      'status': status,
      'createTime': createTime,
      'updateTime': updateTime,
      'networks': networks,
      'volumes': volumes,
      'services': services,
      'containerCount': containerCount,
      'runningCount': runningCount,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        path,
        version,
        status,
        createTime,
        updateTime,
        networks,
        volumes,
        services,
        containerCount,
        runningCount,
      ];
}

/// Container Compose 创建请求模型
class ContainerComposeCreate extends Equatable {
  final String from;
  final String name;
  final String? path;
  final String? file;
  final String? env;
  final bool? forcePull;
  final int? template;
  final String? taskID;
  final String? version;
  final List<String>? networks;
  final List<String>? volumes;
  final List<String>? services;

  const ContainerComposeCreate({
    required this.from,
    required this.name,
    this.path,
    this.file,
    this.env,
    this.forcePull,
    this.template,
    this.taskID,
    this.version,
    this.networks,
    this.volumes,
    this.services,
  });

  factory ContainerComposeCreate.fromJson(Map<String, dynamic> json) {
    return ContainerComposeCreate(
      from: json['from'] as String? ?? 'edit',
      name: json['name'] as String,
      path: json['path'] as String?,
      file: json['file'] as String?,
      env: json['env'] as String?,
      forcePull: json['forcePull'] as bool?,
      template: json['template'] as int?,
      taskID: json['taskID'] as String?,
      version: json['version'] as String?,
      networks: (json['networks'] as List?)?.cast<String>(),
      volumes: (json['volumes'] as List?)?.cast<String>(),
      services: (json['services'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'name': name,
      if (path != null) 'path': path,
      if (file != null) 'file': file,
      if (env != null) 'env': env,
      if (forcePull != null) 'forcePull': forcePull,
      if (template != null) 'template': template,
      if (taskID != null) 'taskID': taskID,
      if (version != null) 'version': version,
      if (networks != null) 'networks': networks,
      if (volumes != null) 'volumes': volumes,
      if (services != null) 'services': services,
    };
  }

  @override
  List<Object?> get props => [
        from,
        name,
        path,
        file,
        env,
        forcePull,
        template,
        taskID,
        version,
        networks,
        volumes,
        services,
      ];
}

class ContainerComposeUpdateRequest extends Equatable {
  final String name;
  final String path;
  final String content;
  final String? env;
  final String? detailPath;
  final bool? forcePull;
  final String? taskID;

  const ContainerComposeUpdateRequest({
    required this.name,
    required this.path,
    required this.content,
    this.env,
    this.detailPath,
    this.forcePull,
    this.taskID,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'content': content,
      if (env != null) 'env': env,
      if (detailPath != null) 'detailPath': detailPath,
      if (forcePull != null) 'forcePull': forcePull,
      if (taskID != null) 'taskID': taskID,
    };
  }

  @override
  List<Object?> get props =>
      [name, path, content, env, detailPath, forcePull, taskID];
}

class ContainerComposeLogCleanRequest extends Equatable {
  final String name;
  final String path;
  final String? detailPath;

  const ContainerComposeLogCleanRequest({
    required this.name,
    required this.path,
    this.detailPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      if (detailPath != null) 'detailPath': detailPath,
    };
  }

  @override
  List<Object?> get props => [name, path, detailPath];
}

/// Container Compose 更新请求模型
class ContainerComposeUpdate extends Equatable {
  final String id;
  final String name;
  final String? path;
  final String? version;
  final List<String>? networks;
  final List<String>? volumes;
  final List<String>? services;

  const ContainerComposeUpdate({
    required this.id,
    required this.name,
    this.path,
    this.version,
    this.networks,
    this.volumes,
    this.services,
  });

  factory ContainerComposeUpdate.fromJson(Map<String, dynamic> json) {
    return ContainerComposeUpdate(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String?,
      version: json['version'] as String?,
      networks: (json['networks'] as List?)?.cast<String>(),
      volumes: (json['volumes'] as List?)?.cast<String>(),
      services: (json['services'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'version': version,
      'networks': networks,
      'volumes': volumes,
      'services': services,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        path,
        version,
        networks,
        volumes,
        services,
      ];
}

/// Container Compose 搜索请求模型
class ContainerComposeSearch extends Equatable {
  final int page;
  final int pageSize;
  final String? name;
  final String? status;
  final String? search;

  const ContainerComposeSearch({
    required this.page,
    required this.pageSize,
    this.name,
    this.status,
    this.search,
  });

  factory ContainerComposeSearch.fromJson(Map<String, dynamic> json) {
    return ContainerComposeSearch(
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      name: json['name'] as String?,
      status: json['status'] as String?,
      search: json['search'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'name': name,
      'status': status,
      'search': search,
    };
  }

  @override
  List<Object?> get props => [
        page,
        pageSize,
        name,
        status,
      ];
}

/// Container Compose 操作请求模型
class ContainerComposeOperate extends Equatable {
  final String name;
  final String operation;
  final String? path;
  final bool? withFile;
  final bool? force;

  const ContainerComposeOperate({
    required this.name,
    required this.operation,
    this.path,
    this.withFile,
    this.force,
  });

  factory ContainerComposeOperate.fromJson(Map<String, dynamic> json) {
    return ContainerComposeOperate(
      name: json['name'] as String? ?? '',
      operation: json['operation'] as String,
      path: json['path'] as String?,
      withFile: json['withFile'] as bool?,
      force: json['force'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'operation': operation,
      if (path != null) 'path': path,
      if (withFile != null) 'withFile': withFile,
      if (force != null) 'force': force,
    };
  }

  @override
  List<Object?> get props => [
        name,
        operation,
        path,
        withFile,
        force,
      ];
}

/// Container Compose 日志模型
class ContainerComposeLog extends Equatable {
  final String id;
  final String composeName;
  final String? level;
  final String? message;
  final String? createTime;
  final String? containerName;
  final String? operation;

  const ContainerComposeLog({
    required this.id,
    required this.composeName,
    this.level,
    this.message,
    this.createTime,
    this.containerName,
    this.operation,
  });

  factory ContainerComposeLog.fromJson(Map<String, dynamic> json) {
    return ContainerComposeLog(
      id: json['id'] as String,
      composeName: json['composeName'] as String,
      level: json['level'] as String?,
      message: json['message'] as String?,
      createTime: json['createTime'] as String?,
      containerName: json['containerName'] as String?,
      operation: json['operation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'composeName': composeName,
      'level': level,
      'message': message,
      'createTime': createTime,
      'containerName': containerName,
      'operation': operation,
    };
  }

  @override
  List<Object?> get props => [
        id,
        composeName,
        level,
        message,
        createTime,
        containerName,
        operation,
      ];
}

/// Container Compose 配置模型
class ContainerComposeConfig extends Equatable {
  final String id;
  final String name;
  final String? path;
  final String? version;
  final String? description;
  final bool? workDir;
  final bool? autoRemove;
  final List<String>? networks;
  final List<String>? volumes;
  final List<String>? services;

  const ContainerComposeConfig({
    required this.id,
    required this.name,
    this.path,
    this.version,
    this.description,
    this.workDir,
    this.autoRemove,
    this.networks,
    this.volumes,
    this.services,
  });

  factory ContainerComposeConfig.fromJson(Map<String, dynamic> json) {
    return ContainerComposeConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String?,
      version: json['version'] as String?,
      description: json['description'] as String?,
      workDir: json['workDir'] as bool?,
      autoRemove: json['autoRemove'] as bool?,
      networks: (json['networks'] as List?)?.cast<String>(),
      volumes: (json['volumes'] as List?)?.cast<String>(),
      services: (json['services'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'version': version,
      'description': description,
      'workDir': workDir,
      'autoRemove': autoRemove,
      'networks': networks,
      'volumes': volumes,
      'services': services,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        path,
        version,
        description,
        workDir,
        autoRemove,
        networks,
        volumes,
        services,
      ];
}


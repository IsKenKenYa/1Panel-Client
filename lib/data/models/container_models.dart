import 'package:equatable/equatable.dart';

/// 容器操作模型
class ContainerOperate extends Equatable {
  final bool? autoRemove;
  final List<String>? cmd;
  final String? containerID;
  final int? cpuShares;
  final List<String>? dns;
  final String? domainName;
  final List<String>? entrypoint;
  final List<String>? env;
  final List<PortHelper>? exposedPorts;
  final bool? forcePull;
  final String? hostname;
  final String image;
  final String? ipv4;
  final String? ipv6;
  final List<String>? labels;
  final String? macAddr;
  final int? memory;
  final String name;
  final int? nanoCPUs;
  final String? network;
  final bool? openStdin;
  final bool? privileged;
  final bool? publishAllPorts;
  final String? restartPolicy;
  final String? taskID;
  final bool? tty;
  final String? user;
  final List<VolumeHelper>? volumes;
  final String? workingDir;

  const ContainerOperate({
    this.autoRemove,
    this.cmd,
    this.containerID,
    this.cpuShares,
    this.dns,
    this.domainName,
    this.entrypoint,
    this.env,
    this.exposedPorts,
    this.forcePull,
    this.hostname,
    required this.image,
    this.ipv4,
    this.ipv6,
    this.labels,
    this.macAddr,
    this.memory,
    required this.name,
    this.nanoCPUs,
    this.network,
    this.openStdin,
    this.privileged,
    this.publishAllPorts,
    this.restartPolicy,
    this.taskID,
    this.tty,
    this.user,
    this.volumes,
    this.workingDir,
  });

  factory ContainerOperate.fromJson(Map<String, dynamic> json) {
    return ContainerOperate(
      autoRemove: json['autoRemove'] as bool?,
      cmd: (json['cmd'] as List?)?.cast<String>(),
      containerID: json['containerID'] as String?,
      cpuShares: json['cpuShares'] as int?,
      dns: (json['dns'] as List?)?.cast<String>(),
      domainName: json['domainName'] as String?,
      entrypoint: (json['entrypoint'] as List?)?.cast<String>(),
      env: (json['env'] as List?)?.cast<String>(),
      exposedPorts: (json['exposedPorts'] as List?)
          ?.map((item) => PortHelper.fromJson(item as Map<String, dynamic>))
          .toList(),
      forcePull: json['forcePull'] as bool?,
      hostname: json['hostname'] as String?,
      image: json['image'] as String,
      ipv4: json['ipv4'] as String?,
      ipv6: json['ipv6'] as String?,
      labels: (json['labels'] as List?)?.cast<String>(),
      macAddr: json['macAddr'] as String?,
      memory: json['memory'] as int?,
      name: json['name'] as String,
      nanoCPUs: json['nanoCPUs'] as int?,
      network: json['network'] as String?,
      openStdin: json['openStdin'] as bool?,
      privileged: json['privileged'] as bool?,
      publishAllPorts: json['publishAllPorts'] as bool?,
      restartPolicy: json['restartPolicy'] as String?,
      taskID: json['taskID'] as String?,
      tty: json['tty'] as bool?,
      user: json['user'] as String?,
      volumes: (json['volumes'] as List?)
          ?.map((item) => VolumeHelper.fromJson(item as Map<String, dynamic>))
          .toList(),
      workingDir: json['workingDir'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoRemove': autoRemove,
      'cmd': cmd,
      'containerID': containerID,
      'cpuShares': cpuShares,
      'dns': dns,
      'domainName': domainName,
      'entrypoint': entrypoint,
      'env': env,
      'exposedPorts': exposedPorts?.map((item) => item.toJson()).toList(),
      'forcePull': forcePull,
      'hostname': hostname,
      'image': image,
      'ipv4': ipv4,
      'ipv6': ipv6,
      'labels': labels,
      'macAddr': macAddr,
      'memory': memory,
      'name': name,
      'nanoCPUs': nanoCPUs,
      'network': network,
      'openStdin': openStdin,
      'privileged': privileged,
      'publishAllPorts': publishAllPorts,
      'restartPolicy': restartPolicy,
      'taskID': taskID,
      'tty': tty,
      'user': user,
      'volumes': volumes?.map((item) => item.toJson()).toList(),
      'workingDir': workingDir,
    };
  }

  @override
  List<Object?> get props => [
        autoRemove,
        cmd,
        containerID,
        cpuShares,
        dns,
        domainName,
        entrypoint,
        env,
        exposedPorts,
        forcePull,
        hostname,
        image,
        ipv4,
        ipv6,
        labels,
        macAddr,
        memory,
        name,
        nanoCPUs,
        network,
        openStdin,
        privileged,
        publishAllPorts,
        restartPolicy,
        taskID,
        tty,
        user,
        volumes,
        workingDir,
      ];
}

/// 容器批量操作模型
class ContainerOperation extends Equatable {
  final List<String> names;
  final String operation;

  const ContainerOperation({
    required this.names,
    required this.operation,
  });

  factory ContainerOperation.fromJson(Map<String, dynamic> json) {
    return ContainerOperation(
      names: (json['names'] as List?)?.cast<String>() ?? [],
      operation: json['operation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'names': names,
      'operation': operation,
    };
  }

  @override
  List<Object?> get props => [names, operation];
}

/// 容器统计信息模型
class ContainerStats extends Equatable {
  final num cache;
  final double cpuPercent;
  final num ioRead;
  final num ioWrite;
  final num memory;
  final num networkRX;
  final num networkTX;
  final String? shotTime;

  const ContainerStats({
    required this.cache,
    required this.cpuPercent,
    required this.ioRead,
    required this.ioWrite,
    required this.memory,
    required this.networkRX,
    required this.networkTX,
    this.shotTime,
  });

  factory ContainerStats.fromJson(Map<String, dynamic> json) {
    return ContainerStats(
      cache: json['cache'] as num? ?? 0,
      cpuPercent: (json['cpuPercent'] as num?)?.toDouble() ?? 0.0,
      ioRead: json['ioRead'] as num? ?? 0,
      ioWrite: json['ioWrite'] as num? ?? 0,
      memory: json['memory'] as num? ?? 0,
      networkRX: json['networkRX'] as num? ?? 0,
      networkTX: json['networkTX'] as num? ?? 0,
      shotTime: json['shotTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cache': cache,
      'cpuPercent': cpuPercent,
      'ioRead': ioRead,
      'ioWrite': ioWrite,
      'memory': memory,
      'networkRX': networkRX,
      'networkTX': networkTX,
      'shotTime': shotTime,
    };
  }

  @override
  List<Object?> get props => [
        cache,
        cpuPercent,
        ioRead,
        ioWrite,
        memory,
        networkRX,
        networkTX,
        shotTime,
      ];
}

/// 容器列表统计信息模型
class ContainerListStats extends Equatable {
  final String containerID;
  final double cpuPercent;
  final int cpuTotalUsage;
  final int memoryCache;
  final int memoryLimit;
  final double memoryPercent;
  final int memoryUsage;
  final int percpuUsage;
  final int systemUsage;

  const ContainerListStats({
    required this.containerID,
    required this.cpuPercent,
    required this.cpuTotalUsage,
    required this.memoryCache,
    required this.memoryLimit,
    required this.memoryPercent,
    required this.memoryUsage,
    required this.percpuUsage,
    required this.systemUsage,
  });

  factory ContainerListStats.fromJson(Map<String, dynamic> json) {
    return ContainerListStats(
      containerID: json['containerID'] as String,
      cpuPercent: (json['cpuPercent'] as num?)?.toDouble() ?? 0.0,
      cpuTotalUsage: json['cpuTotalUsage'] as int? ?? 0,
      memoryCache: json['memoryCache'] as int? ?? 0,
      memoryLimit: json['memoryLimit'] as int? ?? 0,
      memoryPercent: (json['memoryPercent'] as num?)?.toDouble() ?? 0.0,
      memoryUsage: json['memoryUsage'] as int? ?? 0,
      percpuUsage: json['percpuUsage'] as int? ?? 0,
      systemUsage: json['systemUsage'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'containerID': containerID,
      'cpuPercent': cpuPercent,
      'cpuTotalUsage': cpuTotalUsage,
      'memoryCache': memoryCache,
      'memoryLimit': memoryLimit,
      'memoryPercent': memoryPercent,
      'memoryUsage': memoryUsage,
      'percpuUsage': percpuUsage,
      'systemUsage': systemUsage,
    };
  }

  @override
  List<Object?> get props => [
        containerID,
        cpuPercent,
        cpuTotalUsage,
        memoryCache,
        memoryLimit,
        memoryPercent,
        memoryUsage,
        percpuUsage,
        systemUsage,
      ];
}

/// 容器状态统计模型
class ContainerStatus extends Equatable {
  final int all;
  final int composeCount;
  final int composeTemplateCount;
  final int containerCount;
  final int created;
  final int dead;
  final int exited;
  final int imageCount;
  final int imageSize;
  final int networkCount;
  final int paused;
  final int removing;
  final int repoCount;
  final int restarting;
  final int running;
  final int volumeCount;

  const ContainerStatus({
    required this.all,
    required this.composeCount,
    required this.composeTemplateCount,
    required this.containerCount,
    required this.created,
    required this.dead,
    required this.exited,
    required this.imageCount,
    required this.imageSize,
    required this.networkCount,
    required this.paused,
    required this.removing,
    required this.repoCount,
    required this.restarting,
    required this.running,
    required this.volumeCount,
  });

  factory ContainerStatus.fromJson(Map<String, dynamic> json) {
    return ContainerStatus(
      all: json['all'] as int? ?? 0,
      composeCount: json['composeCount'] as int? ?? 0,
      composeTemplateCount: json['composeTemplateCount'] as int? ?? 0,
      containerCount: json['containerCount'] as int? ?? 0,
      created: json['created'] as int? ?? 0,
      dead: json['dead'] as int? ?? 0,
      exited: json['exited'] as int? ?? 0,
      imageCount: json['imageCount'] as int? ?? 0,
      imageSize: json['imageSize'] as int? ?? 0,
      networkCount: json['networkCount'] as int? ?? 0,
      paused: json['paused'] as int? ?? 0,
      removing: json['removing'] as int? ?? 0,
      repoCount: json['repoCount'] as int? ?? 0,
      restarting: json['restarting'] as int? ?? 0,
      running: json['running'] as int? ?? 0,
      volumeCount: json['volumeCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'all': all,
      'composeCount': composeCount,
      'composeTemplateCount': composeTemplateCount,
      'containerCount': containerCount,
      'created': created,
      'dead': dead,
      'exited': exited,
      'imageCount': imageCount,
      'imageSize': imageSize,
      'networkCount': networkCount,
      'paused': paused,
      'removing': removing,
      'repoCount': repoCount,
      'restarting': restarting,
      'running': running,
      'volumeCount': volumeCount,
    };
  }

  @override
  List<Object?> get props => [
        all,
        composeCount,
        composeTemplateCount,
        containerCount,
        created,
        dead,
        exited,
        imageCount,
        imageSize,
        networkCount,
        paused,
        removing,
        repoCount,
        restarting,
        running,
        volumeCount,
      ];
}

/// 端口配置模型
class PortHelper extends Equatable {
  final String containerPort;
  final String? hostIP;
  final String? hostPort;
  final String protocol;

  const PortHelper({
    required this.containerPort,
    this.hostIP,
    this.hostPort,
    this.protocol = 'tcp',
  });

  factory PortHelper.fromJson(Map<String, dynamic> json) {
    return PortHelper(
      containerPort: json['containerPort'] as String,
      hostIP: json['hostIP'] as String?,
      hostPort: json['hostPort'] as String?,
      protocol: json['protocol'] as String? ?? 'tcp',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'containerPort': containerPort,
      'hostIP': hostIP,
      'hostPort': hostPort,
      'protocol': protocol,
    };
  }

  @override
  List<Object?> get props => [containerPort, hostIP, hostPort, protocol];
}

/// 卷配置模型
class VolumeHelper extends Equatable {
  final String containerDir;
  final String mode;
  final String sourceDir;
  final String type;

  const VolumeHelper({
    required this.containerDir,
    this.mode = 'rw',
    required this.sourceDir,
    this.type = 'bind',
  });

  factory VolumeHelper.fromJson(Map<String, dynamic> json) {
    return VolumeHelper(
      containerDir: json['containerDir'] as String,
      mode: json['mode'] as String? ?? 'rw',
      sourceDir: json['sourceDir'] as String,
      type: json['type'] as String? ?? 'bind',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'containerDir': containerDir,
      'mode': mode,
      'sourceDir': sourceDir,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [containerDir, mode, sourceDir, type];
}

/// 容器分页查询模型
class PageContainer extends Equatable {
  final bool? excludeAppStore;
  final String? filters;
  final String? name;
  final String order;
  final String orderBy;
  final int page;
  final int pageSize;
  final String? state;

  const PageContainer({
    this.excludeAppStore,
    this.filters,
    this.name,
    this.order = 'descending',
    this.orderBy = 'createdAt',
    this.page = 1,
    this.pageSize = 10,
    this.state = 'all',
  });

  factory PageContainer.fromJson(Map<String, dynamic> json) {
    return PageContainer(
      excludeAppStore: json['excludeAppStore'] as bool?,
      filters: json['filters'] as String?,
      name: json['name'] as String?,
      order: json['order'] as String? ?? 'descending',
      orderBy: json['orderBy'] as String? ?? 'createdAt',
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      state: json['state'] as String? ?? 'all',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (excludeAppStore != null) 'excludeAppStore': excludeAppStore,
      if (filters != null) 'filters': filters,
      if (name != null) 'name': name,
      'order': order,
      'orderBy': orderBy,
      'page': page,
      'pageSize': pageSize,
      'state': state ?? 'all',
    };
  }

  @override
  List<Object?> get props => [
        excludeAppStore,
        filters,
        name,
        order,
        orderBy,
        page,
        pageSize,
        state,
      ];
}

/// 容器信息模型 (对应 Docker Container)
typedef Container = ContainerInfo;

/// 容器信息模型
class ContainerInfo extends Equatable {
  final String id;
  final String name;
  final String image;
  final String status;
  final String state;
  final List<String>? ports;
  final String? createTime;
  final String? ipAddress;
  final String? network;
  final String? cpuUsage;
  final String? memoryUsage;
  final List<String>? labels;
  final List<PortHelper>? portBindings;
  final List<VolumeHelper>? volumeBindings;

  const ContainerInfo({
    required this.id,
    required this.name,
    required this.image,
    required this.status,
    required this.state,
    this.ports,
    this.createTime,
    this.ipAddress,
    this.network,
    this.cpuUsage,
    this.memoryUsage,
    this.labels,
    this.portBindings,
    this.volumeBindings,
  });

  factory ContainerInfo.fromJson(Map<String, dynamic> json) {
    return ContainerInfo(
      id: (json['id'] ?? json['containerID']) as String? ?? '',
      name: json['name'] as String? ?? '',
      image: (json['image'] ?? json['imageName']) as String? ?? '',
      status: (json['status'] ?? json['runTime']) as String? ?? '',
      state: json['state'] as String? ?? '',
      ports: (json['ports'] is List) ? (json['ports'] as List).cast<String>() : null,
      createTime: json['createTime'] as String?,
      ipAddress: json['ipAddress'] as String?,
      network: (json['network'] is List) 
          ? (json['network'] as List).join(', ') 
          : json['network'] as String?,
      cpuUsage: json['cpuUsage'] as String?,
      memoryUsage: json['memoryUsage'] as String?,
      labels: (json['labels'] as List?)?.cast<String>(),
      portBindings: (json['portBindings'] as List?)
          ?.map((item) => PortHelper.fromJson(item as Map<String, dynamic>))
          .toList(),
      volumeBindings: (json['volumeBindings'] as List?)
          ?.map((item) => VolumeHelper.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'status': status,
      'state': state,
      'ports': ports,
      'createTime': createTime,
      'ipAddress': ipAddress,
      'network': network,
      'cpuUsage': cpuUsage,
      'memoryUsage': memoryUsage,
      'labels': labels,
      'portBindings': portBindings?.map((item) => item.toJson()).toList(),
      'volumeBindings': volumeBindings?.map((item) => item.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        image,
        status,
        state,
        ports,
        createTime,
        ipAddress,
        network,
        cpuUsage,
        memoryUsage,
        labels,
        portBindings,
        volumeBindings,
      ];
}

/// 容器提交模型
class ContainerCommit extends Equatable {
  final String? author;
  final String? comment;
  final String containerID;
  final String containerName;
  final String newImageName;
  final bool? pause;

  const ContainerCommit({
    this.author,
    this.comment,
    required this.containerID,
    required this.containerName,
    required this.newImageName,
    this.pause,
  });

  factory ContainerCommit.fromJson(Map<String, dynamic> json) {
    return ContainerCommit(
      author: json['author'] as String?,
      comment: json['comment'] as String?,
      containerID: json['containerID'] as String,
      containerName: json['containerName'] as String,
      newImageName: json['newImageName'] as String,
      pause: json['pause'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'comment': comment,
      'containerID': containerID,
      'containerName': containerName,
      'newImageName': newImageName,
      'pause': pause,
    };
  }

  @override
  List<Object?> get props => [author, comment, containerID, containerName, newImageName, pause];
}

/// 容器清理模型
class ContainerPrune extends Equatable {
  final String pruneType;
  final bool? withTagAll;

  const ContainerPrune({
    required this.pruneType,
    this.withTagAll,
  });

  factory ContainerPrune.fromJson(Map<String, dynamic> json) {
    return ContainerPrune(
      pruneType: json['pruneType'] as String,
      withTagAll: json['withTagAll'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pruneType': pruneType,
      'withTagAll': withTagAll,
    };
  }

  @override
  List<Object?> get props => [pruneType, withTagAll];
}

/// 容器升级模型
class ContainerUpgrade extends Equatable {
  final bool? forcePull;
  final String image;
  final String name;
  final String? taskID;

  const ContainerUpgrade({
    this.forcePull,
    required this.image,
    required this.name,
    this.taskID,
  });

  factory ContainerUpgrade.fromJson(Map<String, dynamic> json) {
    return ContainerUpgrade(
      forcePull: json['forcePull'] as bool?,
      image: json['image'] as String,
      name: json['name'] as String,
      taskID: json['taskID'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'forcePull': forcePull,
      'image': image,
      'name': name,
      'taskID': taskID,
    };
  }

  @override
  List<Object?> get props => [forcePull, image, name, taskID];
}

/// 容器重命名模型
class ContainerRename extends Equatable {
  final String name;
  final String newName;

  const ContainerRename({
    required this.name,
    required this.newName,
  });

  factory ContainerRename.fromJson(Map<String, dynamic> json) {
    return ContainerRename(
      name: json['name'] as String,
      newName: json['newName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'newName': newName,
    };
  }

  @override
  List<Object?> get props => [name, newName];
}

/// 容器操作类型枚举
enum ContainerOperationType {
  up('up', '启动'),
  start('start', '开始'),
  stop('stop', '停止'),
  restart('restart', '重启'),
  kill('kill', '强制停止'),
  pause('pause', '暂停'),
  unpause('unpause', '恢复'),
  remove('remove', '删除');

  const ContainerOperationType(this.value, this.displayName);

  final String value;
  final String displayName;

  static ContainerOperationType fromString(String value) {
    return ContainerOperationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ContainerOperationType.start,
    );
  }
}

/// 容器状态枚举
enum ContainerState {
  all('all', '全部'),
  created('created', '已创建'),
  running('running', '运行中'),
  paused('paused', '已暂停'),
  restarting('restarting', '重启中'),
  removing('removing', '删除中'),
  exited('exited', '已退出'),
  dead('dead', '死亡状态');

  const ContainerState(this.value, this.displayName);

  final String value;
  final String displayName;

  static ContainerState fromString(String value) {
    return ContainerState.values.firstWhere(
      (state) => state.value == value,
      orElse: () => ContainerState.all,
    );
  }
}

/// 容器清理类型枚举
enum ContainerPruneType {
  container('container', '容器'),
  image('image', '镜像'),
  volume('volume', '卷'),
  network('network', '网络'),
  buildcache('buildcache', '构建缓存');

  const ContainerPruneType(this.value, this.displayName);

  final String value;
  final String displayName;

  static ContainerPruneType fromString(String value) {
    return ContainerPruneType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ContainerPruneType.container,
    );
  }
}

/// Container Compose 模型
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
  });

  factory ContainerCompose.fromJson(Map<String, dynamic> json) {
    return ContainerCompose(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String?,
      version: json['version'] as String?,
      status: json['status'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
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
      'status': status,
      'createTime': createTime,
      'updateTime': updateTime,
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
        status,
        createTime,
        updateTime,
        networks,
        volumes,
        services,
      ];
}

/// Container Compose 创建请求模型
class ContainerComposeCreate extends Equatable {
  final String name;
  final String path;
  final String? version;
  final List<String>? networks;
  final List<String>? volumes;
  final List<String>? services;

  const ContainerComposeCreate({
    required this.name,
    required this.path,
    this.version,
    this.networks,
    this.volumes,
    this.services,
  });

  factory ContainerComposeCreate.fromJson(Map<String, dynamic> json) {
    return ContainerComposeCreate(
      name: json['name'] as String,
      path: json['path'] as String,
      version: json['version'] as String?,
      networks: (json['networks'] as List?)?.cast<String>(),
      volumes: (json['volumes'] as List?)?.cast<String>(),
      services: (json['services'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
        name,
        path,
        version,
        networks,
        volumes,
        services,
      ];
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
  final List<int>? ids;
  final String? id;
  final String operation;
  final bool? force;

  const ContainerComposeOperate({
    this.ids,
    this.id,
    required this.operation,
    this.force,
  });

  factory ContainerComposeOperate.fromJson(Map<String, dynamic> json) {
    return ContainerComposeOperate(
      ids: (json['ids'] as List?)?.cast<int>(),
      id: json['id'] as String?,
      operation: json['operation'] as String,
      force: json['force'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ids': ids,
      'id': id,
      'operation': operation,
      'force': force,
    };
  }

  @override
  List<Object?> get props => [
        ids,
        id,
        operation,
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

/// 容器命令创建模型
class ContainerCreateByCommand extends Equatable {
  final String command;
  final String? name;

  const ContainerCreateByCommand({
    required this.command,
    this.name,
  });

  factory ContainerCreateByCommand.fromJson(Map<String, dynamic> json) {
    return ContainerCreateByCommand(
      command: json['command'] as String,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'command': command,
      'name': name,
    };
  }

  @override
  List<Object?> get props => [command, name];
}

/// 容器检查请求模型
class InspectReq extends Equatable {
  final String id;
  final String type;

  const InspectReq({
    required this.id,
    required this.type,
  });

  factory InspectReq.fromJson(Map<String, dynamic> json) {
    return InspectReq(
      id: json['id'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [id, type];
}

/// 镜像构建模型
class ImageBuild extends Equatable {
  final String contextDir;
  final String? dockerfile;
  final List<String>? tags;
  final String? buildArgs;
  final bool? pull;
  final bool? noCache;
  final bool? rm;
  final String? label;

  const ImageBuild({
    required this.contextDir,
    this.dockerfile,
    this.tags,
    this.buildArgs,
    this.pull,
    this.noCache,
    this.rm,
    this.label,
  });

  factory ImageBuild.fromJson(Map<String, dynamic> json) {
    return ImageBuild(
      contextDir: json['contextDir'] as String,
      dockerfile: json['dockerfile'] as String?,
      tags: (json['tags'] as List?)?.cast<String>(),
      buildArgs: json['buildArgs'] as String?,
      pull: json['pull'] as bool?,
      noCache: json['noCache'] as bool?,
      rm: json['rm'] as bool?,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contextDir': contextDir,
      'dockerfile': dockerfile,
      'tags': tags,
      'buildArgs': buildArgs,
      'pull': pull,
      'noCache': noCache,
      'rm': rm,
      'label': label,
    };
  }

  @override
  List<Object?> get props => [
        contextDir,
        dockerfile,
        tags,
        buildArgs,
        pull,
        noCache,
        rm,
        label,
      ];
}

/// 镜像加载模型
class ImageLoad extends Equatable {
  final String filePath;
  final bool? quiet;

  const ImageLoad({
    required this.filePath,
    this.quiet,
  });

  factory ImageLoad.fromJson(Map<String, dynamic> json) {
    return ImageLoad(
      filePath: json['filePath'] as String,
      quiet: json['quiet'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'quiet': quiet,
    };
  }

  @override
  List<Object?> get props => [filePath, quiet];
}

/// 镜像拉取模型
class ImagePull extends Equatable {
  final String image;
  final String? tag;
  final bool? allTags;
  final String? platform;

  const ImagePull({
    required this.image,
    this.tag,
    this.allTags,
    this.platform,
  });

  factory ImagePull.fromJson(Map<String, dynamic> json) {
    return ImagePull(
      image: json['image'] as String,
      tag: json['tag'] as String?,
      allTags: json['allTags'] as bool?,
      platform: json['platform'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'tag': tag,
      'allTags': allTags,
      'platform': platform,
    };
  }

  @override
  List<Object?> get props => [image, tag, allTags, platform];
}

/// 镜像推送模型
class ImagePush extends Equatable {
  final String image;
  final String? tag;
  final String? registry;

  const ImagePush({
    required this.image,
    this.tag,
    this.registry,
  });

  factory ImagePush.fromJson(Map<String, dynamic> json) {
    return ImagePush(
      image: json['image'] as String,
      tag: json['tag'] as String?,
      registry: json['registry'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'tag': tag,
      'registry': registry,
    };
  }

  @override
  List<Object?> get props => [image, tag, registry];
}

/// 镜像保存模型
class ImageSave extends Equatable {
  final List<String> images;
  final String filePath;

  const ImageSave({
    required this.images,
    required this.filePath,
  });

  factory ImageSave.fromJson(Map<String, dynamic> json) {
    return ImageSave(
      images: (json['images'] as List?)?.cast<String>() ?? [],
      filePath: json['filePath'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'images': images,
      'filePath': filePath,
    };
  }

  @override
  List<Object?> get props => [images, filePath];
}

/// 镜像标记模型
class ImageTag extends Equatable {
  final String sourceImage;
  final String targetImage;
  final String? tag;

  const ImageTag({
    required this.sourceImage,
    required this.targetImage,
    this.tag,
  });

  factory ImageTag.fromJson(Map<String, dynamic> json) {
    return ImageTag(
      sourceImage: json['sourceImage'] as String,
      targetImage: json['targetImage'] as String,
      tag: json['tag'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceImage': sourceImage,
      'targetImage': targetImage,
      'tag': tag,
    };
  }

  @override
  List<Object?> get props => [sourceImage, targetImage, tag];
}

/// 网络创建模型
class NetworkCreate extends Equatable {
  final String name;
  final String? driver;
  final bool? internal;
  final bool? attachable;
  final List<String>? ipam;
  final Map<String, String>? labels;
  final bool? enableIPv6;

  const NetworkCreate({
    required this.name,
    this.driver,
    this.internal,
    this.attachable,
    this.ipam,
    this.labels,
    this.enableIPv6,
  });

  factory NetworkCreate.fromJson(Map<String, dynamic> json) {
    return NetworkCreate(
      name: json['name'] as String,
      driver: json['driver'] as String?,
      internal: json['internal'] as bool?,
      attachable: json['attachable'] as bool?,
      ipam: (json['ipam'] as List?)?.cast<String>(),
      labels: (json['labels'] as Map<String, dynamic>?)?.cast<String, String>(),
      enableIPv6: json['enableIPv6'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'driver': driver,
      'internal': internal,
      'attachable': attachable,
      'ipam': ipam,
      'labels': labels,
      'enableIPv6': enableIPv6,
    };
  }

  @override
  List<Object?> get props => [
        name,
        driver,
        internal,
        attachable,
        ipam,
        labels,
        enableIPv6,
      ];
}

/// 卷创建模型
class VolumeCreate extends Equatable {
  final String name;
  final String? driver;
  final Map<String, String>? driverOpts;
  final Map<String, String>? labels;

  const VolumeCreate({
    required this.name,
    this.driver,
    this.driverOpts,
    this.labels,
  });

  factory VolumeCreate.fromJson(Map<String, dynamic> json) {
    return VolumeCreate(
      name: json['name'] as String,
      driver: json['driver'] as String?,
      driverOpts: (json['driverOpts'] as Map<String, dynamic>?)?.cast<String, String>(),
      labels: (json['labels'] as Map<String, dynamic>?)?.cast<String, String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'driver': driver,
      'driverOpts': driverOpts,
      'labels': labels,
    };
  }

  @override
  List<Object?> get props => [name, driver, driverOpts, labels];
}

/// 容器清理报告模型
class ContainerPruneReport extends Equatable {
  final int? deletedCount;
  final int? spaceReclaimed;
  final List<String>? deletedItems;
  final String? message;

  const ContainerPruneReport({
    this.deletedCount,
    this.spaceReclaimed,
    this.deletedItems,
    this.message,
  });

  factory ContainerPruneReport.fromJson(Map<String, dynamic> json) {
    return ContainerPruneReport(
      deletedCount: json['deletedCount'] as int?,
      spaceReclaimed: json['spaceReclaimed'] as int?,
      deletedItems: (json['deletedItems'] as List?)?.cast<String>(),
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deletedCount': deletedCount,
      'spaceReclaimed': spaceReclaimed,
      'deletedItems': deletedItems,
      'message': message,
    };
  }

  @override
  List<Object?> get props => [deletedCount, spaceReclaimed, deletedItems, message];
}

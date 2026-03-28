import 'package:equatable/equatable.dart';

/// Container image model
class ContainerImage extends Equatable {
  final String? id;
  final List<String>? repoTags;
  final String? repoDigests;
  final int? size;
  final String? created;
  final String? labels;
  final String? architecture;
  final String? os;

  const ContainerImage({
    this.id,
    this.repoTags,
    this.repoDigests,
    this.size,
    this.created,
    this.labels,
    this.architecture,
    this.os,
  });

  factory ContainerImage.fromJson(Map<String, dynamic> json) {
    return ContainerImage(
      id: json['id'] as String?,
      repoTags: (json['repoTags'] as List?)?.map((e) => e as String).toList(),
      repoDigests: json['repoDigests'] as String?,
      size: json['size'] as int?,
      created: json['created'] as String?,
      labels: json['labels'] as String?,
      architecture: json['architecture'] as String?,
      os: json['os'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repoTags': repoTags,
      'repoDigests': repoDigests,
      'size': size,
      'created': created,
      'labels': labels,
      'architecture': architecture,
      'os': os,
    };
  }

  @override
  List<Object?> get props =>
      [id, repoTags, repoDigests, size, created, labels, architecture, os];
}

/// Container network model
class ContainerNetwork extends Equatable {
  final String? id;
  final String? name;
  final String? driver;
  final String? scope;
  final bool? internal;
  final bool? enableIPv6;
  final Map<String, dynamic>? ipam;
  final Map<String, dynamic>? options;
  final List<String>? containers;

  const ContainerNetwork({
    this.id,
    this.name,
    this.driver,
    this.scope,
    this.internal,
    this.enableIPv6,
    this.ipam,
    this.options,
    this.containers,
  });

  factory ContainerNetwork.fromJson(Map<String, dynamic> json) {
    return ContainerNetwork(
      id: json['id'] as String?,
      name: json['name'] as String?,
      driver: json['driver'] as String?,
      scope: json['scope'] as String?,
      internal: json['internal'] as bool?,
      enableIPv6: json['enableIPv6'] as bool?,
      ipam: json['ipam'] as Map<String, dynamic>?,
      options: json['options'] as Map<String, dynamic>?,
      containers:
          (json['containers'] as List?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'driver': driver,
      'scope': scope,
      'internal': internal,
      'enableIPv6': enableIPv6,
      'ipam': ipam,
      'options': options,
      'containers': containers,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        driver,
        scope,
        internal,
        enableIPv6,
        ipam,
        options,
        containers
      ];
}

/// Container volume model
class ContainerVolume extends Equatable {
  final String? name;
  final String? driver;
  final Map<String, dynamic>? options;
  final Map<String, dynamic>? labels;
  final String? mountpoint;
  final String? createdAt;
  final String? scope;

  const ContainerVolume({
    this.name,
    this.driver,
    this.options,
    this.labels,
    this.mountpoint,
    this.createdAt,
    this.scope,
  });

  factory ContainerVolume.fromJson(Map<String, dynamic> json) {
    return ContainerVolume(
      name: json['name'] as String?,
      driver: json['driver'] as String?,
      options: json['options'] as Map<String, dynamic>?,
      labels: json['labels'] as Map<String, dynamic>?,
      mountpoint: json['mountpoint'] as String?,
      createdAt: json['createdAt'] as String?,
      scope: json['scope'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'driver': driver,
      'options': options,
      'labels': labels,
      'mountpoint': mountpoint,
      'createdAt': createdAt,
      'scope': scope,
    };
  }

  @override
  List<Object?> get props =>
      [name, driver, options, labels, mountpoint, createdAt, scope];
}

/// Container registry model
class ContainerRegistry extends Equatable {
  final int? id;
  final String? name;
  final String? url;
  final String? username;
  final bool? secure;
  final String? description;
  final bool? enabled;
  final String? createTime;
  final String? updateTime;

  const ContainerRegistry({
    this.id,
    this.name,
    this.url,
    this.username,
    this.secure,
    this.description,
    this.enabled,
    this.createTime,
    this.updateTime,
  });

  factory ContainerRegistry.fromJson(Map<String, dynamic> json) {
    return ContainerRegistry(
      id: json['id'] as int?,
      name: json['name'] as String?,
      url: json['url'] as String?,
      username: json['username'] as String?,
      secure: json['secure'] as bool?,
      description: json['description'] as String?,
      enabled: json['enabled'] as bool?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'username': username,
      'secure': secure,
      'description': description,
      'enabled': enabled,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        url,
        username,
        secure,
        description,
        enabled,
        createTime,
        updateTime
      ];
}

/// Container network creation request
class ContainerNetworkCreate extends Equatable {
  final String name;
  final String? driver;
  final bool? internal;
  final bool? enableIPv6;
  final Map<String, dynamic>? ipam;
  final Map<String, dynamic>? options;
  final Map<String, dynamic>? labels;

  const ContainerNetworkCreate({
    required this.name,
    this.driver,
    this.internal,
    this.enableIPv6,
    this.ipam,
    this.options,
    this.labels,
  });

  factory ContainerNetworkCreate.fromJson(Map<String, dynamic> json) {
    return ContainerNetworkCreate(
      name: json['name'] as String,
      driver: json['driver'] as String?,
      internal: json['internal'] as bool?,
      enableIPv6: json['enableIPv6'] as bool?,
      ipam: json['ipam'] as Map<String, dynamic>?,
      options: json['options'] as Map<String, dynamic>?,
      labels: json['labels'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'driver': driver,
      'internal': internal,
      'enableIPv6': enableIPv6,
      'ipam': ipam,
      'options': options,
      'labels': labels,
    };
  }

  @override
  List<Object?> get props =>
      [name, driver, internal, enableIPv6, ipam, options, labels];
}

/// Container volume creation request
class ContainerVolumeCreate extends Equatable {
  final String name;
  final String? driver;
  final Map<String, dynamic>? driverOpts;
  final Map<String, dynamic>? labels;

  const ContainerVolumeCreate({
    required this.name,
    this.driver,
    this.driverOpts,
    this.labels,
  });

  factory ContainerVolumeCreate.fromJson(Map<String, dynamic> json) {
    return ContainerVolumeCreate(
      name: json['name'] as String,
      driver: json['driver'] as String?,
      driverOpts: json['driverOpts'] as Map<String, dynamic>?,
      labels: json['labels'] as Map<String, dynamic>?,
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

/// Container registry creation request
class ContainerRegistryCreate extends Equatable {
  final String name;
  final String url;
  final String username;
  final String password;
  final bool? secure;
  final String? description;

  const ContainerRegistryCreate({
    required this.name,
    required this.url,
    required this.username,
    required this.password,
    this.secure,
    this.description,
  });

  factory ContainerRegistryCreate.fromJson(Map<String, dynamic> json) {
    return ContainerRegistryCreate(
      name: json['name'] as String,
      url: json['url'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      secure: json['secure'] as bool?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'username': username,
      'password': password,
      'secure': secure,
      'description': description,
    };
  }

  @override
  List<Object?> get props =>
      [name, url, username, password, secure, description];
}

/// Container image pull request
class ContainerImagePull extends Equatable {
  final String image;
  final String? tag;
  final String? registry;
  final bool? pullAll;

  const ContainerImagePull({
    required this.image,
    this.tag,
    this.registry,
    this.pullAll,
  });

  factory ContainerImagePull.fromJson(Map<String, dynamic> json) {
    return ContainerImagePull(
      image: json['image'] as String,
      tag: json['tag'] as String?,
      registry: json['registry'] as String?,
      pullAll: json['pullAll'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'tag': tag,
      'registry': registry,
      'pullAll': pullAll,
    };
  }

  @override
  List<Object?> get props => [image, tag, registry, pullAll];
}

/// Container image push request
class ContainerImagePush extends Equatable {
  final String image;
  final String? tag;
  final String? registry;

  const ContainerImagePush({
    required this.image,
    this.tag,
    this.registry,
  });

  factory ContainerImagePush.fromJson(Map<String, dynamic> json) {
    return ContainerImagePush(
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

/// Container search request
class ContainerSearch extends Equatable {
  final int? page;
  final int? pageSize;
  final String? search;
  final String? status;
  final String? sortBy;
  final String? sortOrder;

  const ContainerSearch({
    this.page,
    this.pageSize,
    this.search,
    this.status,
    this.sortBy,
    this.sortOrder,
  });

  factory ContainerSearch.fromJson(Map<String, dynamic> json) {
    return ContainerSearch(
      page: json['page'] as int?,
      pageSize: json['pageSize'] as int?,
      search: json['search'] as String?,
      status: json['status'] as String?,
      sortBy: json['sortBy'] as String?,
      sortOrder: json['sortOrder'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'search': search,
      'status': status,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
  }

  @override
  List<Object?> get props =>
      [page, pageSize, search, status, sortBy, sortOrder];
}

// ============================================
// Container Compose Models
// ============================================

/// Container Compose Log Search Model
class ContainerComposeLogSearch extends Equatable {
  final int? composeId;
  final int? lines;
  final String? name;
  final String? since;
  final String? tail;
  final bool? follow;
  final String? container;

  const ContainerComposeLogSearch({
    this.composeId,
    this.lines,
    this.name,
    this.since,
    this.tail,
    this.follow,
    this.container,
  });

  factory ContainerComposeLogSearch.fromJson(Map<String, dynamic> json) {
    return ContainerComposeLogSearch(
      composeId: json['composeId'] as int?,
      lines: json['lines'] as int?,
      name: json['name'] as String?,
      since: json['since'] as String?,
      tail: json['tail'] as String?,
      follow: json['follow'] as bool?,
      container: json['container'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'composeId': composeId,
      'lines': lines,
      'name': name,
      'since': since,
      'tail': tail,
      'follow': follow,
      'container': container,
    };
  }

  @override
  List<Object?> get props =>
      [composeId, lines, name, since, tail, follow, container];
}

/// Container Compose Config Update Model
class ContainerComposeConfigUpdate extends Equatable {
  final String? id;
  final String name;
  final String content;
  final String? path;
  final String? description;

  const ContainerComposeConfigUpdate({
    this.id,
    required this.name,
    required this.content,
    this.path,
    this.description,
  });

  factory ContainerComposeConfigUpdate.fromJson(Map<String, dynamic> json) {
    return ContainerComposeConfigUpdate(
      id: json['id'] as String?,
      name: json['name'] as String,
      content: json['content'] as String,
      path: json['path'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'path': path,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [id, name, content, path, description];
}

/// Container Compose Status Model
class ContainerComposeStatus extends Equatable {
  final String name;
  final String status;
  final int? containerCount;
  final int? runningCount;
  final int? exitedCount;
  final String? createdAt;
  final String? updatedAt;

  const ContainerComposeStatus({
    required this.name,
    required this.status,
    this.containerCount,
    this.runningCount,
    this.exitedCount,
    this.createdAt,
    this.updatedAt,
  });

  factory ContainerComposeStatus.fromJson(Map<String, dynamic> json) {
    return ContainerComposeStatus(
      name: json['name'] as String,
      status: json['status'] as String,
      containerCount: json['containerCount'] as int?,
      runningCount: json['runningCount'] as int?,
      exitedCount: json['exitedCount'] as int?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status,
      'containerCount': containerCount,
      'runningCount': runningCount,
      'exitedCount': exitedCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
        name,
        status,
        containerCount,
        runningCount,
        exitedCount,
        createdAt,
        updatedAt
      ];
}

/// Container Compose Import Model
class ContainerComposeImport extends Equatable {
  final String name;
  final String content;
  final String? description;
  final String? path;

  const ContainerComposeImport({
    required this.name,
    required this.content,
    this.description,
    this.path,
  });

  factory ContainerComposeImport.fromJson(Map<String, dynamic> json) {
    return ContainerComposeImport(
      name: json['name'] as String,
      content: json['content'] as String,
      description: json['description'] as String?,
      path: json['path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'content': content,
      'description': description,
      'path': path,
    };
  }

  @override
  List<Object?> get props => [name, content, description, path];
}

/// Container Compose Export Model
class ContainerComposeExport extends Equatable {
  final String name;
  final String? format;
  final String? downloadPath;

  const ContainerComposeExport({
    required this.name,
    this.format,
    this.downloadPath,
  });

  factory ContainerComposeExport.fromJson(Map<String, dynamic> json) {
    return ContainerComposeExport(
      name: json['name'] as String,
      format: json['format'] as String?,
      downloadPath: json['downloadPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'format': format,
      'downloadPath': downloadPath,
    };
  }

  @override
  List<Object?> get props => [name, format, downloadPath];
}

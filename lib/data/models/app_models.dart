import 'package:json_annotation/json_annotation.dart';

part 'app_models.g.dart';

/// 应用搜索请求模型
@JsonSerializable()
class AppSearchRequest {
  final int page;
  @JsonKey(name: 'pageSize')
  final int pageSize;
  final String? name;
  final bool? recommend;
  final String? resource;
  @JsonKey(name: 'showCurrentArch')
  final bool? showCurrentArch;
  final List<String>? tags;
  final String? type;

  AppSearchRequest({
    required this.page,
    required this.pageSize,
    this.name,
    this.recommend,
    this.resource,
    this.showCurrentArch,
    this.tags,
    this.type,
  });

  factory AppSearchRequest.fromJson(Map<String, dynamic> json) => _$AppSearchRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AppSearchRequestToJson(this);
}

/// 应用搜索响应模型
@JsonSerializable()
class AppSearchResponse {
  final List<AppItem> items;
  final int total;

  AppSearchResponse({
    required this.items,
    required this.total,
  });

  factory AppSearchResponse.fromJson(Map<String, dynamic> json) => _$AppSearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AppSearchResponseToJson(this);
}

/// 应用项模型
@JsonSerializable()
class AppItem {
  final String? description;
  final String? github;
  final bool? gpuSupport;
  final String? icon;
  final int? id;
  final bool? installed;
  final String? key;
  final int? limit;
  final String? name;
  final String? readMe;
  final int? recommend;
  final String? resource;
  final String? status;
  final List<dynamic>? tags; // 支持字符串或对象
  final String? type;
  final List<String>? versions;
  final String? website;

  AppItem({
    this.description,
    this.github,
    this.gpuSupport,
    this.icon,
    this.id,
    this.installed,
    this.key,
    this.limit,
    this.name,
    this.readMe,
    this.recommend,
    this.resource,
    this.status,
    this.tags,
    this.type,
    this.versions,
    this.website,
  });

  factory AppItem.fromJson(Map<String, dynamic> json) => _$AppItemFromJson(json);
  Map<String, dynamic> toJson() => _$AppItemToJson(this);
  
  /// 获取标签名称列表
  List<String> get tagNames {
    if (tags == null) return [];
    return tags!.map((t) {
      if (t is String) return t;
      if (t is Map<String, dynamic>) return t['name'] as String? ?? t['key'] as String? ?? '';
      return t.toString();
    }).toList();
  }
}

/// 应用详情简化模型（/apps/detail/node）
class AppDetailSimple {
  final int? id;

  AppDetailSimple({this.id});

  factory AppDetailSimple.fromJson(Map<String, dynamic> json) {
    return AppDetailSimple(id: json['id'] as int?);
  }

  Map<String, dynamic> toJson() => {'id': id};
}

/// 标签DTO模型
@JsonSerializable()
class TagDTO {
  final int id;
  final String key;
  final String name;

  TagDTO({
    required this.id,
    required this.key,
    required this.name,
  });

  factory TagDTO.fromJson(Map<String, dynamic> json) => _$TagDTOFromJson(json);
  Map<String, dynamic> toJson() => _$TagDTOToJson(this);
}

/// 应用安装创建请求模型
@JsonSerializable()
class AppInstallCreateRequest {
  final bool? advanced;
  final bool? allowPort;
  final int appDetailId;
  final String? containerName;
  final double? cpuQuota;
  final String? dockerCompose;
  final bool? editCompose;
  final bool? gpuConfig;
  final bool? hostMode;
  final double? memoryLimit;
  final String? memoryUnit;
  final String name;
  final Map<String, dynamic>? params;
  final bool? pullImage;
  final Map<String, String>? services;
  final String? taskID;
  final String? type;
  final String? webUI;

  AppInstallCreateRequest({
    this.advanced,
    this.allowPort,
    required this.appDetailId,
    this.containerName,
    this.cpuQuota,
    this.dockerCompose,
    this.editCompose,
    this.gpuConfig,
    this.hostMode,
    this.memoryLimit,
    this.memoryUnit,
    required this.name,
    this.params,
    this.pullImage,
    this.services,
    this.taskID,
    this.type,
    this.webUI,
  });

  factory AppInstallCreateRequest.fromJson(Map<String, dynamic> json) => _$AppInstallCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AppInstallCreateRequestToJson(this);
}

/// 应用安装模型
@JsonSerializable()
class AppInstall {
  final App app;
  final int appDetailId;
  final int appId;
  final String? containerName;
  final String createdAt;
  final String? description;
  final String? dockerCompose;
  final String? env;
  final int? httpPort;
  final int? httpsPort;
  final int id;
  final String? message;
  final String name;
  final String? param;
  final String? serviceName;
  final String status;
  final String updatedAt;
  final String version;
  final String? webUI;

  AppInstall({
    required this.app,
    required this.appDetailId,
    required this.appId,
    this.containerName,
    required this.createdAt,
    this.description,
    this.dockerCompose,
    this.env,
    this.httpPort,
    this.httpsPort,
    required this.id,
    this.message,
    required this.name,
    this.param,
    this.serviceName,
    required this.status,
    required this.updatedAt,
    required this.version,
    this.webUI,
  });

  factory AppInstall.fromJson(Map<String, dynamic> json) => _$AppInstallFromJson(json);
  Map<String, dynamic> toJson() => _$AppInstallToJson(this);
}

/// 应用模型
@JsonSerializable()
class App {
  final String architectures;
  final String createdAt;
  final bool crossVersionUpdate;
  final String description;
  final String? document;
  final String? github;
  final bool gpuSupport;
  final String icon;
  final int id;
  final String key;
  final int lastModified;
  final int limit;
  final int memoryRequired;
  final String name;
  final String? readMe;
  final int recommend;
  final String required;
  final double requiredPanelVersion;
  final String resource;
  final String? shortDescEn;
  final String? shortDescZh;
  final String status;
  final List<String> tags;
  final String type;
  final String updatedAt;
  final String? website;

  App({
    required this.architectures,
    required this.createdAt,
    required this.crossVersionUpdate,
    required this.description,
    this.document,
    this.github,
    required this.gpuSupport,
    required this.icon,
    required this.id,
    required this.key,
    required this.lastModified,
    required this.limit,
    required this.memoryRequired,
    required this.name,
    this.readMe,
    required this.recommend,
    required this.required,
    required this.requiredPanelVersion,
    required this.resource,
    this.shortDescEn,
    this.shortDescZh,
    required this.status,
    required this.tags,
    required this.type,
    required this.updatedAt,
    this.website,
  });

  factory App.fromJson(Map<String, dynamic> json) => _$AppFromJson(json);
  Map<String, dynamic> toJson() => _$AppToJson(this);
}

/// 应用安装信息请求模型
@JsonSerializable()
class AppInstalledInfoRequest {
  final String key;
  final String? name;

  AppInstalledInfoRequest({
    required this.key,
    this.name,
  });

  factory AppInstalledInfoRequest.fromJson(Map<String, dynamic> json) => _$AppInstalledInfoRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AppInstalledInfoRequestToJson(this);
}

/// 应用安装检查响应模型
@JsonSerializable()
class AppInstalledCheckResponse {
  final bool exist;
  final String? message;

  AppInstalledCheckResponse({
    required this.exist,
    this.message,
  });

  factory AppInstalledCheckResponse.fromJson(Map<String, dynamic> json) => _$AppInstalledCheckResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AppInstalledCheckResponseToJson(this);
}

/// 应用已安装检查请求模型
@JsonSerializable()
class AppInstalledCheckRequest {
  final String key;
  final String version;
  final String type;

  AppInstalledCheckRequest({
    required this.key,
    required this.version,
    required this.type,
  });

  factory AppInstalledCheckRequest.fromJson(Map<String, dynamic> json) {
    return AppInstalledCheckRequest(
      key: json['key'] as String,
      version: json['version'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'version': version,
    'type': type,
  };
}

/// 应用已安装忽略更新请求模型
@JsonSerializable()
class AppInstalledIgnoreUpgradeRequest {
  final int appInstallId;
  final String reason;
  final String scope;

  AppInstalledIgnoreUpgradeRequest({
    required this.appInstallId,
    required this.reason,
    this.scope = 'project',
  });

  factory AppInstalledIgnoreUpgradeRequest.fromJson(Map<String, dynamic> json) => _$AppInstalledIgnoreUpgradeRequestFromJson(json);
  Map<String, dynamic> toJson() => {
    'appID': appInstallId,
    'reason': reason,
    'scope': scope,
  };
}

/// 应用安装操作请求模型
@JsonSerializable()
class AppInstalledOperateRequest {
  final bool? backup;
  final int? backupId;
  final bool? deleteBackup;
  final bool? deleteDB;
  final bool? deleteImage;
  final int? detailId;
  final String? dockerCompose;
  final bool? forceDelete;
  final int installId;
  final String operate;
  final bool? pullImage;
  final String? taskID;

  AppInstalledOperateRequest({
    this.backup,
    this.backupId,
    this.deleteBackup,
    this.deleteDB,
    this.deleteImage,
    this.detailId,
    this.dockerCompose,
    this.forceDelete,
    required this.installId,
    required this.operate,
    this.pullImage,
    this.taskID,
  });

  factory AppInstalledOperateRequest.fromJson(Map<String, dynamic> json) => _$AppInstalledOperateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AppInstalledOperateRequestToJson(this);
}

/// 应用安装搜索请求模型
@JsonSerializable()
class AppInstalledSearchRequest {
  final bool? all;
  final String? name;
  final int page;
  final int pageSize;
  final bool? sync;
  final List<String>? tags;
  final String? type;
  final bool? unused;
  final bool? update;

  AppInstalledSearchRequest({
    this.all,
    this.name,
    required this.page,
    required this.pageSize,
    this.sync,
    this.tags,
    this.type,
    this.unused,
    this.update,
  });

  factory AppInstalledSearchRequest.fromJson(Map<String, dynamic> json) => _$AppInstalledSearchRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AppInstalledSearchRequestToJson(this);
}

/// 应用服务响应模型
@JsonSerializable()
class AppServiceResponse {
  final dynamic config;
  final String from;
  final String label;
  final String status;
  final String value;

  AppServiceResponse({
    required this.config,
    required this.from,
    required this.label,
    required this.status,
    required this.value,
  });

  factory AppServiceResponse.fromJson(Map<String, dynamic> json) => _$AppServiceResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AppServiceResponseToJson(this);
}

/// 应用商店配置响应模型
class AppstoreConfigResponse {
  final String? uninstallDeleteBackup;
  final String? uninstallDeleteImage;
  final String? upgradeBackup;

  AppstoreConfigResponse({
    this.uninstallDeleteBackup,
    this.uninstallDeleteImage,
    this.upgradeBackup,
  });

  factory AppstoreConfigResponse.fromJson(Map<String, dynamic> json) {
    return AppstoreConfigResponse(
      uninstallDeleteBackup: json['uninstallDeleteBackup'] as String?,
      uninstallDeleteImage: json['uninstallDeleteImage'] as String?,
      upgradeBackup: json['upgradeBackup'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uninstallDeleteBackup': uninstallDeleteBackup,
      'uninstallDeleteImage': uninstallDeleteImage,
      'upgradeBackup': upgradeBackup,
    };
  }
}

/// 应用商店更新请求模型
class AppstoreUpdateRequest {
  final String scope;
  final String status;

  AppstoreUpdateRequest({
    required this.scope,
    required this.status,
  });

  factory AppstoreUpdateRequest.fromJson(Map<String, dynamic> json) {
    return AppstoreUpdateRequest(
      scope: json['scope'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scope': scope,
      'status': status,
    };
  }
}

/// 应用安装信息模型
class AppInstallInfo {
  final int? id;
  final String? name; // install name (e.g. mysql-1)
  final String? appName; // app type name (e.g. MySQL)
  final String? appKey; // app key (e.g. mysql)
  final String? version; // version
  final String? status;
  final String? container; // container name or ID
  final String? appType; // type
  final Map<String, dynamic>? env; // env variables
  final String? icon;
  final String? description;
  final String? createdAt;
  final int? appId;
  final int? appDetailId;
  final String? message;
  final int? httpPort;
  final int? httpsPort;
  final String? path;
  final bool? canUpdate;
  final int? ready;
  final int? total;
  final String? appStatus;
  final String? dockerCompose;
  final String? webUI;
  final bool? favorite;
  final bool? isEdit;
  final bool? linkDB;
  final String? serviceName;

  AppInstallInfo({
    this.id,
    this.name,
    this.appName,
    this.appKey,
    this.version,
    this.status,
    this.container,
    this.appType,
    this.env,
    this.icon,
    this.description,
    this.createdAt,
    this.appId,
    this.appDetailId,
    this.message,
    this.httpPort,
    this.httpsPort,
    this.path,
    this.canUpdate,
    this.ready,
    this.total,
    this.appStatus,
    this.dockerCompose,
    this.webUI,
    this.favorite,
    this.isEdit,
    this.linkDB,
    this.serviceName,
  });

  factory AppInstallInfo.fromJson(Map<String, dynamic> json) {
    return AppInstallInfo(
      id: json['id'] as int?,
      name: json['name'] as String?,
      appName: json['appName'] as String?,
      appKey: json['appKey'] as String? ?? json['key'] as String?,
      version: json['version'] as String?,
      status: json['status'] as String?,
      container: json['container'] as String?,
      appType: json['appType'] as String? ?? json['type'] as String?,
      env: json['env'] is Map ? json['env'] as Map<String, dynamic>? : null,
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      createdAt: json['createdAt'] as String?,
      appId: json['appId'] as int?,
      appDetailId: json['appDetailId'] as int?,
      message: json['message'] as String?,
      httpPort: json['httpPort'] as int?,
      httpsPort: json['httpsPort'] as int?,
      path: json['path'] as String?,
      canUpdate: json['canUpdate'] as bool?,
      ready: json['ready'] as int?,
      total: json['total'] as int?,
      appStatus: json['appStatus'] as String?,
      dockerCompose: json['dockerCompose'] as String?,
      webUI: json['webUI'] as String?,
      favorite: json['favorite'] as bool?,
      isEdit: json['isEdit'] as bool?,
      linkDB: json['linkDB'] as bool?,
      serviceName: json['serviceName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'appName': appName,
    'appKey': appKey,
    'version': version,
    'status': status,
    'container': container,
    'appType': appType,
    'env': env,
    'icon': icon,
    'description': description,
    'createdAt': createdAt,
    'appId': appId,
    'appDetailId': appDetailId,
    'message': message,
    'httpPort': httpPort,
    'httpsPort': httpsPort,
    'path': path,
    'canUpdate': canUpdate,
    'ready': ready,
    'total': total,
    'appStatus': appStatus,
    'dockerCompose': dockerCompose,
    'webUI': webUI,
    'favorite': favorite,
    'isEdit': isEdit,
    'linkDB': linkDB,
    'serviceName': serviceName,
  };
}

/// 应用列表响应模型
@JsonSerializable()
class AppListResponse {
  final List<AppInstallInfo> apps;
  final int total;

  AppListResponse({
    required this.apps,
    required this.total,
  });

  factory AppListResponse.fromJson(Map<String, dynamic> json) => _$AppListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AppListResponseToJson(this);
}

/// 应用更新响应模型
@JsonSerializable()
class AppUpdateResponse {
  final List<AppInstallInfo> updates;
  final int total;

  AppUpdateResponse({
    required this.updates,
    required this.total,
  });

  factory AppUpdateResponse.fromJson(Map<String, dynamic> json) => _$AppUpdateResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AppUpdateResponseToJson(this);
}

/// 应用版本模型
@JsonSerializable()
class AppVersion {
  final String version;
  final String? description;
  final String? releaseDate;
  final bool? isPrerelease;

  AppVersion({
    required this.version,
    this.description,
    this.releaseDate,
    this.isPrerelease,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) => _$AppVersionFromJson(json);
  Map<String, dynamic> toJson() => _$AppVersionToJson(this);
}

/// 分页结果模型
@JsonSerializable(
  genericArgumentFactories: true,
)
class PageResult<T> {
  final List<T> items;
  final int total;

  PageResult({
    required this.items,
    required this.total,
  });

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return _$PageResultFromJson(json, fromJsonT);
  }

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) {
    return _$PageResultToJson(this, toJsonT);
  }
}

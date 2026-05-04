// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSearchRequest _$AppSearchRequestFromJson(Map<String, dynamic> json) =>
    AppSearchRequest(
      page: (json['page'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
      name: json['name'] as String?,
      recommend: json['recommend'] as bool?,
      resource: json['resource'] as String?,
      showCurrentArch: json['showCurrentArch'] as bool?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      type: json['type'] as String?,
    );

Map<String, dynamic> _$AppSearchRequestToJson(AppSearchRequest instance) =>
    <String, dynamic>{
      'page': instance.page,
      'pageSize': instance.pageSize,
      'name': instance.name,
      'recommend': instance.recommend,
      'resource': instance.resource,
      'showCurrentArch': instance.showCurrentArch,
      'tags': instance.tags,
      'type': instance.type,
    };

AppSearchResponse _$AppSearchResponseFromJson(Map<String, dynamic> json) =>
    AppSearchResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => AppItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$AppSearchResponseToJson(AppSearchResponse instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
    };

AppItem _$AppItemFromJson(Map<String, dynamic> json) => AppItem(
      description: json['description'] as String?,
      github: json['github'] as String?,
      gpuSupport: json['gpuSupport'] as bool?,
      icon: json['icon'] as String?,
      id: (json['id'] as num?)?.toInt(),
      installed: json['installed'] as bool?,
      key: json['key'] as String?,
      limit: (json['limit'] as num?)?.toInt(),
      name: json['name'] as String?,
      readMe: json['readMe'] as String?,
      recommend: (json['recommend'] as num?)?.toInt(),
      resource: json['resource'] as String?,
      status: json['status'] as String?,
      tags: json['tags'] as List<dynamic>?,
      type: json['type'] as String?,
      versions: (json['versions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      website: json['website'] as String?,
      params: json['params'] == null
          ? null
          : AppParams.fromJson(json['params'] as Map<String, dynamic>),
      dockerCompose: json['dockerCompose'] as String?,
      hostMode: json['hostMode'] as bool?,
      memoryRequired: (json['memoryRequired'] as num?)?.toInt(),
      architectures: json['architectures'] as String?,
    );

Map<String, dynamic> _$AppItemToJson(AppItem instance) => <String, dynamic>{
      'description': instance.description,
      'github': instance.github,
      'gpuSupport': instance.gpuSupport,
      'icon': instance.icon,
      'id': instance.id,
      'installed': instance.installed,
      'key': instance.key,
      'limit': instance.limit,
      'name': instance.name,
      'readMe': instance.readMe,
      'recommend': instance.recommend,
      'resource': instance.resource,
      'status': instance.status,
      'tags': instance.tags,
      'type': instance.type,
      'versions': instance.versions,
      'website': instance.website,
      'params': instance.params,
      'dockerCompose': instance.dockerCompose,
      'hostMode': instance.hostMode,
      'memoryRequired': instance.memoryRequired,
      'architectures': instance.architectures,
    };

AppParams _$AppParamsFromJson(Map<String, dynamic> json) => AppParams(
      formFields: (json['formFields'] as List<dynamic>)
          .map((e) => AppFormField.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AppParamsToJson(AppParams instance) => <String, dynamic>{
      'formFields': instance.formFields,
    };

AppFormField _$AppFormFieldFromJson(Map<String, dynamic> json) => AppFormField(
      type: json['type'] as String,
      labelZh: json['labelZh'] as String,
      labelEn: json['labelEn'] as String,
      required: json['required'] as bool,
      defaultValue: json['default'],
      envKey: json['envKey'] as String,
      key: json['key'] as String?,
      values: json['values'] as List<dynamic>?,
      child: json['child'] == null
          ? null
          : AppFormFieldChild.fromJson(json['child'] as Map<String, dynamic>),
      params: json['params'] as List<dynamic>?,
      multiple: json['multiple'] as bool?,
      allowCreate: json['allowCreate'] as bool?,
      label: (json['label'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      description: (json['description'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      random: json['random'] as bool?,
      rule: json['rule'] as String?,
      disabled: json['disabled'] as bool?,
    );

Map<String, dynamic> _$AppFormFieldToJson(AppFormField instance) =>
    <String, dynamic>{
      'type': instance.type,
      'labelZh': instance.labelZh,
      'labelEn': instance.labelEn,
      'required': instance.required,
      'default': instance.defaultValue,
      'envKey': instance.envKey,
      'key': instance.key,
      'values': instance.values,
      'child': instance.child,
      'params': instance.params,
      'multiple': instance.multiple,
      'allowCreate': instance.allowCreate,
      'label': instance.label,
      'description': instance.description,
      'random': instance.random,
      'rule': instance.rule,
      'disabled': instance.disabled,
    };

AppFormFieldChild _$AppFormFieldChildFromJson(Map<String, dynamic> json) =>
    AppFormFieldChild(
      type: json['type'] as String,
      labelZh: json['labelZh'] as String,
      labelEn: json['labelEn'] as String,
      required: json['required'] as bool,
      envKey: json['envKey'] as String,
      services: json['services'] as List<dynamic>?,
    );

Map<String, dynamic> _$AppFormFieldChildToJson(AppFormFieldChild instance) =>
    <String, dynamic>{
      'type': instance.type,
      'labelZh': instance.labelZh,
      'labelEn': instance.labelEn,
      'required': instance.required,
      'envKey': instance.envKey,
      'services': instance.services,
    };

TagDTO _$TagDTOFromJson(Map<String, dynamic> json) => TagDTO(
      id: (json['id'] as num).toInt(),
      key: json['key'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$TagDTOToJson(TagDTO instance) => <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'name': instance.name,
    };

AppInstallCreateRequest _$AppInstallCreateRequestFromJson(
        Map<String, dynamic> json) =>
    AppInstallCreateRequest(
      advanced: json['advanced'] as bool?,
      allowPort: json['allowPort'] as bool?,
      appDetailId: (json['appDetailId'] as num).toInt(),
      containerName: json['containerName'] as String?,
      cpuQuota: (json['cpuQuota'] as num?)?.toDouble(),
      dockerCompose: json['dockerCompose'] as String?,
      editCompose: json['editCompose'] as bool?,
      gpuConfig: json['gpuConfig'] as bool?,
      hostMode: json['hostMode'] as bool?,
      memoryLimit: (json['memoryLimit'] as num?)?.toDouble(),
      memoryUnit: json['memoryUnit'] as String?,
      name: json['name'] as String,
      params: json['params'] as Map<String, dynamic>?,
      pullImage: json['pullImage'] as bool?,
      services: (json['services'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      taskID: json['taskID'] as String?,
      type: json['type'] as String?,
      webUI: json['webUI'] as String?,
    );

Map<String, dynamic> _$AppInstallCreateRequestToJson(
        AppInstallCreateRequest instance) =>
    <String, dynamic>{
      'advanced': instance.advanced,
      'allowPort': instance.allowPort,
      'appDetailId': instance.appDetailId,
      'containerName': instance.containerName,
      'cpuQuota': instance.cpuQuota,
      'dockerCompose': instance.dockerCompose,
      'editCompose': instance.editCompose,
      'gpuConfig': instance.gpuConfig,
      'hostMode': instance.hostMode,
      'memoryLimit': instance.memoryLimit,
      'memoryUnit': instance.memoryUnit,
      'name': instance.name,
      'params': instance.params,
      'pullImage': instance.pullImage,
      'services': instance.services,
      'taskID': instance.taskID,
      'type': instance.type,
      'webUI': instance.webUI,
    };

AppInstall _$AppInstallFromJson(Map<String, dynamic> json) => AppInstall(
      app: App.fromJson(json['app'] as Map<String, dynamic>),
      appDetailId: (json['appDetailId'] as num).toInt(),
      appId: (json['appId'] as num).toInt(),
      containerName: json['containerName'] as String?,
      createdAt: json['createdAt'] as String,
      description: json['description'] as String?,
      dockerCompose: json['dockerCompose'] as String?,
      env: json['env'] as String?,
      httpPort: (json['httpPort'] as num?)?.toInt(),
      httpsPort: (json['httpsPort'] as num?)?.toInt(),
      id: (json['id'] as num).toInt(),
      message: json['message'] as String?,
      name: json['name'] as String,
      param: json['param'] as String?,
      serviceName: json['serviceName'] as String?,
      status: json['status'] as String,
      updatedAt: json['updatedAt'] as String,
      version: json['version'] as String,
      webUI: json['webUI'] as String?,
    );

Map<String, dynamic> _$AppInstallToJson(AppInstall instance) =>
    <String, dynamic>{
      'app': instance.app,
      'appDetailId': instance.appDetailId,
      'appId': instance.appId,
      'containerName': instance.containerName,
      'createdAt': instance.createdAt,
      'description': instance.description,
      'dockerCompose': instance.dockerCompose,
      'env': instance.env,
      'httpPort': instance.httpPort,
      'httpsPort': instance.httpsPort,
      'id': instance.id,
      'message': instance.message,
      'name': instance.name,
      'param': instance.param,
      'serviceName': instance.serviceName,
      'status': instance.status,
      'updatedAt': instance.updatedAt,
      'version': instance.version,
      'webUI': instance.webUI,
    };

App _$AppFromJson(Map<String, dynamic> json) => App(
      architectures: json['architectures'] as String,
      createdAt: json['createdAt'] as String,
      crossVersionUpdate: json['crossVersionUpdate'] as bool,
      description: json['description'] as String,
      document: json['document'] as String?,
      github: json['github'] as String?,
      gpuSupport: json['gpuSupport'] as bool,
      icon: json['icon'] as String,
      id: (json['id'] as num).toInt(),
      key: json['key'] as String,
      lastModified: (json['lastModified'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      memoryRequired: (json['memoryRequired'] as num).toInt(),
      name: json['name'] as String,
      readMe: json['readMe'] as String?,
      recommend: (json['recommend'] as num).toInt(),
      required: json['required'] as String,
      requiredPanelVersion: (json['requiredPanelVersion'] as num).toDouble(),
      resource: json['resource'] as String,
      shortDescEn: json['shortDescEn'] as String?,
      shortDescZh: json['shortDescZh'] as String?,
      status: json['status'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      type: json['type'] as String,
      updatedAt: json['updatedAt'] as String,
      website: json['website'] as String?,
    );

Map<String, dynamic> _$AppToJson(App instance) => <String, dynamic>{
      'architectures': instance.architectures,
      'createdAt': instance.createdAt,
      'crossVersionUpdate': instance.crossVersionUpdate,
      'description': instance.description,
      'document': instance.document,
      'github': instance.github,
      'gpuSupport': instance.gpuSupport,
      'icon': instance.icon,
      'id': instance.id,
      'key': instance.key,
      'lastModified': instance.lastModified,
      'limit': instance.limit,
      'memoryRequired': instance.memoryRequired,
      'name': instance.name,
      'readMe': instance.readMe,
      'recommend': instance.recommend,
      'required': instance.required,
      'requiredPanelVersion': instance.requiredPanelVersion,
      'resource': instance.resource,
      'shortDescEn': instance.shortDescEn,
      'shortDescZh': instance.shortDescZh,
      'status': instance.status,
      'tags': instance.tags,
      'type': instance.type,
      'updatedAt': instance.updatedAt,
      'website': instance.website,
    };

AppInstalledInfoRequest _$AppInstalledInfoRequestFromJson(
        Map<String, dynamic> json) =>
    AppInstalledInfoRequest(
      key: json['key'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$AppInstalledInfoRequestToJson(
        AppInstalledInfoRequest instance) =>
    <String, dynamic>{
      'key': instance.key,
      'name': instance.name,
    };

AppInstalledCheckResponse _$AppInstalledCheckResponseFromJson(
        Map<String, dynamic> json) =>
    AppInstalledCheckResponse(
      exist: json['exist'] as bool,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$AppInstalledCheckResponseToJson(
        AppInstalledCheckResponse instance) =>
    <String, dynamic>{
      'exist': instance.exist,
      'message': instance.message,
    };

AppInstalledCheckRequest _$AppInstalledCheckRequestFromJson(
        Map<String, dynamic> json) =>
    AppInstalledCheckRequest(
      key: json['key'] as String,
      version: json['version'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$AppInstalledCheckRequestToJson(
        AppInstalledCheckRequest instance) =>
    <String, dynamic>{
      'key': instance.key,
      'version': instance.version,
      'type': instance.type,
    };

AppInstalledIgnoreUpgradeRequest _$AppInstalledIgnoreUpgradeRequestFromJson(
        Map<String, dynamic> json) =>
    AppInstalledIgnoreUpgradeRequest(
      appInstallId: (json['appInstallId'] as num).toInt(),
      reason: json['reason'] as String,
      scope: json['scope'] as String? ?? AppIgnoreUpgradeScope.version,
    );

Map<String, dynamic> _$AppInstalledIgnoreUpgradeRequestToJson(
        AppInstalledIgnoreUpgradeRequest instance) =>
    <String, dynamic>{
      'appInstallId': instance.appInstallId,
      'reason': instance.reason,
      'scope': instance.scope,
    };

AppInstalledOperateRequest _$AppInstalledOperateRequestFromJson(
        Map<String, dynamic> json) =>
    AppInstalledOperateRequest(
      backup: json['backup'] as bool?,
      backupId: (json['backupId'] as num?)?.toInt(),
      deleteBackup: json['deleteBackup'] as bool?,
      deleteDB: json['deleteDB'] as bool?,
      deleteImage: json['deleteImage'] as bool?,
      detailId: (json['detailId'] as num?)?.toInt(),
      dockerCompose: json['dockerCompose'] as String?,
      forceDelete: json['forceDelete'] as bool?,
      installId: (json['installId'] as num).toInt(),
      operate: json['operate'] as String,
      pullImage: json['pullImage'] as bool?,
      taskID: json['taskID'] as String?,
    );

Map<String, dynamic> _$AppInstalledOperateRequestToJson(
        AppInstalledOperateRequest instance) =>
    <String, dynamic>{
      'backup': instance.backup,
      'backupId': instance.backupId,
      'deleteBackup': instance.deleteBackup,
      'deleteDB': instance.deleteDB,
      'deleteImage': instance.deleteImage,
      'detailId': instance.detailId,
      'dockerCompose': instance.dockerCompose,
      'forceDelete': instance.forceDelete,
      'installId': instance.installId,
      'operate': instance.operate,
      'pullImage': instance.pullImage,
      'taskID': instance.taskID,
    };

AppInstalledSearchRequest _$AppInstalledSearchRequestFromJson(
        Map<String, dynamic> json) =>
    AppInstalledSearchRequest(
      all: json['all'] as bool?,
      name: json['name'] as String?,
      page: (json['page'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
      sync: json['sync'] as bool?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      type: json['type'] as String?,
      unused: json['unused'] as bool?,
      update: json['update'] as bool?,
    );

Map<String, dynamic> _$AppInstalledSearchRequestToJson(
        AppInstalledSearchRequest instance) =>
    <String, dynamic>{
      'all': instance.all,
      'name': instance.name,
      'page': instance.page,
      'pageSize': instance.pageSize,
      'sync': instance.sync,
      'tags': instance.tags,
      'type': instance.type,
      'unused': instance.unused,
      'update': instance.update,
    };

AppServiceResponse _$AppServiceResponseFromJson(Map<String, dynamic> json) =>
    AppServiceResponse(
      config: json['config'],
      from: json['from'] as String,
      label: json['label'] as String,
      status: json['status'] as String,
      value: json['value'] as String,
    );

Map<String, dynamic> _$AppServiceResponseToJson(AppServiceResponse instance) =>
    <String, dynamic>{
      'config': instance.config,
      'from': instance.from,
      'label': instance.label,
      'status': instance.status,
      'value': instance.value,
    };

AppListResponse _$AppListResponseFromJson(Map<String, dynamic> json) =>
    AppListResponse(
      apps: (json['apps'] as List<dynamic>)
          .map((e) => AppInstallInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$AppListResponseToJson(AppListResponse instance) =>
    <String, dynamic>{
      'apps': instance.apps,
      'total': instance.total,
    };

AppUpdateResponse _$AppUpdateResponseFromJson(Map<String, dynamic> json) =>
    AppUpdateResponse(
      updates: (json['updates'] as List<dynamic>)
          .map((e) => AppInstallInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$AppUpdateResponseToJson(AppUpdateResponse instance) =>
    <String, dynamic>{
      'updates': instance.updates,
      'total': instance.total,
    };

AppVersion _$AppVersionFromJson(Map<String, dynamic> json) => AppVersion(
      version: json['version'] as String,
      description: json['description'] as String?,
      releaseDate: json['releaseDate'] as String?,
      isPrerelease: json['isPrerelease'] as bool?,
    );

Map<String, dynamic> _$AppVersionToJson(AppVersion instance) =>
    <String, dynamic>{
      'version': instance.version,
      'description': instance.description,
      'releaseDate': instance.releaseDate,
      'isPrerelease': instance.isPrerelease,
    };

PageResult<T> _$PageResultFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    PageResult<T>(
      items: (json['items'] as List<dynamic>?)?.map(fromJsonT).toList() ?? [],
      total: (json['total'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PageResultToJson<T>(
  PageResult<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'items': instance.items.map(toJsonT).toList(),
      'total': instance.total,
    };

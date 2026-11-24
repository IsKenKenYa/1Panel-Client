// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_downloader_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeaturedModel _$FeaturedModelFromJson(Map<String, dynamic> json) =>
    FeaturedModel(
      key: json['key'] as String,
      repoID: json['repoID'] as String,
      family: json['family'] as String,
      architecture: json['architecture'] as String,
      backboneParams: json['backboneParams'] as String,
      activeParams: json['activeParams'] as String,
      engram: json['engram'] as String,
      weightGB: (json['weightGB'] as num).toDouble(),
      sources: (json['sources'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      sourceModelIds: Map<String, String>.from(json['sourceModelIds'] as Map),
      description: Map<String, String>.from(json['description'] as Map),
      sort: (json['sort'] as num).toInt(),
    );

Map<String, dynamic> _$FeaturedModelToJson(FeaturedModel instance) =>
    <String, dynamic>{
      'key': instance.key,
      'repoID': instance.repoID,
      'family': instance.family,
      'architecture': instance.architecture,
      'backboneParams': instance.backboneParams,
      'activeParams': instance.activeParams,
      'engram': instance.engram,
      'weightGB': instance.weightGB,
      'sources': instance.sources,
      'sourceModelIds': instance.sourceModelIds,
      'description': instance.description,
      'sort': instance.sort,
    };

FeaturedModelPage _$FeaturedModelPageFromJson(Map<String, dynamic> json) =>
    FeaturedModelPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => FeaturedModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      families: (json['families'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$FeaturedModelPageToJson(FeaturedModelPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'families': instance.families,
    };

FeaturedModelSearch _$FeaturedModelSearchFromJson(Map<String, dynamic> json) =>
    FeaturedModelSearch(
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      family: json['family'] as String?,
      info: json['info'] as String?,
    );

Map<String, dynamic> _$FeaturedModelSearchToJson(
  FeaturedModelSearch instance,
) => <String, dynamic>{
  'page': instance.page,
  'pageSize': instance.pageSize,
  'family': instance.family,
  'info': instance.info,
};

ModelItem _$ModelItemFromJson(Map<String, dynamic> json) => ModelItem(
  repoID: json['repoID'] as String,
  name: json['name'] as String,
  downloads: (json['downloads'] as num).toInt(),
  likes: (json['likes'] as num).toInt(),
  size: (json['size'] as num).toInt(),
  sizeFormatted: json['sizeFormatted'] as String,
);

Map<String, dynamic> _$ModelItemToJson(ModelItem instance) => <String, dynamic>{
  'repoID': instance.repoID,
  'name': instance.name,
  'downloads': instance.downloads,
  'likes': instance.likes,
  'size': instance.size,
  'sizeFormatted': instance.sizeFormatted,
};

ModelSearch _$ModelSearchFromJson(Map<String, dynamic> json) => ModelSearch(
  page: (json['page'] as num?)?.toInt() ?? 1,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
  query: json['query'] as String?,
  sort: json['sort'] as String?,
  limit: (json['limit'] as num?)?.toInt(),
);

Map<String, dynamic> _$ModelSearchToJson(ModelSearch instance) =>
    <String, dynamic>{
      'page': instance.page,
      'pageSize': instance.pageSize,
      'query': instance.query,
      'sort': instance.sort,
      'limit': instance.limit,
    };

ModelFile _$ModelFileFromJson(Map<String, dynamic> json) => ModelFile(
  name: json['name'] as String,
  size: (json['size'] as num).toInt(),
  sizeFormatted: json['sizeFormatted'] as String,
);

Map<String, dynamic> _$ModelFileToJson(ModelFile instance) => <String, dynamic>{
  'name': instance.name,
  'size': instance.size,
  'sizeFormatted': instance.sizeFormatted,
};

ModelInfo _$ModelInfoFromJson(Map<String, dynamic> json) => ModelInfo(
  repoID: json['repoID'] as String,
  name: json['name'] as String,
  downloads: (json['downloads'] as num).toInt(),
  likes: (json['likes'] as num).toInt(),
  size: (json['size'] as num).toInt(),
  sizeFormatted: json['sizeFormatted'] as String,
  modelCard: json['modelCard'] as String,
  files: (json['files'] as List<dynamic>)
      .map((e) => ModelFile.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ModelInfoToJson(ModelInfo instance) => <String, dynamic>{
  'repoID': instance.repoID,
  'name': instance.name,
  'downloads': instance.downloads,
  'likes': instance.likes,
  'size': instance.size,
  'sizeFormatted': instance.sizeFormatted,
  'modelCard': instance.modelCard,
  'files': instance.files,
};

ModelInfoReq _$ModelInfoReqFromJson(Map<String, dynamic> json) => ModelInfoReq(
  repoID: json['repoID'] as String,
  revision: json['revision'] as String?,
);

Map<String, dynamic> _$ModelInfoReqToJson(ModelInfoReq instance) =>
    <String, dynamic>{'repoID': instance.repoID, 'revision': instance.revision};

ModelDownload _$ModelDownloadFromJson(Map<String, dynamic> json) =>
    ModelDownload(
      repoID: json['repoID'] as String,
      revision: json['revision'] as String?,
      downloadType: json['downloadType'] as String?,
    );

Map<String, dynamic> _$ModelDownloadToJson(ModelDownload instance) =>
    <String, dynamic>{
      'repoID': instance.repoID,
      'revision': instance.revision,
      'downloadType': instance.downloadType,
    };

LocalModelItem _$LocalModelItemFromJson(Map<String, dynamic> json) =>
    LocalModelItem(
      name: json['name'] as String,
      repoID: json['repoID'] as String,
      revision: json['revision'] as String,
      downloadType: json['downloadType'] as String,
      source: json['source'] as String,
      path: json['path'] as String,
      size: (json['size'] as num).toInt(),
      sizeFormatted: json['sizeFormatted'] as String,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$LocalModelItemToJson(LocalModelItem instance) =>
    <String, dynamic>{
      'name': instance.name,
      'repoID': instance.repoID,
      'revision': instance.revision,
      'downloadType': instance.downloadType,
      'source': instance.source,
      'path': instance.path,
      'size': instance.size,
      'sizeFormatted': instance.sizeFormatted,
      'createdAt': instance.createdAt,
    };

LocalModelSearch _$LocalModelSearchFromJson(Map<String, dynamic> json) =>
    LocalModelSearch(
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      info: json['info'] as String?,
      downloadType: json['downloadType'] as String?,
    );

Map<String, dynamic> _$LocalModelSearchToJson(LocalModelSearch instance) =>
    <String, dynamic>{
      'page': instance.page,
      'pageSize': instance.pageSize,
      'info': instance.info,
      'downloadType': instance.downloadType,
    };

LocalModelDelete _$LocalModelDeleteFromJson(Map<String, dynamic> json) =>
    LocalModelDelete(
      name: json['name'] as String,
      downloadType: json['downloadType'] as String?,
      withFile: json['withFile'] as bool?,
    );

Map<String, dynamic> _$LocalModelDeleteToJson(LocalModelDelete instance) =>
    <String, dynamic>{
      'name': instance.name,
      'downloadType': instance.downloadType,
      'withFile': instance.withFile,
    };

ModelDownloadTaskItem _$ModelDownloadTaskItemFromJson(
  Map<String, dynamic> json,
) => ModelDownloadTaskItem(
  id: (json['id'] as num).toInt(),
  modelName: json['modelName'] as String,
  repoID: json['repoID'] as String,
  revision: json['revision'] as String,
  downloadType: json['downloadType'] as String,
  source: json['source'] as String,
  status: json['status'] as String,
  progress: (json['progress'] as num).toDouble(),
  downloadedSize: (json['downloadedSize'] as num).toInt(),
  totalSize: (json['totalSize'] as num).toInt(),
  targetDir: json['targetDir'] as String,
  errorMessage: json['errorMessage'] as String?,
  createdAt: json['createdAt'] as String?,
  startedAt: json['startedAt'] as String?,
  completedAt: json['completedAt'] as String?,
  canCancel: json['canCancel'] as bool,
  canRetry: json['canRetry'] as bool,
  canRemoveRecord: json['canRemoveRecord'] as bool,
  localModel: json['localModel'] == null
      ? null
      : LocalModelItem.fromJson(json['localModel'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ModelDownloadTaskItemToJson(
  ModelDownloadTaskItem instance,
) => <String, dynamic>{
  'id': instance.id,
  'modelName': instance.modelName,
  'repoID': instance.repoID,
  'revision': instance.revision,
  'downloadType': instance.downloadType,
  'source': instance.source,
  'status': instance.status,
  'progress': instance.progress,
  'downloadedSize': instance.downloadedSize,
  'totalSize': instance.totalSize,
  'targetDir': instance.targetDir,
  'errorMessage': instance.errorMessage,
  'createdAt': instance.createdAt,
  'startedAt': instance.startedAt,
  'completedAt': instance.completedAt,
  'canCancel': instance.canCancel,
  'canRetry': instance.canRetry,
  'canRemoveRecord': instance.canRemoveRecord,
  'localModel': instance.localModel,
};

ModelDownloadTaskSearch _$ModelDownloadTaskSearchFromJson(
  Map<String, dynamic> json,
) => ModelDownloadTaskSearch(
  page: (json['page'] as num?)?.toInt() ?? 1,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
  info: json['info'] as String?,
  status: json['status'] as String?,
  downloadType: json['downloadType'] as String?,
  includeLocal: json['includeLocal'] as bool?,
);

Map<String, dynamic> _$ModelDownloadTaskSearchToJson(
  ModelDownloadTaskSearch instance,
) => <String, dynamic>{
  'page': instance.page,
  'pageSize': instance.pageSize,
  'info': instance.info,
  'status': instance.status,
  'downloadType': instance.downloadType,
  'includeLocal': instance.includeLocal,
};

ModelDownloadTaskOperate _$ModelDownloadTaskOperateFromJson(
  Map<String, dynamic> json,
) => ModelDownloadTaskOperate(
  id: (json['id'] as num).toInt(),
  withFile: json['withFile'] as bool?,
);

Map<String, dynamic> _$ModelDownloadTaskOperateToJson(
  ModelDownloadTaskOperate instance,
) => <String, dynamic>{'id': instance.id, 'withFile': instance.withFile};

ModelDownloaderSyncSetting _$ModelDownloaderSyncSettingFromJson(
  Map<String, dynamic> json,
) => ModelDownloaderSyncSetting(value: json['value'] as String);

Map<String, dynamic> _$ModelDownloaderSyncSettingToJson(
  ModelDownloaderSyncSetting instance,
) => <String, dynamic>{'value': instance.value};

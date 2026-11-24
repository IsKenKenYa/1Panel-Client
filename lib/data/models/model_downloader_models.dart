import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model_downloader_models.g.dart';

/// 推荐模型条目（dto.FeaturedModel）。
///
/// sources / sourceModelIds / description 在上游为值类型集合，服务端
/// 始终返回这三个键（可能为空集合）。
@JsonSerializable()
class FeaturedModel extends Equatable {
  final String key;
  final String repoID;
  final String family;
  final String architecture;
  final String backboneParams;
  final String activeParams;
  final String engram;
  final double weightGB;
  final List<String> sources;
  final Map<String, String> sourceModelIds;
  final Map<String, String> description;
  final int sort;

  const FeaturedModel({
    required this.key,
    required this.repoID,
    required this.family,
    required this.architecture,
    required this.backboneParams,
    required this.activeParams,
    required this.engram,
    required this.weightGB,
    required this.sources,
    required this.sourceModelIds,
    required this.description,
    required this.sort,
  });

  factory FeaturedModel.fromJson(Map<String, dynamic> json) =>
      _$FeaturedModelFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturedModelToJson(this);

  @override
  List<Object?> get props => <Object?>[
        key,
        repoID,
        family,
        architecture,
        backboneParams,
        activeParams,
        engram,
        weightGB,
        sources,
        sourceModelIds,
        description,
        sort,
      ];
}

/// 推荐模型分页结果（dto.FeaturedModelPage）。
@JsonSerializable()
class FeaturedModelPage extends Equatable {
  final List<FeaturedModel> items;
  final int total;
  final List<String> families;

  const FeaturedModelPage({
    required this.items,
    required this.total,
    required this.families,
  });

  factory FeaturedModelPage.fromJson(Map<String, dynamic> json) =>
      _$FeaturedModelPageFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturedModelPageToJson(this);

  @override
  List<Object?> get props => <Object?>[items, total, families];
}

/// 推荐模型分页请求（dto.FeaturedModelSearch）。
@JsonSerializable()
class FeaturedModelSearch extends Equatable {
  final int page;
  final int pageSize;
  final String? family;
  final String? info;

  const FeaturedModelSearch({
    this.page = 1,
    this.pageSize = 20,
    this.family,
    this.info,
  });

  factory FeaturedModelSearch.fromJson(Map<String, dynamic> json) =>
      _$FeaturedModelSearchFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturedModelSearchToJson(this);

  @override
  List<Object?> get props => <Object?>[page, pageSize, family, info];
}

/// 模型市场条目（dto.ModelItem；HF/ModelScope 搜索结果）。
@JsonSerializable()
class ModelItem extends Equatable {
  final String repoID;
  final String name;
  final int downloads;
  final int likes;
  final int size;
  final String sizeFormatted;

  const ModelItem({
    required this.repoID,
    required this.name,
    required this.downloads,
    required this.likes,
    required this.size,
    required this.sizeFormatted,
  });

  factory ModelItem.fromJson(Map<String, dynamic> json) =>
      _$ModelItemFromJson(json);

  Map<String, dynamic> toJson() => _$ModelItemToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[repoID, name, downloads, likes, size, sizeFormatted];
}

/// HF/ModelScope 模型搜索请求（dto.ModelSearch）。
///
/// sort 取值：trending / downloads / updated / created / likes /
/// most_params / least_params；pageSize 上限 100。
@JsonSerializable()
class ModelSearch extends Equatable {
  final int page;
  final int pageSize;
  final String? query;
  final String? sort;
  final int? limit;

  const ModelSearch({
    this.page = 1,
    this.pageSize = 20,
    this.query,
    this.sort,
    this.limit,
  });

  factory ModelSearch.fromJson(Map<String, dynamic> json) =>
      _$ModelSearchFromJson(json);

  Map<String, dynamic> toJson() => _$ModelSearchToJson(this);

  @override
  List<Object?> get props => <Object?>[page, pageSize, query, sort, limit];
}

/// 模型文件（dto.ModelFile）。
@JsonSerializable()
class ModelFile extends Equatable {
  final String name;
  final int size;
  final String sizeFormatted;

  const ModelFile({
    required this.name,
    required this.size,
    required this.sizeFormatted,
  });

  factory ModelFile.fromJson(Map<String, dynamic> json) =>
      _$ModelFileFromJson(json);

  Map<String, dynamic> toJson() => _$ModelFileToJson(this);

  @override
  List<Object?> get props => <Object?>[name, size, sizeFormatted];
}

/// 模型详情（dto.ModelInfo；HF/ModelScope info）。
@JsonSerializable()
class ModelInfo extends Equatable {
  final String repoID;
  final String name;
  final int downloads;
  final int likes;
  final int size;
  final String sizeFormatted;
  final String modelCard;
  final List<ModelFile> files;

  const ModelInfo({
    required this.repoID,
    required this.name,
    required this.downloads,
    required this.likes,
    required this.size,
    required this.sizeFormatted,
    required this.modelCard,
    required this.files,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ModelInfoToJson(this);

  @override
  List<Object?> get props => <Object?>[
        repoID,
        name,
        downloads,
        likes,
        size,
        sizeFormatted,
        modelCard,
        files,
      ];
}

/// 模型详情请求（dto.ModelInfoReq）。
@JsonSerializable()
class ModelInfoReq extends Equatable {
  final String repoID;
  final String? revision;

  const ModelInfoReq({required this.repoID, this.revision});

  factory ModelInfoReq.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoReqFromJson(json);

  Map<String, dynamic> toJson() => _$ModelInfoReqToJson(this);

  @override
  List<Object?> get props => <Object?>[repoID, revision];
}

/// 模型下载请求（dto.ModelDownload）。
///
/// downloadType 取值：all / tokenizer。
@JsonSerializable()
class ModelDownload extends Equatable {
  final String repoID;
  final String? revision;
  final String? downloadType;

  const ModelDownload({
    required this.repoID,
    this.revision,
    this.downloadType,
  });

  factory ModelDownload.fromJson(Map<String, dynamic> json) =>
      _$ModelDownloadFromJson(json);

  Map<String, dynamic> toJson() => _$ModelDownloadToJson(this);

  @override
  List<Object?> get props => <Object?>[repoID, revision, downloadType];
}

/// 本地已下载模型（dto.LocalModelItem）。
@JsonSerializable()
class LocalModelItem extends Equatable {
  final String name;
  final String repoID;
  final String revision;
  final String downloadType;
  final String source;
  final String path;
  final int size;
  final String sizeFormatted;
  final String createdAt;

  const LocalModelItem({
    required this.name,
    required this.repoID,
    required this.revision,
    required this.downloadType,
    required this.source,
    required this.path,
    required this.size,
    required this.sizeFormatted,
    required this.createdAt,
  });

  factory LocalModelItem.fromJson(Map<String, dynamic> json) =>
      _$LocalModelItemFromJson(json);

  Map<String, dynamic> toJson() => _$LocalModelItemToJson(this);

  @override
  List<Object?> get props => <Object?>[
        name,
        repoID,
        revision,
        downloadType,
        source,
        path,
        size,
        sizeFormatted,
        createdAt,
      ];
}

/// 本地模型分页请求（dto.LocalModelSearch）。
@JsonSerializable()
class LocalModelSearch extends Equatable {
  final int page;
  final int pageSize;
  final String? info;
  final String? downloadType;

  const LocalModelSearch({
    this.page = 1,
    this.pageSize = 20,
    this.info,
    this.downloadType,
  });

  factory LocalModelSearch.fromJson(Map<String, dynamic> json) =>
      _$LocalModelSearchFromJson(json);

  Map<String, dynamic> toJson() => _$LocalModelSearchToJson(this);

  @override
  List<Object?> get props => <Object?>[page, pageSize, info, downloadType];
}

/// 本地模型删除请求（dto.LocalModelDelete）。
@JsonSerializable()
class LocalModelDelete extends Equatable {
  final String name;
  final String? downloadType;
  final bool? withFile;

  const LocalModelDelete({
    required this.name,
    this.downloadType,
    this.withFile,
  });

  factory LocalModelDelete.fromJson(Map<String, dynamic> json) =>
      _$LocalModelDeleteFromJson(json);

  Map<String, dynamic> toJson() => _$LocalModelDeleteToJson(this);

  @override
  List<Object?> get props => <Object?>[name, downloadType, withFile];
}

/// 模型下载任务（dto.ModelDownloadTaskItem）。
///
/// errorMessage 与三个时间戳在上游为指针，任务未开始或未结束时为空。
@JsonSerializable()
class ModelDownloadTaskItem extends Equatable {
  final int id;
  final String modelName;
  final String repoID;
  final String revision;
  final String downloadType;
  final String source;
  final String status;
  final double progress;
  final int downloadedSize;
  final int totalSize;
  final String targetDir;
  final String? errorMessage;
  final String? createdAt;
  final String? startedAt;
  final String? completedAt;
  final bool canCancel;
  final bool canRetry;
  final bool canRemoveRecord;
  final LocalModelItem? localModel;

  const ModelDownloadTaskItem({
    required this.id,
    required this.modelName,
    required this.repoID,
    required this.revision,
    required this.downloadType,
    required this.source,
    required this.status,
    required this.progress,
    required this.downloadedSize,
    required this.totalSize,
    required this.targetDir,
    this.errorMessage,
    this.createdAt,
    this.startedAt,
    this.completedAt,
    required this.canCancel,
    required this.canRetry,
    required this.canRemoveRecord,
    this.localModel,
  });

  factory ModelDownloadTaskItem.fromJson(Map<String, dynamic> json) =>
      _$ModelDownloadTaskItemFromJson(json);

  Map<String, dynamic> toJson() => _$ModelDownloadTaskItemToJson(this);

  @override
  List<Object?> get props => <Object?>[
        id,
        modelName,
        repoID,
        revision,
        downloadType,
        source,
        status,
        progress,
        downloadedSize,
        totalSize,
        targetDir,
        errorMessage,
        createdAt,
        startedAt,
        completedAt,
        canCancel,
        canRetry,
        canRemoveRecord,
        localModel,
      ];
}

/// 下载任务分页请求（dto.ModelDownloadTaskSearch）。
///
/// includeLocal 为 true 时同时返回本地已下载模型。
@JsonSerializable()
class ModelDownloadTaskSearch extends Equatable {
  final int page;
  final int pageSize;
  final String? info;
  final String? status;
  final String? downloadType;
  final bool? includeLocal;

  const ModelDownloadTaskSearch({
    this.page = 1,
    this.pageSize = 20,
    this.info,
    this.status,
    this.downloadType,
    this.includeLocal,
  });

  factory ModelDownloadTaskSearch.fromJson(Map<String, dynamic> json) =>
      _$ModelDownloadTaskSearchFromJson(json);

  Map<String, dynamic> toJson() => _$ModelDownloadTaskSearchToJson(this);

  @override
  List<Object?> get props =>
      <Object?>[page, pageSize, info, status, downloadType, includeLocal];
}

/// 下载任务取消/移除请求（dto.ModelDownloadTaskOperate）。
@JsonSerializable()
class ModelDownloadTaskOperate extends Equatable {
  final int id;
  final bool? withFile;

  const ModelDownloadTaskOperate({required this.id, this.withFile});

  factory ModelDownloadTaskOperate.fromJson(Map<String, dynamic> json) =>
      _$ModelDownloadTaskOperateFromJson(json);

  Map<String, dynamic> toJson() => _$ModelDownloadTaskOperateToJson(this);

  @override
  List<Object?> get props => <Object?>[id, withFile];
}

/// 推荐模型自动同步设置请求（dto.ModelDownloaderSyncSetting）。
///
/// value 取值：Enable / Disable。
@JsonSerializable()
class ModelDownloaderSyncSetting extends Equatable {
  final String value;

  const ModelDownloaderSyncSetting({required this.value});

  factory ModelDownloaderSyncSetting.fromJson(Map<String, dynamic> json) =>
      _$ModelDownloaderSyncSettingFromJson(json);

  Map<String, dynamic> toJson() => _$ModelDownloaderSyncSettingToJson(this);

  @override
  List<Object?> get props => <Object?>[value];
}

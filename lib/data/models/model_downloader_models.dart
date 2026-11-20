import 'package:equatable/equatable.dart';

/// 推荐模型条目（dto.FeaturedModel）。
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
    this.key = '',
    this.repoID = '',
    this.family = '',
    this.architecture = '',
    this.backboneParams = '',
    this.activeParams = '',
    this.engram = '',
    this.weightGB = 0,
    this.sources = const <String>[],
    this.sourceModelIds = const <String, String>{},
    this.description = const <String, String>{},
    this.sort = 0,
  });

  factory FeaturedModel.fromJson(Map<String, dynamic> json) {
    return FeaturedModel(
      key: json['key'] as String? ?? '',
      repoID: json['repoID'] as String? ?? '',
      family: json['family'] as String? ?? '',
      architecture: json['architecture'] as String? ?? '',
      backboneParams: json['backboneParams'] as String? ?? '',
      activeParams: json['activeParams'] as String? ?? '',
      engram: json['engram'] as String? ?? '',
      weightGB: (json['weightGB'] as num?)?.toDouble() ?? 0,
      sources: (json['sources'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
      sourceModelIds: (json['sourceModelIds'] as Map?)
              ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
          const <String, String>{},
      description: (json['description'] as Map?)
              ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
          const <String, String>{},
      sort: json['sort'] as int? ?? 0,
    );
  }

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
class FeaturedModelPage extends Equatable {
  final List<FeaturedModel> items;
  final int total;
  final List<String> families;

  const FeaturedModelPage({
    this.items = const <FeaturedModel>[],
    this.total = 0,
    this.families = const <String>[],
  });

  factory FeaturedModelPage.fromJson(Map<String, dynamic> json) {
    return FeaturedModelPage(
      items: (json['items'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(FeaturedModel.fromJson)
              .toList(growable: false) ??
          const <FeaturedModel>[],
      total: json['total'] as int? ?? 0,
      families: (json['families'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
    );
  }

  @override
  List<Object?> get props => <Object?>[items, total, families];
}

/// 推荐模型分页请求（dto.FeaturedModelSearch）。
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (family != null) 'family': family,
        if (info != null) 'info': info,
      };

  @override
  List<Object?> get props => <Object?>[page, pageSize, family, info];
}

/// 模型市场条目（dto.ModelItem；HF/ModelScope 搜索结果）。
class ModelItem extends Equatable {
  final String repoID;
  final String name;
  final int downloads;
  final int likes;
  final int size;
  final String sizeFormatted;

  const ModelItem({
    this.repoID = '',
    this.name = '',
    this.downloads = 0,
    this.likes = 0,
    this.size = 0,
    this.sizeFormatted = '',
  });

  factory ModelItem.fromJson(Map<String, dynamic> json) {
    return ModelItem(
      repoID: json['repoID'] as String? ?? '',
      name: json['name'] as String? ?? '',
      downloads: json['downloads'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      sizeFormatted: json['sizeFormatted'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[repoID, name, downloads, likes, size, sizeFormatted];
}

/// HF/ModelScope 模型搜索请求（dto.ModelSearch）。
///
/// sort 取值：trending / downloads / updated / created / likes /
/// most_params / least_params；pageSize 上限 100。
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (query != null) 'query': query,
        if (sort != null) 'sort': sort,
        if (limit != null) 'limit': limit,
      };

  @override
  List<Object?> get props => <Object?>[page, pageSize, query, sort, limit];
}

/// 模型文件（dto.ModelFile）。
class ModelFile extends Equatable {
  final String name;
  final int size;
  final String sizeFormatted;

  const ModelFile({
    this.name = '',
    this.size = 0,
    this.sizeFormatted = '',
  });

  factory ModelFile.fromJson(Map<String, dynamic> json) {
    return ModelFile(
      name: json['name'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      sizeFormatted: json['sizeFormatted'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[name, size, sizeFormatted];
}

/// 模型详情（dto.ModelInfo；HF/ModelScope info）。
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
    this.repoID = '',
    this.name = '',
    this.downloads = 0,
    this.likes = 0,
    this.size = 0,
    this.sizeFormatted = '',
    this.modelCard = '',
    this.files = const <ModelFile>[],
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      repoID: json['repoID'] as String? ?? '',
      name: json['name'] as String? ?? '',
      downloads: json['downloads'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      sizeFormatted: json['sizeFormatted'] as String? ?? '',
      modelCard: json['modelCard'] as String? ?? '',
      files: (json['files'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ModelFile.fromJson)
              .toList(growable: false) ??
          const <ModelFile>[],
    );
  }

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
class ModelInfoReq extends Equatable {
  final String repoID;
  final String? revision;

  const ModelInfoReq({required this.repoID, this.revision});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'repoID': repoID,
        if (revision != null) 'revision': revision,
      };

  @override
  List<Object?> get props => <Object?>[repoID, revision];
}

/// 模型下载请求（dto.ModelDownload）。
///
/// downloadType 取值：all / tokenizer。
class ModelDownload extends Equatable {
  final String repoID;
  final String? revision;
  final String? downloadType;

  const ModelDownload({
    required this.repoID,
    this.revision,
    this.downloadType,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'repoID': repoID,
        if (revision != null) 'revision': revision,
        if (downloadType != null) 'downloadType': downloadType,
      };

  @override
  List<Object?> get props => <Object?>[repoID, revision, downloadType];
}

/// 本地已下载模型（dto.LocalModelItem）。
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
    this.name = '',
    this.repoID = '',
    this.revision = '',
    this.downloadType = '',
    this.source = '',
    this.path = '',
    this.size = 0,
    this.sizeFormatted = '',
    this.createdAt = '',
  });

  factory LocalModelItem.fromJson(Map<String, dynamic> json) {
    return LocalModelItem(
      name: json['name'] as String? ?? '',
      repoID: json['repoID'] as String? ?? '',
      revision: json['revision'] as String? ?? '',
      downloadType: json['downloadType'] as String? ?? '',
      source: json['source'] as String? ?? '',
      path: json['path'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      sizeFormatted: json['sizeFormatted'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (info != null) 'info': info,
        if (downloadType != null) 'downloadType': downloadType,
      };

  @override
  List<Object?> get props => <Object?>[page, pageSize, info, downloadType];
}

/// 本地模型删除请求（dto.LocalModelDelete）。
class LocalModelDelete extends Equatable {
  final String name;
  final String? downloadType;
  final bool? withFile;

  const LocalModelDelete({
    required this.name,
    this.downloadType,
    this.withFile,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        if (downloadType != null) 'downloadType': downloadType,
        if (withFile != null) 'withFile': withFile,
      };

  @override
  List<Object?> get props => <Object?>[name, downloadType, withFile];
}

/// 模型下载任务（dto.ModelDownloadTaskItem）。
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
    this.id = 0,
    this.modelName = '',
    this.repoID = '',
    this.revision = '',
    this.downloadType = '',
    this.source = '',
    this.status = '',
    this.progress = 0,
    this.downloadedSize = 0,
    this.totalSize = 0,
    this.targetDir = '',
    this.errorMessage,
    this.createdAt,
    this.startedAt,
    this.completedAt,
    this.canCancel = false,
    this.canRetry = false,
    this.canRemoveRecord = false,
    this.localModel,
  });

  factory ModelDownloadTaskItem.fromJson(Map<String, dynamic> json) {
    return ModelDownloadTaskItem(
      id: json['id'] as int? ?? 0,
      modelName: json['modelName'] as String? ?? '',
      repoID: json['repoID'] as String? ?? '',
      revision: json['revision'] as String? ?? '',
      downloadType: json['downloadType'] as String? ?? '',
      source: json['source'] as String? ?? '',
      status: json['status'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      downloadedSize: json['downloadedSize'] as int? ?? 0,
      totalSize: json['totalSize'] as int? ?? 0,
      targetDir: json['targetDir'] as String? ?? '',
      errorMessage: json['errorMessage'] as String?,
      createdAt: json['createdAt'] as String?,
      startedAt: json['startedAt'] as String?,
      completedAt: json['completedAt'] as String?,
      canCancel: json['canCancel'] as bool? ?? false,
      canRetry: json['canRetry'] as bool? ?? false,
      canRemoveRecord: json['canRemoveRecord'] as bool? ?? false,
      localModel: json['localModel'] is Map<String, dynamic>
          ? LocalModelItem.fromJson(json['localModel'] as Map<String, dynamic>)
          : null,
    );
  }

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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (info != null) 'info': info,
        if (status != null) 'status': status,
        if (downloadType != null) 'downloadType': downloadType,
        if (includeLocal != null) 'includeLocal': includeLocal,
      };

  @override
  List<Object?> get props =>
      <Object?>[page, pageSize, info, status, downloadType, includeLocal];
}

/// 下载任务取消/移除请求（dto.ModelDownloadTaskOperate）。
class ModelDownloadTaskOperate extends Equatable {
  final int id;
  final bool? withFile;

  const ModelDownloadTaskOperate({required this.id, this.withFile});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        if (withFile != null) 'withFile': withFile,
      };

  @override
  List<Object?> get props => <Object?>[id, withFile];
}

/// 推荐模型自动同步设置请求（dto.ModelDownloaderSyncSetting）。
///
/// value 取值：Enable / Disable。
class ModelDownloaderSyncSetting extends Equatable {
  final String value;

  const ModelDownloaderSyncSetting({required this.value});

  Map<String, dynamic> toJson() => <String, dynamic>{'value': value};

  @override
  List<Object?> get props => <Object?>[value];
}

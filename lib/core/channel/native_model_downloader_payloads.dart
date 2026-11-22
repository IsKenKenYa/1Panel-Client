import '../../data/models/model_downloader_models.dart';
import '../../data/models/setting_models.dart';

/// 模型下载器通道返回结构。
///
/// 状态语义、进度归一化、推荐模型默认来源与下载来源映射在 Dart 侧完成。

Map<String, Object?> modelDownloaderFeaturedPayload(FeaturedModel model) {
  final preferredSource =
      model.sources.isEmpty ? 'hf' : model.sources.first;
  return <String, Object?>{
    'key': model.key,
    'repoID': model.repoID,
    'family': model.family,
    'architecture': model.architecture,
    'backboneParams': model.backboneParams,
    'activeParams': model.activeParams,
    'engram': model.engram,
    'weightGB': model.weightGB,
    'sources': model.sources,
    'sourceModelIds': model.sourceModelIds,
    'description': model.description,
    'preferredSource': preferredSource,
    'preferredRepoID':
        model.sourceModelIds[preferredSource] ?? model.repoID,
    'sort': model.sort,
  };
}

Map<String, Object?> modelDownloaderMarketPayload(ModelItem model) {
  return <String, Object?>{
    'repoID': model.repoID,
    'name': model.name,
    'downloads': model.downloads,
    'likes': model.likes,
    'size': model.size,
    'sizeFormatted': model.sizeFormatted,
  };
}

Map<String, Object?> modelDownloaderTaskPayload(
  ModelDownloadTaskItem task,
) {
  final ratio = task.progress > 1 ? task.progress / 100 : task.progress;
  return <String, Object?>{
    'id': task.id,
    'modelName': task.modelName,
    'repoID': task.repoID,
    'revision': task.revision,
    'downloadType': task.downloadType,
    'source': task.source,
    'status': task.status,
    'statusTone': _taskStatusTone(task.status),
    'progressRatio': ratio.clamp(0, 1).toDouble(),
    'downloadedSize': task.downloadedSize,
    'totalSize': task.totalSize,
    'targetDir': task.targetDir,
    'errorMessage': task.errorMessage,
    'createdAt': task.createdAt,
    'startedAt': task.startedAt,
    'completedAt': task.completedAt,
    'canCancel': task.canCancel,
    'canRetry': task.canRetry,
    'canRemoveRecord': task.canRemoveRecord,
  };
}

Map<String, Object?> modelDownloaderLocalPayload(LocalModelItem model) {
  return <String, Object?>{
    'name': model.name,
    'repoID': model.repoID,
    'revision': model.revision,
    'downloadType': model.downloadType,
    'source': model.source,
    'path': model.path,
    'size': model.size,
    'sizeFormatted': model.sizeFormatted,
    'createdAt': model.createdAt,
  };
}

Map<String, Object?> modelDownloaderSettingsPayload(
  ModelDownloaderSetting setting,
) {
  return <String, Object?>{
    'modelDir': setting.modelDir,
    'featuredModelsSync': setting.featuredModelsSync,
    'featuredSyncEnabled': setting.featuredModelsSync == 'Enable',
    'hfEndpoint': setting.hfEndpoint,
    'hfToken': setting.hfToken,
    'modelScopeEndpoint': setting.modelScopeEndpoint,
    'modelScopeToken': setting.modelScopeToken,
  };
}

/// 模型下载器表单选项与固定取值。
Map<String, Object?> modelDownloaderOptionsPayload() {
  return <String, Object?>{
    'sources': const <String>['hf', 'modelScope'],
    'sorts': const <String>[
      'trending',
      'downloads',
      'likes',
      'updated',
      'created',
      'most_params',
      'least_params',
    ],
    'downloadTypes': const <String>['all', 'tokenizer'],
    'taskStatuses': const <String>[
      'running',
      'waiting',
      'completed',
      'failed',
      'cancelled',
    ],
  };
}

String _taskStatusTone(String status) {
  switch (status.toLowerCase()) {
    case 'running':
    case 'waiting':
      return 'info';
    case 'completed':
    case 'success':
      return 'positive';
    case 'failed':
    case 'error':
      return 'negative';
    case 'cancelled':
    case 'canceled':
      return 'neutral';
    default:
      return 'neutral';
  }
}
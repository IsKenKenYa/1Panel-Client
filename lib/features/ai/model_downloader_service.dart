import '../../api/v2/xpack_model_downloader_v2.dart';
import '../../core/services/base_component.dart';
import '../../data/models/common_models.dart';
import '../../data/models/model_downloader_models.dart';
import '../../data/models/setting_models.dart';
import '../../data/repositories/model_downloader_repository.dart';

/// 模型下载器业务服务。
///
/// 推荐目录、市场搜索、本地模型与下载任务走 `XpackModelDownloaderV2Api`；
/// 下载设置端点位于 `setting_v2.dart`（`/xpack/model/downloader/settings`），
/// 与下载器其余端点同属一个模块，经 [ModelDownloaderRepository] 统一注入。
class ModelDownloaderService extends BaseComponent {
  ModelDownloaderService({
    ModelDownloaderRepository? repository,
    XpackModelDownloaderV2Api? api,
    super.clientManager,
    super.permissionResolver,
  }) : _repository = repository ??
            ModelDownloaderRepository(
              clientManager: clientManager,
              api: api,
            );

  final ModelDownloaderRepository _repository;

  Future<XpackModelDownloaderV2Api> _ensureApi() => _repository.ensureApi();

  void resetForServerChange() {
    _repository.resetForServerChange();
  }

  // ==================== 推荐模型 ====================

  Future<FeaturedModelPage> searchFeatured({
    int page = 1,
    int pageSize = 20,
    String? family,
    String? info,
  }) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).searchFeaturedModels(
        FeaturedModelSearch(
          page: page,
          pageSize: pageSize,
          family: family,
          info: info,
        ),
      );
      return response.data ??
          const FeaturedModelPage(items: <FeaturedModel>[], total: 0);
    });
  }

  Future<void> syncFeatured() {
    return runGuarded(() async {
      await (await _ensureApi()).syncFeaturedModels();
    });
  }

  Future<void> updateFeaturedSyncStatus(bool enabled) {
    return runGuarded(() async {
      await (await _ensureApi()).updateFeaturedSyncStatus(
        ModelDownloaderSyncSetting(value: enabled ? 'Enable' : 'Disable'),
      );
    });
  }

  // ==================== 市场搜索 ====================

  Future<PageResult<ModelItem>> searchHuggingFace({
    int page = 1,
    int pageSize = 20,
    String? query,
    String? sort,
  }) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).searchHuggingFaceModels(
        ModelSearch(page: page, pageSize: pageSize, query: query, sort: sort),
      );
      return response.data ??
          const PageResult<ModelItem>(items: <ModelItem>[], total: 0);
    });
  }

  Future<ModelInfo> getHuggingFaceInfo(String repoID, {String? revision}) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).getHuggingFaceModelInfo(
        ModelInfoReq(repoID: repoID, revision: revision),
      );
      return response.data ?? const ModelInfo();
    });
  }

  Future<void> downloadHuggingFace({
    required String repoID,
    String? revision,
    String downloadType = 'all',
  }) {
    return runGuarded(() async {
      await (await _ensureApi()).downloadHuggingFaceModel(
        ModelDownload(
          repoID: repoID,
          revision: revision,
          downloadType: downloadType,
        ),
      );
    });
  }

  Future<PageResult<ModelItem>> searchModelScope({
    int page = 1,
    int pageSize = 20,
    String? query,
    String? sort,
  }) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).searchModelScopeModels(
        ModelSearch(page: page, pageSize: pageSize, query: query, sort: sort),
      );
      return response.data ??
          const PageResult<ModelItem>(items: <ModelItem>[], total: 0);
    });
  }

  Future<ModelInfo> getModelScopeInfo(String repoID, {String? revision}) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).getModelScopeModelInfo(
        ModelInfoReq(repoID: repoID, revision: revision),
      );
      return response.data ?? const ModelInfo();
    });
  }

  Future<void> downloadModelScope({
    required String repoID,
    String? revision,
    String downloadType = 'all',
  }) {
    return runGuarded(() async {
      await (await _ensureApi()).downloadModelScopeModel(
        ModelDownload(
          repoID: repoID,
          revision: revision,
          downloadType: downloadType,
        ),
      );
    });
  }

  // ==================== 本地模型 ====================

  Future<PageResult<LocalModelItem>> searchLocal({
    int page = 1,
    int pageSize = 20,
    String? info,
    String? downloadType,
  }) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).searchLocalModels(
        LocalModelSearch(
          page: page,
          pageSize: pageSize,
          info: info,
          downloadType: downloadType,
        ),
      );
      return response.data ??
          const PageResult<LocalModelItem>(items: <LocalModelItem>[], total: 0);
    });
  }

  Future<void> deleteLocalModel({
    required String name,
    String? downloadType,
    bool withFile = true,
  }) {
    return runGuarded(() async {
      await (await _ensureApi()).deleteLocalModel(
        LocalModelDelete(
          name: name,
          downloadType: downloadType,
          withFile: withFile,
        ),
      );
    });
  }

  // ==================== 下载任务 ====================

  Future<PageResult<ModelDownloadTaskItem>> searchTasks({
    int page = 1,
    int pageSize = 20,
    String? status,
    bool includeLocal = false,
  }) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).searchDownloadTasks(
        ModelDownloadTaskSearch(
          page: page,
          pageSize: pageSize,
          status: status,
          includeLocal: includeLocal,
        ),
      );
      return response.data ??
          const PageResult<ModelDownloadTaskItem>(
            items: <ModelDownloadTaskItem>[],
            total: 0,
          );
    });
  }

  Future<void> cancelTask(int id, {bool withFile = false}) {
    return runGuarded(() async {
      await (await _ensureApi()).cancelDownloadTask(
        ModelDownloadTaskOperate(id: id, withFile: withFile),
      );
    });
  }

  Future<void> removeTask(int id, {bool? withFile}) {
    return runGuarded(() async {
      await (await _ensureApi()).removeDownloadTask(
        ModelDownloadTaskOperate(id: id, withFile: withFile),
      );
    });
  }

  Future<void> retryTask(int id) {
    return runGuarded(() async {
      await (await _ensureApi()).retryDownloadTask(OperateByID(id: id));
    });
  }

  // ==================== 设置 ====================

  Future<ModelDownloaderSetting> getSettings() {
    return runGuarded(() async {
      final response =
          await (await _repository.ensureSettingApi()).getModelDownloaderSettings();
      return response.data ??
          const ModelDownloaderSetting(modelDir: '');
    });
  }

  Future<void> updateSettings(ModelDownloaderSetting setting) {
    return runGuarded(() async {
      await (await _repository.ensureSettingApi())
          .updateModelDownloaderSettings(setting);
    });
  }
}

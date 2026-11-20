import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/common_models.dart';
import '../../data/models/model_downloader_models.dart';
import 'api_response_parser.dart';

/// 1Panel model downloader API client.
///
/// 覆盖 swagger `/xpack/model/downloader` 除 settings 外的全部端点；
/// settings 读写已在 `setting_v2.dart` 实现，覆盖统计经 xpack 路径过滤合并。
class XpackModelDownloaderV2Api {
  XpackModelDownloaderV2Api(this._client);

  final DioClient _client;

  /// 下载与删除在服务端为异步任务或文件操作，耗时较长；
  /// 对齐上游 AI 模块长超时习惯。
  static final Options _asyncOpOptions = Options(
    receiveTimeout: const Duration(minutes: 5),
    sendTimeout: const Duration(minutes: 1),
  );

  // ==================== 推荐模型 ====================

  /// 分页查询推荐模型目录。
  Future<Response<FeaturedModelPage>> searchFeaturedModels(
      FeaturedModelSearch request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/xpack/model/downloader/featured/search'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      FeaturedModelPage.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  /// 立即同步推荐模型目录（离线模式下不执行）。
  Future<Response<void>> syncFeaturedModels() async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/xpack/model/downloader/featured/sync'),
    );
  }

  /// 更新推荐模型自动同步设置（Enable / Disable）。
  Future<Response<void>> updateFeaturedSyncStatus(
      ModelDownloaderSyncSetting request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/xpack/model/downloader/featured/sync/status'),
      data: request.toJson(),
    );
  }

  // ==================== Hugging Face ====================

  /// 搜索 Hugging Face 模型。
  Future<Response<PageResult<ModelItem>>> searchHuggingFaceModels(
      ModelSearch request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/xpack/model/downloader/hf/search'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      PageResult.fromJson(
        ApiResponseParser.asMap(response.data),
        (dynamic item) => ModelItem.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  /// 加载 Hugging Face 模型详情。
  Future<Response<ModelInfo>> getHuggingFaceModelInfo(
      ModelInfoReq request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/xpack/model/downloader/hf/info'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      ModelInfo.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  /// 发起 Hugging Face 模型下载（异步任务，进度经 tasks/search 查询）。
  Future<Response<void>> downloadHuggingFaceModel(
      ModelDownload request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/xpack/model/downloader/hf/download'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
  }

  // ==================== ModelScope ====================

  /// 搜索 ModelScope 模型。
  Future<Response<PageResult<ModelItem>>> searchModelScopeModels(
      ModelSearch request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/xpack/model/downloader/modelscope/search'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      PageResult.fromJson(
        ApiResponseParser.asMap(response.data),
        (dynamic item) => ModelItem.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  /// 加载 ModelScope 模型详情。
  Future<Response<ModelInfo>> getModelScopeModelInfo(
      ModelInfoReq request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/xpack/model/downloader/modelscope/info'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      ModelInfo.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  /// 发起 ModelScope 模型下载（异步任务，进度经 tasks/search 查询）。
  Future<Response<void>> downloadModelScopeModel(
      ModelDownload request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/xpack/model/downloader/modelscope/download'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
  }

  // ==================== 本地模型 ====================

  /// 分页查询本地已下载模型。
  Future<Response<PageResult<LocalModelItem>>> searchLocalModels(
      LocalModelSearch request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/xpack/model/downloader/local/search'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      PageResult.fromJson(
        ApiResponseParser.asMap(response.data),
        (dynamic item) => LocalModelItem.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  /// 删除本地模型（异步任务）。
  Future<Response<void>> deleteLocalModel(LocalModelDelete request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/xpack/model/downloader/local/delete'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
  }

  // ==================== 下载任务 ====================

  /// 分页查询下载任务；includeLocal 为 true 时合并本地模型。
  Future<Response<PageResult<ModelDownloadTaskItem>>> searchDownloadTasks(
      ModelDownloadTaskSearch request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/xpack/model/downloader/tasks/search'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      PageResult.fromJson(
        ApiResponseParser.asMap(response.data),
        (dynamic item) =>
            ModelDownloadTaskItem.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  /// 取消下载任务。
  Future<Response<void>> cancelDownloadTask(
      ModelDownloadTaskOperate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/xpack/model/downloader/tasks/cancel'),
      data: request.toJson(),
    );
  }

  /// 移除下载任务记录。
  Future<Response<void>> removeDownloadTask(
      ModelDownloadTaskOperate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/xpack/model/downloader/tasks/remove'),
      data: request.toJson(),
    );
  }

  /// 重试失败的下载任务。
  Future<Response<void>> retryDownloadTask(OperateByID request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/xpack/model/downloader/tasks/retry'),
      data: request.toJson(),
    );
  }
}

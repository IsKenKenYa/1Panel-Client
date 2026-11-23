import 'package:dio/dio.dart';
import '../../api/v2/ai_v2.dart';
import '../../core/network/api_client_manager.dart';
import '../../data/models/ai_models.dart';
import '../../data/models/common_models.dart';

/// AI数据仓库类
class AIRepository {
  AIRepository({ApiClientManager? clientManager})
      : _clientManager = clientManager ?? ApiClientManager.instance;

  final ApiClientManager _clientManager;

  Future<AIV2Api> _getApi() => _clientManager.getAiApi();

  /// Public API accessor for direct API calls (R5 frontend alignment).
  Future<AIV2Api> getApi() => _getApi();

  /// 绑定域名
  ///
  /// 为AI服务绑定域名
  /// @param appInstallId 应用安装ID
  /// @param domain 域名
  /// @param ipList IP列表
  /// @param sslId SSL证书ID
  /// @param websiteId 网站ID
  /// @return 绑定结果
  Future<Response> bindDomain({
    required int appInstallID,
    required String domain,
    String? ipList,
    int? sslID,
    int? websiteID,
  }) async {
    final api = await _getApi();
    final request = OllamaBindDomain(
      appInstallID: appInstallID,
      domain: domain,
      ipList: ipList,
      sslID: sslID,
      websiteID: websiteID,
    );
    return api.bindDomain(request);
  }

  /// 更新绑定域名
  ///
  /// 更新当前AI服务绑定的域名信息
  /// @param appInstallID 应用安装ID
  /// @param domain 域名
  /// @param ipList IP列表
  /// @param sslID SSL证书ID
  /// @param websiteID 网站ID
  /// @return 更新结果
  Future<Response> updateBindDomain({
    required int appInstallID,
    required String domain,
    String? ipList,
    int? sslID,
    int? websiteID,
  }) async {
    final api = await _getApi();
    final request = OllamaBindDomain(
      appInstallID: appInstallID,
      domain: domain,
      ipList: ipList,
      sslID: sslID,
      websiteID: websiteID,
    );
    return api.updateBindDomain(request);
  }

  /// 获取绑定域名
  ///
  /// 获取当前AI服务绑定的域名信息
  /// @param appInstallID 应用安装ID
  /// @return 域名信息
  Future<OllamaBindDomainRes> getBindDomain({
    required int appInstallID,
  }) async {
    final api = await _getApi();
    final request = OllamaBindDomainReq(appInstallID: appInstallID);
    final response = await api.getBindDomain(request);
    return response.data!;
  }

  /// 加载GPU/XPU信息
  ///
  /// 获取系统中的GPU或XPU信息
  /// @return GPU/XPU信息列表
  Future<List<GpuInfo>> loadGpuInfo() async {
    final api = await _getApi();
    final response = await api.loadGpuInfo();
    return response.data!;
  }

  /// 创建Ollama模型
  ///
  /// 创建一个新的Ollama模型
  /// @param name 模型名称
  /// @param taskID 任务ID
  /// @return 创建结果
  Future<Response> createOllamaModel({
    required String name,
    String? taskID,
  }) async {
    final api = await _getApi();
    final request = OllamaModelName(
      name: name,
      taskID: taskID,
    );
    return api.createOllamaModel(request);
  }

  /// 关闭Ollama模型连接
  ///
  /// 关闭指定Ollama模型的连接
  /// @param name 模型名称
  /// @param taskID 任务ID
  /// @return 操作结果
  Future<Response> closeOllamaModel({
    required String name,
    String? taskID,
  }) async {
    final api = await _getApi();
    final request = OllamaModelName(
      name: name,
      taskID: taskID,
    );
    return api.closeOllamaModel(request);
  }

  /// 删除Ollama模型
  ///
  /// 删除指定的Ollama模型
  /// @param ids 模型ID列表
  /// @param forceDelete 是否强制删除
  /// @return 删除结果
  Future<Response> deleteOllamaModel({
    required List<int> ids,
    bool forceDelete = false,
  }) async {
    final api = await _getApi();
    final request = ForceDelete(
      forceDelete: forceDelete,
      ids: ids,
    );
    return api.deleteOllamaModel(request);
  }

  /// 加载Ollama模型
  ///
  /// 加载指定的Ollama模型
  /// @param name 模型名称
  /// @param taskID 任务ID
  /// @return 加载结果
  Future<String> loadOllamaModel({
    required String name,
    String? taskID,
  }) async {
    final api = await _getApi();
    final request = OllamaModelName(
      name: name,
      taskID: taskID,
    );
    final response = await api.loadOllamaModel(request);
    return response.data!;
  }

  /// 重新创建Ollama模型
  ///
  /// 重新创建指定的Ollama模型
  /// @param name 模型名称
  /// @param taskID 任务ID
  /// @return 创建结果
  Future<Response> recreateOllamaModel({
    required String name,
    String? taskID,
  }) async {
    final api = await _getApi();
    final request = OllamaModelName(
      name: name,
      taskID: taskID,
    );
    return api.recreateOllamaModel(request);
  }

  /// 搜索Ollama模型
  ///
  /// 搜索Ollama模型列表
  /// @param page 页码
  /// @param pageSize 每页大小
  /// @param info 搜索信息
  /// @return 搜索结果
  Future<PageResult<OllamaModel>> searchOllamaModels({
    required int page,
    required int pageSize,
    String? info,
  }) async {
    final api = await _getApi();
    final request = SearchWithPage(
      page: page,
      pageSize: pageSize,
      info: info,
    );
    final response = await api.searchOllamaModels(request);
    return response.data!;
  }

  /// 同步Ollama模型列表
  ///
  /// 同步Ollama模型列表
  /// @return 模型列表
  Future<List<OllamaModelDropList>> syncOllamaModels() async {
    final api = await _getApi();
    final response = await api.syncOllamaModels();
    return response.data!;
  }

  /// Search GPU monitor data for history chart (R5 frontend alignment).
  /// 读取 GPU 历史序列。
  ///
  /// 上游 `/ai/gpu/search` 要求携带设备（deviceID 或 productName），
  /// 否则直接返回业务错误；返回体是 `{memoryActivity, computeUtil, ...}`
  /// 这样的时间序列对象，不是设备列表。这里先经 `/ai/gpu/options`
  /// 取得设备，再按对象返回原始序列。
  Future<Map<String, dynamic>> searchGpu(
      Map<String, dynamic> request) async {
    final api = await _getApi();
    final response = await api.searchGpu(request);
    return response.data ?? const <String, dynamic>{};
  }

  /// 读取 GPU 设备选项。
  ///
  /// 上游返回 `{chartHide: [...], chartSelect: [...]}` 对象，设备列表在
  /// `chartHide` 里；按数组解析会得到空列表。
  Future<Map<String, dynamic>> getGpuOptions() async {
    final api = await _getApi();
    final response = await api.getGpuOptionsRaw();
    return response;
  }

  /// 解析设备选项里的第一台 GPU，没有设备时返回 null。
  static ({String deviceId, String productName, bool legacy})? firstGpuDevice(
    Map<String, dynamic> options,
  ) {
    final chartHide = options['chartHide'];
    if (chartHide is! List || chartHide.isEmpty) return null;
    final first = chartHide.first;
    if (first is! Map) return null;
    final deviceId = (first['deviceID'] as String? ?? '').trim();
    final productName = (first['productName'] as String? ?? '').trim();
    if (deviceId.isEmpty && productName.isEmpty) return null;
    return (
      deviceId: deviceId,
      productName: productName,
      legacy: first['legacy'] == true,
    );
  }
}

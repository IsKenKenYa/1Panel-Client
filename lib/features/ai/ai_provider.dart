import 'package:flutter/foundation.dart';
import '../../data/models/ai_models.dart';
import 'ai_repository.dart';

/// AI状态管理类
class AIProvider with ChangeNotifier {
  final AIRepository _repository;

  /// GPU信息列表
  List<GpuInfo> _gpuInfoList = [];

  /// Ollama模型列表
  List<OllamaModel> _ollamaModelList = [];

  /// Ollama模型下拉列表
  List<OllamaModelDropList> _ollamaModelDropList = [];

  /// 绑定域名信息
  OllamaBindDomainRes? _bindDomainInfo;

  /// 是否正在加载
  bool _isLoading = false;

  /// 错误信息
  String? _errorMessage;

  /// 获取GPU信息列表
  List<GpuInfo> get gpuInfoList => _gpuInfoList;

  /// 获取Ollama模型列表
  List<OllamaModel> get ollamaModelList => _ollamaModelList;

  /// 获取Ollama模型下拉列表
  List<OllamaModelDropList> get ollamaModelDropList => _ollamaModelDropList;

  /// 获取绑定域名信息
  OllamaBindDomainRes? get bindDomainInfo => _bindDomainInfo;

  /// 获取是否正在加载
  bool get isLoading => _isLoading;

  /// 获取错误信息
  String? get errorMessage => _errorMessage;

  /// 构造函数
  AIProvider({AIRepository? repository})
      : _repository = repository ?? AIRepository();

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 加载GPU/XPU信息
  ///
  /// 获取系统中的GPU或XPU信息
  Future<void> loadGpuInfo() async {
    _setLoading(true);
    _setError(null);

    try {
      _gpuInfoList = await _repository.loadGpuInfo();
      notifyListeners();
    } catch (e) {
      _setError('加载GPU信息失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 搜索Ollama模型
  ///
  /// 搜索Ollama模型列表
  /// @param page 页码
  /// @param pageSize 每页大小
  /// @param info 搜索信息
  Future<void> searchOllamaModels({
    required int page,
    required int pageSize,
    String? info,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _repository.searchOllamaModels(
        page: page,
        pageSize: pageSize,
        info: info,
      );
      _ollamaModelList = result.items;
      notifyListeners();
    } catch (e) {
      _setError('搜索Ollama模型失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 同步Ollama模型列表
  ///
  /// 同步Ollama模型列表
  Future<void> syncOllamaModels() async {
    _setLoading(true);
    _setError(null);

    try {
      _ollamaModelDropList = await _repository.syncOllamaModels();
      notifyListeners();
    } catch (e) {
      _setError('同步Ollama模型失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 获取绑定域名
  ///
  /// 获取当前AI服务绑定的域名信息
  /// @param appInstallId 应用安装ID
  Future<void> getBindDomain({
    required int appInstallId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      _bindDomainInfo = await _repository.getBindDomain(
        appInstallID: appInstallId,
      );
      notifyListeners();
    } catch (e) {
      _setError('获取绑定域名失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 绑定域名
  ///
  /// 为AI服务绑定域名
  /// @param appInstallId 应用安装ID
  /// @param domain 域名
  /// @param ipList IP列表
  /// @param sslId SSL证书ID
  /// @param websiteId 网站ID
  Future<void> bindDomain({
    required int appInstallId,
    String? domain,
    String? ipList,
    int? sslId,
    int? websiteId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _repository.bindDomain(
        appInstallID: appInstallId,
        domain: domain ?? '',
        ipList: ipList,
        sslID: sslId,
        websiteID: websiteId,
      );
      notifyListeners();
    } catch (e) {
      _setError('绑定域名失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 创建Ollama模型
  ///
  /// 创建一个新的Ollama模型
  /// @param name 模型名称
  /// @param taskId 任务ID
  Future<void> createOllamaModel({
    required String name,
    String? taskId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _repository.createOllamaModel(
        name: name,
        taskID: taskId,
      );
      notifyListeners();
    } catch (e) {
      _setError('创建Ollama模型失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 关闭Ollama模型连接
  ///
  /// 关闭指定Ollama模型的连接
  /// @param name 模型名称
  /// @param taskId 任务ID
  Future<void> closeOllamaModel({
    required String name,
    String? taskId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _repository.closeOllamaModel(
        name: name,
        taskID: taskId,
      );
      notifyListeners();
    } catch (e) {
      _setError('关闭Ollama模型失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 删除Ollama模型
  ///
  /// 删除指定的Ollama模型
  /// @param ids 模型ID列表
  /// @param forceDelete 是否强制删除
  Future<void> deleteOllamaModel({
    required List<int> ids,
    bool forceDelete = false,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _repository.deleteOllamaModel(
        ids: ids,
        forceDelete: forceDelete,
      );
      notifyListeners();
    } catch (e) {
      _setError('删除Ollama模型失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载Ollama模型
  ///
  /// 加载指定的Ollama模型
  /// @param name 模型名称
  /// @param taskId 任务ID
  Future<void> loadOllamaModel({
    required String name,
    String? taskId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _repository.loadOllamaModel(
        name: name,
        taskID: taskId,
      );
      notifyListeners();
    } catch (e) {
      _setError('加载Ollama模型失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 重新创建Ollama模型
  ///
  /// 重新创建指定的Ollama模型
  /// @param name 模型名称
  /// @param taskId 任务ID
  Future<void> recreateOllamaModel({
    required String name,
    String? taskId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _repository.recreateOllamaModel(
        name: name,
        taskID: taskId,
      );
      notifyListeners();
    } catch (e) {
      _setError('重新创建Ollama模型失败: $e');
    } finally {
      _setLoading(false);
    }
  }
}

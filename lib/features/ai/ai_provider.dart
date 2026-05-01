import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import '../../data/models/ai_models.dart';
import 'ai_repository.dart';

/// AI状态管理类
class AIProvider with ChangeNotifier, SafeChangeNotifier {
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

  /// 最近一次操作返回信息
  String? _lastOperationMessage;

  /// 当前操作的 appInstallId
  int _activeAppInstallId = 0;

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

  /// 获取最近一次操作返回信息
  String? get lastOperationMessage => _lastOperationMessage;

  /// 获取当前 appInstallId
  int get activeAppInstallId => _activeAppInstallId;

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

  void _setLastOperationMessage(String? message) {
    _lastOperationMessage = message;
    notifyListeners();
  }

  void setActiveAppInstallId(int appInstallId) {
    _activeAppInstallId = appInstallId;
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearLastOperationMessage() {
    _lastOperationMessage = null;
    notifyListeners();
  }

  /// 加载GPU/XPU信息
  ///
  /// 获取系统中的GPU或XPU信息
  Future<bool> loadGpuInfo() async {
    _setLoading(true);
    _setError(null);

    try {
      _gpuInfoList = await _repository.loadGpuInfo();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('加载GPU信息失败: $e');
      return false;
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
  Future<bool> searchOllamaModels({
    int page = 1,
    int pageSize = 20,
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
      return true;
    } catch (e) {
      _setError('搜索Ollama模型失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 同步Ollama模型列表
  ///
  /// 同步Ollama模型列表
  Future<bool> syncOllamaModels() async {
    _setLoading(true);
    _setError(null);

    try {
      _ollamaModelDropList = await _repository.syncOllamaModels();
      await searchOllamaModels();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('同步Ollama模型失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 获取绑定域名
  ///
  /// 获取当前AI服务绑定的域名信息
  /// @param appInstallId 应用安装ID
  Future<bool> getBindDomain({
    required int appInstallId,
  }) async {
    _activeAppInstallId = appInstallId;
    _setLoading(true);
    _setError(null);

    try {
      _bindDomainInfo = await _repository.getBindDomain(
        appInstallID: appInstallId,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _setError('获取绑定域名失败: $e');
      return false;
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
  Future<bool> bindDomain({
    required int appInstallId,
    String? domain,
    String? ipList,
    int? sslId,
    int? websiteId,
  }) async {
    _activeAppInstallId = appInstallId;
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
      await getBindDomain(appInstallId: appInstallId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('绑定域名失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 创建Ollama模型
  ///
  /// 创建一个新的Ollama模型
  /// @param name 模型名称
  /// @param taskId 任务ID
  Future<bool> createOllamaModel({
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
      await searchOllamaModels();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('创建Ollama模型失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 关闭Ollama模型连接
  ///
  /// 关闭指定Ollama模型的连接
  /// @param name 模型名称
  /// @param taskId 任务ID
  Future<bool> closeOllamaModel({
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
      await searchOllamaModels();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('关闭Ollama模型失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除Ollama模型
  ///
  /// 删除指定的Ollama模型
  /// @param ids 模型ID列表
  /// @param forceDelete 是否强制删除
  Future<bool> deleteOllamaModel({
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
      await searchOllamaModels();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('删除Ollama模型失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 加载Ollama模型
  ///
  /// 加载指定的Ollama模型
  /// @param name 模型名称
  /// @param taskId 任务ID
  Future<bool> loadOllamaModel({
    required String name,
    String? taskId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _repository.loadOllamaModel(
        name: name,
        taskID: taskId,
      );
      _setLastOperationMessage(result);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('加载Ollama模型失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 重新创建Ollama模型
  ///
  /// 重新创建指定的Ollama模型
  /// @param name 模型名称
  /// @param taskId 任务ID
  Future<bool> recreateOllamaModel({
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
      await searchOllamaModels();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('重新创建Ollama模型失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}

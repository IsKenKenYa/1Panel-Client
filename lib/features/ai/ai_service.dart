import 'package:dio/dio.dart';
import '../../api/v2/ai_v2.dart';
import '../../data/models/ai_models.dart';
import '../../data/models/common_models.dart';

/// AI服务类
class AIService {
  final AIV2Api _api;

  AIService(this._api);

  /// 绑定域名
  ///
  /// 为AI服务绑定域名
  /// @param request 绑定域名请求
  /// @return 绑定结果
  Future<Response> bindDomain(OllamaBindDomain request) async {
    try {
      return await _api.bindDomain(request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('绑定域名失败: $e');
    }
  }

  /// 获取绑定域名
  ///
  /// 获取当前AI服务绑定的域名信息
  /// @param request 获取绑定域名请求
  /// @return 域名信息
  Future<OllamaBindDomainRes> getBindDomain(OllamaBindDomainReq request) async {
    try {
      final response = await _api.getBindDomain(request);
      return response.data!;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('获取绑定域名失败: $e');
    }
  }

  /// 加载GPU/XPU信息
  ///
  /// 获取系统中的GPU或XPU信息
  /// @return GPU/XPU信息列表
  Future<List<GpuInfo>> loadGpuInfo() async {
    try {
      final response = await _api.loadGpuInfo();
      return response.data!;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('加载GPU信息失败: $e');
    }
  }

  /// 创建Ollama模型
  ///
  /// 创建一个新的Ollama模型
  /// @param request 模型名称请求
  /// @return 创建结果
  Future<Response> createOllamaModel(OllamaModelName request) async {
    try {
      return await _api.createOllamaModel(request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('创建Ollama模型失败: $e');
    }
  }

  /// 关闭Ollama模型连接
  ///
  /// 关闭指定Ollama模型的连接
  /// @param request 模型名称请求
  /// @return 操作结果
  Future<Response> closeOllamaModel(OllamaModelName request) async {
    try {
      return await _api.closeOllamaModel(request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('关闭Ollama模型失败: $e');
    }
  }

  /// 删除Ollama模型
  ///
  /// 删除指定的Ollama模型
  /// @param request 删除请求
  /// @return 删除结果
  Future<Response> deleteOllamaModel(ForceDelete request) async {
    try {
      return await _api.deleteOllamaModel(request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('删除Ollama模型失败: $e');
    }
  }

  /// 加载Ollama模型
  ///
  /// 加载指定的Ollama模型
  /// @param request 模型名称请求
  /// @return 加载结果
  Future<String> loadOllamaModel(OllamaModelName request) async {
    try {
      final response = await _api.loadOllamaModel(request);
      return response.data!;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('加载Ollama模型失败: $e');
    }
  }

  /// 重新创建Ollama模型
  ///
  /// 重新创建指定的Ollama模型
  /// @param request 模型名称请求
  /// @return 创建结果
  Future<Response> recreateOllamaModel(OllamaModelName request) async {
    try {
      return await _api.recreateOllamaModel(request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('重新创建Ollama模型失败: $e');
    }
  }

  /// 搜索Ollama模型
  ///
  /// 搜索Ollama模型列表
  /// @param request 搜索请求
  /// @return 搜索结果
  Future<PageResult<OllamaModel>> searchOllamaModels(
      SearchWithPage request) async {
    try {
      final response = await _api.searchOllamaModels(request);
      return response.data!;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('搜索Ollama模型失败: $e');
    }
  }

  /// 同步Ollama模型列表
  ///
  /// 同步Ollama模型列表
  /// @return 模型列表
  Future<List<OllamaModelDropList>> syncOllamaModels() async {
    try {
      final response = await _api.syncOllamaModels();
      return response.data!;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('同步Ollama模型失败: $e');
    }
  }

  /// 处理Dio异常
  ///
  /// 将Dio异常转换为更友好的错误信息
  /// @param error Dio异常
  /// @return 友好的错误信息
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return Exception('连接超时，请检查网络连接');
      case DioExceptionType.sendTimeout:
        return Exception('发送超时，请重试');
      case DioExceptionType.receiveTimeout:
        return Exception('接收超时，请重试');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return Exception('未授权，请重新登录');
        } else if (statusCode == 403) {
          return Exception('权限不足');
        } else if (statusCode == 404) {
          return Exception('资源不存在');
        } else if (statusCode == 500) {
          return Exception('服务器内部错误');
        } else {
          return Exception('请求失败: ${error.response?.data}');
        }
      case DioExceptionType.cancel:
        return Exception('请求已取消');
      case DioExceptionType.unknown:
        return Exception('网络错误，请检查网络连接');
      default:
        return Exception('未知错误');
    }
  }
}

import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/ai_models.dart';
import '../../data/models/mcp_models.dart';
import '../../data/models/common_models.dart';

class AIV2Api {
  final DioClient _client;

  AIV2Api(this._client);

  /// 绑定域名
  ///
  /// 为AI服务绑定域名
  /// @param request 绑定域名请求
  /// @return 绑定结果
  Future<Response> bindDomain(OllamaBindDomain request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/ai/domain/bind'),
      data: request.toJson(),
    );
  }

  /// 获取绑定域名
  ///
  /// 获取当前AI服务绑定的域名信息
  /// @param request 获取绑定域名请求
  /// @return 域名信息
  Future<Response<OllamaBindDomainRes>> getBindDomain(
      OllamaBindDomainReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/domain/get'),
      data: request.toJson(),
    );
    return Response(
      data: OllamaBindDomainRes.fromJson(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 加载GPU/XPU信息
  ///
  /// 获取系统中的GPU或XPU信息
  /// @return GPU/XPU信息
  Future<Response<List<GpuInfo>>> loadGpuInfo() async {
    final response =
        await _client.get(ApiConstants.buildApiPath('/ai/gpu/load'));
    return Response(
      data:
          (response.data as List?)?.map((i) => GpuInfo.fromJson(i)).toList() ??
              [],
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 创建Ollama模型
  ///
  /// 创建一个新的Ollama模型
  /// @param request 模型名称请求
  /// @return 创建结果
  Future<Response> createOllamaModel(OllamaModelName request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/ai/ollama/model'),
      data: request.toJson(),
    );
  }

  /// 关闭Ollama模型连接
  ///
  /// 关闭指定Ollama模型的连接
  /// @param request 模型名称请求
  /// @return 操作结果
  Future<Response> closeOllamaModel(OllamaModelName request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/ai/ollama/close'),
      data: request.toJson(),
    );
  }

  /// 删除Ollama模型
  ///
  /// 删除指定的Ollama模型
  /// @param request 删除请求
  /// @return 删除结果
  Future<Response> deleteOllamaModel(ForceDelete request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/ai/ollama/model/del'),
      data: request.toJson(),
    );
  }

  /// 加载Ollama模型
  ///
  /// 加载指定的Ollama模型
  /// @param request 模型名称请求
  /// @return 加载结果
  Future<Response<String>> loadOllamaModel(OllamaModelName request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/ollama/model/load'),
      data: request.toJson(),
    );
    return Response(
      data: response.data?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 重新创建Ollama模型
  ///
  /// 重新创建指定的Ollama模型
  /// @param request 模型名称请求
  /// @return 创建结果
  Future<Response> recreateOllamaModel(OllamaModelName request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/ai/ollama/model/recreate'),
      data: request.toJson(),
    );
  }

  /// 搜索Ollama模型
  ///
  /// 搜索Ollama模型列表
  /// @param request 搜索请求
  /// @return 搜索结果
  Future<Response<PageResult<OllamaModel>>> searchOllamaModels(
      SearchWithPage request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/ollama/model/search'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult<OllamaModel>.fromJson(response.data,
          (json) => OllamaModel.fromJson(json as Map<String, dynamic>)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 同步Ollama模型列表
  ///
  /// 同步Ollama模型列表
  /// @return 模型列表
  Future<Response<List<OllamaModelDropList>>> syncOllamaModels() async {
    final response =
        await _client.post(ApiConstants.buildApiPath('/ai/ollama/model/sync'));
    return Response(
      data: (response.data as List?)
              ?.map((i) => OllamaModelDropList.fromJson(i))
              .toList() ??
          [],
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // ==================== MCP 服务器管理 ====================

  /// 绑定MCP域名
  ///
  /// 为MCP服务器绑定域名
  /// @param request 绑定域名请求
  /// @return 绑定结果
  Future<Response> bindMcpDomain(McpBindDomain request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/ai/mcp/domain/bind'),
      data: request.toJson(),
    );
  }

  /// 获取MCP绑定域名
  ///
  /// 获取当前MCP服务器绑定的域名信息
  /// @return 域名信息
  Future<Response<McpBindDomainRes>> getMcpBindDomain() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/ai/mcp/domain/get'),
    );
    return Response(
      data: McpBindDomainRes.fromJson(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新MCP绑定域名
  ///
  /// 更新MCP服务器的域名绑定
  /// @param request 更新域名请求
  /// @return 更新结果
  Future<Response> updateMcpDomain(McpBindDomainUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/ai/mcp/domain/update'),
      data: request.toJson(),
    );
  }

  /// 搜索MCP服务器
  ///
  /// 搜索MCP服务器列表
  /// @param request 搜索请求
  /// @return 搜索结果
  Future<Response<McpServersRes>> searchMcpServers(
      McpServerSearch request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/mcp/search'),
      data: request.toJson(),
    );
    return Response(
      data: McpServersRes.fromJson(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 创建MCP服务器
  ///
  /// 创建一个新的MCP服务器
  /// @param request 创建请求
  /// @return 创建结果
  Future<Response> createMcpServer(McpServerCreate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/ai/mcp/server'),
      data: request.toJson(),
    );
  }

  /// 删除MCP服务器
  ///
  /// 删除指定的MCP服务器
  /// @param request 删除请求
  /// @return 删除结果
  Future<Response> deleteMcpServer(McpServerDelete request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/ai/mcp/server/del'),
      data: request.toJson(),
    );
  }

  /// 操作MCP服务器
  ///
  /// 对MCP服务器进行操作（启动/停止/重启等）
  /// @param request 操作请求
  /// @return 操作结果
  Future<Response> operateMcpServer(McpServerOperate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/ai/mcp/server/op'),
      data: request.toJson(),
    );
  }

  /// 更新MCP服务器
  ///
  /// 更新MCP服务器配置
  /// @param request 更新请求
  /// @return 更新结果
  Future<Response> updateMcpServer(McpServerUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/ai/mcp/server/update'),
      data: request.toJson(),
    );
  }
}

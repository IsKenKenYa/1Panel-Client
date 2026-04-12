import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/monitoring_models.dart';
import '../../data/models/common_models.dart';
import 'api_response_parser.dart';

/// Dashboard V2 API客户端
///
/// 基于docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json规范实现
/// 包含12个端点：8个GET + 4个POST
class DashboardV2Api {
  final DioClient _client;

  DashboardV2Api(this._client);

  // ==================== 基础信息模块 (2个端点) ====================

  /// 获取仪表盘基础信息
  ///
  /// GET /dashboard/base/:ioOption/:netOption
  /// @param ioOption IO选项 (default/custom)
  /// @param netOption 网络选项 (default/custom)
  /// @return 基础指标数据
  Future<Response<Map<String, dynamic>>> getDashboardBase({
    String? ioOption,
    String? netOption,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath(
          '/dashboard/base/${ioOption ?? 'default'}/${netOption ?? 'default'}'),
    );
    return Response(
      data: ApiResponseParser.extractMapData(response),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取操作系统信息
  ///
  /// GET /dashboard/base/os
  /// @return 操作系统信息
  Future<Response<SystemInfo>> getOperatingSystemInfo() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/dashboard/base/os'),
    );
    return Response(
      data: ApiResponseParser.extractData(response, SystemInfo.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // ==================== 实时监控模块 (4个端点) ====================

  /// 获取当前实时指标
  ///
  /// GET /dashboard/current/:ioOption/:netOption
  /// @param ioOption IO选项 (default/custom)
  /// @param netOption 网络选项 (default/custom)
  /// @return 当前指标数据
  Future<Response<SystemMetrics>> getCurrentMetrics({
    String? ioOption,
    String? netOption,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath(
          '/dashboard/current/${ioOption ?? 'default'}/${netOption ?? 'default'}'),
    );
    return Response(
      data: ApiResponseParser.extractData(response, SystemMetrics.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取实时指标 (不带基础信息，仅更新)
  Future<Response> getCurrentMetricsBase(String ioOption, String netOption) async {
    return await _client.get(
      ApiConstants.buildApiPath('/dashboard/current/$ioOption/$netOption'),
    );
  }

  /// 获取仪表盘基础信息 (带详细)
  Future<Response> getDashboardBaseDetailed(String ioOption, String netOption) async {
    return await _client.get(
      ApiConstants.buildApiPath('/dashboard/base/$ioOption/$netOption'),
    );
  }

  /// 获取当前节点信息
  ///
  /// GET /dashboard/current/node
  /// @return 节点信息
  Future<Response<Map<String, dynamic>>> getCurrentNode() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/dashboard/current/node'),
    );
    return Response(
      data: ApiResponseParser.extractMapData(response),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取CPU占用Top进程
  ///
  /// GET /dashboard/current/top/cpu
  /// @return Top CPU进程列表
  Future<Response<dynamic>> getTopCPUProcesses() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/dashboard/current/top/cpu'),
    );
    return Response(
      data: ApiResponseParser.extractDynamicData(response),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取内存占用Top进程
  ///
  /// GET /dashboard/current/top/mem
  /// @return Top内存进程列表
  Future<Response<dynamic>> getTopMemoryProcesses() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/dashboard/current/top/mem'),
    );
    return Response(
      data: ApiResponseParser.extractDynamicData(response),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // ==================== 应用启动器模块 (3个端点) ====================

  /// 获取应用启动器列表
  ///
  /// GET /dashboard/app/launcher
  /// @return 应用启动器列表
  Future<Response<List<dynamic>>> getAppLauncher() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/dashboard/app/launcher'),
    );
    return Response(
      data: ApiResponseParser.extractListData(response),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取应用启动器选项
  ///
  /// POST /dashboard/app/launcher/option
  /// @param request 请求参数
  /// @return 应用启动器选项
  Future<Response<List<dynamic>>> getAppLauncherOption({
    Map<String, dynamic>? request,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/dashboard/app/launcher/option'),
      data: request,
    );
    return Response(
      data: ApiResponseParser.extractListData(response),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新应用启动器展示
  ///
  /// POST /dashboard/app/launcher/show
  /// @param request 请求参数
  /// @return 操作结果
  Future<Response<dynamic>> updateAppLauncherShow({
    Map<String, dynamic>? request,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/dashboard/app/launcher/show'),
      data: request,
    );
    return Response(
      data: ApiResponseParser.extractDynamicData(response),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // ==================== 快捷跳转模块 (2个端点) ====================

  /// 获取快捷跳转选项
  ///
  /// GET /dashboard/quick/option
  /// @return 快捷跳转选项列表
  Future<Response<List<dynamic>>> getQuickOption() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/dashboard/quick/option'),
    );
    return Response(
      data: ApiResponseParser.extractListData(response),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新快捷跳转配置
  ///
  /// POST /dashboard/quick/change
  /// @param request 请求参数
  /// @return 操作结果
  Future<Response<Map<String, dynamic>>> updateQuickChange({
    Map<String, dynamic>? request,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/dashboard/quick/change'),
      data: request,
    );
    return Response(
      data: ApiResponseParser.extractMapData(response),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // ==================== 系统操作模块 (1个端点) ====================

  /// 系统重启/关机操作
  ///
  /// POST /dashboard/system/restart/:operation
  /// @param operation 操作类型 (restart/shutdown)
  /// @return 操作结果
  Future<Response<Map<String, dynamic>>> systemRestart(String operation) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/dashboard/system/restart/$operation'),
    );
    return Response(
      data: ApiResponseParser.extractMapData(response),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }
}

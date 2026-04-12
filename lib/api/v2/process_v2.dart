import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/process_detail_models.dart';
import '../../data/models/process_models.dart';

class ProcessV2Api {
  ProcessV2Api(this._client);

  final DioClient _client;

  Future<Response<void>> stopProcess(ProcessStopRequest request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/process/stop'),
      data: request.toJson(),
    );
  }

  Future<Response<ProcessDetail>> getProcessByPid(int pid) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/process/$pid'),
    );
    return Response<ProcessDetail>(
      data: ProcessDetail.fromJson(
        response.data?['data'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<List<ListeningProcess>>> getListeningProcesses() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/process/listening'),
    );
    final rawItems = response.data?['data'] as List<dynamic>? ?? const [];
    return Response<List<ListeningProcess>>(
      data: rawItems
          .whereType<Map<String, dynamic>>()
          .map(ListeningProcess.fromJson)
          .toList(growable: false),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // ==================== Supervisor 相关配置模块 ====================

  /// 获取 Supervisor 进程配置 (宿主机)
  Future<Response<void>> getHostSupervisorProcess() async {
    return await _client.get<void>(
      ApiConstants.buildApiPath('/hosts/tool/supervisor/process'),
    );
  }

  /// 创建/更新 Supervisor 进程配置 (宿主机)
  Future<Response<void>> saveHostSupervisorProcess(Map<String, dynamic> request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/tool/supervisor/process'),
      data: request,
    );
  }

  /// 更新 Supervisor 进程文件 (宿主机)
  Future<Response<void>> saveHostSupervisorProcessFile(Map<String, dynamic> request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/tool/supervisor/process/file'),
      data: request,
    );
  }

  /// 获取 Supervisor 进程配置 (运行时环境)
  Future<Response<void>> getRuntimeSupervisorProcess(String runtimeName) async {
    return await _client.get<void>(
      ApiConstants.buildApiPath('/runtimes/supervisor/process/$runtimeName'),
    );
  }

  /// 创建/更新 Supervisor 进程配置 (运行时环境)
  Future<Response<void>> saveRuntimeSupervisorProcess(Map<String, dynamic> request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/runtimes/supervisor/process'),
      data: request,
    );
  }

  /// 更新 Supervisor 进程文件 (运行时环境)
  Future<Response<void>> saveRuntimeSupervisorProcessFile(Map<String, dynamic> request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/runtimes/supervisor/process/file'),
      data: request,
    );
  }
}

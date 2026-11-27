import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/task_log_models.dart';
import '../../data/models/common_models.dart';
import '../../data/models/file/file_read_by_line.dart';

/// 1Panel task log API client.
///
/// Queries executing task count and paginated task log search.
class TaskLogV2Api {
  final DioClient _client;

  TaskLogV2Api(this._client);

  Future<Response<int>> getExecutingTaskCount() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/logs/tasks/executing/count'),
    );
    return Response(
      data: response.data?['data'] as int? ?? 0,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<PageResult<TaskLog>>> searchTaskLogs(
      TaskLogSearch request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/logs/tasks/search'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? {},
        (dynamic item) => TaskLog.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// `POST /logs/tasks/read`：按行读取任务日志，支持最新优先与页码。
  Future<Response<FileReadByLineResponse>> readTaskLog(
    TaskLogReadRequest request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/logs/tasks/read'),
      data: request.toJson(),
    );
    final wrapper = response.data ?? const <String, dynamic>{};
    final data = wrapper['data'] as Map<String, dynamic>? ?? wrapper;
    return Response<FileReadByLineResponse>(
      data: FileReadByLineResponse.fromJson(data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }
}

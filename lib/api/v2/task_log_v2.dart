import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/task_log_models.dart';
import '../../data/models/common_models.dart';

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
}

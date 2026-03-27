import 'package:onepanel_client/api/v2/task_log_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/task_log_models.dart';

class TaskLogRepository {
  TaskLogRepository({
    ApiClientManager? clientManager,
    TaskLogV2Api? api,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api;

  final ApiClientManager _clientManager;
  TaskLogV2Api? _api;

  Future<TaskLogV2Api> _ensureApi() async {
    return _api ??= await _clientManager.getTaskLogApi();
  }

  Future<PageResult<TaskLog>> searchTaskLogs(TaskLogSearch request) async {
    final api = await _ensureApi();
    final response = await api.searchTaskLogs(request);
    return response.data ??
        const PageResult<TaskLog>(items: <TaskLog>[], total: 0);
  }

  Future<int> loadExecutingTaskCount() async {
    final api = await _ensureApi();
    final response = await api.getExecutingTaskCount();
    return response.data ?? 0;
  }
}

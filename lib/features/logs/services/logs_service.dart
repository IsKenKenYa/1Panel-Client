import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/data/models/logs_models.dart';
import 'package:onepanel_client/data/models/task_log_models.dart';
import 'package:onepanel_client/data/repositories/logs_repository.dart';
import 'package:onepanel_client/data/repositories/task_log_repository.dart';

class LogsService {
  LogsService({
    LogsRepository? logsRepository,
    TaskLogRepository? taskLogRepository,
  })  : _logsRepository = logsRepository ?? LogsRepository(),
        _taskLogRepository = taskLogRepository ?? TaskLogRepository();

  final LogsRepository _logsRepository;
  final TaskLogRepository _taskLogRepository;

  Future<PageResult<OperationLogEntry>> searchOperationLogs(
    OperationLogSearchRequest request,
  ) {
    return _logsRepository.searchOperationLogs(request);
  }

  Future<PageResult<LoginLogEntry>> searchLoginLogs(
    LoginLogSearchRequest request,
  ) {
    return _logsRepository.searchLoginLogs(request);
  }

  Future<List<String>> loadSystemLogFiles() {
    return _logsRepository.loadSystemLogFiles();
  }

  Future<PageResult<TaskLog>> searchTaskLogs(TaskLogSearch request) {
    return _taskLogRepository.searchTaskLogs(request);
  }

  Future<int> loadExecutingTaskCount() {
    return _taskLogRepository.loadExecutingTaskCount();
  }

  Future<FileReadByLineResponse> loadSystemLogContent({
    required String fileName,
    bool useCoreLogs = false,
    int page = 1,
    int pageSize = 200,
    bool latest = true,
  }) {
    final effectiveName = useCoreLogs ? 'Core-$fileName' : fileName;
    return _logsRepository.readLogLines(
      FileReadByLineRequest(
        type: 'system',
        name: effectiveName,
        page: page,
        pageSize: pageSize,
        latest: latest,
      ),
    );
  }

  Future<FileReadByLineResponse> loadTaskLogContent({
    required String taskId,
    String? taskType,
    String? taskOperate,
    int? resourceId,
    int page = 1,
    int pageSize = 200,
    bool latest = true,
  }) {
    return _logsRepository.readLogLines(
      FileReadByLineRequest(
        type: 'task',
        taskId: taskId,
        taskType: taskType,
        taskOperate: taskOperate,
        resourceId: resourceId,
        page: page,
        pageSize: pageSize,
        latest: latest,
      ),
    );
  }
}

import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/paged_query.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/data/models/logs_models.dart';
import 'package:onepanel_client/data/models/system_log_models.dart';
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

  Future<SystemLogStatus> loadSystemLogStatus() {
    return _logsRepository.loadSystemLogStatus();
  }

  Future<List<String>> loadRunningServices() {
    return _logsRepository.loadRunningServices();
  }

  Future<SystemLogPage> readSystemLogs(SystemLogSearch request) {
    return _logsRepository.readSystemLogs(request);
  }

  Future<PageResult<TaskLog>> searchTaskLogs(TaskLogSearch request) {
    return _taskLogRepository.searchTaskLogs(request);
  }

  Future<int> loadExecutingTaskCount() {
    return _taskLogRepository.loadExecutingTaskCount();
  }

  /// 读取单个系统日志文件的按行内容，对应 `/files/read/system`。
  ///
  /// 与 [readSystemLogs] 的条目查询是两条入口：前者用于按文件查看原始行，
  /// 后者用于按服务、级别与关键字查询宿主日志条目。
  Future<FileReadByLineResponse> loadSystemLogContent({
    required String fileName,
    bool useCoreLogs = false,
    int page = 1,
    int pageSize = PagedQuery.logPageSize,
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

  /// 按行读取任务日志，对应 `POST /logs/tasks/read`。
  Future<FileReadByLineResponse> loadTaskLogContent({
    required String taskId,
    String? taskType,
    String? taskOperate,
    int? resourceId,
    int page = 1,
    int pageSize = PagedQuery.logPageSize,
    bool latest = true,
  }) {
    return _taskLogRepository.readTaskLog(
      TaskLogReadRequest(
        page: page,
        pageSize: pageSize,
        latest: latest,
        taskId: taskId,
        taskType: taskType,
        taskOperate: taskOperate,
        resourceId: resourceId,
      ),
    );
  }
}

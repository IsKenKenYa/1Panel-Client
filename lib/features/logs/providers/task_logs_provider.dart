import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/task_log_models.dart';
import 'package:onepanel_client/features/logs/models/task_log_detail_args.dart';
import 'package:onepanel_client/features/logs/services/logs_service.dart';

class TaskLogsProvider extends ChangeNotifier with SafeChangeNotifier {
  TaskLogsProvider({
    LogsService? service,
  }) : _service = service ?? LogsService();

  final LogsService _service;

  List<TaskLog> _items = const <TaskLog>[];
  bool _isLoading = false;
  String? _errorMessage;
  String _typeFilter = '';
  String _statusFilter = '';
  int _executingCount = 0;

  TaskLogDetailArgs? _detailArgs;
  bool _detailLoading = false;
  String? _detailError;
  String _detailContent = '';
  String _detailPath = '';

  List<TaskLog> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !_isLoading && _errorMessage == null && _items.isEmpty;
  String get typeFilter => _typeFilter;
  String get statusFilter => _statusFilter;
  int get executingCount => _executingCount;

  TaskLogDetailArgs? get detailArgs => _detailArgs;
  bool get detailLoading => _detailLoading;
  String? get detailError => _detailError;
  String get detailContent => _detailContent;
  String get detailPath => _detailPath;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _service.searchTaskLogs(
          TaskLogSearch(
            type: _typeFilter.trim().isEmpty ? null : _typeFilter.trim(),
            status: _statusFilter.trim().isEmpty ? null : _statusFilter.trim(),
          ),
        ),
        _service.loadExecutingTaskCount(),
      ]);
      _items = (results[0] as PageResult<TaskLog>).items;
      _executingCount = results[1] as int;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.logs.providers.task_logs',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _items = const <TaskLog>[];
      _executingCount = 0;
      _errorMessage = 'logs.task.loadFailed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initializeDetail(TaskLogDetailArgs args) async {
    _detailArgs = args;
    await loadDetail();
  }

  Future<void> loadDetail() async {
    final args = _detailArgs;
    if (args == null || args.taskId.trim().isEmpty) {
      _detailContent = '';
      _detailPath = '';
      _detailError = 'logs.task.missingTaskId';
      notifyListeners();
      return;
    }

    _detailLoading = true;
    _detailError = null;
    notifyListeners();
    try {
      final result = await _service.loadTaskLogContent(
        taskId: args.taskId,
        taskType: args.taskType,
        taskOperate: args.taskOperate,
        resourceId: args.resourceId,
      );
      _detailContent = result.lines.join('\n');
      _detailPath = result.path;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.logs.providers.task_logs',
        'loadDetail failed',
        error: error,
        stackTrace: stackTrace,
      );
      _detailContent = '';
      _detailPath = '';
      _detailError = 'logs.task.detailLoadFailed';
    } finally {
      _detailLoading = false;
      notifyListeners();
    }
  }

  void updateTypeFilter(String value) {
    _typeFilter = value;
    notifyListeners();
  }

  void updateStatusFilter(String value) {
    _statusFilter = value;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/features/toolbox/services/toolbox_clam_service.dart';

class ToolboxClamProvider extends ChangeNotifier with SafeChangeNotifier {
  ToolboxClamProvider({ToolboxClamService? service})
      : _service = service ?? ToolboxClamService();

  final ToolboxClamService _service;

  static const int _taskPageSize = 20;
  static const int _recordPageSize = 20;

  bool _isLoading = false;
  bool _isMutating = false;
  String? _error;
  String _taskKeyword = '';
  int _taskPage = 1;
  int _recordPage = 1;
  bool _hasMoreTasks = false;
  bool _hasMoreRecords = false;
  int? _selectedTaskId;
  List<ClamBaseInfo> _tasks = const <ClamBaseInfo>[];
  List<ClamLogInfo> _records = const <ClamLogInfo>[];

  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get error => _error;
  String get taskKeyword => _taskKeyword;
  int get taskPage => _taskPage;
  int get recordPage => _recordPage;
  bool get hasMoreTasks => _hasMoreTasks;
  bool get hasMoreRecords => _hasMoreRecords;
  int? get selectedTaskId => _selectedTaskId;
  List<ClamBaseInfo> get tasks {
    final keyword = _taskKeyword.toLowerCase();
    if (keyword.isEmpty) {
      return _tasks;
    }
    return _tasks
        .where(
          (item) => (item.name ?? '').toLowerCase().contains(keyword),
        )
        .toList(growable: false);
  }

  List<ClamBaseInfo> get allTasks => _tasks;
  List<ClamLogInfo> get records => _records;

  ClamBaseInfo? get selectedTask {
    for (final item in _tasks) {
      if (item.id == _selectedTaskId) {
        return item;
      }
    }
    return null;
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final snapshot = await _service.loadSnapshot(
        taskPage: _taskPage,
        taskPageSize: _taskPageSize,
        recordPage: _recordPage,
        recordPageSize: _recordPageSize,
        selectedTaskId: _selectedTaskId,
      );
      _tasks = snapshot.tasks;
      _records = snapshot.records;
      _selectedTaskId = snapshot.selectedTaskId;
      _hasMoreTasks = snapshot.tasks.length >= _taskPageSize;
      _hasMoreRecords = snapshot.records.length >= _recordPageSize;
      _error = null;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_clam',
        'load clam failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTaskKeyword(String keyword) {
    _taskKeyword = keyword.trim();
    notifyListeners();
  }

  Future<void> selectTask(int? taskId) async {
    if (taskId == null || taskId == _selectedTaskId) {
      return;
    }
    _selectedTaskId = taskId;
    _recordPage = 1;
    await load(silent: true);
  }

  Future<void> nextTaskPage() async {
    if (!_hasMoreTasks) {
      return;
    }
    _taskPage += 1;
    await load();
  }

  Future<void> previousTaskPage() async {
    if (_taskPage <= 1) {
      return;
    }
    _taskPage -= 1;
    await load();
  }

  Future<void> nextRecordPage() async {
    if (!_hasMoreRecords || _selectedTaskId == null) {
      return;
    }
    _recordPage += 1;
    await load();
  }

  Future<void> previousRecordPage() async {
    if (_recordPage <= 1 || _selectedTaskId == null) {
      return;
    }
    _recordPage -= 1;
    await load();
  }

  Future<bool> createTask(ClamCreate request) {
    return _runMutation(action: () => _service.createTask(request));
  }

  Future<bool> updateTask(ClamUpdate request) {
    return _runMutation(action: () => _service.updateTask(request));
  }

  Future<bool> deleteTask(
    int id, {
    bool removeInfected = false,
  }) {
    return _runMutation(
      action: () => _service.deleteTasks(
        ids: <int>[id],
        removeInfected: removeInfected,
      ),
    );
  }

  Future<bool> handleTask(int id) {
    return _runMutation(action: () => _service.handleTask(id));
  }

  Future<bool> operateService(String operation) {
    return _runMutation(action: () => _service.operateService(operation));
  }

  Future<bool> cleanRecords(int taskId) {
    return _runMutation(action: () => _service.cleanRecords(taskId));
  }

  Future<bool> _runMutation({
    required Future<void> Function() action,
    bool reload = true,
  }) async {
    _isMutating = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      if (reload) {
        await load(silent: true);
      }
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_clam',
        'clam mutation failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}

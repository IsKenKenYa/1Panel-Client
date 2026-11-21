import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'toolbox_snapshot_provider.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/features/toolbox/services/toolbox_clam_service.dart';

class ToolboxClamProvider extends ToolboxSnapshotProvider {
  ToolboxClamProvider({ToolboxClamService? service, String? serverId})
      : _service = service ?? ToolboxClamService(serverId: serverId);

  final ToolboxClamService _service;

  static const int _taskPageSize = 20;
  static const int _recordPageSize = 20;

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

  bool get isMutating => _isMutating;
  String? get error => _error ?? loadError;
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

  // ── 配置文件（对齐前端 clam/setting：clamd/freshclam/clamd-log/freshclam-log）──
  static const List<String> clamFileNames = <String>[
    'clamd',
    'freshclam',
    'clamd-log',
    'freshclam-log',
  ];

  String _selectedClamFileName = 'clamd';
  String _clamFileContent = '';
  bool _isLoadingFile = false;
  bool _isSavingFile = false;

  String get selectedClamFileName => _selectedClamFileName;
  String get clamFileContent => _clamFileContent;
  bool get isLoadingFile => _isLoadingFile;
  bool get isSavingFile => _isSavingFile;
  bool get isClamLogFile => _selectedClamFileName.endsWith('-log');

  Future<void> selectClamFile(String name) async {
    _selectedClamFileName = name;
    await loadClamFile();
  }

  Future<void> loadClamFile() async {
    if (isDisposed) return;
    _isLoadingFile = true;
    notifyListeners();
    try {
      final lines = await _service.loadClamFileLines(
        name: _selectedClamFileName,
        tail: '200',
      );
      _clamFileContent = lines
          .map((line) => line.name ?? '')
          .join('\n');
    } catch (error, stackTrace) {
      _clamFileContent = '';
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_clam',
        'load clam file failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isLoadingFile = false;
      notifyListeners();
    }
  }

  Future<bool> saveClamFile(String content) async {
    if (isDisposed) return false;
    _isSavingFile = true;
    notifyListeners();
    try {
      await _service.saveClamFile(
        name: _selectedClamFileName,
        file: content,
      );
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_clam',
        'save clam file failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = ErrorMessageUtils.userFacingMessage(error);
      return false;
    } finally {
      _isSavingFile = false;
      notifyListeners();
    }
  }

  ClamBaseInfo? get selectedTask {
    for (final item in _tasks) {
      if (item.id == _selectedTaskId) {
        return item;
      }
    }
    return null;
  }

  Future<void> load({bool silent = false}) {
    _error = null;
    return loadSnapshot(
      fetch: () => _service.loadSnapshot(
        taskPage: _taskPage,
        taskPageSize: _taskPageSize,
        recordPage: _recordPage,
        recordPageSize: _recordPageSize,
        selectedTaskId: _selectedTaskId,
      ),
      apply: (snapshot) {
        _tasks = snapshot.tasks;
        _records = snapshot.records;
        _selectedTaskId = snapshot.selectedTaskId;
        _hasMoreTasks = snapshot.tasks.length >= _taskPageSize;
        _hasMoreRecords = snapshot.records.length >= _recordPageSize;
      },
      logPackage: 'features.toolbox.providers.toolbox_clam',
      silent: silent,
    );
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
    if (isDisposed) return false;
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
      _error = ErrorMessageUtils.userFacingMessage(error);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}

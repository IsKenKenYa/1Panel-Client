import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/system_log_models.dart';
import 'package:onepanel_client/features/logs/services/logs_service.dart';

/// 宿主系统日志的条目查询状态。
///
/// 对应上游 `/logs/system` 页面：服务端游标分页，只前进与回退各一页，
/// 状态接口决定关键字筛选是否可用，服务列表供应筛选下拉。
class SystemLogEntriesProvider extends ChangeNotifier with SafeChangeNotifier {
  SystemLogEntriesProvider({
    LogsService? service,
  }) : _service = service ?? LogsService();

  final LogsService _service;

  SystemLogStatus? _status;
  List<String> _services = const <String>[];

  List<SystemLogEntry> _entries = const <SystemLogEntry>[];
  bool _loading = false;
  String? _errorMessage;

  String _keyword = '';
  String _priority = '';
  String _serviceFilter = '';
  String? _startTime;
  String? _endTime;

  /// 已加载页的游标栈：首屏为空字符串，翻页时在其基础上追加。
  final List<String> _cursorStack = <String>[''];
  int _cursorIndex = 0;
  bool _hasMore = false;

  SystemLogStatus? get status => _status;
  List<String> get services => _services;
  List<SystemLogEntry> get entries => _entries;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !_loading && _errorMessage == null && _entries.isEmpty;

  String get keyword => _keyword;
  String get priority => _priority;
  String get serviceFilter => _serviceFilter;
  String? get startTime => _startTime;
  String? get endTime => _endTime;

  bool get canFilterByKeyword => _status?.canFilterByKeyword ?? false;
  bool get hasMore => _hasMore;
  bool get canGoPrevious => _cursorIndex > 0;
  bool get canGoNext => _hasMore;

  /// 首屏加载：状态、服务列表与第一页条目并行获取。
  Future<void> initialize() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _service.loadSystemLogStatus(),
        _service.loadRunningServices(),
      ]);
      _status = results[0] as SystemLogStatus;
      _services = results[1] as List<String>;
      _cursorStack
        ..clear()
        ..add('');
      _cursorIndex = 0;
      final page = await _service.readSystemLogs(_buildSearch(cursor: ''));
      _entries = page.items;
      _hasMore = page.hasMore;
      _rememberNextCursor(page.nextCursor);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.logs.providers.system_log_entries',
        'initialize failed',
        error: error,
        stackTrace: stackTrace,
      );
      _entries = const <SystemLogEntry>[];
      _hasMore = false;
      _errorMessage = 'logs.system.entriesLoadFailed';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 修改筛选条件后从第一页重新查询。
  Future<void> applyFilters({
    String? keyword,
    String? priority,
    String? service,
    String? startTime,
    String? endTime,
  }) async {
    if (keyword != null) _keyword = keyword;
    if (priority != null) _priority = priority;
    if (service != null) _serviceFilter = service;
    if (startTime != null) _startTime = startTime.isEmpty ? null : startTime;
    if (endTime != null) _endTime = endTime.isEmpty ? null : endTime;
    _cursorStack
      ..clear()
      ..add('');
    _cursorIndex = 0;
    await _loadCursor('');
  }

  Future<void> loadNextPage() async {
    if (!_hasMore) return;
    final next = _cursorIndex + 1;
    if (next >= _cursorStack.length) return;
    _cursorIndex = next;
    await _loadCursor(_cursorStack[_cursorIndex]);
  }

  Future<void> loadPreviousPage() async {
    if (!_canGoPreviousCursor) return;
    _cursorIndex -= 1;
    await _loadCursor(_cursorStack[_cursorIndex]);
  }

  /// 刷新当前页。
  Future<void> reload() => _loadCursor(_cursorStack[_cursorIndex]);

  bool get _canGoPreviousCursor => _cursorIndex > 0;

  Future<void> _loadCursor(String cursor) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final page = await _service.readSystemLogs(_buildSearch(cursor: cursor));
      _entries = page.items;
      _hasMore = page.hasMore;
      _rememberNextCursor(page.nextCursor);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.logs.providers.system_log_entries',
        'readSystemLogs failed',
        error: error,
        stackTrace: stackTrace,
      );
      _entries = const <SystemLogEntry>[];
      _hasMore = false;
      _errorMessage = 'logs.system.entriesLoadFailed';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 追加下一页游标，供后续 `loadNextPage` 使用。
  void _rememberNextCursor(String? nextCursor) {
    if (nextCursor == null || nextCursor.isEmpty) return;
    final position = _cursorIndex + 1;
    if (_cursorStack.length > position) {
      _cursorStack[position] = nextCursor;
    } else {
      _cursorStack.add(nextCursor);
    }
  }

  SystemLogSearch _buildSearch({required String cursor}) {
    return SystemLogSearch(
      cursor: cursor,
      keyword: _keyword.trim().isEmpty ? null : _keyword.trim(),
      priority: _priority.isEmpty ? null : _priority,
      service: _serviceFilter.isEmpty ? null : _serviceFilter,
      startTime: _startTime,
      endTime: _endTime,
    );
  }
}

part of 'dashboard_provider.dart';

extension DashboardProviderLoading on DashboardProvider {
  Future<void> loadData({bool silent = false, bool liveOnly = false}) {
    if (isDisposed) return Future.value();
    final pending = _dashboardLoad;
    if (pending != null) {
      if (!liveOnly && _loadingLive) _needsBase = true;
      return pending;
    }
    _loadingLive = liveOnly && _status == DashboardStatus.loaded;
    final operation =
        Future.microtask(() => _loadDashboard(silent)).whenComplete(() {
      _dashboardLoad = null;
    });
    _dashboardLoad = operation;
    if (silent) {
      _isRefreshing = true;
    } else {
      _status = DashboardStatus.loading;
    }
    _emitChange();
    return operation;
  }

  Future<void> _loadDashboard(bool silent) async {
    Future<void>? processes;
    try {
      if (isDisposed) return;
      if (_status == DashboardStatus.loaded &&
          (!_hasOpened || _visiblePages.isNotEmpty)) {
        processes = loadTopProcesses();
      }
      final next = _loadingLive && !_needsBase
          ? await _service.loadLiveData(_data)
          : await _loadBase();
      if (isDisposed) return;
      _publishSnapshot(next);
      if (processes == null && (!_hasOpened || _visiblePages.isNotEmpty)) {
        processes = loadTopProcesses();
      }
      if (processes != null) await processes;
      if (_needsBase && !isDisposed) {
        final base = await _loadBase();
        if (!isDisposed) _publishSnapshot(base);
      }
    } catch (e, stackTrace) {
      if (isDisposed) return;
      _errorMessage = _recordError('loadData', e, stackTrace, _errorMessage);
      if (!silent || _status != DashboardStatus.loaded) {
        _status = DashboardStatus.error;
      }
      if (processes != null) await processes;
    } finally {
      _loadingLive = false;
      _needsBase = false;
      _isRefreshing = false;
      _emitChange();
    }
  }

  Future<DashboardData> _loadBase() {
    _loadingLive = false;
    _needsBase = false;
    return _service.loadDashboardData();
  }

  void _publishSnapshot(DashboardData next) {
    _data = next.copyWith(
      nodeInfo: _data.nodeInfo,
      topCpuProcesses: _data.topCpuProcesses,
      topMemoryProcesses: _data.topMemoryProcesses,
      appLaunchers: _data.appLaunchers,
      appLauncherOptions: _data.appLauncherOptions,
      quickOptions: _data.quickOptions,
    );
    _lastLoad = DateTime.now();
    _status = DashboardStatus.loaded;
    _errorMessage = '';
    _emitChange();
  }

  Future<void> loadTopProcesses() {
    if (isDisposed) return Future.value();
    final pending = _processLoad;
    if (pending != null) return pending;
    final operation = Future.microtask(_loadProcesses).whenComplete(() {
      _processLoad = null;
    });
    _processLoad = operation;
    _isLoadingTopProcesses = true;
    _emitChange();
    return operation;
  }

  Future<void> _loadProcesses() async {
    try {
      if (isDisposed) return;
      final result = await _service.loadTopProcesses();
      if (isDisposed) return;
      _processError = '';
      if (!listEquals(_data.topCpuProcesses, result.cpu) ||
          !listEquals(_data.topMemoryProcesses, result.memory)) {
        _data = _data.copyWith(
          topCpuProcesses: result.cpu,
          topMemoryProcesses: result.memory,
        );
      }
    } catch (e, stackTrace) {
      if (!isDisposed) {
        _processError =
            _recordError('loadTopProcesses', e, stackTrace, _processError);
      }
    } finally {
      _isLoadingTopProcesses = false;
      _emitChange();
    }
  }

  String _recordError(
      String action, Object error, StackTrace trace, String previous) {
    final message =
        error is NetworkException ? error.message : error.toString();
    if (message != previous) {
      appLogger.eWithPackage(
          'features.dashboard.dashboard_provider', '$action failed',
          error: error, stackTrace: trace);
    }
    return message;
  }

  Future<void> loadAppLaunchers() async {
    _isLoadingAppLaunchers = true;
    _emitChange();

    try {
      final items = await _service.loadAppLaunchers();
      _data = _data.copyWith(appLaunchers: items);
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.dashboard.dashboard_provider',
        'loadAppLaunchers failed',
        error: e,
        stackTrace: stackTrace,
      );
    }

    _isLoadingAppLaunchers = false;
    _emitChange();
  }

  Future<void> loadAppLauncherOptions() async {
    try {
      final items = await _service.loadAppLauncherOptions();
      _data = _data.copyWith(appLauncherOptions: items);
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.dashboard.dashboard_provider',
        'loadAppLauncherOptions failed',
        error: e,
        stackTrace: stackTrace,
      );
    }

    _emitChange();
  }

  Future<void> loadCurrentNode() async {
    try {
      final node = await _service.loadCurrentNode();
      _data = _data.copyWith(nodeInfo: node);
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.dashboard.dashboard_provider',
        'loadCurrentNode failed',
        error: e,
        stackTrace: stackTrace,
      );
    }

    _emitChange();
  }

  Future<void> loadQuickOptions() async {
    _isLoadingQuickOptions = true;
    _emitChange();

    try {
      final options = await _service.loadQuickOptions();
      _data = _data.copyWith(quickOptions: options);
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.dashboard.dashboard_provider',
        'loadQuickOptions failed',
        error: e,
        stackTrace: stackTrace,
      );
    }

    _isLoadingQuickOptions = false;
    _emitChange();
  }
}

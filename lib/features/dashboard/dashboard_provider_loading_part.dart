part of 'dashboard_provider.dart';

extension DashboardProviderLoading on DashboardProvider {
  Future<void> loadData({bool silent = false}) async {
    if (!silent) {
      _status = DashboardStatus.loading;
      _emitChange();
    } else {
      _isRefreshing = true;
      _emitChange();
    }

    try {
      _data = await _service.loadDashboardData();
      _status = DashboardStatus.loaded;
      _errorMessage = '';
      _isRefreshing = false;
      unawaited(loadTopProcesses());
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.dashboard.dashboard_provider',
        'loadData failed',
        error: e,
        stackTrace: stackTrace,
      );
      _status = DashboardStatus.error;
      _errorMessage = e.toString();
      _isRefreshing = false;
    }

    _emitChange();
  }

  Future<void> loadTopProcesses() async {
    _isLoadingTopProcesses = true;
    _emitChange();

    try {
      final result = await _service.loadTopProcesses();
      _data = _data.copyWith(
        topCpuProcesses: result.cpu,
        topMemoryProcesses: result.memory,
      );
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.dashboard.dashboard_provider',
        'loadTopProcesses failed',
        error: e,
        stackTrace: stackTrace,
      );
    }

    _isLoadingTopProcesses = false;
    _emitChange();
  }

  Future<void> loadAppLaunchers() async {
    _isLoadingAppLaunchers = true;
    _emitChange();

    try {
      _data = _data.copyWith(
        appLaunchers: await _service.loadAppLaunchers(),
      );
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
      _data = _data.copyWith(
        appLauncherOptions: await _service.loadAppLauncherOptions(),
      );
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
      _data = _data.copyWith(nodeInfo: await _service.loadCurrentNode());
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
      _data = _data.copyWith(
        quickOptions: await _service.loadQuickOptions(),
      );
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

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import '../../data/models/monitoring_runtime_models.dart';
import '../../data/models/monitor_models.dart';
import 'monitoring_service.dart';
import 'data/datasources/monitor_local_datasource.dart';
import '../../core/services/logger/logger_service.dart';

const String _monitoringProviderPackage =
    'features.monitoring.monitoring_provider';

/// 监控数据状态
class MonitoringData {
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final MonitorMetricsSnapshot? currentMetrics;
  final MonitorTimeSeries? cpuTimeSeries;
  final MonitorTimeSeries? memoryTimeSeries;
  final MonitorTimeSeries? loadTimeSeries;
  final MonitorTimeSeries? ioTimeSeries;
  final MonitorTimeSeries? networkTimeSeries;
  final List<MonitorGpuInfo> gpuInfo;
  final MonitorSetting? settings;
  final List<String> ioOptions;
  final List<String> networkOptions;
  final String selectedIO;
  final String selectedNetwork;
  final DateTime? lastUpdated;

  bool get hasData =>
      currentMetrics?.hasData == true ||
      cpuTimeSeries?.data.isNotEmpty == true ||
      memoryTimeSeries?.data.isNotEmpty == true ||
      loadTimeSeries?.data.isNotEmpty == true ||
      ioTimeSeries?.data.isNotEmpty == true ||
      networkTimeSeries?.data.isNotEmpty == true ||
      gpuInfo.isNotEmpty;

  const MonitoringData({
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.currentMetrics,
    this.cpuTimeSeries,
    this.memoryTimeSeries,
    this.loadTimeSeries,
    this.ioTimeSeries,
    this.networkTimeSeries,
    this.gpuInfo = const [],
    this.settings,
    this.ioOptions = const ['all'],
    this.networkOptions = const ['all'],
    this.selectedIO = 'all',
    this.selectedNetwork = 'all',
    this.lastUpdated,
  });

  MonitoringData copyWith({
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    MonitorMetricsSnapshot? currentMetrics,
    MonitorTimeSeries? cpuTimeSeries,
    MonitorTimeSeries? memoryTimeSeries,
    MonitorTimeSeries? loadTimeSeries,
    MonitorTimeSeries? ioTimeSeries,
    MonitorTimeSeries? networkTimeSeries,
    List<MonitorGpuInfo>? gpuInfo,
    MonitorSetting? settings,
    List<String>? ioOptions,
    List<String>? networkOptions,
    String? selectedIO,
    String? selectedNetwork,
    DateTime? lastUpdated,
  }) {
    return MonitoringData(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      currentMetrics: currentMetrics ?? this.currentMetrics,
      cpuTimeSeries: cpuTimeSeries ?? this.cpuTimeSeries,
      memoryTimeSeries: memoryTimeSeries ?? this.memoryTimeSeries,
      loadTimeSeries: loadTimeSeries ?? this.loadTimeSeries,
      ioTimeSeries: ioTimeSeries ?? this.ioTimeSeries,
      networkTimeSeries: networkTimeSeries ?? this.networkTimeSeries,
      gpuInfo: gpuInfo ?? this.gpuInfo,
      settings: settings ?? this.settings,
      ioOptions: ioOptions ?? this.ioOptions,
      networkOptions: networkOptions ?? this.networkOptions,
      selectedIO: selectedIO ?? this.selectedIO,
      selectedNetwork: selectedNetwork ?? this.selectedNetwork,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// 监控数据Provider
///
/// 用于MonitoringPage的状态管理
/// 实现了增量拉取和生命周期感知
class MonitoringProvider extends ChangeNotifier with SafeChangeNotifier {
  MonitoringProvider({
    ApiConfig? server,
    MonitoringService? service,
    MonitorLocalDataSource? dataSource,
  })  : _service = service ??
            (server == null
                ? MonitoringService()
                : MonitoringService.forServer(server)),
        _dataSource = dataSource ?? MonitorLocalDataSource(server: server);

  MonitoringProvider.forSettings(ApiConfig server)
      : _service = MonitoringService.forServer(server, requireSettings: true),
        _dataSource = MonitorLocalDataSource(server: server);

  final MonitoringService _service;
  final MonitorLocalDataSource _dataSource;
  Timer? _refreshTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  MonitoringData _data = const MonitoringData();

  // 自动刷新设置
  Duration _refreshInterval = const Duration(seconds: 5);
  bool _autoRefreshEnabled = false;
  Duration _gpuRefreshInterval = const Duration(seconds: 30);
  bool _gpuAutoRefreshEnabled = true;
  DateTime? _lastGpuRefreshAt;
  int _maxDataPoints = 1000; // 默认增加点数，支持更平滑的曲线
  int _queryRevision = 0;
  CancelToken _historyCancellation = CancelToken();
  ({int revision, Future<void> completion})? _polling;
  final _visiblePages = <Object>{};
  bool get _pageVisible => _visiblePages.isNotEmpty;
  bool? _online;
  bool _opened = false;
  bool _optionsLoaded = false;
  String? _selectedIO;
  String? _selectedNetwork;

  // 时间范围设置
  Duration _timeRange = const Duration(hours: 1);
  DateTime? _customStartTime;
  DateTime? _customEndTime;

  // 增量更新状态
  DateTime? _lastFetchTime;
  bool _cacheLoaded = false;
  final _reportedErrors = <String, String>{};
  String? get _pollError =>
      _reportedErrors['加载监控数据'] ?? _reportedErrors['加载GPU信息'];
  final Map<String, List<MonitorDataPoint>> _rawTimeSeries = {
    'cpu': [],
    'memory': [],
    'load': [],
    'io': [],
    'network': [],
  };

  MonitoringData get data => _data;
  Duration get refreshInterval => _refreshInterval;
  bool get autoRefreshEnabled => _autoRefreshEnabled;
  Duration get gpuRefreshInterval => _gpuRefreshInterval;
  bool get gpuAutoRefreshEnabled => _gpuAutoRefreshEnabled;
  int get maxDataPoints => _maxDataPoints;
  Duration get timeRange => _timeRange;
  DateTime? get customStartTime => _customStartTime;
  DateTime? get customEndTime => _customEndTime;

  String _normalizeMonitorOption(String? value, List<String> options) {
    if (options.isEmpty) {
      return 'all';
    }
    if (value != null && value.isNotEmpty && options.contains(value)) {
      return value;
    }

    for (final option in options) {
      if (option != 'all') {
        return option;
      }
    }
    return options.first;
  }

  bool _isCurrent(int revision) => !isDisposed && revision == _queryRevision;

  void _invalidateQuery() {
    _queryRevision++;
    _historyCancellation.cancel();
    _historyCancellation = CancelToken();
  }

  Future<void> _loadMonitorOptionsIfNeeded(int revision) async {
    if (_optionsLoaded) return;
    final (settings, ioOptions, networkOptions) = await (
      _service.getSetting(),
      _service.getIOOptions(),
      _service.getNetworkOptions(),
    ).wait;
    if (!_isCurrent(revision)) return;
    _optionsLoaded = settings != null;
    final safeIoOptions = ioOptions.isEmpty ? const ['all'] : ioOptions;
    final safeNetworkOptions =
        networkOptions.isEmpty ? const ['all'] : networkOptions;

    _data = _data.copyWith(
      settings: settings,
      ioOptions: safeIoOptions,
      networkOptions: safeNetworkOptions,
      selectedIO: _normalizeMonitorOption(
        _selectedIO ?? settings?.defaultIO,
        safeIoOptions,
      ),
      selectedNetwork: _normalizeMonitorOption(
        _selectedNetwork ?? settings?.defaultNetwork,
        safeNetworkOptions,
      ),
    );
  }

  Future<void> selectIOOption(String value) async {
    if (value == _data.selectedIO) {
      return;
    }
    _rawTimeSeries['io']!.clear();
    _selectedIO = value;
    _invalidateQuery();
    _lastFetchTime = null;
    _cacheLoaded = false;
    _data = _data.copyWith(
        selectedIO: value, ioTimeSeries: MonitorTimeSeries.empty('disk'));
    notifyListeners();
    await refreshByPolicy();
  }

  Future<void> selectNetworkOption(String value) async {
    if (value == _data.selectedNetwork) {
      return;
    }
    _rawTimeSeries['network']!.clear();
    _selectedNetwork = value;
    _invalidateQuery();
    _lastFetchTime = null;
    _cacheLoaded = false;
    _data = _data.copyWith(
        selectedNetwork: value,
        networkTimeSeries: MonitorTimeSeries.empty('networkIn'));
    notifyListeners();
    await refreshByPolicy();
  }

  void _recordError(
    String action,
    Object error, {
    StackTrace? stackTrace,
  }) {
    final message = ErrorMessageUtils.normalize(error);
    if (_reportedErrors[action] != message) {
      _reportedErrors[action] = message;
      appLogger.eWithPackage(_monitoringProviderPackage, '$action failed',
          error: error, stackTrace: stackTrace);
    }
    _data = _data.copyWith(
      isLoading: false,
      isRefreshing: false,
      error: _pollError ?? message,
    );
    notifyListeners();
  }

  void _initConnectivity() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final connected =
          results.any((result) => result != ConnectivityResult.none);
      final restored = connected && _online == false;
      _online = connected;
      if (restored && _pageVisible && _autoRefreshEnabled) {
        appLogger.iWithPackage(
          _monitoringProviderPackage,
          'Network restored, reloading monitoring data',
        );
        // 网络恢复，尝试重新加载数据并补全缺口
        unawaited(refreshByPolicy(silent: true));
      }
    });
  }

  void setPageVisible(Object page, bool visible) {
    if (isDisposed) return;
    final wasVisible = _pageVisible;
    if (visible) {
      _visiblePages.add(page);
    } else {
      _visiblePages.remove(page);
    }
    if (_pageVisible == wasVisible) return;
    _stopTimer();
    if (!_pageVisible) {
      _connectivitySubscription?.cancel();
      _online = null;
      _invalidateQuery();
      _data = _data.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: _data.error,
      );
      return;
    }
    if (!_opened) {
      _opened = true;
      _autoRefreshEnabled = true;
    }
    _initConnectivity();
    if (_autoRefreshEnabled) _startTimer();
    final lastFetch = _lastFetchTime;
    if (lastFetch == null ||
        (_autoRefreshEnabled &&
            _customEndTime == null &&
            DateTime.now().difference(lastFetch) >= _refreshInterval)) {
      unawaited(refreshByPolicy(silent: _data.lastUpdated != null));
    } else if (_autoRefreshEnabled &&
        _online == true &&
        _lastGpuRefreshAt == null) {
      unawaited(_refreshGpuInfoByPolicy());
    }
  }

  void invalidateMonitorSettings() {
    if (isDisposed) return;
    _invalidateQuery();
    _optionsLoaded = false;
    _lastFetchTime = null;
    _cacheLoaded = false;
    if (_pageVisible) unawaited(refreshByPolicy());
  }

  /// 设置刷新间隔
  void setRefreshInterval(Duration interval) {
    _refreshInterval = interval;
    if (_autoRefreshEnabled && _pageVisible) {
      _startTimer();
    }
    notifyListeners();
  }

  /// 设置GPU自动刷新开关
  void setGpuAutoRefreshEnabled(bool enabled) {
    _gpuAutoRefreshEnabled = enabled;
    if (enabled) {
      _lastGpuRefreshAt = null;
      if (_pageVisible) unawaited(_refreshGpuInfoByPolicy());
    }
    notifyListeners();
  }

  /// 设置GPU自动刷新间隔
  void setGpuRefreshInterval(Duration interval) {
    if (interval <= Duration.zero) {
      return;
    }
    _gpuRefreshInterval = interval;
    notifyListeners();
  }

  /// 原子更新GPU刷新策略
  void updateGpuRefreshPolicy({
    required bool enabled,
    required Duration interval,
  }) {
    if (interval > Duration.zero) {
      _gpuRefreshInterval = interval;
    }
    _gpuAutoRefreshEnabled = enabled;
    if (enabled) {
      _lastGpuRefreshAt = null;
      if (_pageVisible) unawaited(_refreshGpuInfoByPolicy());
    }
    notifyListeners();
  }

  /// 设置最大数据点数量
  void setMaxDataPoints(int count) {
    if (count < 2) throw RangeError.range(count, 2, null);
    if (_maxDataPoints == count) return;
    _maxDataPoints = count;
    // 触发UI刷新，使用新的点数限制重新过滤数据
    _updateDisplayData();
  }

  /// 设置时间范围
  void setTimeRange(Duration range) {
    _invalidateQuery();
    _timeRange = range;
    _customStartTime = null;
    _customEndTime = null;
    // 时间范围变更，重置增量状态，重新全量拉取
    _lastFetchTime = null;
    _cacheLoaded = false;
    _clearRawData();
    if (_pageVisible && _autoRefreshEnabled) _startTimer();
    if (_pageVisible) unawaited(refreshByPolicy(silent: false));
    notifyListeners();
  }

  /// 设置自定义时间范围
  void setCustomTimeRange(DateTime startTime, DateTime endTime) {
    _invalidateQuery();
    _stopTimer();
    _customStartTime = startTime;
    _customEndTime = endTime;
    _timeRange = endTime.difference(startTime);
    _lastFetchTime = null;
    _cacheLoaded = false;
    _clearRawData();
    if (_pageVisible) unawaited(refreshByPolicy(silent: false));
    notifyListeners();
  }

  /// 启用/禁用自动刷新
  void toggleAutoRefresh(bool enabled) {
    _autoRefreshEnabled = enabled;
    if (enabled && _pageVisible) {
      _startTimer();
      unawaited(refreshByPolicy(silent: true));
    } else {
      _stopTimer();
    }
    notifyListeners();
  }

  void _startTimer() {
    _stopTimer();
    if (_customEndTime != null) return;
    appLogger.dWithPackage(
      _monitoringProviderPackage,
      'Auto refresh started: ${_refreshInterval.inSeconds}s',
    );
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      unawaited(refreshByPolicy(silent: true));
    });
  }

  Future<void> _refreshGpuInfoByPolicy() async {
    if (!_gpuAutoRefreshEnabled || _online != true) {
      return;
    }
    final now = DateTime.now();
    final lastRefreshAt = _lastGpuRefreshAt;
    if (lastRefreshAt != null &&
        now.difference(lastRefreshAt) < _gpuRefreshInterval) {
      return;
    }
    _lastGpuRefreshAt = now;
    await loadGPUInfo();
  }

  void _stopTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    _historyCancellation.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _clearRawData() {
    for (var key in _rawTimeSeries.keys) {
      _rawTimeSeries[key]!.clear();
    }
  }

  Future<void> _saveToStorage(
    Map<String, MonitorTimeSeries> data,
    int revision,
  ) async {
    for (var entry in data.entries) {
      if (!_isCurrent(revision)) return;
      if (entry.value.data.isEmpty) continue;
      await _dataSource.savePoints(_storageKey(entry.key), entry.value.data);
    }
  }

  String _storageKey(String metric) {
    final device = switch (metric) {
      'io' => _data.selectedIO,
      'network' => _data.selectedNetwork,
      _ => null,
    };
    return device == null
        ? metric
        : '$metric-${base64.encode(utf8.encode(device))}';
  }

  Future<void> _loadFromStorage(DateTime now, int revision) async {
    final start = _customStartTime ?? now.subtract(_timeRange);
    final end = _customEndTime ?? now;

    for (var key in _rawTimeSeries.keys) {
      final points = await _dataSource.getPoints(_storageKey(key), start, end);
      if (!_isCurrent(revision)) return;
      if (points.isNotEmpty) {
        _rawTimeSeries[key] = points;
      }
    }
  }

  /// 加载所有监控数据
  Future<void> load({bool silent = false}) async {
    final revision = _queryRevision;
    if (!silent) {
      _data = _data.copyWith(isLoading: true, error: null);
      notifyListeners();
    } else {
      _data = _data.copyWith(isRefreshing: true, error: _data.error);
    }

    try {
      var online = _pageVisible ? _online : null;
      if (online == null) {
        final connectivity = await Connectivity().checkConnectivity();
        if (!_isCurrent(revision)) return;
        online = (_pageVisible ? _online : null) ??
            connectivity.any((value) => value != ConnectivityResult.none);
        _online = online;
      }
      if (!_isCurrent(revision)) return;
      if (online) await _loadMonitorOptionsIfNeeded(revision);
      if (!_isCurrent(revision)) return;

      final now = DateTime.now();
      final start =
          _customStartTime ?? _lastFetchTime ?? now.subtract(_timeRange);
      final initial = !_cacheLoaded;
      if (initial) {
        _clearRawData();
        await _loadFromStorage(now, revision);
        if (!_isCurrent(revision)) return;
        _cacheLoaded = true;
      }

      if (!online) {
        _updateDisplayData(now: now, changed: initial ? null : const {});
        return;
      }

      final result = await _service.getMonitorData(
        cancelToken: _historyCancellation,
        io: _data.selectedIO,
        network: _data.selectedNetwork,
        duration: _timeRange,
        startTime: start,
        endTime: _customEndTime ?? now,
      );
      if (!_isCurrent(revision)) return;
      await _saveToStorage(result.timeSeries, revision);
      if (!_isCurrent(revision)) return;
      final changed = <String>{};
      for (final entry in _rawTimeSeries.entries) {
        final points = result.timeSeries[entry.key]?.data;
        if (points != null && mergeMonitorPoints(entry.value, points)) {
          changed.add(entry.key);
        }
      }
      _reportedErrors.remove('加载监控数据');
      _lastFetchTime = now;
      _updateDisplayData(
          currentMetrics: result.current, changed: initial ? null : changed);
    } catch (e, stackTrace) {
      if (!_isCurrent(revision)) return;
      if (!_data.hasData &&
          _lastFetchTime == null &&
          _rawTimeSeries.values.any((points) => points.isNotEmpty)) {
        _updateDisplayData();
      }
      _recordError('加载监控数据', e, stackTrace: stackTrace);
    }
  }

  void _updateDisplayData(
      {MonitorMetricsSnapshot? currentMetrics,
      DateTime? now,
      Set<String>? changed}) {
    now ??= DateTime.now();
    final start = _customStartTime ?? now.subtract(_timeRange);
    final end = _customEndTime ?? now;
    MonitorTimeSeries project(
        String key, String name, MonitorTimeSeries? previous) {
      final points = _rawTimeSeries[key]!;
      final expired = points.isNotEmpty && points.first.time.isBefore(start);
      final previousEnd = _customEndTime ?? _data.lastUpdated;
      final hadFutureSamples = points.isNotEmpty &&
          previousEnd != null &&
          points.last.time.isAfter(previousEnd);
      if (previous != null &&
          changed != null &&
          !changed.contains(key) &&
          !expired &&
          !hadFutureSamples) {
        return previous;
      }
      if (expired) {
        final first = points.indexWhere((point) => !point.time.isBefore(start));
        points.removeRange(0, first < 0 ? points.length : first);
      }
      final visible = points.isEmpty || !points.last.time.isAfter(end)
          ? points
          : points.takeWhile((point) => !point.time.isAfter(end)).toList();
      return MonitorTimeSeries.fromPoints(name, visible,
          limit: _maxDataPoints == 1000 ? null : _maxDataPoints);
    }

    _data = _data.copyWith(
      currentMetrics: currentMetrics,
      cpuTimeSeries: project('cpu', 'cpu', _data.cpuTimeSeries),
      memoryTimeSeries: project('memory', 'memory', _data.memoryTimeSeries),
      loadTimeSeries: project('load', 'load', _data.loadTimeSeries),
      ioTimeSeries: project('io', 'disk', _data.ioTimeSeries),
      networkTimeSeries:
          project('network', 'networkIn', _data.networkTimeSeries),
      isLoading: false,
      isRefreshing: false,
      error: _pollError,
      lastUpdated: now,
    );

    notifyListeners();
  }

  /// 刷新数据
  Future<void> refresh() => refreshByPolicy();

  /// 按策略刷新（主监控 + 可选GPU）
  Future<void> refreshByPolicy({bool silent = true}) {
    if (isDisposed) return Future.value();
    final revision = _queryRevision;
    final active = _polling;
    if (active != null && active.revision == revision) return active.completion;

    final completion = Future<void>.microtask(() async {
      try {
        if (!_isCurrent(revision)) return;
        await load(silent: silent);
        if (_isCurrent(revision) && (!_opened || _pageVisible)) {
          await _refreshGpuInfoByPolicy();
        }
      } finally {
        if (_polling?.revision == revision) _polling = null;
      }
    });
    _polling = (revision: revision, completion: completion);
    return completion;
  }

  /// 清除错误
  void clearError() {
    _data = _data.copyWith(error: null);
    notifyListeners();
  }

  /// 加载监控设置
  Future<bool> loadSettings({bool reloadDevices = true}) async {
    try {
      final (settings, ioOptions, networkOptions) = await (
        _service.getSetting(),
        reloadDevices ? _service.getIOOptions() : Future.value(_data.ioOptions),
        reloadDevices
            ? _service.getNetworkOptions()
            : Future.value(_data.networkOptions),
      ).wait;
      if (settings == null || settings.enabled == null) {
        throw const FormatException('Missing monitor settings');
      }
      _data = _data.copyWith(
        settings: settings,
        ioOptions: ioOptions,
        networkOptions: networkOptions,
        selectedIO: _normalizeMonitorOption(settings.defaultIO, ioOptions),
        selectedNetwork: _normalizeMonitorOption(
          settings.defaultNetwork,
          networkOptions,
        ),
      );
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _recordError('加载监控设置', e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 更新监控设置
  Future<bool> updateSettings({
    int? interval,
    int? retention,
    bool? enabled,
    String? defaultIO,
    String? defaultNetwork,
  }) async {
    try {
      return await _service.updateSetting(
        interval: interval,
        retention: retention,
        enabled: enabled,
        defaultIO: defaultIO,
        defaultNetwork: defaultNetwork,
      );
    } catch (e, stackTrace) {
      _recordError('更新监控设置', e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 清理监控数据
  Future<bool> cleanData() async {
    try {
      return await _service.cleanData();
    } catch (e, stackTrace) {
      _recordError('清理监控数据', e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 加载GPU信息
  Future<void> loadGPUInfo() async {
    final revision = _queryRevision;
    try {
      final gpuInfo = await _service.getGPUInfo();
      if (!_isCurrent(revision) ||
          !_gpuAutoRefreshEnabled ||
          (_opened && !_pageVisible)) {
        return;
      }
      _reportedErrors.remove('加载GPU信息');
      if (listEquals(gpuInfo, _data.gpuInfo) && _data.error == _pollError) {
        return;
      }
      _data = _data.copyWith(gpuInfo: gpuInfo, error: _pollError);
      notifyListeners();
    } catch (e, stackTrace) {
      if (_isCurrent(revision) && _gpuAutoRefreshEnabled) {
        _recordError('加载GPU信息', e, stackTrace: stackTrace);
      }
    }
  }
}

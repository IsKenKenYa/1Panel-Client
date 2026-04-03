import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import '../../data/repositories/monitor_repository.dart';
import '../../api/v2/monitor_v2.dart';
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
  final MonitorTimeSeries? cpuPreviousSeries;
  final MonitorTimeSeries? memoryTimeSeries;
  final MonitorTimeSeries? memoryPreviousSeries;
  final MonitorTimeSeries? loadTimeSeries;
  final MonitorTimeSeries? loadPreviousSeries;
  final MonitorTimeSeries? ioTimeSeries;
  final MonitorTimeSeries? ioPreviousSeries;
  final MonitorTimeSeries? networkTimeSeries;
  final MonitorTimeSeries? networkPreviousSeries;
  final List<GPUInfo> gpuInfo;
  final MonitorSetting? settings;
  final List<String> ioOptions;
  final List<String> networkOptions;
  final String selectedIO;
  final String selectedNetwork;
  final DateTime? lastUpdated;

  const MonitoringData({
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.currentMetrics,
    this.cpuTimeSeries,
    this.cpuPreviousSeries,
    this.memoryTimeSeries,
    this.memoryPreviousSeries,
    this.loadTimeSeries,
    this.loadPreviousSeries,
    this.ioTimeSeries,
    this.ioPreviousSeries,
    this.networkTimeSeries,
    this.networkPreviousSeries,
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
    MonitorTimeSeries? cpuPreviousSeries,
    MonitorTimeSeries? memoryTimeSeries,
    MonitorTimeSeries? memoryPreviousSeries,
    MonitorTimeSeries? loadTimeSeries,
    MonitorTimeSeries? loadPreviousSeries,
    MonitorTimeSeries? ioTimeSeries,
    MonitorTimeSeries? ioPreviousSeries,
    MonitorTimeSeries? networkTimeSeries,
    MonitorTimeSeries? networkPreviousSeries,
    List<GPUInfo>? gpuInfo,
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
      cpuPreviousSeries: cpuPreviousSeries ?? this.cpuPreviousSeries,
      memoryTimeSeries: memoryTimeSeries ?? this.memoryTimeSeries,
      memoryPreviousSeries: memoryPreviousSeries ?? this.memoryPreviousSeries,
      loadTimeSeries: loadTimeSeries ?? this.loadTimeSeries,
      loadPreviousSeries: loadPreviousSeries ?? this.loadPreviousSeries,
      ioTimeSeries: ioTimeSeries ?? this.ioTimeSeries,
      ioPreviousSeries: ioPreviousSeries ?? this.ioPreviousSeries,
      networkTimeSeries: networkTimeSeries ?? this.networkTimeSeries,
      networkPreviousSeries:
          networkPreviousSeries ?? this.networkPreviousSeries,
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
    MonitoringService? service,
    MonitorLocalDataSource? dataSource,
  })  : _service = service,
        _dataSource = dataSource ?? MonitorLocalDataSource() {
    _initConnectivity();
  }

  MonitoringService? _service;
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
  bool _isPolling = false;

  // 时间范围设置
  Duration _timeRange = const Duration(hours: 1);
  DateTime? _customStartTime;
  DateTime? _customEndTime;

  // 增量更新状态
  DateTime? _lastFetchTime;
  final Map<String, List<MonitorDataPoint>> _rawTimeSeries = {
    'cpu': [],
    'memory': [],
    'load': [],
    'io': [],
    'network': [],
  };

  // 上一周期（同比）数据缓存
  final Map<String, List<MonitorDataPoint>> _previousRawTimeSeries = {
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

  Future<void> _loadMonitorOptionsIfNeeded() async {
    final needsOptions =
        _data.ioOptions.length <= 1 || _data.networkOptions.length <= 1;
    final needsSettings = _data.settings == null;
    if (!needsOptions && !needsSettings) {
      return;
    }

    final settings =
        needsSettings ? await _service!.getSetting() : _data.settings;
    final ioOptions =
        needsOptions ? await _service!.getIOOptions() : _data.ioOptions;
    final networkOptions = needsOptions
        ? await _service!.getNetworkOptions()
        : _data.networkOptions;
    final safeIoOptions = ioOptions.isEmpty ? const ['all'] : ioOptions;
    final safeNetworkOptions =
        networkOptions.isEmpty ? const ['all'] : networkOptions;

    _data = _data.copyWith(
      settings: settings,
      ioOptions: safeIoOptions,
      networkOptions: safeNetworkOptions,
      selectedIO: _normalizeMonitorOption(
        _data.selectedIO != 'all' ? _data.selectedIO : settings?.defaultIO,
        safeIoOptions,
      ),
      selectedNetwork: _normalizeMonitorOption(
        _data.selectedNetwork != 'all'
            ? _data.selectedNetwork
            : settings?.defaultNetwork,
        safeNetworkOptions,
      ),
    );
  }

  Future<void> selectIOOption(String value) async {
    if (value == _data.selectedIO) {
      return;
    }
    _rawTimeSeries['io']!.clear();
    _previousRawTimeSeries['io']!.clear();
    _lastFetchTime = null;
    _data = _data.copyWith(selectedIO: value);
    notifyListeners();
    await load(silent: true);
  }

  Future<void> selectNetworkOption(String value) async {
    if (value == _data.selectedNetwork) {
      return;
    }
    _rawTimeSeries['network']!.clear();
    _previousRawTimeSeries['network']!.clear();
    _lastFetchTime = null;
    _data = _data.copyWith(selectedNetwork: value);
    notifyListeners();
    await load(silent: true);
  }

  void _recordError(
    String action,
    Object error, {
    StackTrace? stackTrace,
  }) {
    appLogger.eWithPackage(
      _monitoringProviderPackage,
      '$action failed',
      error: error,
      stackTrace: stackTrace,
    );
    _data = _data.copyWith(
      isLoading: false,
      isRefreshing: false,
      error: '$action失败: $error',
    );
    notifyListeners();
  }

  Future<void> _ensureService() async {
    _service ??= MonitoringService();
    await _dataSource.init();
  }

  void _initConnectivity() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        appLogger.iWithPackage(
          _monitoringProviderPackage,
          'Network restored, reloading monitoring data',
        );
        // 网络恢复，尝试重新加载数据并补全缺口
        unawaited(refreshByPolicy(silent: true));
      }
    });
  }

  /// 生命周期变化处理
  void onAppLifecycleChanged(AppLifecycleState state) {
    if (!_autoRefreshEnabled) return;

    if (state == AppLifecycleState.paused) {
      appLogger.dWithPackage(
        _monitoringProviderPackage,
        'App paused, switching to background refresh (5 min)',
      );
      _stopTimer();
      // 后台模式：5分钟刷新一次
      _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        unawaited(refreshByPolicy(silent: true));
      });
    } else if (state == AppLifecycleState.resumed) {
      appLogger.dWithPackage(
        _monitoringProviderPackage,
        'App resumed, foreground refresh=${_refreshInterval.inSeconds}s',
      );
      _stopTimer();
      _startTimer();
    }
  }

  /// 设置刷新间隔
  void setRefreshInterval(Duration interval) {
    _refreshInterval = interval;
    if (_autoRefreshEnabled) {
      _startTimer();
    }
    notifyListeners();
  }

  /// 设置GPU自动刷新开关
  void setGpuAutoRefreshEnabled(bool enabled) {
    _gpuAutoRefreshEnabled = enabled;
    if (enabled) {
      _lastGpuRefreshAt = null;
      unawaited(_refreshGpuInfoByPolicy());
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
      unawaited(_refreshGpuInfoByPolicy());
    }
    notifyListeners();
  }

  /// 设置最大数据点数量
  void setMaxDataPoints(int count) {
    _maxDataPoints = count;
    notifyListeners();
    // 触发UI刷新，使用新的点数限制重新过滤数据
    _updateDisplayData();
  }

  /// 设置时间范围
  void setTimeRange(Duration range) {
    _timeRange = range;
    _customStartTime = null;
    _customEndTime = null;
    // 时间范围变更，重置增量状态，重新全量拉取
    _lastFetchTime = null;
    _clearRawData();
    load();
    notifyListeners();
  }

  /// 设置自定义时间范围
  void setCustomTimeRange(DateTime startTime, DateTime endTime) {
    _customStartTime = startTime;
    _customEndTime = endTime;
    _timeRange = endTime.difference(startTime);
    _lastFetchTime = null;
    _clearRawData();
    load();
    notifyListeners();
  }

  /// 启用/禁用自动刷新
  void toggleAutoRefresh(bool enabled) {
    _autoRefreshEnabled = enabled;
    if (enabled) {
      _startTimer();
      unawaited(refreshByPolicy(silent: true));
    } else {
      _stopTimer();
    }
    notifyListeners();
  }

  void _startTimer() {
    _stopTimer();
    appLogger.dWithPackage(
      _monitoringProviderPackage,
      'Auto refresh started: ${_refreshInterval.inSeconds}s',
    );
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      unawaited(refreshByPolicy(silent: true));
    });
  }

  Future<void> _refreshGpuInfoByPolicy() async {
    if (!_gpuAutoRefreshEnabled) {
      return;
    }
    final now = DateTime.now();
    final lastRefreshAt = _lastGpuRefreshAt;
    if (lastRefreshAt != null &&
        now.difference(lastRefreshAt) < _gpuRefreshInterval) {
      return;
    }
    await loadGPUInfo();
  }

  void _stopTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _clearRawData() {
    for (var key in _rawTimeSeries.keys) {
      _rawTimeSeries[key]!.clear();
    }
    for (var key in _previousRawTimeSeries.keys) {
      _previousRawTimeSeries[key]!.clear();
    }
  }

  Future<void> _saveToStorage(Map<String, MonitorTimeSeries> data) async {
    for (var entry in data.entries) {
      // 转换 metric key 为存储 key
      // API 返回的 key 可能是 'cpu', 'memory' 等
      // MonitorLocalDataSource 需要这些 key
      await _dataSource.savePoints(entry.key, entry.value.data);
    }
  }

  Future<void> _loadFromStorage(DateTime now) async {
    final start = _customStartTime ?? now.subtract(_timeRange);
    final end = _customEndTime ?? now;

    for (var key in _rawTimeSeries.keys) {
      final points = await _dataSource.getPoints(key, start, end);
      if (points.isNotEmpty) {
        _rawTimeSeries[key] = points;
      }
    }
  }

  Future<void> _loadPreviousData(DateTime now) async {
    // 上一周期：24小时前（同比）
    // 如果当前查看的是过去的时间段，则同比时间段也相应前移
    final currentStart = _customStartTime ?? now.subtract(_timeRange);
    final start = currentStart.subtract(const Duration(days: 1));
    final end = (_customEndTime ?? now).subtract(const Duration(days: 1));

    for (var key in _previousRawTimeSeries.keys) {
      // 尝试从本地存储加载
      final points = await _dataSource.getPoints(key, start, end);
      if (points.isNotEmpty) {
        _previousRawTimeSeries[key] = points;
      }
    }
  }

  /// 加载所有监控数据
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _data = _data.copyWith(isLoading: true, error: null);
      notifyListeners();
    } else {
      _data = _data.copyWith(isRefreshing: true, error: null);
    }

    try {
      await _ensureService();
      await _loadMonitorOptionsIfNeeded();

      final now = DateTime.now();
      DateTime fetchStartTime;

      // 决定拉取起始时间
      if (_lastFetchTime != null && _customStartTime == null) {
        // 增量拉取：从上次拉取时间开始
        fetchStartTime = _lastFetchTime!;
      } else {
        // 全量拉取：从时间范围开始
        fetchStartTime = _customStartTime ?? now.subtract(_timeRange);
        if (_lastFetchTime == null) {
          _clearRawData();
          // 尝试从本地加载当前数据
          await _loadFromStorage(now);
          // 尝试从本地加载上一周期数据
          await _loadPreviousData(now);
        }
      }

      // 检查网络状态
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        appLogger.wWithPackage(
          _monitoringProviderPackage,
          'Offline mode detected, fallback to local data',
        );
        _updateDisplayData(now: now);
        return;
      }

      // 在线模式：获取数据
      try {
        final result = await _service!.getMonitorData(
          io: _data.selectedIO,
          network: _data.selectedNetwork,
          duration: _timeRange,
          startTime: fetchStartTime,
        );

        // 合并增量数据
        _mergeData('cpu', result.timeSeries['cpu']);
        _mergeData('memory', result.timeSeries['memory']);
        _mergeData('load', result.timeSeries['load']);
        _mergeData('io', result.timeSeries['io']);
        _mergeData('network', result.timeSeries['network']);

        _lastFetchTime = now;

        // 保存到本地存储
        await _saveToStorage(result.timeSeries);

        // 如果是全量拉取，尝试重新加载上一周期数据
        if (fetchStartTime == _customStartTime ||
            fetchStartTime == now.subtract(_timeRange)) {
          await _loadPreviousData(now);
        }

        // 更新展示数据
        _updateDisplayData(currentMetrics: result.current, now: now);
      } catch (e, stackTrace) {
        appLogger.wWithPackage(
          _monitoringProviderPackage,
          'Network fetch failed, fallback to local cache',
          error: e,
          stackTrace: stackTrace,
        );
        // 网络请求失败，降级使用本地数据
        if (_lastFetchTime == null) {
          _updateDisplayData(now: now);
        }
        if (!silent && _rawTimeSeries['cpu']!.isEmpty) {
          rethrow;
        }
      }
    } catch (e, stackTrace) {
      _recordError('加载监控数据', e, stackTrace: stackTrace);
    }
  }

  void _mergeData(String key, MonitorTimeSeries? newSeries) {
    if (newSeries == null || newSeries.data.isEmpty) return;
    final list = _rawTimeSeries[key]!;

    if (list.isNotEmpty) {
      final lastTime = list.last.time;
      // 仅添加比本地最新数据更新的数据点
      final newPoints = newSeries.data.where((p) => p.time.isAfter(lastTime));
      list.addAll(newPoints);
    } else {
      list.addAll(newSeries.data);
    }

    // 简单的内存保护：如果数据点过多（例如超过24小时的秒级数据），可以清理旧数据
    // 这里暂不实现复杂清理，假设内存足够
  }

  void _updateDisplayData(
      {MonitorMetricsSnapshot? currentMetrics, DateTime? now}) {
    now ??= DateTime.now();

    final displayCpu = _getDisplaySeries('cpu', 'cpu', now);
    final displayMemory = _getDisplaySeries('memory', 'memory', now);
    final displayLoad = _getDisplaySeries('load', 'load', now);
    final displayIo = _getDisplaySeries('io', 'disk', now);
    final displayNetwork = _getDisplaySeries('network', 'networkIn', now);

    final prevCpu = _getPreviousDisplaySeries('cpu', 'cpu', now);
    final prevMemory = _getPreviousDisplaySeries('memory', 'memory', now);
    final prevLoad = _getPreviousDisplaySeries('load', 'load', now);
    final prevIo = _getPreviousDisplaySeries('io', 'disk', now);
    final prevNetwork = _getPreviousDisplaySeries('network', 'networkIn', now);

    _data = _data.copyWith(
      currentMetrics: currentMetrics,
      cpuTimeSeries: displayCpu,
      cpuPreviousSeries: prevCpu,
      memoryTimeSeries: displayMemory,
      memoryPreviousSeries: prevMemory,
      loadTimeSeries: displayLoad,
      loadPreviousSeries: prevLoad,
      ioTimeSeries: displayIo,
      ioPreviousSeries: prevIo,
      networkTimeSeries: displayNetwork,
      networkPreviousSeries: prevNetwork,
      isLoading: false,
      isRefreshing: false,
      lastUpdated: now,
    );

    if (currentMetrics != null) {
      _data = _data.copyWith(currentMetrics: currentMetrics);
    }

    notifyListeners();
  }

  MonitorTimeSeries _getDisplaySeries(String key, String name, DateTime now) {
    final list = _rawTimeSeries[key]!;
    final start = _customStartTime ?? now.subtract(_timeRange);
    final end = _customEndTime ?? now;

    // 过滤时间范围
    var filtered = list
        .where((p) =>
            p.time.isAfter(start) &&
            p.time.isBefore(end.add(const Duration(seconds: 1))))
        .toList();

    // 如果数据点太多，且设置了 maxDataPoints，则进行采样
    if (_maxDataPoints < 100 && filtered.length > _maxDataPoints) {
      final step = (filtered.length / _maxDataPoints).ceil();
      final sampled = <MonitorDataPoint>[];
      for (var i = 0; i < filtered.length; i += step) {
        sampled.add(filtered[i]);
      }
      filtered = sampled;
    }

    // 计算统计信息
    double? min, max;
    double sum = 0;
    for (var p in filtered) {
      if (min == null || p.value < min) min = p.value;
      if (max == null || p.value > max) max = p.value;
      sum += p.value;
    }

    return MonitorTimeSeries(
      name: name,
      data: filtered,
      min: min,
      max: max,
      avg: filtered.isNotEmpty ? sum / filtered.length : null,
    );
  }

  MonitorTimeSeries _getPreviousDisplaySeries(
      String key, String name, DateTime now) {
    final list = _previousRawTimeSeries[key]!;
    final start = _customStartTime ?? now.subtract(_timeRange);
    final end = _customEndTime ?? now;

    // 平移时间戳：+1天（假设上一周期是昨天同一时间）
    final shift = const Duration(days: 1);
    final shifted = <MonitorDataPoint>[];

    for (var p in list) {
      final newTime = p.time.add(shift);
      if (newTime.isAfter(start) &&
          newTime.isBefore(end.add(const Duration(seconds: 1)))) {
        shifted.add(MonitorDataPoint(time: newTime, value: p.value));
      }
    }

    // 计算统计信息
    double? min, max;
    double sum = 0;
    for (var p in shifted) {
      if (min == null || p.value < min) min = p.value;
      if (max == null || p.value > max) max = p.value;
      sum += p.value;
    }

    return MonitorTimeSeries(
      name: name,
      data: shifted,
      min: min,
      max: max,
      avg: shifted.isNotEmpty ? sum / shifted.length : null,
    );
  }

  /// 刷新数据
  Future<void> refresh() async {
    await load(silent: true);
  }

  /// 按策略刷新（主监控 + 可选GPU）
  Future<void> refreshByPolicy({bool silent = true}) async {
    if (_isPolling) {
      return;
    }
    _isPolling = true;
    try {
      await load(silent: silent);
      await _refreshGpuInfoByPolicy();
    } finally {
      _isPolling = false;
    }
  }

  /// 清除错误
  void clearError() {
    _data = _data.copyWith(error: null);
    notifyListeners();
  }

  /// 加载监控设置
  Future<void> loadSettings() async {
    try {
      await _ensureService();
      final settings = await _service!.getSetting();
      final ioOptions = await _service!.getIOOptions();
      final networkOptions = await _service!.getNetworkOptions();
      final safeIoOptions = ioOptions.isEmpty ? const ['all'] : ioOptions;
      final safeNetworkOptions =
          networkOptions.isEmpty ? const ['all'] : networkOptions;
      _data = _data.copyWith(
        settings: settings,
        ioOptions: safeIoOptions,
        networkOptions: safeNetworkOptions,
        selectedIO: _normalizeMonitorOption(settings?.defaultIO, safeIoOptions),
        selectedNetwork: _normalizeMonitorOption(
          settings?.defaultNetwork,
          safeNetworkOptions,
        ),
      );
      notifyListeners();
    } catch (e, stackTrace) {
      _recordError('加载监控设置', e, stackTrace: stackTrace);
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
      await _ensureService();
      final success = await _service!.updateSetting(
        interval: interval,
        retention: retention,
        enabled: enabled,
        defaultIO: defaultIO,
        defaultNetwork: defaultNetwork,
      );
      if (success) {
        await loadSettings();
        _lastFetchTime = null;
        await load(silent: true);
      }
      return success;
    } catch (e, stackTrace) {
      _recordError('更新监控设置', e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 清理监控数据
  Future<bool> cleanData() async {
    try {
      await _ensureService();
      return await _service!.cleanData();
    } catch (e, stackTrace) {
      _recordError('清理监控数据', e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 加载GPU信息
  Future<void> loadGPUInfo() async {
    try {
      await _ensureService();
      final gpuInfo = await _service!.getGPUInfo();
      _lastGpuRefreshAt = DateTime.now();
      _data = _data.copyWith(gpuInfo: gpuInfo);
      notifyListeners();
    } catch (e, stackTrace) {
      _recordError('加载GPU信息', e, stackTrace: stackTrace);
    }
  }
}

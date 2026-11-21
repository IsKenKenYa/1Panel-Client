import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';
import 'package:onepanel_client/data/repositories/dashboard_repository.dart';
import 'package:onepanel_client/features/dashboard/models/dashboard_view_models.dart';
import 'package:onepanel_client/features/dashboard/services/dashboard_service.dart';

export 'models/dashboard_view_models.dart';

part 'dashboard_provider_loading_part.dart';
part 'dashboard_provider_actions_part.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardProvider extends ChangeNotifier with SafeChangeNotifier {
  DashboardProvider({DashboardService? service, ApiConfig? server})
      : _service = service ??
            DashboardService(
              repository:
                  server == null ? null : DashboardRepository.forServer(server),
            );

  final DashboardService _service;
  Timer? _refreshTimer;
  final _visiblePages = <Object>{};
  bool _hasOpened = false;
  DateTime? _lastLoad;
  Future<void>? _dashboardLoad;
  Future<void>? _processLoad;
  bool _needsBase = false;
  bool _loadingLive = false;
  String _processError = '';

  DashboardStatus _status = DashboardStatus.initial;
  DashboardData _data = const DashboardData();
  String _errorMessage = '';
  List<DashboardActivity> _activities = <DashboardActivity>[];
  bool _isLoadingTopProcesses = false;
  bool _isLoadingAppLaunchers = false;
  bool _isLoadingQuickOptions = false;
  Duration _refreshInterval = const Duration(seconds: 5);
  bool _autoRefreshEnabled = false;
  bool _isRefreshing = false;

  DashboardStatus get status => _status;
  DashboardData get data => _data;
  String get errorMessage =>
      _errorMessage.isEmpty ? _processError : _errorMessage;
  List<DashboardActivity> get activities => _activities;
  bool get isLoadingTopProcesses => _isLoadingTopProcesses;
  bool get isLoadingAppLaunchers => _isLoadingAppLaunchers;
  bool get isLoadingQuickOptions => _isLoadingQuickOptions;
  Duration get refreshInterval => _refreshInterval;
  bool get autoRefreshEnabled => _autoRefreshEnabled;
  bool get isRefreshing => _isRefreshing;

  void _emitChange() {
    notifyListeners();
  }

  void setRefreshInterval(Duration interval) {
    if (interval <= Duration.zero) {
      throw ArgumentError.value(interval, 'interval');
    }
    if (_refreshInterval == interval) return;
    _refreshInterval = interval;
    _schedulePolling();
    _emitChange();
  }

  void toggleAutoRefresh(bool enabled) {
    if (_autoRefreshEnabled == enabled) return;
    _autoRefreshEnabled = enabled;
    _schedulePolling();
    _emitChange();
  }

  void setPageVisible(Object page, bool visible) {
    if (isDisposed) return;
    final wasVisible = _visiblePages.isNotEmpty;
    if (visible) {
      _visiblePages.add(page);
    } else {
      _visiblePages.remove(page);
    }
    if (wasVisible == _visiblePages.isNotEmpty) return;
    if (!_hasOpened && visible) {
      _hasOpened = true;
      _autoRefreshEnabled = true;
    }
    _schedulePolling();
    if (!visible) return;
    final lastLoad = _lastLoad;
    if (lastLoad == null ||
        (_autoRefreshEnabled &&
            DateTime.now().difference(lastLoad) >= _refreshInterval)) {
      unawaited(_poll());
    }
  }

  void _schedulePolling() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    if (_autoRefreshEnabled && _visiblePages.isNotEmpty) {
      _refreshTimer =
          Timer.periodic(_refreshInterval, (_) => unawaited(_poll()));
    }
  }

  Future<void> refresh() => loadData(silent: _status == DashboardStatus.loaded);

  Future<void> _poll() => loadData(
        silent: _status != DashboardStatus.initial,
        liveOnly: _status == DashboardStatus.loaded,
      );

  void _addActivity({
    required String title,
    required String description,
    ActivityType type = ActivityType.info,
  }) {
    _activities = [
      DashboardActivity(
        title: title,
        description: description,
        time: DateTime.now(),
        type: type,
      ),
      ..._activities.take(9),
    ];
    _emitChange();
  }

  void stopAutoRefresh() => toggleAutoRefresh(false);

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _visiblePages.clear();
    super.dispose();
  }
}

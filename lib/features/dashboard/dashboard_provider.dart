import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/features/dashboard/models/dashboard_view_models.dart';
import 'package:onepanel_client/features/dashboard/services/dashboard_service.dart';

export 'models/dashboard_view_models.dart';

part 'dashboard_provider_loading_part.dart';
part 'dashboard_provider_actions_part.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({DashboardService? service})
      : _service = service ?? DashboardService();

  final DashboardService _service;
  Timer? _refreshTimer;

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
  String get errorMessage => _errorMessage;
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
    _refreshInterval = interval;
    if (_autoRefreshEnabled) {
      _stopAutoRefresh();
      _startAutoRefresh();
    }
    _emitChange();
  }

  void toggleAutoRefresh(bool enabled) {
    _autoRefreshEnabled = enabled;
    if (enabled) {
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
    _emitChange();
  }

  void _startAutoRefresh() {
    _stopAutoRefresh();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      loadData(silent: true);
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> refresh() async {
    await loadData(silent: true);
    await loadTopProcesses();
  }

  void _addActivity({
    required String title,
    required String description,
    ActivityType type = ActivityType.info,
  }) {
    _activities.insert(
      0,
      DashboardActivity(
        title: title,
        description: description,
        time: DateTime.now(),
        type: type,
      ),
    );
    if (_activities.length > 10) {
      _activities = _activities.sublist(0, 10);
    }
    _emitChange();
  }

  void startAutoRefresh({Duration interval = const Duration(seconds: 30)}) {
    stopAutoRefresh();
    _refreshTimer = Timer.periodic(interval, (_) async {
      if (_status == DashboardStatus.loaded) {
        await refresh();
      }
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    appLogger.dWithPackage('features.dashboard.dashboard_provider', 'dispose');
    stopAutoRefresh();
    super.dispose();
  }
}

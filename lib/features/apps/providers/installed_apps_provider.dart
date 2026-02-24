import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/models/app_models.dart';
import '../app_service.dart';

/// 应用统计数据
class AppStats {
  final int total;
  final int installed;
  final int running;
  final int stopped;

  const AppStats({
    this.total = 0,
    this.installed = 0,
    this.running = 0,
    this.stopped = 0,
  });
}

class InstalledAppsProvider extends ChangeNotifier {
  final AppService _appService;
  Timer? _pollingTimer;

  InstalledAppsProvider({AppService? appService})
      : _appService = appService ?? AppService();

  List<AppInstallInfo> _installedApps = [];
  AppStats _stats = const AppStats();
  bool _isLoading = false;
  String? _error;

  List<AppInstallInfo> get installedApps => _installedApps;
  AppStats get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  void startPolling() {
    stopPolling();
    // 立即加载一次
    loadInstalledApps(silent: true);
    // 每5秒轮询一次
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      loadInstalledApps(silent: true);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> loadInstalledApps({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final result = await _appService.searchInstalledApps(
        AppInstalledSearchRequest(
          page: 1,
          pageSize: 100,
        ),
      );
      _installedApps = result.items;
      _calculateStats();
    } catch (e) {
      if (!silent) {
        _error = e.toString();
      }
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void _calculateStats() {
    int running = 0;
    int stopped = 0;
    for (var app in _installedApps) {
      if (app.status?.toLowerCase() == 'running') {
        running++;
      } else {
        stopped++;
      }
    }
    _stats = AppStats(
      total: _installedApps.length,
      installed: _installedApps.length,
      running: running,
      stopped: stopped,
    );
  }

  Future<void> operateApp(String installId, String operate) async {
    try {
      final id = int.tryParse(installId);
      if (id == null) throw Exception('Invalid install ID');
      await _appService.operateApp(id, operate);
      // 操作后立即刷新状态
      await loadInstalledApps(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAppParams(int appInstallId, Map<String, dynamic> params) async {
    try {
      await _appService.updateAppParams({
        'appInstallId': appInstallId,
        'params': params,
      });
      // Refresh after update
      await loadInstalledApps(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAppInstallConfig(Map<String, dynamic> config) async {
    try {
      await _appService.updateAppInstallConfig(config);
      await loadInstalledApps(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changeAppPort(int appInstallId, int httpPort, int httpsPort) async {
    try {
      await _appService.changeAppPort({
        'appInstallId': appInstallId,
        'httpPort': httpPort,
        'httpsPort': httpsPort,
      });
      await loadInstalledApps(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateApp(String installId) async {
    try {
      await _appService.updateApp(installId);
      // 更新后立即刷新状态
      await loadInstalledApps(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uninstallApp(String installId) async {
    try {
      await _appService.uninstallApp(installId);
      // 卸载后立即刷新状态
      await loadInstalledApps(silent: true);
    } catch (e) {
      rethrow;
    }
  }
}

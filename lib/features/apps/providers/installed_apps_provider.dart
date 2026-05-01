import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
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

class InstalledAppsProvider extends ChangeNotifier with SafeChangeNotifier {
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

  Future<void> onServerChanged() async {
    if (isDisposed) return;
    stopPolling();
    _installedApps = [];
    _stats = const AppStats();
    _error = null;
    _isLoading = false;
    _appService.resetForServerChange();
    notifyListeners();
    await loadInstalledApps();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  void startPolling() {
    if (isDisposed) return;
    stopPolling();
    // 立即加载一次
    loadInstalledApps(silent: true);
    // 每5秒轮询一次
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!isDisposed) {
        loadInstalledApps(silent: true);
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<List<AppInstallInfo>> _loadAllInstalledApps() async {
    const int pageSize = 100;
    final List<AppInstallInfo> allItems = [];
    int page = 1;
    int total = 0;

    while (true) {
      final result = await _appService.searchInstalledApps(
        AppInstalledSearchRequest(
          page: page,
          pageSize: pageSize,
        ),
      );
      allItems.addAll(result.items);
      total = result.total;

      if (result.items.isEmpty) {
        break;
      }
      if (total > 0 && allItems.length >= total) {
        break;
      }
      page++;
    }

    // Some backends return total=0 with valid list items; keep collected list.
    if (allItems.isNotEmpty) {
      return allItems;
    }
    // Fallback for environments where search endpoint is restricted.
    return _appService.getInstalledApps();
  }

  Future<void> loadInstalledApps({bool silent = false}) async {
    if (isDisposed) return;
    
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _installedApps = await _loadAllInstalledApps();
      if (isDisposed) return;
      _calculateStats();
    } catch (e) {
      if (!silent && !isDisposed) {
        _error = e.toString();
      }
    } finally {
      if (!silent && !isDisposed) {
        _isLoading = false;
      }
      if (!isDisposed) {
        notifyListeners();
      }
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
    if (isDisposed) return;
    try {
      final id = int.tryParse(installId);
      if (id == null) throw Exception('Invalid install ID');
      await _appService.operateApp(id, operate);
      if (isDisposed) return;
      // 操作后立即刷新状态
      await loadInstalledApps(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAppParams(AppInstalledParamsUpdateRequest request) async {
    if (isDisposed) return;
    try {
      await _appService.updateAppParams(request);
      if (isDisposed) return;
      // Refresh after update
      await loadInstalledApps(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAppInstallConfig(AppConfigUpdateRequest config) async {
    if (isDisposed) return;
    try {
      await _appService.updateAppInstallConfig(config);
      if (isDisposed) return;
      await loadInstalledApps(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changeAppPort(AppPortUpdateRequest request) async {
    if (isDisposed) return;
    try {
      await _appService.changeAppPort(request);
      if (isDisposed) return;
      await loadInstalledApps(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateApp(String installId) async {
    if (isDisposed) return;
    try {
      await _appService.updateApp(installId);
      if (isDisposed) return;
      // 更新后立即刷新状态
      await loadInstalledApps(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> ignoreUpdate(int appInstallId, String reason) async {
    if (isDisposed) return;
    try {
      await _appService.ignoreAppUpdate(
        AppInstalledIgnoreUpgradeRequest(
          appInstallId: appInstallId,
          reason: reason,
          scope: AppIgnoreUpgradeScope.version,
        ),
      );
      if (isDisposed) return;
      await loadInstalledApps(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelIgnoreUpdate(int appInstallId) async {
    if (isDisposed) return;
    try {
      await _appService.cancelIgnoreAppUpdate(
        AppInstalledIgnoreUpgradeRequest(
          appInstallId: appInstallId,
          reason: '',
        ),
      );
      if (isDisposed) return;
      await loadInstalledApps(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkUninstall(String installId) async {
    try {
      return await _appService.checkAppUninstall(installId);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> loadAppPort(Map<String, dynamic> request) async {
    try {
      return await _appService.loadAppPort(request);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uninstallApp(String installId) async {
    if (isDisposed) return;
    try {
      await _appService.uninstallApp(installId);
      if (isDisposed) return;
      // 卸载后立即刷新状态
      await loadInstalledApps(silent: true);
    } catch (e) {
      rethrow;
    }
  }
}

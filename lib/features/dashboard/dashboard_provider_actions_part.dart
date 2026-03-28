part of 'dashboard_provider.dart';

extension DashboardProviderActions on DashboardProvider {
  Future<void> updateAppLauncherShow(String key, bool show) async {
    try {
      await _service.updateAppLauncherShow(key: key, show: show);
      await loadAppLaunchers();
      _addActivity(
        title: 'App Launcher Updated',
        description: 'App launcher visibility changed for $key',
        type: ActivityType.success,
      );
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.dashboard.dashboard_provider',
        'updateAppLauncherShow failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> updateQuickChange(List<String> enabledKeys) async {
    try {
      await _service.updateQuickChange(enabledKeys);
      await loadQuickOptions();
      _addActivity(
        title: 'Quick Options Updated',
        description: 'Quick jump options have been updated',
        type: ActivityType.success,
      );
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.dashboard.dashboard_provider',
        'updateQuickChange failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> restartSystem() async {
    await _service.restartSystem();
    _addActivity(
      title: 'System Restart',
      description: 'System restart command sent successfully',
      type: ActivityType.success,
    );
  }

  Future<void> shutdownSystem() async {
    await _service.shutdownSystem();
    _addActivity(
      title: 'System Shutdown',
      description: 'System shutdown command sent',
      type: ActivityType.warning,
    );
  }

  Future<void> upgradeSystem() async {
    await _service.upgradeSystem();
    _addActivity(
      title: 'System Upgrade',
      description: 'System upgrade initiated',
      type: ActivityType.info,
    );
  }
}

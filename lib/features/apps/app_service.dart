import 'package:dio/dio.dart';
import '../../api/v2/app_v2.dart';
import '../../core/services/base_component.dart';
import '../../data/models/app_models.dart';

import '../../data/models/app_config_models.dart';

class AppService extends BaseComponent {
  AppService({
    AppV2Api? api,
    super.clientManager,
    super.permissionResolver,
  }) : _api = api;

  Future<Response<List<int>>> getAppIcon(String appKey) {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.getAppIcon(appKey);
    });
  }

  AppV2Api? _api;

  Future<AppV2Api> _ensureApi() async {
    if (_api != null) {
      return _api!;
    }
    _api = await clientManager.getAppApi();
    return _api!;
  }

  Future<AppSearchResponse> searchApps(AppSearchRequest request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.searchApps(request);
    });
  }

  Future<List<AppInstallInfo>> getInstalledApps() {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.getInstalledApps();
    });
  }

  Future<PageResult<AppInstallInfo>> searchInstalledApps(AppInstalledSearchRequest request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.searchInstalledApps(request);
    });
  }

  Future<void> installApp(AppInstallCreateRequest request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.installApp(request);
    });
  }

  Future<void> uninstallApp(String installId) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.uninstallApp(installId);
    });
  }

  Future<void> operateApp(int installId, String operate) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.operateApp(
        AppInstalledOperateRequest(
          installId: installId,
          operate: operate,
        ),
      );
    });
  }

  Future<void> syncInstalledApps() {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.syncAppStatus();
    });
  }

  Future<AppItem> getAppDetail(String appId, String version, String type) {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.getAppDetail(appId, version, type);
    });
  }

  Future<AppDetailSimple> getAppDetailNode(String appKey, String version) {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.getAppDetailNode(appKey, version);
    });
  }

  Future<AppInstallInfo> getAppInstallInfo(String appInstallId) {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.getAppInstallInfo(appInstallId);
    });
  }

  Future<Map<String, dynamic>> getAppInstallConfig(String name, String key) {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.getAppInstallConfig(name, key);
    });
  }

  Future<AppConfig> getAppInstallParams(String appInstallId) {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.getAppInstallParams(int.parse(appInstallId));
    });
  }

  Future<AppstoreConfigResponse> getAppstoreConfig() {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.getAppstoreConfig();
    });
  }

  Future<void> updateAppstoreConfig(AppstoreUpdateRequest request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.updateAppstoreConfig(request);
    });
  }

  Future<void> updateAppInstallConfig(Map<String, dynamic> config) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.updateAppInstallConfig(config);
    });
  }

  Future<void> syncRemoteApps() {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.syncRemoteApps();
    });
  }

  Future<void> syncLocalApps() {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.syncLocalApps();
    });
  }

  Future<List<AppInstallInfo>> getIgnoredAppDetails() {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.getIgnoredAppDetails();
    });
  }

  Future<void> ignoreAppUpdate(AppInstalledIgnoreUpgradeRequest request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.ignoreAppUpdate(request);
    });
  }

  Future<void> cancelIgnoreAppUpdate(AppInstalledIgnoreUpgradeRequest request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.cancelIgnoreAppUpdate(request);
    });
  }

  Future<AppInstalledCheckResponse> checkAppInstall(AppInstalledCheckRequest request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.checkAppInstall(request);
    });
  }

  Future<Map<String, dynamic>> checkAppUninstall(String appInstallId) {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.checkAppUninstall(appInstallId);
    });
  }

  Future<int> loadAppPort(Map<String, dynamic> request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.loadAppPort(request);
    });
  }

  Future<AppUpdateResponse> checkAppUpdate() {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.checkAppUpdate();
    });
  }

  Future<List<AppVersion>> getAppUpdateVersions(String appInstallId) {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.getAppUpdateVersions(appInstallId);
    });
  }

  Future<List<AppServiceResponse>> getAppServices(String key) {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.getAppServices(key);
    });
  }

  Future<void> updateApp(String appInstallId) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.updateApp(appInstallId);
    });
  }

  Future<void> updateAppParams(Map<String, dynamic> request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.updateAppParams(request);
    });
  }

  Future<void> changeAppPort(Map<String, dynamic> request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.changeAppPort(request);
    });
  }

  Future<Map<String, dynamic>> getAppConnInfo(String name, String key) {
    return runGuarded(() async {
      final api = await _ensureApi();
      return api.getAppConnInfo(name, key);
    });
  }
}

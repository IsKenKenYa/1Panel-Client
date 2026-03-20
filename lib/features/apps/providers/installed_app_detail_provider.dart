import 'package:flutter/foundation.dart';
import 'package:onepanelapp_app/core/services/logger/logger_service.dart';
import 'package:onepanelapp_app/data/models/app_config_models.dart';
import 'package:onepanelapp_app/data/models/app_models.dart';
import 'package:onepanelapp_app/data/models/container_models.dart';
import 'package:onepanelapp_app/features/apps/app_service.dart';
import 'package:onepanelapp_app/features/containers/container_service.dart';

class InstalledAppDetailProvider extends ChangeNotifier {
  final AppService _appService;
  final ContainerService _containerService;

  InstalledAppDetailProvider({
    AppService? appService,
    ContainerService? containerService,
  })  : _appService = appService ?? AppService(),
        _containerService = containerService ?? ContainerService();

  AppInstallInfo? _appInfo;
  AppItem? _storeDetail;
  List<AppServiceResponse> _services = const [];
  AppConfig? _appConfig;
  List<AppVersion> _updateVersions = const [];

  bool _loading = false;
  String? _error;

  String? _storeDetailError;
  String? _servicesError;
  String? _configError;
  String? _updateVersionsError;

  String? _appId;

  AppInstallInfo? get appInfo => _appInfo;
  AppItem? get storeDetail => _storeDetail;
  List<AppServiceResponse> get services => _services;
  AppConfig? get appConfig => _appConfig;
  List<AppVersion> get updateVersions => _updateVersions;
  bool get loading => _loading;
  String? get error => _error;
  String? get storeDetailError => _storeDetailError;
  String? get servicesError => _servicesError;
  String? get configError => _configError;
  String? get updateVersionsError => _updateVersionsError;

  bool get hasUpdate => _updateVersions.isNotEmpty;

  Future<void> initialize({AppInstallInfo? appInfo, String? appId}) async {
    _appInfo = appInfo;
    _appId = appId;
    await refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    _storeDetailError = null;
    _servicesError = null;
    _configError = null;
    _updateVersionsError = null;
    notifyListeners();

    try {
      if (_appInfo == null && _appId != null) {
        _appInfo = await _appService.getAppInstallInfo(_appId!);
      }

      if (_appInfo == null) {
        _error = 'App install info is empty';
        _loading = false;
        notifyListeners();
        return;
      }

      final String version = _appInfo!.version ?? 'latest';
      final String type = _appInfo!.appType ?? 'app';

      if (_appInfo!.appId != null) {
        try {
          _storeDetail = await _appService.getAppDetail(
            _appInfo!.appId!.toString(),
            version,
            type,
          );
        } catch (e) {
          _storeDetailError = e.toString();
          appLogger.wWithPackage(
            'features.apps.providers.installed_app_detail_provider',
            'Failed to load store detail',
            error: e,
          );
        }
      }

      if (_appInfo!.appKey != null && _appInfo!.appKey!.isNotEmpty) {
        try {
          _services = await _appService.getAppServices(_appInfo!.appKey!);
        } catch (e) {
          _servicesError = e.toString();
          _services = const [];
          appLogger.wWithPackage(
            'features.apps.providers.installed_app_detail_provider',
            'Failed to load app services',
            error: e,
          );
        }
      }

      if (_appInfo!.id != null) {
        try {
          _appConfig = await _appService.getAppInstallParams(_appInfo!.id.toString());
        } catch (e) {
          _configError = e.toString();
          _appConfig = null;
          appLogger.wWithPackage(
            'features.apps.providers.installed_app_detail_provider',
            'Failed to load app config',
            error: e,
          );
        }

        if (_appInfo!.canUpdate == true) {
          try {
            _updateVersions = await _appService.getAppUpdateVersions(_appInfo!.id.toString());
          } catch (e) {
            _updateVersionsError = e.toString();
            _updateVersions = const [];
            appLogger.wWithPackage(
              'features.apps.providers.installed_app_detail_provider',
              'Failed to load app update versions',
              error: e,
            );
          }
        } else {
          _updateVersions = const [];
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getConnectionInfo() async {
    if (_appInfo?.name == null || _appInfo?.appKey == null) {
      return {};
    }
    return _appService.getAppConnInfo(_appInfo!.name!, _appInfo!.appKey!);
  }

  Future<ContainerInfo?> findInstalledContainer() async {
    final containerName = _appInfo?.container;
    if (containerName == null || containerName.isEmpty) {
      return null;
    }

    final containers = await _containerService.listContainers();
    for (final container in containers) {
      if (container.name == containerName || container.name == '/$containerName') {
        return container;
      }
    }
    return null;
  }

  Future<void> syncInstallInfo() async {
    if (_appInfo?.id == null) {
      return;
    }
    _appInfo = await _appService.getAppInstallInfo(_appInfo!.id.toString());
    notifyListeners();
  }
}

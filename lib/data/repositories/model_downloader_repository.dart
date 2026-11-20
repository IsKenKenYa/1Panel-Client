import 'package:onepanel_client/api/v2/setting_v2.dart';
import 'package:onepanel_client/api/v2/xpack_model_downloader_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';

/// 模型下载器仓库。
///
/// 模型目录、下载任务与本地模型走 [XpackModelDownloaderV2Api]；
/// 下载设置端点位于 `setting_v2.dart`，复用同一个客户端实例。
class ModelDownloaderRepository {
  ModelDownloaderRepository({
    ApiClientManager? clientManager,
    XpackModelDownloaderV2Api? api,
    SettingV2Api? settingApi,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api,
        _settingApi = settingApi;

  final ApiClientManager _clientManager;
  XpackModelDownloaderV2Api? _api;
  SettingV2Api? _settingApi;

  Future<XpackModelDownloaderV2Api> ensureApi() async {
    try {
      _api ??= await _clientManager.getXpackModelDownloaderApi();
      return _api!;
    } catch (e) {
      if (e is StateError && e.message == 'No API config available') {
        throw const NetworkConnectionException('未配置服务器连接');
      }
      rethrow;
    }
  }

  Future<SettingV2Api> ensureSettingApi() async {
    try {
      _settingApi ??= await _clientManager.getSettingApi();
      return _settingApi!;
    } catch (e) {
      if (e is StateError && e.message == 'No API config available') {
        throw const NetworkConnectionException('未配置服务器连接');
      }
      rethrow;
    }
  }

  void resetForServerChange() {
    _api = null;
    _settingApi = null;
  }
}

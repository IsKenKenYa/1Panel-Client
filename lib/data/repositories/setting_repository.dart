import 'package:onepanel_client/api/v2/setting_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';

class SettingRepository {
  SettingRepository({
    ApiClientManager? clientManager,
    SettingV2Api? api,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api;

  final ApiClientManager _clientManager;
  SettingV2Api? _api;

  Future<SettingV2Api> ensureApi() async {
    _api ??= await _clientManager.getSettingApi();
    return _api!;
  }

  void resetForServerChange() {
    _api = null;
  }
}

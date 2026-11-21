import 'package:onepanel_client/api/v2/setting_v2.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';

class SettingRepository {
  SettingRepository({
    ApiClientManager? clientManager,
    SettingV2Api? api,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api,
        _server = null;

  SettingRepository.forServer(ApiConfig server)
      : _server = server,
        _clientManager = ApiClientManager.instance;

  final ApiClientManager _clientManager;
  final ApiConfig? _server;
  SettingV2Api? _api;

  Future<SettingV2Api> ensureApi() async {
    final server = _server;
    _api ??= server == null
        ? await _clientManager.getSettingApi()
        : SettingV2Api(await _clientManager.getClientForServer(server));
    return _api!;
  }

  void resetForServerChange() {
    _api = null;
  }
}

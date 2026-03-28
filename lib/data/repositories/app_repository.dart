import 'package:onepanel_client/api/v2/app_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';

class AppRepository {
  AppRepository({
    ApiClientManager? clientManager,
    AppV2Api? api,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api;

  final ApiClientManager _clientManager;
  AppV2Api? _api;

  Future<AppV2Api> ensureApi() async {
    _api ??= await _clientManager.getAppApi();
    return _api!;
  }

  void resetForServerChange() {
    _api = null;
  }
}

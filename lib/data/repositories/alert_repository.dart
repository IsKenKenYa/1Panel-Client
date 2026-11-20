import 'package:onepanel_client/api/v2/alert_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';

class AlertRepository {
  AlertRepository({
    ApiClientManager? clientManager,
    AlertV2Api? api,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api;

  final ApiClientManager _clientManager;
  AlertV2Api? _api;

  Future<AlertV2Api> ensureApi() async {
    try {
      _api ??= await _clientManager.getAlertApi();
      return _api!;
    } catch (e) {
      if (e is StateError && e.message == 'No API config available') {
        throw const NetworkConnectionException('未配置服务器连接');
      }
      rethrow;
    }
  }

  void resetForServerChange() {
    _api = null;
  }
}

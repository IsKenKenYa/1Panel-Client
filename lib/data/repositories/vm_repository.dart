import 'package:onepanel_client/api/v2/vm_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';

class VMRepository {
  VMRepository({
    ApiClientManager? clientManager,
    VMV2Api? api,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api;

  final ApiClientManager _clientManager;
  VMV2Api? _api;

  Future<VMV2Api> ensureApi() async {
    try {
      _api ??= await _clientManager.getVMApi();
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

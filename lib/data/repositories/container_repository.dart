import 'package:onepanel_client/api/v2/container_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';

class ContainerRepository {
  ContainerRepository({
    ApiClientManager? clientManager,
    ContainerV2Api? api,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api;

  final ApiClientManager _clientManager;
  ContainerV2Api? _api;

  Future<ContainerV2Api> ensureApi() async {
    _api ??= await _clientManager.getContainerApi();
    return _api!;
  }

  void resetForServerChange() {
    _api = null;
  }
}

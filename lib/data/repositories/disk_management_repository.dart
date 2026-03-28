import 'package:onepanel_client/api/v2/disk_management_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/disk_management_models.dart';

class DiskManagementRepository {
  DiskManagementRepository({
    ApiClientManager? clientManager,
    DiskManagementV2Api? api,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api;

  final ApiClientManager _clientManager;
  DiskManagementV2Api? _api;

  Future<DiskManagementV2Api> _ensureApi() async {
    return _api ??= await _clientManager.getDiskManagementApi();
  }

  Future<CompleteDiskInfo> getCompleteDiskInfo() async {
    final api = await _ensureApi();
    return (await api.getCompleteDiskInfo()).data ?? const CompleteDiskInfo();
  }

  Future<void> mountDisk(DiskMountRequest request) async {
    final api = await _ensureApi();
    await api.mountDisk(request);
  }

  Future<void> partitionDisk(DiskPartitionRequest request) async {
    final api = await _ensureApi();
    await api.partitionDisk(request);
  }

  Future<void> unmountDisk(DiskUnmountRequest request) async {
    final api = await _ensureApi();
    await api.unmountDisk(request);
  }
}

import 'package:onepanel_client/data/models/disk_management_models.dart';
import 'package:onepanel_client/data/repositories/disk_management_repository.dart';

class ToolboxDiskService {
  ToolboxDiskService({DiskManagementRepository? repository})
      : _repository = repository ?? DiskManagementRepository();

  final DiskManagementRepository _repository;

  Future<CompleteDiskInfo> loadSnapshot() {
    return _repository.getCompleteDiskInfo();
  }

  Future<void> mountDisk(DiskMountRequest request) {
    return _repository.mountDisk(request);
  }

  Future<void> partitionDisk(DiskPartitionRequest request) {
    return _repository.partitionDisk(request);
  }

  Future<void> unmountDisk(DiskUnmountRequest request) {
    return _repository.unmountDisk(request);
  }
}

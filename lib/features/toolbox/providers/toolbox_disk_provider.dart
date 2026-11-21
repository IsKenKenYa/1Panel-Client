import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'toolbox_snapshot_provider.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/disk_management_models.dart';
import 'package:onepanel_client/features/toolbox/services/toolbox_disk_service.dart';

class ToolboxDiskProvider extends ToolboxSnapshotProvider {
  ToolboxDiskProvider({ToolboxDiskService? service, String? serverId})
      : _service = service ?? ToolboxDiskService(serverId: serverId);

  final ToolboxDiskService _service;

  bool _isMutating = false;
  String? _error;
  CompleteDiskInfo _diskInfo = const CompleteDiskInfo();

  bool get isMutating => _isMutating;
  String? get error => _error ?? loadError;
  CompleteDiskInfo get diskInfo => _diskInfo;
  List<DiskInfo> get dataDisks => _diskInfo.disks
      .where((DiskInfo item) => !item.isSystem)
      .toList(growable: false);

  Future<void> load() {
    _error = null;
    return loadSnapshot(
      fetch: _service.loadSnapshot,
      apply: (snapshot) => _diskInfo = snapshot,
      logPackage: 'features.toolbox.providers.toolbox_disk',
    );
  }

  Future<bool> mountDisk(DiskMountRequest request) async {
    return _runMutation(() => _service.mountDisk(request));
  }

  Future<bool> partitionDisk(DiskPartitionRequest request) async {
    return _runMutation(() => _service.partitionDisk(request));
  }

  Future<bool> unmountDisk(DiskUnmountRequest request) async {
    return _runMutation(() => _service.unmountDisk(request));
  }

  Future<bool> _runMutation(Future<void> Function() action) async {
    if (isDisposed) return false;
    _isMutating = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      await load();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_disk',
        'disk mutation failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = ErrorMessageUtils.userFacingMessage(error);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}

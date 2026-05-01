import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/disk_management_models.dart';
import 'package:onepanel_client/features/toolbox/services/toolbox_disk_service.dart';

class ToolboxDiskProvider extends ChangeNotifier with SafeChangeNotifier {
  ToolboxDiskProvider({ToolboxDiskService? service})
      : _service = service ?? ToolboxDiskService();

  final ToolboxDiskService _service;

  bool _isLoading = false;
  bool _isMutating = false;
  String? _error;
  CompleteDiskInfo _diskInfo = const CompleteDiskInfo();

  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get error => _error;
  CompleteDiskInfo get diskInfo => _diskInfo;
  List<DiskInfo> get dataDisks => _diskInfo.disks
      .where((DiskInfo item) => !item.isSystem)
      .toList(growable: false);

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _diskInfo = await _service.loadSnapshot();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_disk',
        'load disk info failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      _error = error.toString();
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}

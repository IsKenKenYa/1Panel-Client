import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import '../../../data/models/vm/vm_models.dart';
import '../../../data/models/vm/vm_resource_models.dart';
import '../vm_service.dart';

/// 按分区维护的加载状态；六个 Tab 各自独立，互不阻塞。
class VmSectionState {
  const VmSectionState({
    this.isLoading = false,
    this.error,
  });

  final bool isLoading;
  final String? error;

  VmSectionState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return VmSectionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 虚拟机模块状态。
///
/// 六个分区（环境/实例/ISO/模板/网络/存储池）各自持有列表与加载状态；
/// 环境未就绪时其余分区仍可加载，由界面按环境结果给出提示与启用入口。
class VmProvider extends ChangeNotifier with SafeChangeNotifier {
  VmProvider({VMService? service}) : _service = service ?? VMService();

  final VMService _service;

  VMEnvironment _environment = const VMEnvironment();
  VmSectionState _environmentState = const VmSectionState();

  List<VMItem> _vms = const <VMItem>[];
  int _vmTotal = 0;
  int _vmLimit = 0;
  VmSectionState _vmState = const VmSectionState();
  String _vmSearch = '';
  String? _vmStatusFilter;

  List<VMIsoItem> _isos = const <VMIsoItem>[];
  VmSectionState _isoState = const VmSectionState();

  List<VMTemplateItem> _templates = const <VMTemplateItem>[];
  VmSectionState _templateState = const VmSectionState();

  List<VMNetworkItem> _networks = const <VMNetworkItem>[];
  VmSectionState _networkState = const VmSectionState();

  List<VMStorageItem> _storages = const <VMStorageItem>[];
  VmSectionState _storageState = const VmSectionState();

  bool _isMutating = false;

  VMEnvironment get environment => _environment;
  VmSectionState get environmentState => _environmentState;
  bool get environmentReady => _environment.ready;

  List<VMItem> get vms => _vms;
  int get vmTotal => _vmTotal;
  int get vmLimit => _vmLimit;
  VmSectionState get vmState => _vmState;
  String get vmSearch => _vmSearch;
  String? get vmStatusFilter => _vmStatusFilter;

  List<VMIsoItem> get isos => _isos;
  VmSectionState get isoState => _isoState;

  List<VMTemplateItem> get templates => _templates;
  VmSectionState get templateState => _templateState;

  List<VMNetworkItem> get networks => _networks;
  VmSectionState get networkState => _networkState;

  List<VMStorageItem> get storages => _storages;
  VmSectionState get storageState => _storageState;

  bool get isMutating => _isMutating;

  /// 已分配的 CPU 核数之和。
  int get allocatedCpu =>
      _vms.fold<int>(0, (sum, vm) => sum + vm.cpu);

  /// 已分配的内存（MiB）之和。
  int get allocatedMemory =>
      _vms.fold<int>(0, (sum, vm) => sum + vm.memory);

  /// 已分配的磁盘（字节）之和。
  int get allocatedDisk =>
      _vms.fold<int>(0, (sum, vm) => sum + vm.diskSize);

  /// 是否有可用的虚拟机数量配额；limit 为 0 表示不限制。
  bool get canCreateVm => _vmLimit == 0 || _vms.length < _vmLimit;

  Future<void> onServerChanged() async {
    _service.resetForServerChange();
    _environment = const VMEnvironment();
    _environmentState = const VmSectionState();
    _vms = const <VMItem>[];
    _vmTotal = 0;
    _vmLimit = 0;
    _vmState = const VmSectionState();
    _isos = const <VMIsoItem>[];
    _isoState = const VmSectionState();
    _templates = const <VMTemplateItem>[];
    _templateState = const VmSectionState();
    _networks = const <VMNetworkItem>[];
    _networkState = const VmSectionState();
    _storages = const <VMStorageItem>[];
    _storageState = const VmSectionState();
    notifyListeners();
    await loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadEnvironment(),
      loadVms(),
      loadIsos(),
      loadTemplates(),
      loadNetworks(),
      loadStorages(),
    ]);
  }

  // ==================== 环境 ====================

  Future<void> loadEnvironment() async {
    if (isDisposed) return;
    _environmentState = const VmSectionState(isLoading: true);
    notifyListeners();
    try {
      _environment = await _service.checkEnvironment();
      _environmentState = const VmSectionState();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.vm.provider',
        'loadEnvironment failed',
        error: error,
        stackTrace: stackTrace,
      );
      _environmentState = VmSectionState(
        error: ErrorMessageUtils.userFacingMessage(error),
      );
    } finally {
      if (!isDisposed) notifyListeners();
    }
  }

  /// 启用虚拟机运行环境；成功后重新读取环境状态。
  Future<bool> enableEnvironment() async {
    return _mutate(() async {
      await _service.enableEnvironment();
      await loadEnvironment();
      return true;
    });
  }

  // ==================== 实例 ====================

  Future<void> loadVms() async {
    if (isDisposed) return;
    _vmState = const VmSectionState(isLoading: true);
    notifyListeners();
    try {
      final result = await _service.searchVMs(info: _vmSearch);
      _vms = result.items
          .where((vm) =>
              _vmStatusFilter == null || vm.status == _vmStatusFilter)
          .toList(growable: false);
      _vmTotal = result.total;
      _vmLimit = result.limit;
      _vmState = const VmSectionState();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.vm.provider',
        'loadVms failed',
        error: error,
        stackTrace: stackTrace,
      );
      _vms = const <VMItem>[];
      _vmState = VmSectionState(
        error: ErrorMessageUtils.userFacingMessage(error),
      );
    } finally {
      if (!isDisposed) notifyListeners();
    }
  }

  Future<void> setVmSearch(String value) async {
    _vmSearch = value.trim();
    await loadVms();
  }

  Future<void> setVmStatusFilter(String? status) async {
    _vmStatusFilter = status;
    await loadVms();
  }

  Future<void> syncVms() async {
    await _mutate(() async {
      await _service.syncVMs();
      await loadVms();
    });
  }

  Future<VMItem> loadVmDetail(String name, {bool checkDisks = false}) async {
    return _service.getVMInfo(name, checkDisks: checkDisks);
  }

  Future<VMHealthCheckResult> healthCheck(String name) async {
    return _service.healthCheck(name);
  }

  /// 读取实时统计，供监控弹层按固定间隔轮询。
  Future<VMStats> getStats(String name) async {
    return _service.getVMStats(name);
  }

  Future<VMGraphics> loadConsole(String name) async {
    return _service.getConsole(name);
  }

  /// 获取面板网页端 VNC 控制台地址。
  Future<String> consoleUrl({
    required String name,
    required String baseUrl,
  }) async {
    return _service.buildConsoleUrl(name: name, baseUrl: baseUrl);
  }

  Future<void> operate(String name, String operation) async {
    await _mutate(() async {
      await _service.operateVM(name, operation);
      await loadVms();
    });
  }

  Future<void> createVm(VMCreate request) async {
    await _mutate(() async {
      await _service.createVM(request);
      await loadVms();
      await loadStorages();
    });
  }

  Future<void> updateVm(VMUpdate request) async {
    await _mutate(() async {
      await _service.updateVM(request);
      await loadVms();
    });
  }

  Future<void> deleteVm(int id, {bool force = false}) async {
    await _mutate(() async {
      await _service.deleteVM(id, force: force);
      await loadVms();
      await loadStorages();
    });
  }

  Future<void> renameVm(String name, String newName) async {
    await _mutate(() async {
      await _service.renameVM(name, newName);
      await loadVms();
    });
  }

  Future<void> resizeDisk({
    required String name,
    required String target,
    required int sizeGiB,
  }) async {
    await _mutate(() async {
      await _service.resizeDisk(
        name: name,
        target: target,
        sizeGiB: sizeGiB,
      );
      await loadVms();
    });
  }

  // ==================== 快照 ====================

  Future<List<VMSnapshotItem>> listSnapshots(String name) async {
    return _service.listSnapshots(name);
  }

  Future<void> createSnapshot(VMSnapshotReq request) async {
    await _mutate(() => _service.createSnapshot(request));
  }

  Future<void> recoverSnapshot(VMSnapshotReq request) async {
    await _mutate(() => _service.recoverSnapshot(request));
  }

  Future<void> deleteSnapshot(VMSnapshotReq request) async {
    await _mutate(() => _service.deleteSnapshot(request));
  }

  // ==================== ISO ====================

  Future<void> loadIsos() async {
    if (isDisposed) return;
    _isoState = const VmSectionState(isLoading: true);
    notifyListeners();
    try {
      _isos = await _service.listIso();
      _isoState = const VmSectionState();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.vm.provider',
        'loadIsos failed',
        error: error,
        stackTrace: stackTrace,
      );
      _isos = const <VMIsoItem>[];
      _isoState = VmSectionState(
        error: ErrorMessageUtils.userFacingMessage(error),
      );
    } finally {
      if (!isDisposed) notifyListeners();
    }
  }

  Future<void> createIso(VMIsoCreate request) async {
    await _mutate(() async {
      await _service.createIso(request);
      await loadIsos();
    });
  }

  Future<void> updateIso(VMIsoUpdate request) async {
    await _mutate(() async {
      await _service.updateIso(request);
      await loadIsos();
    });
  }

  Future<void> deleteIso(int id, {bool deleteFile = false}) async {
    await _mutate(() async {
      await _service.deleteIso(id, deleteFile: deleteFile);
      await loadIsos();
    });
  }

  Future<int> startIsoImport(VMIsoImportStart request) async {
    final id = await _mutate(() => _service.startIsoImport(request));
    await loadIsos();
    return id;
  }

  Future<void> updateIsoImport(VMIsoImportUpdate request) async {
    await _mutate(() => _service.updateIsoImport(request));
  }

  // ==================== 模板 ====================

  Future<void> loadTemplates() async {
    if (isDisposed) return;
    _templateState = const VmSectionState(isLoading: true);
    notifyListeners();
    try {
      _templates = await _service.listTemplates();
      _templateState = const VmSectionState();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.vm.provider',
        'loadTemplates failed',
        error: error,
        stackTrace: stackTrace,
      );
      _templates = const <VMTemplateItem>[];
      _templateState = VmSectionState(
        error: ErrorMessageUtils.userFacingMessage(error),
      );
    } finally {
      if (!isDisposed) notifyListeners();
    }
  }

  Future<void> createTemplate(VMTemplateCreate request) async {
    await _mutate(() async {
      await _service.createTemplate(request);
      await loadTemplates();
    });
  }

  Future<void> deleteTemplate(int id, {bool deleteDisk = false}) async {
    await _mutate(() async {
      await _service.deleteTemplate(id, deleteDisk: deleteDisk);
      await loadTemplates();
    });
  }

  // ==================== 网络 ====================

  Future<void> loadNetworks() async {
    if (isDisposed) return;
    _networkState = const VmSectionState(isLoading: true);
    notifyListeners();
    try {
      _networks = await _service.listNetworks();
      _networkState = const VmSectionState();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.vm.provider',
        'loadNetworks failed',
        error: error,
        stackTrace: stackTrace,
      );
      _networks = const <VMNetworkItem>[];
      _networkState = VmSectionState(
        error: ErrorMessageUtils.userFacingMessage(error),
      );
    } finally {
      if (!isDisposed) notifyListeners();
    }
  }

  Future<List<VMNetworkBridgeItem>> listBridges() async {
    return _service.listNetworkBridges();
  }

  Future<List<VMNetworkInterfaceItem>> listInterfaces() async {
    return _service.listNetworkInterfaces();
  }

  Future<void> createNetwork(VMNetworkCreate request) async {
    await _mutate(() async {
      await _service.createNetwork(request);
      await loadNetworks();
    });
  }

  Future<void> updateNetwork(VMNetworkUpdate request) async {
    await _mutate(() async {
      await _service.updateNetwork(request);
      await loadNetworks();
    });
  }

  Future<void> deleteNetwork(int id) async {
    await _mutate(() async {
      await _service.deleteNetwork(id);
      await loadNetworks();
    });
  }

  // ==================== 存储池 ====================

  Future<void> loadStorages() async {
    if (isDisposed) return;
    _storageState = const VmSectionState(isLoading: true);
    notifyListeners();
    try {
      _storages = await _service.listStorages();
      _storageState = const VmSectionState();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.vm.provider',
        'loadStorages failed',
        error: error,
        stackTrace: stackTrace,
      );
      _storages = const <VMStorageItem>[];
      _storageState = VmSectionState(
        error: ErrorMessageUtils.userFacingMessage(error),
      );
    } finally {
      if (!isDisposed) notifyListeners();
    }
  }

  Future<void> createStorage(VMStorageCreate request) async {
    await _mutate(() async {
      await _service.createStorage(request);
      await loadStorages();
    });
  }

  Future<void> updateStorage(VMStorageUpdate request) async {
    await _mutate(() async {
      await _service.updateStorage(request);
      await loadStorages();
    });
  }

  Future<void> deleteStorage(int id) async {
    await _mutate(() async {
      await _service.deleteStorage(id);
      await loadStorages();
    });
  }

  // ==================== 孤儿数据 ====================

  Future<List<VMOrphanItem>> scanOrphans() async {
    return _service.scanOrphans();
  }

  Future<List<VMOrphanItem>> cleanOrphans(List<VMOrphanItem> items) async {
    final remaining = await _mutate(() => _service.cleanOrphans(items));
    await loadStorages();
    return remaining;
  }

  /// 统一包装写操作：标记变更中状态，出错时向上抛出供界面展示。
  Future<T> _mutate<T>(Future<T> Function() action) async {
    if (isDisposed) throw StateError('Provider 已释放');
    _isMutating = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      if (!isDisposed) {
        _isMutating = false;
        notifyListeners();
      }
    }
  }
}

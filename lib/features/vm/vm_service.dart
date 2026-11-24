import '../../api/v2/vm_v2.dart';
import '../../core/services/base_component.dart';
import '../../data/models/common_models.dart';
import '../../data/models/vm/vm_models.dart';
import '../../data/models/vm/vm_resource_models.dart';
import '../../data/repositories/vm_repository.dart';

/// 虚拟机业务服务。
///
/// 转发 `VMV2Api` 并承担三处加工：异步任务句柄归一、ISO 导入记录 id 校验、
/// 消费者视图侧的图形控制台地址拼装。
class VMService extends BaseComponent {
  VMService({
    VMRepository? repository,
    VMV2Api? api,
    super.clientManager,
    super.permissionResolver,
  }) : _repository = repository ??
            VMRepository(
              clientManager: clientManager,
              api: api,
            );

  final VMRepository _repository;

  Future<VMV2Api> _ensureApi() => _repository.ensureApi();

  void resetForServerChange() {
    _repository.resetForServerChange();
  }

  /// 任务句柄缺失时就地判定失败：异步操作没有 taskID 无法追踪结果。
  ///
  /// 上游 `dto.VMTaskResp` 的 taskID 是值类型字符串，服务端一定返回该键，
  /// 但排队失败等场景可能回空串，空串同样无法追踪，按失败处理。
  static VMTaskResp _requireTaskResp(VMTaskResp? data, String operation) {
    if (data == null || data.taskID.isEmpty) {
      throw StateError('服务端未返回$operation的任务编号');
    }
    return data;
  }

  // ==================== 环境 ====================

  Future<VMEnvironment> checkEnvironment() {
    return runGuarded(() async {
      final response = await (await _ensureApi()).getVMEnvironment();
      final data = response.data;
      if (data == null) {
        throw StateError('服务端未返回虚拟机环境检测结果');
      }
      return data;
    });
  }

  Future<void> enableEnvironment() {
    return runGuarded(() async {
      await (await _ensureApi()).enableVMEnvironment();
    });
  }

  // ==================== 实例 ====================

  Future<VMSearchResult> searchVMs({String? info, int page = 1, int pageSize = 100}) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).searchVMs(
        SearchWithPage(
          info: info,
          page: page,
          pageSize: pageSize,
        ),
      );
      final data = response.data;
      if (data == null) {
        throw StateError('服务端未返回虚拟机列表');
      }
      return data;
    });
  }

  Future<void> syncVMs() {
    return runGuarded(() async {
      await (await _ensureApi()).syncVMs();
    });
  }

  Future<VMItem> getVMInfo(String name, {bool checkDisks = false}) {
    return runGuarded(() async {
      final response =
          await (await _ensureApi()).getVMInfo(VMInfoReq(name: name, checkDisks: checkDisks));
      final data = response.data;
      if (data == null) {
        throw StateError('服务端未返回虚拟机 $name 的详情');
      }
      return data;
    });
  }

  Future<VMHealthCheckResult> healthCheck(String name) {
    return runGuarded(() async {
      final response = await (await _ensureApi())
          .healthCheckVM(OperationWithName(name: name));
      final data = response.data;
      if (data == null) {
        throw StateError('服务端未返回虚拟机 $name 的健康检查结果');
      }
      return data;
    });
  }

  Future<VMStats> getVMStats(String name) {
    return runGuarded(() async {
      final response =
          await (await _ensureApi()).getVMStats(OperationWithName(name: name));
      final data = response.data;
      if (data == null) {
        throw StateError('服务端未返回虚拟机 $name 的实时统计');
      }
      return data;
    });
  }

  Future<VMTaskResp> createVM(VMCreate request) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).createVM(request);
      return _requireTaskResp(response.data, '创建虚拟机');
    });
  }

  Future<VMTaskResp> updateVM(VMUpdate request) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).updateVM(request);
      return _requireTaskResp(response.data, '更新虚拟机');
    });
  }

  Future<void> operateVM(String name, String operate) {
    return runGuarded(() async {
      await (await _ensureApi())
          .operateVM(VMOperate(name: name, operate: operate));
    });
  }

  Future<VMTaskResp> deleteVM(int id, {bool force = false}) {
    return runGuarded(() async {
      final response =
          await (await _ensureApi()).deleteVM(VMDelete(id: id, force: force));
      return _requireTaskResp(response.data, '删除虚拟机');
    });
  }

  Future<VMTaskResp> resizeDisk({
    required String name,
    required String target,
    required int sizeGiB,
  }) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).resizeVMDisk(
        VMDiskResize(name: name, target: target, sizeGiB: sizeGiB),
      );
      return _requireTaskResp(response.data, '扩容磁盘');
    });
  }

  Future<VMTaskResp> renameVM(String name, String newName) {
    return runGuarded(() async {
      final response =
          await (await _ensureApi()).renameVM(VMRename(name: name, newName: newName));
      return _requireTaskResp(response.data, '重命名虚拟机');
    });
  }

  /// 加载图形控制台信息。
  Future<VMGraphics> getConsole(String name) {
    return runGuarded(() async {
      final response =
          await (await _ensureApi()).getVMConsole(OperationWithName(name: name));
      final data = response.data;
      if (data == null) {
        throw StateError('服务端未返回虚拟机 $name 的控制台信息');
      }
      return data;
    });
  }

  /// 组装面板网页端 VNC 控制台地址。
  ///
  /// 服务端 `GET /vms/console/ws` 为 WebSocket 升级端点，需要面板认证请求头；
  /// 客户端不实现 RFB 渲染，用面板自身的网页控制台承载。
  /// 返回 [VMGraphics.url] 已给出时优先使用该地址，否则由 [baseUrl] 拼装。
  Future<String> buildConsoleUrl({
    required String name,
    required String baseUrl,
  }) {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.getVMConsole(OperationWithName(name: name));
      final graphics = response.data;
      if (graphics == null) {
        throw StateError('服务端未返回虚拟机 $name 的控制台信息');
      }
      final explicit = graphics.url;
      if (explicit != null && explicit.isNotEmpty) {
        return explicit;
      }
      return composeConsoleUrl(baseUrl: baseUrl, name: name);
    });
  }

  /// 由面板地址拼装控制台网页路径。
  ///
  /// 面板的 VNC 控制台页位于 `/vm/list`，查询参数 `name` 选中目标虚拟机。
  static String composeConsoleUrl({
    required String baseUrl,
    required String name,
  }) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final query = Uri(queryParameters: <String, String>{'name': name}).query;
    return '$base/vm/list?$query';
  }

  // ==================== 模板 ====================

  Future<List<VMTemplateItem>> listTemplates() {
    return runGuarded(() async {
      final response = await (await _ensureApi()).listVMTemplates();
      return response.data ?? const <VMTemplateItem>[];
    });
  }

  Future<VMTaskResp> createTemplate(VMTemplateCreate request) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).createVMTemplate(request);
      return _requireTaskResp(response.data, '创建模板');
    });
  }

  Future<VMTaskResp> deleteTemplate(int id, {bool deleteDisk = false}) {
    return runGuarded(() async {
      final response = await (await _ensureApi())
          .deleteVMTemplate(VMTemplateDelete(id: id, deleteDisk: deleteDisk));
      return _requireTaskResp(response.data, '删除模板');
    });
  }

  // ==================== 快照 ====================

  Future<List<VMSnapshotItem>> listSnapshots(String name) {
    return runGuarded(() async {
      final response = await (await _ensureApi())
          .listVMSnapshots(OperationWithName(name: name));
      return response.data ?? const <VMSnapshotItem>[];
    });
  }

  Future<VMTaskResp> createSnapshot(VMSnapshotReq request) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).createVMSnapshot(request);
      return _requireTaskResp(response.data, '创建快照');
    });
  }

  Future<VMTaskResp> recoverSnapshot(VMSnapshotReq request) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).recoverVMSnapshot(request);
      return _requireTaskResp(response.data, '恢复快照');
    });
  }

  Future<VMTaskResp> deleteSnapshot(VMSnapshotReq request) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).deleteVMSnapshot(request);
      return _requireTaskResp(response.data, '删除快照');
    });
  }

  // ==================== ISO ====================

  Future<List<VMIsoItem>> listIso() {
    return runGuarded(() async {
      final response = await (await _ensureApi()).listVMIso();
      return response.data ?? const <VMIsoItem>[];
    });
  }

  Future<PageResult<VMIsoItem>> searchIso({String? info, int page = 1, int pageSize = 20}) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).searchVMIso(
        SearchWithPage(info: info, page: page, pageSize: pageSize),
      );
      return response.data ??
          const PageResult<VMIsoItem>(items: <VMIsoItem>[], total: 0);
    });
  }

  Future<void> createIso(VMIsoCreate request) {
    return runGuarded(() async {
      await (await _ensureApi()).createVMIso(request);
    });
  }

  Future<void> updateIso(VMIsoUpdate request) {
    return runGuarded(() async {
      await (await _ensureApi()).updateVMIso(request);
    });
  }

  Future<void> deleteIso(int id, {bool deleteFile = false}) {
    return runGuarded(() async {
      await (await _ensureApi())
          .deleteVMIso(VMIsoDelete(id: id, deleteFile: deleteFile));
    });
  }

  /// 启动 ISO 导入，返回导入记录 id。
  ///
  /// 服务端在 `data.id` 缺失时客户端无法追踪进度，就地判定失败。
  Future<int> startIsoImport(VMIsoImportStart request) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).startVMIsoImport(request);
      final id = response.data ?? 0;
      if (id <= 0) {
        throw StateError('服务端未返回 ISO 导入记录 id');
      }
      return id;
    });
  }

  Future<void> updateIsoImport(VMIsoImportUpdate request) {
    return runGuarded(() async {
      await (await _ensureApi()).updateVMIsoImport(request);
    });
  }

  // ==================== 网络 ====================

  Future<List<VMNetworkItem>> listNetworks() {
    return runGuarded(() async {
      final response = await (await _ensureApi()).listVMNetworks();
      return response.data ?? const <VMNetworkItem>[];
    });
  }

  Future<List<VMNetworkBridgeItem>> listNetworkBridges() {
    return runGuarded(() async {
      final response = await (await _ensureApi()).listVMNetworkBridges();
      return response.data ?? const <VMNetworkBridgeItem>[];
    });
  }

  Future<List<VMNetworkInterfaceItem>> listNetworkInterfaces() {
    return runGuarded(() async {
      final response = await (await _ensureApi()).listVMNetworkInterfaces();
      return response.data ?? const <VMNetworkInterfaceItem>[];
    });
  }

  Future<void> createNetwork(VMNetworkCreate request) {
    return runGuarded(() async {
      await (await _ensureApi()).createVMNetwork(request);
    });
  }

  Future<void> updateNetwork(VMNetworkUpdate request) {
    return runGuarded(() async {
      await (await _ensureApi()).updateVMNetwork(request);
    });
  }

  Future<void> deleteNetwork(int id) {
    return runGuarded(() async {
      await (await _ensureApi()).deleteVMNetwork(VMResourceDelete(id: id));
    });
  }

  // ==================== 存储池 ====================

  Future<List<VMStorageItem>> listStorages() {
    return runGuarded(() async {
      final response = await (await _ensureApi()).listVMStorages();
      return response.data ?? const <VMStorageItem>[];
    });
  }

  Future<void> createStorage(VMStorageCreate request) {
    return runGuarded(() async {
      await (await _ensureApi()).createVMStorage(request);
    });
  }

  Future<void> updateStorage(VMStorageUpdate request) {
    return runGuarded(() async {
      await (await _ensureApi()).updateVMStorage(request);
    });
  }

  Future<void> deleteStorage(int id) {
    return runGuarded(() async {
      await (await _ensureApi()).deleteVMStorage(VMResourceDelete(id: id));
    });
  }

  // ==================== 孤儿数据 ====================

  Future<List<VMOrphanItem>> scanOrphans() {
    return runGuarded(() async {
      final response = await (await _ensureApi()).scanVMOrphans();
      return response.data ?? const <VMOrphanItem>[];
    });
  }

  Future<List<VMOrphanItem>> cleanOrphans(List<VMOrphanItem> items) {
    return runGuarded(() async {
      final response = await (await _ensureApi())
          .cleanVMOrphans(VMOrphanClean(items: items));
      return response.data ?? const <VMOrphanItem>[];
    });
  }
}

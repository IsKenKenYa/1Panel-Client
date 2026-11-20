import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/common_models.dart';
import '../../data/models/vm/vm_models.dart';
import '../../data/models/vm/vm_resource_models.dart';
import 'api_response_parser.dart';

/// 1Panel virtual machine API client.
///
/// 覆盖 swagger `/vms` 全部 REST 端点；`GET /vms/console/ws` 为 VNC
/// WebSocket 升级端点，经 WebSocket connector 在控制台 UI 批次接入。
class VMV2Api {
  VMV2Api(this._client);

  final DioClient _client;

  /// 创建、更新、删除、快照、ISO 导入、存储池等异步操作，服务端返回
  /// taskID 且执行时间较长；对齐上游前端 T_5M 长超时。
  static final Options _asyncOpOptions = Options(
    receiveTimeout: const Duration(minutes: 5),
    sendTimeout: const Duration(minutes: 1),
  );

  /// 环境探测会检查 KVM、libvirt 与存储目录，未安装依赖的主机上
  /// 需要遍历多个系统路径；全局 8 秒接收超时不足，单独放宽到 2 分钟。
  static final Options _environmentProbeOptions = Options(
    receiveTimeout: const Duration(minutes: 2),
  );

  // ==================== 环境 ====================

  /// 检查虚拟机运行环境（KVM/libvirt/存储）。
  Future<Response<VMEnvironment>> getVMEnvironment() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/environment'),
      options: _environmentProbeOptions,
    );
    return ApiResponseParser.withData(
      response,
      VMEnvironment.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  /// 启用虚拟机环境（安装依赖），服务端同步执行。
  Future<Response<void>> enableVMEnvironment() async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/vms/environment/enable'),
      data: const <String, dynamic>{},
      options: _asyncOpOptions,
    );
  }

  // ==================== 虚拟机实例 ====================

  /// 分页查询虚拟机。
  Future<Response<VMSearchResult>> searchVMs(SearchWithPage request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/search'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      VMSearchResult.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  /// 从宿主机同步虚拟机列表。
  Future<Response<void>> syncVMs() async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/vms/sync'),
    );
  }

  /// 加载虚拟机详情；checkDisks 时同步探测磁盘，耗时较长。
  Future<Response<VMItem>> getVMInfo(VMInfoReq request) async {
    return await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/info'),
      data: request.toJson(),
      options: request.checkDisks
          ? Options(receiveTimeout: const Duration(minutes: 3))
          : null,
    ).then((response) => ApiResponseParser.withData(
          response,
          VMItem.fromJson(ApiResponseParser.asMap(response.data)),
        ));
  }

  /// 虚拟机健康检查。
  Future<Response<VMHealthCheckResult>> healthCheckVM(
      OperationWithName request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/health/check'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
    return ApiResponseParser.withData(
      response,
      VMHealthCheckResult.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  /// 加载虚拟机实时统计。
  Future<Response<VMStats>> getVMStats(OperationWithName request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/stats'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      VMStats.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  /// 创建虚拟机（异步任务）。
  Future<Response<VMTaskResp>> createVM(VMCreate request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
    return ApiResponseParser.withData(
      response,
      VMTaskResp.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  /// 更新虚拟机配置（异步任务）。
  Future<Response<VMTaskResp>> updateVM(VMUpdate request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/update'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
    return ApiResponseParser.withData(
      response,
      VMTaskResp.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  /// 电源操作：start/shutdown/reboot/destroy/suspend/resume。
  Future<Response<void>> operateVM(VMOperate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/vms/operate'),
      data: request.toJson(),
    );
  }

  /// 删除虚拟机（异步任务）。
  Future<Response<VMTaskResp>> deleteVM(VMDelete request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/del'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
    return ApiResponseParser.withData(
      response,
      VMTaskResp.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  /// 扩容虚拟机磁盘（异步任务）。
  Future<Response<VMTaskResp>> resizeVMDisk(VMDiskResize request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/disks/resize'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
    return ApiResponseParser.withData(
      response,
      VMTaskResp.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  /// 重命名虚拟机（异步任务）。
  Future<Response<VMTaskResp>> renameVM(VMRename request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/rename'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
    return ApiResponseParser.withData(
      response,
      VMTaskResp.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  /// 加载虚拟机图形控制台连接信息。
  Future<Response<VMGraphics>> getVMConsole(OperationWithName request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/console'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      VMGraphics.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  // ==================== 模板 ====================

  /// 加载虚拟机模板列表。
  Future<Response<List<VMTemplateItem>>> listVMTemplates() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/templates/list'),
    );
    return ApiResponseParser.withData(
      response,
      ApiResponseParser.extractListDataFromMap(response, VMTemplateItem.fromJson),
    );
  }

  /// 从虚拟机创建模板（异步任务）。
  Future<Response<VMTaskResp>> createVMTemplate(
      VMTemplateCreate request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/templates'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
    return ApiResponseParser.withData(
      response,
      VMTaskResp.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  /// 删除模板（异步任务）。
  Future<Response<VMTaskResp>> deleteVMTemplate(
      VMTemplateDelete request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/templates/del'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
    return ApiResponseParser.withData(
      response,
      VMTaskResp.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  // ==================== 快照 ====================

  /// 加载虚拟机快照列表。
  Future<Response<List<VMSnapshotItem>>> listVMSnapshots(
      OperationWithName request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/snapshots/list'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      ApiResponseParser.extractListDataFromMap(response, VMSnapshotItem.fromJson),
    );
  }

  /// 创建快照（异步任务）。
  Future<Response<VMTaskResp>> createVMSnapshot(VMSnapshotReq request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/snapshots'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
    return ApiResponseParser.withData(
      response,
      VMTaskResp.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  /// 恢复快照（异步任务）。
  Future<Response<VMTaskResp>> recoverVMSnapshot(
      VMSnapshotReq request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/snapshots/recover'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
    return ApiResponseParser.withData(
      response,
      VMTaskResp.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  /// 删除快照（异步任务）。
  Future<Response<VMTaskResp>> deleteVMSnapshot(VMSnapshotReq request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/snapshots/del'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
    return ApiResponseParser.withData(
      response,
      VMTaskResp.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }

  // ==================== ISO ====================

  /// 加载 ISO 列表。
  Future<Response<List<VMIsoItem>>> listVMIso() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/iso/list'),
    );
    return ApiResponseParser.withData(
      response,
      ApiResponseParser.extractListDataFromMap(response, VMIsoItem.fromJson),
    );
  }

  /// 分页查询 ISO。
  Future<Response<PageResult<VMIsoItem>>> searchVMIso(
      SearchWithPage request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/iso/search'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      PageResult.fromJson(
        ApiResponseParser.asMap(response.data),
        (dynamic item) => VMIsoItem.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  /// 新建 ISO 记录（异步任务）。
  Future<Response<void>> createVMIso(VMIsoCreate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/vms/iso'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
  }

  /// 启动 ISO 导入，返回导入记录 id。
  Future<Response<int>> startVMIsoImport(VMIsoImportStart request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/iso/import/start'),
      data: request.toJson(),
    );
    final data = ApiResponseParser.asMap(response.data);
    return ApiResponseParser.withData(response, data['id'] as int? ?? 0);
  }

  /// 更新 ISO 导入状态。
  Future<Response<void>> updateVMIsoImport(VMIsoImportUpdate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/vms/iso/import/update'),
      data: request.toJson(),
    );
  }

  /// 更新 ISO 记录（异步任务）。
  Future<Response<void>> updateVMIso(VMIsoUpdate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/vms/iso/update'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
  }

  /// 删除 ISO（异步任务）。
  Future<Response<void>> deleteVMIso(VMIsoDelete request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/vms/iso/del'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
  }

  // ==================== 网络 ====================

  /// 加载虚拟机网络列表。
  Future<Response<List<VMNetworkItem>>> listVMNetworks() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/networks/list'),
    );
    return ApiResponseParser.withData(
      response,
      ApiResponseParser.extractListDataFromMap(
          response, VMNetworkItem.fromJson),
    );
  }

  /// 加载宿主机网桥列表。
  Future<Response<List<VMNetworkBridgeItem>>> listVMNetworkBridges() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/networks/bridges'),
    );
    return ApiResponseParser.withData(
      response,
      ApiResponseParser.extractListDataFromMap(
          response, VMNetworkBridgeItem.fromJson),
    );
  }

  /// 加载宿主机网络接口列表。
  Future<Response<List<VMNetworkInterfaceItem>>>
      listVMNetworkInterfaces() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/networks/interfaces'),
    );
    return ApiResponseParser.withData(
      response,
      ApiResponseParser.extractListDataFromMap(
          response, VMNetworkInterfaceItem.fromJson),
    );
  }

  /// 创建虚拟机网络（异步任务）。
  Future<Response<void>> createVMNetwork(VMNetworkCreate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/vms/networks'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
  }

  /// 更新虚拟机网络。
  Future<Response<void>> updateVMNetwork(VMNetworkUpdate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/vms/networks/update'),
      data: request.toJson(),
    );
  }

  /// 删除虚拟机网络（异步任务）。
  Future<Response<void>> deleteVMNetwork(VMResourceDelete request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/vms/networks/del'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
  }

  // ==================== 存储池 ====================

  /// 加载存储池列表。
  Future<Response<List<VMStorageItem>>> listVMStorages() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/storages/list'),
    );
    return ApiResponseParser.withData(
      response,
      ApiResponseParser.extractListDataFromMap(
          response, VMStorageItem.fromJson),
    );
  }

  /// 创建存储池（异步任务）。
  Future<Response<void>> createVMStorage(VMStorageCreate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/vms/storages'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
  }

  /// 更新存储池。
  Future<Response<void>> updateVMStorage(VMStorageUpdate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/vms/storages/update'),
      data: request.toJson(),
    );
  }

  /// 删除存储池（异步任务）。
  Future<Response<void>> deleteVMStorage(VMResourceDelete request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/vms/storages/del'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
  }

  // ==================== 孤儿数据 ====================

  /// 扫描孤儿虚拟机数据。
  Future<Response<List<VMOrphanItem>>> scanVMOrphans() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/orphans/scan'),
    );
    return ApiResponseParser.withData(
      response,
      ApiResponseParser.extractListDataFromMap(
          response, VMOrphanItem.fromJson),
    );
  }

  /// 清理孤儿虚拟机数据（异步任务）。
  Future<Response<List<VMOrphanItem>>> cleanVMOrphans(
      VMOrphanClean request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/vms/orphans/clean'),
      data: request.toJson(),
      options: _asyncOpOptions,
    );
    return ApiResponseParser.withData(
      response,
      ApiResponseParser.extractListDataFromMap(
          response, VMOrphanItem.fromJson),
    );
  }
}

import 'package:onepanel_client/api/v2/toolbox_v2.dart';
import 'package:onepanel_client/data/models/paged_query.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';

const String _toolboxRepoPackage = 'data.repositories.toolbox_repository';

class ToolboxRepository {
  ToolboxRepository({ToolboxV2Api? apiClient}) : _api = apiClient;

  ToolboxV2Api? _api;

  Future<ToolboxV2Api> _ensureApi() async {
    _api ??= await ApiClientManager.instance.getToolboxApi();
    return _api!;
  }

  Future<DeviceBaseInfo> getDeviceBaseInfo() async {
    final api = await _ensureApi();
    return (await api.getDeviceBaseInfo()).data ?? const DeviceBaseInfo();
  }

  /// 逐项获取设备配置。
  ///
  /// V2 契约：/toolbox/device/conf 必须按具体 name 请求（服务端仅支持
  /// DNS/Hosts，传 'all' 会报 not support such name），逐项请求并对单项
  /// 失败容错（失败项不进入结果，不阻塞其它项），按服务端 name 拼装返回。
  Future<Map<String, dynamic>> getDeviceConf() async {
    final api = await _ensureApi();
    final conf = <String, dynamic>{};
    for (final name in const <String>['DNS', 'Hosts']) {
      try {
        final content = (await api.getDeviceConf(name)).data;
        if (content != null && content.isNotEmpty) {
          conf[name] = content;
        }
      } catch (e, stack) {
        appLogger.wWithPackage(
          _toolboxRepoPackage,
          'load device conf failed: name=$name',
          error: e,
          stackTrace: stack,
        );
      }
    }
    return conf;
  }

  Future<void> updateDeviceConf(DeviceConfUpdate request) async {
    final api = await _ensureApi();
    await api.updateDeviceConf(request);
  }

  Future<void> updateDevicePassword(DevicePasswdUpdate request) async {
    final api = await _ensureApi();
    await api.updateDevicePassword(request);
  }

  Future<void> updateDeviceSwap(String swap) async {
    final api = await _ensureApi();
    await api.updateDeviceSwap(swap);
  }

  Future<void> checkDns(String key, String value) async {
    final api = await _ensureApi();
    await api.checkDNS(key, value);
  }

  Future<List<String>> getDeviceUsers() async {
    final api = await _ensureApi();
    return (await api.getDeviceUsers()).data ?? const <String>[];
  }

  Future<List<String>> getDeviceZoneOptions() async {
    final api = await _ensureApi();
    return (await api.getDeviceZoneOptions()).data ?? const <String>[];
  }

  Future<ClamBaseInfo> getClamBaseInfo() async {
    final api = await _ensureApi();
    return (await api.getClamBaseInfo()).data ?? const ClamBaseInfo();
  }

  Future<void> createClamTask(ClamCreate request) async {
    final api = await _ensureApi();
    await api.createClam(request);
  }

  Future<void> updateClamTask(ClamUpdate request) async {
    final api = await _ensureApi();
    await api.updateClam(request);
  }

  Future<void> deleteClamTasks({
    required List<int> ids,
    bool removeInfected = false,
  }) async {
    if (ids.isEmpty) {
      return;
    }
    final api = await _ensureApi();
    await api.deleteClam(
      ClamDelete(ids: ids, removeInfected: removeInfected),
    );
  }

  Future<void> handleClam(int id) async {
    final api = await _ensureApi();
    await api.handleClam(OperateByID(id: id));
  }

  Future<void> operateClam(String operation) async {
    final api = await _ensureApi();
    await api.operateClam(operation);
  }

  Future<List<ClamFileInfo>> searchClamFileLines({
    required String name,
    String tail = '200',
  }) async {
    final api = await _ensureApi();
    final response = await api.searchClamFiles(
      ClamFileReq(name: name, tail: tail),
    );
    return response.data?.items ?? const <ClamFileInfo>[];
  }

  Future<void> updateClamFile({
    required String name,
    required String file,
  }) async {
    final api = await _ensureApi();
    await api.updateClamFile(ClamFileUpdateReq(name: name, file: file));
  }

  Future<void> cleanClamRecords(int id) async {
    final api = await _ensureApi();
    await api.cleanClamRecords(OperateByID(id: id));
  }

  Future<List<ClamBaseInfo>> searchClamTasks({
    int page = 1,
    int pageSize = PagedQuery.searchPageSize,
  }) async {
    final api = await _ensureApi();
    final response = await api.searchClam(
      ClamSearch(page: page, pageSize: pageSize),
    );
    return response.data?.items ?? const <ClamBaseInfo>[];
  }

  Future<List<ClamLogInfo>> searchClamRecords({
    required int clamId,
    int page = 1,
    int pageSize = PagedQuery.searchPageSize,
  }) async {
    final api = await _ensureApi();
    final response = await api.searchClamRecords(
      ClamLogSearch(
        clamId: clamId,
        page: page,
        pageSize: pageSize,
      ),
    );
    return response.data?.items ?? const <ClamLogInfo>[];
  }

  Future<Fail2banBaseInfo> getFail2banBaseInfo() async {
    final api = await _ensureApi();
    return (await api.getFail2banBaseInfo()).data ?? const Fail2banBaseInfo();
  }

  Future<String> loadFail2banConf() async {
    final api = await _ensureApi();
    return (await api.loadFail2banConf()).data ?? '';
  }

  /// 搜索Fail2ban记录。
  ///
  /// V2 契约：/toolbox/fail2ban/search 请求仅需 status（必填，默认 banned），
  /// 响应为 IP 字符串数组；这里将其映射为 Fail2banRecord（ip + 查询状态）。
  Future<List<Fail2banRecord>> searchFail2banRecords({
    int page = 1,
    int pageSize = PagedQuery.searchPageSize,
    String? status,
  }) async {
    final api = await _ensureApi();
    final resolvedStatus = status ?? 'banned';
    final response = await api.searchFail2ban(
      Fail2banSearch(
        page: page,
        pageSize: pageSize,
        status: resolvedStatus,
      ),
    );
    final ips = response.data ?? const <String>[];
    return <Fail2banRecord>[
      for (final ip in ips) Fail2banRecord(ip: ip, status: resolvedStatus),
    ];
  }

  Future<void> updateFail2ban(Fail2banUpdate request) async {
    final api = await _ensureApi();
    await api.updateFail2ban(request);
  }

  Future<void> operateFail2ban(String operation) async {
    final api = await _ensureApi();
    await api.operateFail2ban(operation);
  }

  Future<void> operateFail2banSshd({
    required String operate,
    List<String> ips = const <String>[],
  }) async {
    final api = await _ensureApi();
    await api.operateFail2banSshd(
      Fail2banSet(operate: operate, ips: ips),
    );
  }

  Future<FtpBaseInfo> getFtpBaseInfo() async {
    final api = await _ensureApi();
    return (await api.getFtpBaseInfo()).data ?? const FtpBaseInfo();
  }

  Future<List<FtpInfo>> searchFtpUsers({
    int page = 1,
    int pageSize = PagedQuery.searchPageSize,
    String? keyword,
  }) async {
    final api = await _ensureApi();
    final response = await api.searchFtp(
      FtpSearch(
        info: keyword,
        page: page,
        pageSize: pageSize,
      ),
    );
    return response.data?.items ?? const <FtpInfo>[];
  }

  Future<void> syncFtp() async {
    final api = await _ensureApi();
    await api.syncFtp();
  }

  Future<void> createFtpUser(FtpCreate request) async {
    final api = await _ensureApi();
    await api.createFtp(request);
  }

  Future<void> updateFtpUser(FtpUpdate request) async {
    final api = await _ensureApi();
    await api.updateFtp(request);
  }

  Future<void> deleteFtpUsers(List<int> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final api = await _ensureApi();
    await api.deleteFtp(FtpDelete(ids: ids));
  }

  Future<void> operateFtp(String operation) async {
    final api = await _ensureApi();
    await api.operateFtp(operation);
  }
}

import '../../api/v2/alert_v2.dart';
import '../../core/services/base_component.dart';
import '../../data/models/alert_models.dart';
import '../../data/models/common_models.dart';
import '../../data/repositories/alert_repository.dart';

/// 告警中心业务服务。
///
/// 覆盖任务规则、告警日志、通知渠道三块。渠道状态切换在社区版 swagger
/// 中没有独立端点，经 `/alert/config/update` 的 status 字段实现；
/// 短信渠道不在客户端提供，请求侧固定排除。
class AlertService extends BaseComponent {
  AlertService({
    AlertRepository? repository,
    AlertV2Api? api,
    super.clientManager,
    super.permissionResolver,
  }) : _repository = repository ??
            AlertRepository(
              clientManager: clientManager,
              api: api,
            );

  final AlertRepository _repository;

  /// 客户端不提供的渠道类型；`common` 为服务端聚合类型，列表侧过滤。
  static const List<String> hiddenConfigTypes = <String>['sms', 'common'];

  Future<AlertV2Api> _ensureApi() => _repository.ensureApi();

  void resetForServerChange() {
    _repository.resetForServerChange();
  }

  // ==================== 告警任务 ====================

  Future<PageResult<AlertInfo>> searchAlerts({
    int page = 1,
    int pageSize = 20,
    String? type,
    String? status,
    String? method,
  }) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).searchAlerts(
        AlertSearch(
          page: page,
          pageSize: pageSize,
          type: type,
          status: status,
          method: method,
          orderBy: 'created_at',
          order: 'descending',
        ),
      );
      return response.data ??
          const PageResult<AlertInfo>(items: <AlertInfo>[], total: 0);
    });
  }

  Future<void> createAlert(AlertCreate request) {
    return runGuarded(() async {
      await (await _ensureApi()).createAlert(request);
    });
  }

  Future<void> updateAlert(AlertUpdate request) {
    return runGuarded(() async {
      await (await _ensureApi()).updateAlert(request);
    });
  }

  Future<void> deleteAlert(int id) {
    return runGuarded(() async {
      await (await _ensureApi()).deleteAlert(OperateByID(id: id));
    });
  }

  Future<void> updateAlertStatus(int id, String status) {
    return runGuarded(() async {
      await (await _ensureApi())
          .updateAlertStatus(AlertUpdateStatus(id: id, status: status));
    });
  }

  // ==================== 目标选项 ====================

  Future<List<AlertDisk>> listDisks() {
    return runGuarded(() async {
      final response = await (await _ensureApi()).listAlertDisks();
      return response.data ?? const <AlertDisk>[];
    });
  }

  Future<List<AlertClam>> listClams() {
    return runGuarded(() async {
      final response = await (await _ensureApi()).listAlertClams();
      return response.data ?? const <AlertClam>[];
    });
  }

  Future<List<AlertCronJob>> listCronJobs({String? type}) {
    return runGuarded(() async {
      final response =
          await (await _ensureApi()).listAlertCronJobs(AlertCronJobReq(type: type));
      return response.data ?? const <AlertCronJob>[];
    });
  }

  // ==================== 告警日志 ====================

  Future<PageResult<AlertLog>> searchLogs({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).searchAlertLogs(
        AlertLogSearch(page: page, pageSize: pageSize, status: status),
      );
      return response.data ??
          const PageResult<AlertLog>(items: <AlertLog>[], total: 0);
    });
  }

  Future<void> cleanLogs() {
    return runGuarded(() async {
      await (await _ensureApi()).cleanAlertLogs();
    });
  }

  // ==================== 通知渠道 ====================

  Future<List<AlertConfigInfo>> listConfigs() {
    return runGuarded(() async {
      final response = await (await _ensureApi()).listAlertConfigs(
        const AlertConfigFilterReq(excludeTypes: hiddenConfigTypes),
      );
      final items = response.data ?? const <AlertConfigInfo>[];
      return items
          .where((item) => !hiddenConfigTypes.contains(item.type))
          .toList(growable: false);
    });
  }

  Future<PageResult<AlertConfigInfo>> searchConfigs({
    int page = 1,
    int pageSize = 20,
  }) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).searchAlertConfigs(
        AlertConfigPageReq(
          page: page,
          pageSize: pageSize,
          excludeTypes: hiddenConfigTypes,
        ),
      );
      final result = response.data ??
          const PageResult<AlertConfigInfo>(items: <AlertConfigInfo>[], total: 0);
      return PageResult<AlertConfigInfo>(
        items: result.items
            .where((item) => !hiddenConfigTypes.contains(item.type))
            .toList(growable: false),
        total: result.total,
        page: result.page,
        pageSize: result.pageSize,
        totalPages: result.totalPages,
      );
    });
  }

  Future<void> deleteConfig(int id) {
    return runGuarded(() async {
      await (await _ensureApi()).deleteAlertConfig(OperateByID(id: id));
    });
  }

  Future<void> saveConfig(AlertConfigUpdate request) {
    return runGuarded(() async {
      await (await _ensureApi()).updateAlertConfig(request);
    });
  }

  Future<void> updateConfigStatus(int id, String status) {
    return runGuarded(() async {
      await (await _ensureApi())
          .updateAlertConfig(AlertConfigUpdate(id: id, status: status));
    });
  }

  Future<AlertConfigTestResult> testConfig(AlertConfigTest request) {
    return runGuarded(() async {
      final response = await (await _ensureApi()).testAlertConfig(request);
      final data = response.data;
      if (data == null) {
        throw StateError('服务端未返回告警配置测试结果');
      }
      return data;
    });
  }
}

import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/alert_models.dart';
import '../../data/models/common_models.dart';
import 'api_response_parser.dart';

/// 1Panel alert center API client.
///
/// 覆盖 swagger `/alert` 全部端点；上游前端引用的 `/alert/config/status`
/// 与 `/xpack/alert/logs/sync*` 未出现在社区版 swagger 中，不在此实现。
class AlertV2Api {
  AlertV2Api(this._client);

  final DioClient _client;

  /// 分页查询告警规则。
  Future<Response<PageResult<AlertInfo>>> searchAlerts(
      AlertSearch request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/alert/search'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      PageResult.fromJson(
        ApiResponseParser.asMap(response.data),
        (dynamic item) => AlertInfo.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  /// 创建告警规则。
  Future<Response<void>> createAlert(AlertCreate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/alert'),
      data: request.toJson(),
    );
  }

  /// 更新告警规则。
  Future<Response<void>> updateAlert(AlertUpdate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/alert/update'),
      data: request.toJson(),
    );
  }

  /// 删除告警规则。
  Future<Response<void>> deleteAlert(OperateByID request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/alert/del'),
      data: request.toJson(),
    );
  }

  /// 更新告警规则状态。
  Future<Response<void>> updateAlertStatus(AlertUpdateStatus request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/alert/status'),
      data: request.toJson(),
    );
  }

  /// 加载可用磁盘列表（告警目标选择）。
  Future<Response<List<AlertDisk>>> listAlertDisks() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/alert/disks/list'),
    );
    return ApiResponseParser.withData(
      response,
      ApiResponseParser.extractListDataFromMap(response, AlertDisk.fromJson),
    );
  }

  /// 分页查询告警日志。
  Future<Response<PageResult<AlertLog>>> searchAlertLogs(
      AlertLogSearch request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/alert/logs/search'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      PageResult.fromJson(
        ApiResponseParser.asMap(response.data),
        (dynamic item) => AlertLog.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  /// 清空告警日志。
  Future<Response<void>> cleanAlertLogs() async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/alert/logs/clean'),
    );
  }

  /// 加载杀毒扫描目标列表。
  Future<Response<List<AlertClam>>> listAlertClams() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/alert/clams/list'),
    );
    return ApiResponseParser.withData(
      response,
      ApiResponseParser.extractListDataFromMap(response, AlertClam.fromJson),
    );
  }

  /// 加载计划任务选项（告警规则目标选择）。
  Future<Response<List<AlertCronJob>>> listAlertCronJobs(
      AlertCronJobReq request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/alert/cronjob/list'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      ApiResponseParser.extractListDataFromMap(
          response, AlertCronJob.fromJson),
    );
  }

  /// 加载告警配置列表。
  Future<Response<List<AlertConfigInfo>>> listAlertConfigs(
      AlertConfigFilterReq request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/alert/config/info'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      ApiResponseParser.extractListDataFromMap(
          response, AlertConfigInfo.fromJson),
    );
  }

  /// 分页查询告警配置。
  Future<Response<PageResult<AlertConfigInfo>>> searchAlertConfigs(
      AlertConfigPageReq request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/alert/config/search'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      PageResult.fromJson(
        ApiResponseParser.asMap(response.data),
        (dynamic item) =>
            AlertConfigInfo.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  /// 删除告警配置。
  Future<Response<void>> deleteAlertConfig(OperateByID request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/alert/config/del'),
      data: request.toJson(),
    );
  }

  /// 更新告警配置。
  Future<Response<void>> updateAlertConfig(AlertConfigUpdate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/alert/config/update'),
      data: request.toJson(),
    );
  }

  /// 测试告警配置（邮箱 / 自定义 webhook）。
  Future<Response<AlertConfigTestResult>> testAlertConfig(
      AlertConfigTest request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/alert/config/test'),
      data: request.toJson(),
    );
    return ApiResponseParser.withData(
      response,
      AlertConfigTestResult.fromJson(ApiResponseParser.asMap(response.data)),
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/alert_v2.dart';
import 'package:onepanel_client/api/v2/health_v2.dart';
import 'package:onepanel_client/api/v2/vm_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/alert_models.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import '../core/test_config_manager.dart';

/// 虚拟机与告警中心的真实面板契约测试。
///
/// 本批接入界面后首次进入 live 回归。社区版面板的虚拟机配额为 1，因此
/// 列表必须容忍 `limit: 1` 且不创建实例；告警端点只做读取，不创建渠道
/// 或规则，避免在共享面板上留下测试数据。
void main() {
  late DioClient client;
  late VMV2Api vmApi;
  late AlertV2Api alertApi;
  late HealthV2Api healthApi;
  bool hasApiKey = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    hasApiKey = TestEnvironment.apiKey.isNotEmpty &&
        TestEnvironment.apiKey != 'your_api_key_here';
    if (hasApiKey) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      vmApi = VMV2Api(client);
      alertApi = AlertV2Api(client);
      healthApi = HealthV2Api(client);
    }
  });

  group('虚拟机与告警中心 live 契约', () {
    test('GET /health/check 返回成功信封', () async {
      if (!hasApiKey) return;
      final response = await healthApi.checkHealth();
      expect(response.statusCode, 200);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('POST /vms/search 返回社区版配额与列表', () async {
      if (!hasApiKey) return;
      final response = await vmApi.searchVMs(
        const SearchWithPage(page: 1, pageSize: 10),
      );
      expect(response.statusCode, 200);
      final result = response.data;
      expect(result, isNotNull);
      // 社区版返回 1，专业版 5，企业版 0 表示不限制。
      expect(result!.limit, greaterThanOrEqualTo(0));
      expect(result.items.length, lessThanOrEqualTo(result.total));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('GET /vms/environment 返回完整依赖探测结构', () async {
      if (!hasApiKey) return;
      final response = await vmApi.getVMEnvironment();
      expect(response.statusCode, 200);
      final environment = response.data;
      expect(environment, isNotNull);
      expect(environment!.arch, isNotEmpty);
    }, timeout: const Timeout(Duration(seconds: 150)));

    test('GET /alert/disks/list 返回磁盘目标', () async {
      if (!hasApiKey) return;
      final response = await alertApi.listAlertDisks();
      expect(response.statusCode, 200);
      expect(response.data, isNotNull);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('GET /alert/clams/list 返回杀毒扫描目标', () async {
      if (!hasApiKey) return;
      final response = await alertApi.listAlertClams();
      expect(response.statusCode, 200);
      expect(response.data, isNotNull);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('POST /alert/search 分页返回规则列表', () async {
      if (!hasApiKey) return;
      final response = await alertApi.searchAlerts(
        const AlertSearch(
          page: 1,
          pageSize: 10,
          orderBy: 'created_at',
          order: 'descending',
        ),
      );
      expect(response.statusCode, 200);
      final result = response.data;
      expect(result, isNotNull);
      expect(result!.items.length, lessThanOrEqualTo(result.total));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('POST /alert/logs/search 分页返回推送日志', () async {
      if (!hasApiKey) return;
      final response = await alertApi.searchAlertLogs(
        const AlertLogSearch(page: 1, pageSize: 10),
      );
      expect(response.statusCode, 200);
      expect(response.data, isNotNull);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('POST /alert/config/info 排除隐藏渠道类型', () async {
      if (!hasApiKey) return;
      final response = await alertApi.listAlertConfigs(
        const AlertConfigFilterReq(excludeTypes: <String>['sms', 'common']),
      );
      expect(response.statusCode, 200);
      final configs = response.data ?? const <AlertConfigInfo>[];
      for (final config in configs) {
        expect(config.type, isNot('sms'));
        expect(config.type, isNot('common'));
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

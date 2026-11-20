import 'package:onepanel_client/api/v2/dashboard_v2.dart';
import 'package:onepanel_client/api/v2/health_v2.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/repositories/dashboard_repository.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';
import 'server_models.dart';

/// 健康探测结果的占位句柄：`ping` 尚未完成时也可继续加载监控指标。
class _HealthProbe {
  const _HealthProbe(this.ping);

  final Future<int?> ping;
}

/// 服务器仓库
///
/// 提供服务器列表管理和监控数据获取功能
class ServerRepository {
  const ServerRepository();

  /// 加载服务器卡片列表
  Future<List<ServerCardViewModel>> loadServerCards() async {
    final configs = await ApiConfigManager.getConfigs();
    final current = await ApiConfigManager.getCurrentConfig();

    return configs
        .map(
          (config) => ServerCardViewModel(
            config: config,
            isCurrent: current?.id == config.id,
            metrics: const ServerMetricsSnapshot(),
          ),
        )
        .toList();
  }

  /// 加载服务器监控指标
  ///
  /// 使用 DashboardRepository 获取当前服务器快照数据；同时用
  /// `GET /health/check` 探测连通性与往返延迟，探测失败时仍返回已有指标，
  /// 由界面区分"不可达"与"监控数据缺失"。
  Future<ServerMetricsSnapshot> loadServerMetrics(String serverId) async {
    try {
      final configs = await ApiConfigManager.getConfigs();
      final config = configs.firstWhere(
        (c) => c.id == serverId,
        orElse: () => throw Exception('Server not found'),
      );

      // 每台服务器绑定自己的 client：默认 DashboardRepository 读取当前服务器
      // 配置，会让服务器列表所有卡片显示同一份指标（离线服务器也显示已加载）。
      final manager = ApiClientManager.instance;
      final client = manager.getClient(
        serverId,
        config.url,
        config.apiKey,
        allowInsecureTls: config.allowInsecureTls,
      );

      final probe = _probeReachability(client);
      final dashboardRepo = DashboardRepository(api: DashboardV2Api(client));
      final metrics = await dashboardRepo.getCurrentServerMetrics();
      final latency = await probe.ping;

      if (latency == null) {
        return metrics.copyWith(isReachable: false);
      }
      return metrics.copyWith(isReachable: true, latencyMs: latency);
    } catch (e, stack) {
      if (e is NetworkException) {
        appLogger.wWithPackage(
          'features.server.repository',
          'Network error loading server metrics: ${e.message}',
        );
      } else {
        appLogger.eWithPackage(
          'features.server.repository',
          'Error loading server metrics',
          error: e,
          stackTrace: stack,
        );
      }
      return const ServerMetricsSnapshot(isReachable: false);
    }
  }

  /// 健康探测：返回往返毫秒数，失败返回 null。
  _HealthProbe _probeReachability(DioClient client) {
    final stopwatch = Stopwatch()..start();
    final ping = HealthV2Api(client).checkHealth().then<int?>((_) {
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    }).catchError((Object error) {
      stopwatch.stop();
      return null;
    });
    return _HealthProbe(ping);
  }

  /// 设置当前服务器
  Future<void> setCurrent(String id) async {
    await ApiConfigManager.setCurrentConfig(id);
  }

  /// 删除服务器配置
  Future<void> removeConfig(String id) async {
    await ApiConfigManager.deleteConfig(id);
    ApiClientManager.instance.removeClient(id);
  }

  /// 保存服务器配置
  Future<void> saveConfig(ApiConfig config) async {
    await ApiConfigManager.saveConfig(config);
    await ApiConfigManager.setCurrentConfig(config.id);
  }
}

import 'package:onepanel_client/api/v2/dashboard_v2.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/repositories/dashboard_repository.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';
import 'server_models.dart';

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
  /// 使用 DashboardRepository 获取当前服务器快照数据
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

      // 使用 DashboardRepository 获取该服务器指标
      final dashboardRepo = DashboardRepository(api: DashboardV2Api(client));
      final metrics = await dashboardRepo.getCurrentServerMetrics();

      return metrics;
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
      return const ServerMetricsSnapshot();
    }
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

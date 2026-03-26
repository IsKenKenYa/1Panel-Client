import 'package:flutter/foundation.dart';
import 'package:onepanelapp_app/core/config/api_config.dart';
import 'package:onepanelapp_app/core/network/api_client_manager.dart';
import 'package:onepanelapp_app/data/repositories/monitor_repository.dart';
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
  /// 使用统一的 MonitorRepository 获取监控数据
  Future<ServerMetricsSnapshot> loadServerMetrics(String serverId) async {
    try {
      final configs = await ApiConfigManager.getConfigs();
      final config = configs.firstWhere(
        (c) => c.id == serverId,
        orElse: () => throw Exception('Server not found'),
      );

      final manager = ApiClientManager.instance;
      final client = manager.getClient(serverId, config.url, config.apiKey,
          ignoreTls: config.ignoreTls);

      final monitorRepo = const MonitorRepository();
      final metrics = await monitorRepo.getCurrentMetrics(client);

      return ServerMetricsSnapshot(
        cpuPercent: metrics.cpuPercent,
        memoryPercent: metrics.memoryPercent,
        diskPercent: metrics.diskPercent,
        load: metrics.load1,
      );
    } catch (e, stack) {
      debugPrint('[ServerRepository] Error loading metrics: $e');
      debugPrint('[ServerRepository] Stack: $stack');
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
  }

  /// 保存服务器配置
  Future<void> saveConfig(ApiConfig config) async {
    await ApiConfigManager.saveConfig(config);
    await ApiConfigManager.setCurrentConfig(config.id);
  }
}

import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/panels/panel_adapter.dart';
import 'package:onepanel_client/data/panels/panel_registry.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';
import 'server_models.dart';

/// 服务器仓库
///
/// 提供服务器列表管理和监控数据获取功能
class ServerRepository {
  const ServerRepository({PanelRegistry? registry}) : _registry = registry;

  final PanelRegistry? _registry;
  PanelRegistry get _panels => _registry ?? PanelRegistry.instance;

  /// 加载服务器卡片列表。
  ///
  /// [withMetrics] 为 true 时并发拉取每台服务器的指标与可达状态，
  /// 供原生轨道的服务器列表使用；MDUI3 轨道由 ServerProvider 自行
  /// 按可见性刷新，不重复拉取。
  Future<List<ServerCardViewModel>> loadServerCards({
    bool withMetrics = false,
  }) async {
    final directory = await ApiConfigManager.getServerDirectory();

    final cards = directory.servers
        .map(
          (config) => ServerCardViewModel(
            config: config,
            isCurrent: directory.selectedId == config.id,
            metrics: const ServerMetricsSnapshot(),
          ),
        )
        .toList();

    if (!withMetrics || cards.isEmpty) return cards;

    final metrics = await Future.wait(
      cards.map((card) => loadMetricsForConfig(card.config)),
    );
    return [
      for (var i = 0; i < cards.length; i++)
        cards[i].copyWith(metrics: metrics[i]),
    ];
  }

  Future<ServerMetricsSnapshot> loadMetricsForConfig(ApiConfig metadata) async {
    try {
      if (!_panels.supports(metadata.panelType)) {
        return const ServerMetricsSnapshot();
      }
      final session = await _panels.savedSessionFor(metadata);
      return await session?.loadMetrics() ?? const ServerMetricsSnapshot();
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

  Future<Map<String, PanelAccess>> capabilitiesFor(ApiConfig config) async {
    final session = await _panels.savedSessionFor(config);
    if (session == null) throw StateError('Server configuration changed');
    return Map.unmodifiable(await session.loadCapabilities());
  }

  Future<ApiConfig> readConfig(String serverId) => ApiConfigManager.getConfig(serverId);

  void _release(String id) {
    _panels.release(id);
    ApiClientManager.instance.removeClient(id);
  }

  Future<void> updateConfig(ApiConfig config, {required ApiConfig expected}) async {
    await ApiConfigManager.updateConfig(config, expected: expected);
    _panels.invalidateIfChanged(config);
    ApiClientManager.instance.invalidateIfChanged(config);
  }

  /// 设置当前服务器
  Future<void> setCurrent(String id) async {
    await ApiConfigManager.setCurrentConfig(id);
  }

  /// 删除服务器配置
  Future<void> removeConfig(String id) async {
    await ApiConfigManager.deleteConfig(id);
    _release(id);
  }

  /// 保存服务器配置
  Future<void> saveConfig(ApiConfig config) async {
    if (config.id.trim().isEmpty || config.panelType.trim().isEmpty) {
      throw ArgumentError('服务器标识和面板类型不能为空');
    }
    await ApiConfigManager.saveConfig(config);
    _panels.invalidateIfChanged(config);
    ApiClientManager.instance.invalidateIfChanged(config);
  }

  /// 按输入顺序保存，调用方可用每条结果的 id 单独重试。
  Future<List<({String serverId, Object? error})>> saveConfigs(
    Iterable<ApiConfig> configs,
  ) async {
    final results = <({String serverId, Object? error})>[];
    for (final config in configs) {
      try {
        await saveConfig(config);
        results.add((serverId: config.id, error: null));
      } catch (error) {
        results.add((serverId: config.id, error: error));
      }
    }
    return results;
  }
}

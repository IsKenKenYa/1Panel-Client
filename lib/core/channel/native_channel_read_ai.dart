import '../../data/models/ai/agent_account_model_pool_models.dart';
import '../../data/models/ai/agent_account_models.dart';
import '../../data/models/ai/agent_core_models.dart';
import '../../data/models/common_models.dart';
import '../../data/models/mcp_models.dart';
import '../../features/ai/ai_repository.dart';
import '../services/logger/logger_service.dart';

/// 读通道 AI 域：模型列表、GPU 负载与历史、智能体渠道、MCP、智能体实例与
/// 绑定域名。
///
/// 协议单一事实源：docs/development/modules/b3_ai_channel_contract.md。
/// 读语义：透传解析数据（不做字段裁剪），缺参/失败返回空值并记录日志。
class NativeChannelAIReadHandlers {
  /// AI 模型：返回 Ollama 模型列表。
  static Future<dynamic> getAIModels(dynamic arguments) async {
    try {
      final repository = AIRepository();
      final page = await repository.searchOllamaModels(page: 1, pageSize: 100);
      return page.items
          .map((m) => {
                'id': m.id,
                'name': m.name ?? '',
                'size': m.size ?? '',
                'modified': m.modified ?? '',
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get AI models for native: $e');
      return [];
    }
  }

  /// GPU/XPU 负载。参数：`{}`。GET /ai/gpu/load。
  static Future<dynamic> getGpuLoad(dynamic arguments) async {
    try {
      final gpus = await AIRepository().loadGpuInfo();
      return gpus.map((g) => g.toJson()).toList();
    } catch (e) {
      appLogger.e('Failed to get gpu load for native: $e');
      return [];
    }
  }

  /// GPU 设备选项。参数：`{}`。GET /ai/gpu/options。
  /// 返回 `{chartHide: [...], chartSelect: [...]}` 原始对象。
  static Future<dynamic> getGpuOptions(dynamic arguments) async {
    try {
      return await AIRepository().getGpuOptions();
    } catch (e) {
      appLogger.e('Failed to get gpu options for native: $e');
      return <String, dynamic>{};
    }
  }

  /// GPU 历史监控。参数：
  /// `{deviceID?: String, productName?: String, startTime: String, endTime: String}`。
  /// POST /ai/gpu/search，返回时间序列对象；缺少设备时服务端报错，这里
  /// 先经 `/ai/gpu/options` 取设备，无 GPU 时直接返回空对象。
  static Future<dynamic> searchGpuHistory(dynamic arguments) async {
    try {
      final startTime = arguments?['startTime'] as String? ?? '';
      final endTime = arguments?['endTime'] as String? ?? '';
      if (startTime.isEmpty || endTime.isEmpty) {
        return <String, dynamic>{};
      }
      final repository = AIRepository();
      var deviceId = arguments?['deviceID'] as String? ?? '';
      var productName = arguments?['productName'] as String? ?? '';
      var legacy = arguments?['legacy'] as bool? ?? false;
      if (deviceId.isEmpty && productName.isEmpty) {
        final device =
            AIRepository.firstGpuDevice(await repository.getGpuOptions());
        if (device == null) return <String, dynamic>{};
        deviceId = device.deviceId;
        productName = device.productName;
        legacy = device.legacy;
      }
      return await repository.searchGpu(<String, dynamic>{
        'deviceID': deviceId,
        'productName': productName,
        'legacy': legacy,
        'startTime': startTime,
        'endTime': endTime,
      });
    } catch (e) {
      appLogger.e('Failed to search gpu history for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 智能体渠道账号分页。参数：`{page: int, pageSize: int, name?: String}`。
  /// POST /ai/accounts/search。
  static Future<dynamic> getAgentAccounts(dynamic arguments) async {
    try {
      final page = (await (await AIRepository().getApi()).pageAgentAccounts(
        AgentAccountSearch(
          page: int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
          pageSize: int.tryParse('${arguments?['pageSize'] ?? 20}') ?? 20,
          name: arguments?['name'] as String? ?? '',
        ),
      ))
          .data!;
      return <String, dynamic>{
        'items': page.items.map((a) => a.toJson()).toList(),
        'total': page.total,
        'page': page.page,
        'pageSize': page.pageSize,
        'totalPages': page.totalPages,
      };
    } catch (e) {
      appLogger.e('Failed to get agent accounts for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 渠道账号可选 provider 列表。参数：无。GET /ai/accounts/providers。
  static Future<dynamic> getAgentProviders(dynamic arguments) async {
    try {
      final providers = (await (await AIRepository().getApi())
                  .getAgentProviders())
              .data ??
          const <ProviderInfo>[];
      return providers
          .map((p) => {
                'provider': p.provider,
                'displayName': p.displayName,
                'baseUrl': p.baseUrl,
                'defaultApiType': p.defaultApiType,
                'apiTypes': p.apiTypes,
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get agent providers for native: $e');
      return [];
    }
  }

  /// 渠道账号可用模型列表。参数：`{accountId: int}`。POST /ai/accounts/models。
  static Future<dynamic> getAgentAccountModels(dynamic arguments) async {
    try {
      final accountId = int.tryParse('${arguments?['accountId'] ?? ''}');
      if (accountId == null) {
        return [];
      }
      final models = (await (await AIRepository().getApi())
              .getAgentAccountModels(AgentAccountModelReq(accountId: accountId)))
          .data!;
      return models.map((m) => m.toJson()).toList();
    } catch (e) {
      appLogger.e('Failed to get agent account models for native: $e');
      return [];
    }
  }

  /// MCP 服务器分页。参数：`{page: int, pageSize: int, name?: String}`。
  /// POST /ai/mcp/search。
  static Future<dynamic> getMcpServers(dynamic arguments) async {
    try {
      return (await (await AIRepository().getApi()).searchMcpServers(
                McpServerSearch(
                  page: int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
                  pageSize:
                      int.tryParse('${arguments?['pageSize'] ?? 20}') ?? 20,
                  name: arguments?['name'] as String? ?? '',
                ),
              ))
                  .data
                  ?.toJson() ??
          <String, dynamic>{};
    } catch (e) {
      appLogger.e('Failed to get mcp servers for native: $e');
      return <String, dynamic>{};
    }
  }

  /// MCP 服务器详情。参数：`{id: int}`。POST /ai/mcp/server/detail。
  static Future<dynamic> getMcpServerDetail(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null) {
        return <String, dynamic>{};
      }
      return await (await AIRepository().getApi())
          .getMcpServerDetail(<String, dynamic>{'id': id})
          .then((r) => r.data ?? <String, dynamic>{});
    } catch (e) {
      appLogger.e('Failed to get mcp server detail for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 智能体实例分页。参数：`{page: int, pageSize: int}`。POST /ai/agents/search。
  static Future<dynamic> pageAgentsNative(dynamic arguments) async {
    try {
      final page = (await (await AIRepository().getApi()).pageAgents(
              SearchWithPage(
                page: int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
                pageSize: int.tryParse('${arguments?['pageSize'] ?? 20}') ?? 20,
              ),
            ))
                .data!;
      return <String, dynamic>{
        'items': page.items.map((a) => a.toJson()).toList(),
        'total': page.total,
        'page': page.page,
        'pageSize': page.pageSize,
        'totalPages': page.totalPages,
      };
    } catch (e) {
      appLogger.e('Failed to page agents for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 智能体总览。参数：`{agentId: int}`。POST /ai/agents/overview。
  static Future<dynamic> getAgentOverviewNative(dynamic arguments) async {
    try {
      final agentId = int.tryParse('${arguments?['agentId'] ?? ''}');
      if (agentId == null) {
        return <String, dynamic>{};
      }
      return (await (await AIRepository().getApi())
                  .getAgentOverview(AgentOverviewReq(agentId: agentId)))
              .data
              ?.toJson() ??
          <String, dynamic>{};
    } catch (e) {
      appLogger.e('Failed to get agent overview for native: $e');
      return <String, dynamic>{};
    }
  }

  /// AI 服务绑定域名。参数：`{appInstallID: int}`。POST /ai/domain/get。
  static Future<dynamic> getAIBindDomain(dynamic arguments) async {
    try {
      final appInstallID = int.tryParse('${arguments?['appInstallID'] ?? ''}');
      if (appInstallID == null) {
        return <String, dynamic>{};
      }
      return (await AIRepository().getBindDomain(appInstallID: appInstallID))
          .toJson();
    } catch (e) {
      appLogger.e('Failed to get AI bind domain for native: $e');
      return <String, dynamic>{};
    }
  }
}
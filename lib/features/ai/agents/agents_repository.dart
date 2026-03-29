import 'package:onepanel_client/api/v2/ai_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/ai/agent_models.dart';
import 'package:onepanel_client/data/models/common_models.dart';

class AgentsRepository {
  AgentsRepository({ApiClientManager? clientManager})
      : _clientManager = clientManager ?? ApiClientManager.instance;

  final ApiClientManager _clientManager;

  Future<AIV2Api> _getApi() => _clientManager.getAiApi();

  Future<PageResult<AgentItem>> pageAgents({
    int page = 1,
    int pageSize = 20,
    String? keyword,
  }) async {
    final api = await _getApi();
    final response = await api.pageAgents(
      SearchWithPage(
        page: page,
        pageSize: pageSize,
        info: keyword,
      ),
    );
    return response.data ??
        const PageResult<AgentItem>(
          items: <AgentItem>[],
          total: 0,
        );
  }

  Future<AgentItem> createAgent(AgentCreateReq request) async {
    final api = await _getApi();
    final response = await api.createAgent(request);
    return response.data ?? const AgentItem();
  }

  Future<void> deleteAgent(AgentDeleteReq request) async {
    final api = await _getApi();
    await api.deleteAgent(request);
  }

  Future<AgentOverview> getAgentOverview(int agentId) async {
    final api = await _getApi();
    final response = await api.getAgentOverview(AgentOverviewReq(agentId: agentId));
    return response.data ?? const AgentOverview();
  }

  Future<List<ProviderInfo>> getAgentProviders() async {
    final api = await _getApi();
    final response = await api.getAgentProviders();
    return response.data ?? const <ProviderInfo>[];
  }

  Future<PageResult<AgentAccountItem>> pageAccounts({
    int page = 1,
    int pageSize = 20,
    String provider = '',
    String name = '',
  }) async {
    final api = await _getApi();
    final response = await api.pageAgentAccounts(
      AgentAccountSearch(
        page: page,
        pageSize: pageSize,
        provider: provider,
        name: name,
      ),
    );
    return response.data ??
        const PageResult<AgentAccountItem>(
          items: <AgentAccountItem>[],
          total: 0,
        );
  }

  Future<void> createAccount(AgentAccountCreateReq request) async {
    final api = await _getApi();
    await api.createAgentAccount(request);
  }

  Future<void> updateAccount(AgentAccountUpdateReq request) async {
    final api = await _getApi();
    await api.updateAgentAccount(request);
  }

  Future<void> verifyAccount(AgentAccountVerifyReq request) async {
    final api = await _getApi();
    await api.verifyAgentAccount(request);
  }

  Future<void> deleteAccount(int id) async {
    final api = await _getApi();
    await api.deleteAgentAccount(AgentAccountDeleteReq(id: id));
  }

  Future<List<AgentSkillItem>> listSkills(int agentId) async {
    final api = await _getApi();
    final response = await api.listAgentSkills(AgentSkillsReq(agentId: agentId));
    return response.data ?? const <AgentSkillItem>[];
  }

  Future<List<AgentSkillSearchItem>> searchSkills({
    required int agentId,
    required String source,
    required String keyword,
  }) async {
    final api = await _getApi();
    final response = await api.searchAgentSkills(
      AgentSkillSearchReq(
        agentId: agentId,
        source: source,
        keyword: keyword,
      ),
    );
    return response.data ?? const <AgentSkillSearchItem>[];
  }

  Future<void> updateSkill({
    required int agentId,
    required String name,
    required bool enabled,
  }) async {
    final api = await _getApi();
    await api.updateAgentSkill(
      AgentSkillUpdateReq(
        agentId: agentId,
        name: name,
        enabled: enabled,
      ),
    );
  }

  Future<void> installSkill({
    required int agentId,
    required String source,
    required String slug,
    required String taskId,
  }) async {
    final api = await _getApi();
    await api.installAgentSkill(
      AgentSkillInstallReq(
        agentId: agentId,
        source: source,
        slug: slug,
        taskID: taskId,
      ),
    );
  }

  Future<AgentFeishuConfig> getFeishuConfig(int agentId) async {
    final api = await _getApi();
    final response =
        await api.getAgentFeishuConfig(AgentFeishuConfigReq(agentId: agentId));
    return response.data ?? const AgentFeishuConfig();
  }

  Future<AgentTelegramConfig> getTelegramConfig(int agentId) async {
    final api = await _getApi();
    final response = await api
        .getAgentTelegramConfig(AgentTelegramConfigReq(agentId: agentId));
    return response.data ?? const AgentTelegramConfig();
  }

  Future<AgentDiscordConfig> getDiscordConfig(int agentId) async {
    final api = await _getApi();
    final response =
        await api.getAgentDiscordConfig(AgentDiscordConfigReq(agentId: agentId));
    return response.data ?? const AgentDiscordConfig();
  }

  Future<AgentWecomConfig> getWecomConfig(int agentId) async {
    final api = await _getApi();
    final response =
        await api.getAgentWecomConfig(AgentWecomConfigReq(agentId: agentId));
    return response.data ?? const AgentWecomConfig();
  }

  Future<AgentDingTalkConfig> getDingTalkConfig(int agentId) async {
    final api = await _getApi();
    final response = await api
        .getAgentDingTalkConfig(AgentDingTalkConfigReq(agentId: agentId));
    return response.data ?? const AgentDingTalkConfig();
  }

  Future<AgentQQBotConfig> getQQBotConfig(int agentId) async {
    final api = await _getApi();
    final response =
        await api.getAgentQQBotConfig(AgentQQBotConfigReq(agentId: agentId));
    return response.data ?? const AgentQQBotConfig();
  }

  Future<AgentSecurityConfig> getSecurityConfig(int agentId) async {
    final api = await _getApi();
    final response =
        await api.getAgentSecurityConfig(AgentSecurityConfigReq(agentId: agentId));
    return response.data ?? const AgentSecurityConfig();
  }

  Future<void> updateSecurityConfig({
    required int agentId,
    required List<String> allowedOrigins,
  }) async {
    final api = await _getApi();
    await api.updateAgentSecurityConfig(
      AgentSecurityConfigUpdateReq(
        agentId: agentId,
        allowedOrigins: allowedOrigins,
      ),
    );
  }

  Future<AgentOtherConfig> getOtherConfig(int agentId) async {
    final api = await _getApi();
    final response =
        await api.getAgentOtherConfig(AgentOtherConfigReq(agentId: agentId));
    return response.data ?? const AgentOtherConfig();
  }

  Future<void> updateOtherConfig({
    required int agentId,
    required String userTimezone,
    required bool browserEnabled,
    required String npmRegistry,
  }) async {
    final api = await _getApi();
    await api.updateAgentOtherConfig(
      AgentOtherConfigUpdateReq(
        agentId: agentId,
        userTimezone: userTimezone,
        browserEnabled: browserEnabled,
        npmRegistry: npmRegistry,
      ),
    );
  }

  Future<AgentConfigFile> getConfigFile(int agentId) async {
    final api = await _getApi();
    final response =
        await api.getAgentConfigFile(AgentConfigFileReq(agentId: agentId));
    return response.data ?? const AgentConfigFile();
  }

  Future<void> updateConfigFile({
    required int agentId,
    required String content,
  }) async {
    final api = await _getApi();
    await api.updateAgentConfigFile(
      AgentConfigFileUpdateReq(
        agentId: agentId,
        content: content,
      ),
    );
  }
}

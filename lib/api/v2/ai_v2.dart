import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/ai_models.dart';
import '../../data/models/ai/agent_models.dart';
import '../../data/models/mcp_models.dart';
import '../../data/models/common_models.dart';
import 'api_response_parser.dart';

class AIV2Api {
  final DioClient _client;

  AIV2Api(this._client);

  Map<String, dynamic> _unwrapDataMap(dynamic payload) {
    return ApiResponseParser.asMap(payload);
  }

  List<dynamic> _unwrapDataList(dynamic payload) {
    return ApiResponseParser.asList(payload);
  }

  /// 绑定域名
  ///
  /// 为AI服务绑定域名
  /// @param request 绑定域名请求
  /// @return 绑定结果
  Future<Response<void>> bindDomain(OllamaBindDomain request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/domain/bind'),
      data: request.toJson(),
    );
  }

  /// 获取绑定域名
  ///
  /// 获取当前AI服务绑定的域名信息
  /// @param request 获取绑定域名请求
  /// @return 域名信息
  Future<Response<OllamaBindDomainRes>> getBindDomain(
      OllamaBindDomainReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/domain/get'),
      data: request.toJson(),
    );
    return Response(
      data: OllamaBindDomainRes.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 加载GPU/XPU信息
  ///
  /// 获取系统中的GPU或XPU信息
  /// @return GPU/XPU信息
  Future<Response<List<GpuInfo>>> loadGpuInfo() async {
    final response =
        await _client.get(ApiConstants.buildApiPath('/ai/gpu/load'));
    return Response(
      data: _unwrapDataList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(GpuInfo.fromJson)
          .toList(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 创建Ollama模型
  ///
  /// 创建一个新的Ollama模型
  /// @param request 模型名称请求
  /// @return 创建结果
  Future<Response<void>> createOllamaModel(OllamaModelName request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/ollama/model'),
      data: request.toJson(),
    );
  }

  /// 关闭Ollama模型连接
  ///
  /// 关闭指定Ollama模型的连接
  /// @param request 模型名称请求
  /// @return 操作结果
  Future<Response<void>> closeOllamaModel(OllamaModelName request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/ollama/close'),
      data: request.toJson(),
    );
  }

  /// 删除Ollama模型
  ///
  /// 删除指定的Ollama模型
  /// @param request 删除请求
  /// @return 删除结果
  Future<Response<void>> deleteOllamaModel(ForceDelete request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/ollama/model/del'),
      data: request.toJson(),
    );
  }

  /// 加载Ollama模型
  ///
  /// 加载指定的Ollama模型
  /// @param request 模型名称请求
  /// @return 加载结果
  Future<Response<String>> loadOllamaModel(OllamaModelName request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/ollama/model/load'),
      data: request.toJson(),
    );
    return Response(
      data: response.data?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 重新创建Ollama模型
  ///
  /// 重新创建指定的Ollama模型
  /// @param request 模型名称请求
  /// @return 创建结果
  Future<Response<void>> recreateOllamaModel(OllamaModelName request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/ollama/model/recreate'),
      data: request.toJson(),
    );
  }

  /// 搜索Ollama模型
  ///
  /// 搜索Ollama模型列表
  /// @param request 搜索请求
  /// @return 搜索结果
  Future<Response<PageResult<OllamaModel>>> searchOllamaModels(
      SearchWithPage request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/ollama/model/search'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult<OllamaModel>.fromJson(_unwrapDataMap(response.data),
          (json) => OllamaModel.fromJson(json as Map<String, dynamic>)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 同步Ollama模型列表
  ///
  /// 同步Ollama模型列表
  /// @return 模型列表
  Future<Response<List<OllamaModelDropList>>> syncOllamaModels() async {
    final response =
        await _client.post(ApiConstants.buildApiPath('/ai/ollama/model/sync'));
    return Response(
      data: _unwrapDataList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(OllamaModelDropList.fromJson)
          .toList(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // ==================== Agents 管理 ====================

  /// 创建 Agent
  Future<Response<AgentItem>> createAgent(AgentCreateReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents'),
      data: request.toJson(),
    );
    return Response(
      data: AgentItem.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 分页查询 Agents
  Future<Response<PageResult<AgentItem>>> pageAgents(
      SearchWithPage request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/search'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult<AgentItem>.fromJson(
        _unwrapDataMap(response.data),
        (dynamic json) => AgentItem.fromJson(json as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 删除 Agent
  Future<Response<void>> deleteAgent(AgentDeleteReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/delete'),
      data: request.toJson(),
    );
  }

  /// 重置 Agent token
  Future<Response<void>> resetAgentToken(AgentTokenResetReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/token/reset'),
      data: request.toJson(),
    );
  }

  /// 绑定 Agent 角色通道
  Future<Response<void>> bindAgentRoleChannel(AgentRoleBindReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/agent/bind'),
      data: request.toJson(),
    );
  }

  /// 解绑 Agent 角色通道
  Future<Response<void>> unbindAgentRoleChannel(AgentRoleBindReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/agent/unbind'),
      data: request.toJson(),
    );
  }

  /// 查询 Agent 角色通道
  Future<Response<List<AgentRoleChannelItem>>> getAgentRoleChannels(
      AgentRoleChannelsReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/agent/channels'),
      data: request.toJson(),
    );
    return Response(
      data: _unwrapDataList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(AgentRoleChannelItem.fromJson)
          .toList(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 创建 Agent 角色
  Future<Response<AgentRoleCreateResp>> createAgentRole(
      AgentRoleCreateReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/agent/create'),
      data: request.toJson(),
    );
    return Response(
      data: AgentRoleCreateResp.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 删除 Agent 角色
  Future<Response<void>> deleteAgentRole(AgentRoleDeleteReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/agent/delete'),
      data: request.toJson(),
    );
  }

  /// 查询 Agent 角色列表
  Future<Response<List<AgentConfiguredAgentItem>>> listAgentRoles(
      AgentConfiguredAgentsReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/agent/list'),
      data: request.toJson(),
    );
    return Response(
      data: _unwrapDataList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(AgentConfiguredAgentItem.fromJson)
          .toList(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 查询 Agent 角色 Markdown 文件
  Future<Response<List<AgentRoleMarkdownFileItem>>> listAgentRoleMarkdownFiles(
      AgentRoleMarkdownFilesReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/agent/md/list'),
      data: request.toJson(),
    );
    return Response(
      data: _unwrapDataList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(AgentRoleMarkdownFileItem.fromJson)
          .toList(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新 Agent 角色 Markdown 文件
  Future<Response<void>> updateAgentRoleMarkdownFiles(
      AgentRoleMarkdownFilesUpdateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/agent/md/update'),
      data: request.toJson(),
    );
  }

  /// 获取 Agent 模型配置
  Future<Response<AgentModelConfig>> getAgentModelConfig(
      AgentIdReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/model/get'),
      data: request.toJson(),
    );
    return Response(
      data: AgentModelConfig.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新 Agent 备注
  Future<Response<void>> updateAgentRemark(AgentRemarkUpdateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/remark'),
      data: request.toJson(),
    );
  }

  /// 绑定 Agent 网站
  Future<Response<void>> bindAgentWebsite(AgentWebsiteBindReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/website/bind'),
      data: request.toJson(),
    );
  }

  /// 更新 Agent 模型配置
  Future<Response<void>> updateAgentModelConfig(
      AgentModelConfigUpdateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/model/update'),
      data: request.toJson(),
    );
  }

  /// 获取 Agent 总览
  Future<Response<AgentOverview>> getAgentOverview(
      AgentOverviewReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/overview'),
      data: request.toJson(),
    );
    return Response(
      data: AgentOverview.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取 Agent 支持的模型供应商
  Future<Response<List<ProviderInfo>>> getAgentProviders() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/ai/agents/providers'),
    );
    return Response(
      data: _unwrapDataList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(ProviderInfo.fromJson)
          .toList(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 创建 Agent 账号
  Future<Response<void>> createAgentAccount(AgentAccountCreateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/accounts'),
      data: request.toJson(),
    );
  }

  /// 更新 Agent 账号
  Future<Response<void>> updateAgentAccount(AgentAccountUpdateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/accounts/update'),
      data: request.toJson(),
    );
  }

  /// 分页查询 Agent 账号
  Future<Response<PageResult<AgentAccountItem>>> pageAgentAccounts(
      AgentAccountSearch request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/accounts/search'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult<AgentAccountItem>.fromJson(
        _unwrapDataMap(response.data),
        (dynamic json) =>
            AgentAccountItem.fromJson(json as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取账号模型列表
  Future<Response<List<AgentAccountModel>>> getAgentAccountModels(
      AgentAccountModelReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/accounts/models'),
      data: request.toJson(),
    );
    return Response(
      data: _unwrapDataList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(AgentAccountModel.fromJson)
          .toList(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 创建账号模型
  Future<Response<void>> createAgentAccountModel(
      AgentAccountModelCreateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/accounts/models/create'),
      data: request.toJson(),
    );
  }

  /// 更新账号模型
  Future<Response<void>> updateAgentAccountModel(
      AgentAccountModelUpdateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/accounts/models/update'),
      data: request.toJson(),
    );
  }

  /// 删除账号模型
  Future<Response<void>> deleteAgentAccountModel(
      AgentAccountModelDeleteReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/accounts/models/delete'),
      data: request.toJson(),
    );
  }

  /// 验证账号配置
  Future<Response<void>> verifyAgentAccount(AgentAccountVerifyReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/accounts/verify'),
      data: request.toJson(),
    );
  }

  /// 删除账号
  Future<Response<void>> deleteAgentAccount(AgentAccountDeleteReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/accounts/delete'),
      data: request.toJson(),
    );
  }

  /// 获取飞书通道配置
  Future<Response<AgentFeishuConfig>> getAgentFeishuConfig(
      AgentFeishuConfigReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/channel/feishu/get'),
      data: request.toJson(),
    );
    return Response(
      data: AgentFeishuConfig.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新飞书通道配置
  Future<Response<void>> updateAgentFeishuConfig(
      AgentFeishuConfigUpdateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/channel/feishu/update'),
      data: request.toJson(),
    );
  }

  /// 审批飞书通道配对
  Future<Response<void>> approveAgentFeishuPairing(
      AgentFeishuPairingApproveReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/channel/feishu/approve'),
      data: request.toJson(),
    );
  }

  /// 获取 Telegram 通道配置
  Future<Response<AgentTelegramConfig>> getAgentTelegramConfig(
      AgentTelegramConfigReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/channel/telegram/get'),
      data: request.toJson(),
    );
    return Response(
      data: AgentTelegramConfig.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新 Telegram 通道配置
  Future<Response<void>> updateAgentTelegramConfig(
      AgentTelegramConfigUpdateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/channel/telegram/update'),
      data: request.toJson(),
    );
  }

  /// 获取 Discord 通道配置
  Future<Response<AgentDiscordConfig>> getAgentDiscordConfig(
      AgentDiscordConfigReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/channel/discord/get'),
      data: request.toJson(),
    );
    return Response(
      data: AgentDiscordConfig.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新 Discord 通道配置
  Future<Response<void>> updateAgentDiscordConfig(
      AgentDiscordConfigUpdateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/channel/discord/update'),
      data: request.toJson(),
    );
  }

  /// 获取企业微信通道配置
  Future<Response<AgentWecomConfig>> getAgentWecomConfig(
      AgentWecomConfigReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/channel/wecom/get'),
      data: request.toJson(),
    );
    return Response(
      data: AgentWecomConfig.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新企业微信通道配置
  Future<Response<void>> updateAgentWecomConfig(
      AgentWecomConfigUpdateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/channel/wecom/update'),
      data: request.toJson(),
    );
  }

  /// 获取钉钉通道配置
  Future<Response<AgentDingTalkConfig>> getAgentDingTalkConfig(
      AgentDingTalkConfigReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/channel/dingtalk/get'),
      data: request.toJson(),
    );
    return Response(
      data: AgentDingTalkConfig.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新钉钉通道配置
  Future<Response<void>> updateAgentDingTalkConfig(
      AgentDingTalkConfigUpdateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/channel/dingtalk/update'),
      data: request.toJson(),
    );
  }

  /// 登录微信通道
  Future<Response<void>> loginAgentWeixinChannel(AgentWeixinLoginReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/channel/weixin/login'),
      data: request.toJson(),
    );
  }

  /// 获取 QQ Bot 配置
  Future<Response<AgentQQBotConfig>> getAgentQQBotConfig(
      AgentQQBotConfigReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/channel/qqbot/get'),
      data: request.toJson(),
    );
    return Response(
      data: AgentQQBotConfig.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新 QQ Bot 配置
  Future<Response<void>> updateAgentQQBotConfig(
      AgentQQBotConfigUpdateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/channel/qqbot/update'),
      data: request.toJson(),
    );
  }

  /// 安装 Agent 插件
  Future<Response<void>> installAgentPlugin(AgentPluginInstallReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/plugin/install'),
      data: request.toJson(),
    );
  }

  /// 卸载 Agent 插件
  Future<Response<void>> uninstallAgentPlugin(AgentPluginUninstallReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/plugin/uninstall'),
      data: request.toJson(),
    );
  }

  /// 升级 Agent 插件
  Future<Response<void>> upgradeAgentPlugin(AgentPluginUpgradeReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/plugin/upgrade'),
      data: request.toJson(),
    );
  }

  /// 检查 Agent 插件状态
  Future<Response<AgentPluginStatus>> checkAgentPlugin(
      AgentPluginCheckReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/plugin/check'),
      data: request.toJson(),
    );
    return Response(
      data: AgentPluginStatus.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取 Agent 安全配置
  Future<Response<AgentSecurityConfig>> getAgentSecurityConfig(
      AgentSecurityConfigReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/security/get'),
      data: request.toJson(),
    );
    return Response(
      data: AgentSecurityConfig.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新 Agent 安全配置
  Future<Response<void>> updateAgentSecurityConfig(
      AgentSecurityConfigUpdateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/security/update'),
      data: request.toJson(),
    );
  }

  /// 获取 Agent 其他配置
  Future<Response<AgentOtherConfig>> getAgentOtherConfig(
      AgentOtherConfigReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/other/get'),
      data: request.toJson(),
    );
    return Response(
      data: AgentOtherConfig.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新 Agent 其他配置
  Future<Response<void>> updateAgentOtherConfig(
      AgentOtherConfigUpdateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/other/update'),
      data: request.toJson(),
    );
  }

  /// 获取 Agent 浏览器配置
  Future<Response<AgentBrowserConfig>> getAgentBrowserConfig(
      AgentBrowserConfigReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/browser/get'),
      data: request.toJson(),
    );
    return Response(
      data: AgentBrowserConfig.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新 Agent 浏览器配置
  Future<Response<void>> updateAgentBrowserConfig(
      AgentBrowserConfigUpdateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/browser/update'),
      data: request.toJson(),
    );
  }

  /// 获取 Agent 配置文件
  Future<Response<AgentConfigFile>> getAgentConfigFile(
      AgentConfigFileReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/config-file/get'),
      data: request.toJson(),
    );
    return Response(
      data: AgentConfigFile.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新 Agent 配置文件
  Future<Response<void>> updateAgentConfigFile(
      AgentConfigFileUpdateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/config-file/update'),
      data: request.toJson(),
    );
  }

  /// 列出 Agent 技能
  Future<Response<List<AgentSkillItem>>> listAgentSkills(
      AgentSkillsReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/skills/list'),
      data: request.toJson(),
    );
    return Response(
      data: _unwrapDataList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(AgentSkillItem.fromJson)
          .toList(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 搜索 Agent 技能
  Future<Response<List<AgentSkillSearchItem>>> searchAgentSkills(
      AgentSkillSearchReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/agents/skills/search'),
      data: request.toJson(),
    );
    return Response(
      data: _unwrapDataList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(AgentSkillSearchItem.fromJson)
          .toList(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新 Agent 技能启用状态
  Future<Response<void>> updateAgentSkill(AgentSkillUpdateReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/skills/update'),
      data: request.toJson(),
    );
  }

  /// 安装 Agent 技能
  Future<Response<void>> installAgentSkill(AgentSkillInstallReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/skills/install'),
      data: request.toJson(),
    );
  }

  /// 审批通道配对
  Future<Response<void>> approveAgentChannelPairing(
      AgentChannelPairingApproveReq request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/channel/pairing/approve'),
      data: request.toJson(),
    );
  }

  // ==================== MCP 服务器管理 ====================

  /// 绑定MCP域名
  ///
  /// 为MCP服务器绑定域名
  /// @param request 绑定域名请求
  /// @return 绑定结果
  Future<Response<void>> bindMcpDomain(McpBindDomain request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/mcp/domain/bind'),
      data: request.toJson(),
    );
  }

  /// 获取MCP绑定域名
  ///
  /// 获取当前MCP服务器绑定的域名信息
  /// @return 域名信息
  Future<Response<McpBindDomainRes>> getMcpBindDomain() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/ai/mcp/domain/get'),
    );
    return Response(
      data: McpBindDomainRes.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新MCP绑定域名
  ///
  /// 更新MCP服务器的域名绑定
  /// @param request 更新域名请求
  /// @return 更新结果
  Future<Response<void>> updateMcpDomain(McpBindDomainUpdate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/mcp/domain/update'),
      data: request.toJson(),
    );
  }

  /// 搜索MCP服务器
  ///
  /// 搜索MCP服务器列表
  /// @param request 搜索请求
  /// @return 搜索结果
  Future<Response<McpServersRes>> searchMcpServers(
      McpServerSearch request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/ai/mcp/search'),
      data: request.toJson(),
    );
    return Response(
      data: McpServersRes.fromJson(_unwrapDataMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 创建MCP服务器
  ///
  /// 创建一个新的MCP服务器
  /// @param request 创建请求
  /// @return 创建结果
  Future<Response<void>> createMcpServer(McpServerCreate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/mcp/server'),
      data: request.toJson(),
    );
  }

  /// 删除MCP服务器
  ///
  /// 删除指定的MCP服务器
  /// @param request 删除请求
  /// @return 删除结果
  Future<Response<void>> deleteMcpServer(McpServerDelete request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/mcp/server/del'),
      data: request.toJson(),
    );
  }

  /// 操作MCP服务器
  ///
  /// 对MCP服务器进行操作（启动/停止/重启等）
  /// @param request 操作请求
  /// @return 操作结果
  Future<Response<void>> operateMcpServer(McpServerOperate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/mcp/server/op'),
      data: request.toJson(),
    );
  }

  /// 更新MCP服务器
  ///
  /// 更新MCP服务器配置
  /// @param request 更新请求
  /// @return 更新结果
  Future<Response<void>> updateMcpServer(McpServerUpdate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/mcp/server/update'),
      data: request.toJson(),
    );
  }

  /// 测试大模型接口联通性
  Future<Response<void>> testAgentModelConnection(Map<String, dynamic> request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/ai/agents/models/test'),
      data: request,
    );
  }

}

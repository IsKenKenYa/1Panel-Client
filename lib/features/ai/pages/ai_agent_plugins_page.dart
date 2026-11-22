import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/api/v2/ai_v2.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';

/// AI Agent 插件管理页。
/// 对齐前端 `ai/agents` 详情的插件子页：已装列表 + 插件市场 + 安装/操作。
class AiAgentPluginsPage extends StatefulWidget {
  const AiAgentPluginsPage({super.key, required this.agentId});

  final String agentId;

  @override
  State<AiAgentPluginsPage> createState() => _AiAgentPluginsPageState();
}

class _AiAgentPluginsPageState extends State<AiAgentPluginsPage> {
  List<Map<String, dynamic>> _plugins = [];
  List<Map<String, dynamic>> _market = [];
  bool _isLoading = true;
  bool _isMutating = false;
  String? _error;
  final _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _withApi(
    Future<Map<String, dynamic>?> Function(AIV2Api api) action,
  ) async {
    final api = AIV2Api(await ApiClientManager.instance.getCurrentClient());
    return action(api);
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await _withApi((api) async {
        final res = await api.listAgentPlugins({'agentId': widget.agentId});
        _plugins = _asList(res.data);
        return null;
      });
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorMessageUtils.userFacingMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchMarket() async {
    try {
      await _withApi((api) async {
        final res = await api.searchAgentPlugins(<String, dynamic>{
          'agentId': widget.agentId,
          'keyword': _keywordController.text.trim(),
          'limit': 20,
        });
        _market = _asList(res.data);
        return null;
      });
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
            context, ErrorMessageUtils.userFacingMessage(e));
      }
    }
  }

  Future<void> _operate(
    Map<String, dynamic> plugin,
    String operate,
  ) async {
    setState(() => _isMutating = true);
    try {
      await _withApi((api) async {
        await api.operateAgentPlugin(<String, dynamic>{
          'agentId': widget.agentId,
          'pluginId': plugin['id'] ?? plugin['pluginId'] ?? '',
          'operate': operate,
          'taskID': '',
        });
        return null;
      });
      if (mounted) {
        SnackBarUtils.showSuccess(context, context.l10n.aiOperationSuccess);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
            context, ErrorMessageUtils.userFacingMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _installMarket(Map<String, dynamic> item) async {
    setState(() => _isMutating = true);
    try {
      await _withApi((api) async {
        await api.installAgentMarketPlugin(<String, dynamic>{
          'agentId': widget.agentId,
          'package': item['package'] ?? item['name'] ?? '',
          'version': item['version']?.toString() ?? '',
          'taskID': '',
        });
        return null;
      });
      if (mounted) {
        SnackBarUtils.showSuccess(context, context.l10n.aiOperationSuccess);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
            context, ErrorMessageUtils.userFacingMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _confirmOperate(String title, Future<void> Function() action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) await action();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.aiAgentPluginsTitle),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh_outlined), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(
                        onPressed: _load,
                        child: Text(l10n.commonRetry),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: AppDesignTokens.cardPadding,
                  children: [
                    Text(l10n.aiAgentInstalledPlugins,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_plugins.isEmpty) Text(l10n.commonEmpty),
                    for (final plugin in _plugins)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(plugin['name']?.toString() ?? '-'),
                          subtitle: Text(
                            'v${plugin['version'] ?? '-'} · ${plugin['origin'] ?? ''}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => _confirmOperate(
                              value,
                              () => _operate(plugin, value),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: (plugin['enabled'] == true)
                                    ? 'disable'
                                    : 'enable',
                                child: Text(
                                  (plugin['enabled'] == true)
                                      ? l10n.aiAgentsDisabled
                                      : l10n.aiAgentsEnabled,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'upgrade',
                                child: Text(l10n.aiAgentPluginUpgrade),
                              ),
                              PopupMenuItem(
                                value: 'uninstall',
                                child: Text(l10n.aiAgentPluginUninstall),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(l10n.aiAgentPluginMarket,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _keywordController,
                            decoration: InputDecoration(
                              hintText: l10n.aiAgentPluginSearchHint,
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _searchMarket(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: context.l10n.commonSearch,
                          onPressed: _isMutating ? null : _searchMarket,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_market.isEmpty) Text(l10n.aiAgentPluginMarketEmpty),
                    for (final item in _market)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(item['name']?.toString() ?? '-'),
                          subtitle: Text(
                            item['description']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.download_outlined),
                            tooltip: l10n.imageOpsPush,
                            onPressed: _isMutating
                                ? null
                                : () => _confirmOperate(
                                      l10n.aiAgentPluginInstallConfirm,
                                      () => _installMarket(item),
                                    ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

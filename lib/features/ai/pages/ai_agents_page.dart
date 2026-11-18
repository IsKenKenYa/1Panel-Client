import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/ai/agents/agents_repository.dart';
import 'package:onepanel_client/features/ai/agents/agents_provider.dart';
import 'package:onepanel_client/features/ai/pages/ai_agent_plugins_page.dart';
import 'package:onepanel_client/data/models/ai/agent_core_models.dart';
import 'package:provider/provider.dart';

/// AI Agent management page.
/// Mirrors frontend's ai/agents/agent page: list/create/delete agents.
class AiAgentsPage extends StatefulWidget {
  const AiAgentsPage({super.key});

  @override
  State<AiAgentsPage> createState() => _AiAgentsPageState();
}

class _AiAgentsPageState extends State<AiAgentsPage> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final provider = context.read<AgentsProvider>();
      await provider.loadInitial();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _deleteAgent(int agentId) async {
    try {
      final repo = AgentsRepository();
      await repo.deleteAgent(AgentDeleteReq(id: agentId, taskID: ''));
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, context.l10n.commonDeleted);
      _load();
    } catch (e) {
      if (context.mounted) SnackBarUtils.showError(context, context.l10n.commonDeleteFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title:  Text(context.l10n.aiAgentsTitle),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh_outlined), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Consumer<AgentsProvider>(
                  builder: (context, provider, _) {
                    final agents = provider.agents;
                    if (agents.isEmpty) {
                      return  Center(child: Text(context.l10n.aiAgentsNoAgents));
                    }
                    return ListView.builder(
                      itemCount: agents.length,
                      itemBuilder: (context, index) {
                        final agent = agents[index];
                        return Card(
                          child: ListTile(
                            title: Text(agent.name ?? 'Unnamed'),
                            subtitle: Text('${context.l10n.aiAgentsTypeWith(agent.agentType ?? 'N/A')} | ${context.l10n.commonStatus}: ${agent.status ?? 'N/A'}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.extension_outlined),
                                  tooltip: context.l10n.aiAgentPluginsTitle,
                                  onPressed: agent.id == null
                                      ? null
                                      : () => Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  AiAgentPluginsPage(
                                                agentId: agent.id.toString(),
                                              ),
                                            ),
                                          ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: context.l10n.commonDelete,
                                  onPressed: () => _deleteAgent(agent.id ?? 0),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/ai/agents/agents_provider.dart';
import 'package:provider/provider.dart';

import 'ai_agent_create_dialog.dart';
import 'ai_agents_detail_widget.dart';

class AIAgentsListWidget extends StatefulWidget {
  const AIAgentsListWidget({super.key});

  @override
  State<AIAgentsListWidget> createState() => _AIAgentsListWidgetState();
}

class _AIAgentsListWidgetState extends State<AIAgentsListWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<AgentsProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        labelText: l10n.aiAgentsSearchHint,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: provider.searchAgents,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: provider.isMutating
                        ? null
                        : () => _showCreateDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.commonCreate),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.searchAgents(
                              _searchController.text.trim(),
                            ),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.commonRefresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (provider.agents.isEmpty && !provider.isLoading) {
                      return Center(child: Text(l10n.aiAgentsNoAgents));
                    }

                    final list = _buildAgentList(context, provider);
                    final detail = AIAgentsDetailWidget(
                      key: ValueKey<int>(provider.selectedAgent?.id ?? 0),
                    );

                    if (constraints.maxWidth < 900) {
                      return Column(
                        children: <Widget>[
                          SizedBox(height: 260, child: list),
                          const SizedBox(height: 8),
                          Expanded(child: detail),
                        ],
                      );
                    }

                    return Row(
                      children: <Widget>[
                        SizedBox(width: 380, child: list),
                        const SizedBox(width: 12),
                        Expanded(child: detail),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgentList(BuildContext context, AgentsProvider provider) {
    final l10n = context.l10n;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: provider.agents.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = provider.agents[index];
          final selected = provider.selectedAgent?.id == item.id;
          return ListTile(
            selected: selected,
            title: Text(item.name ?? '-'),
            subtitle: Text('${item.agentType ?? '-'}  ·  ${item.status ?? '-'}'),
            onTap: () => provider.selectAgent(item),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.commonDelete,
              onPressed: provider.isMutating || item.id == null
                  ? null
                  : () => _confirmDelete(context, item.id!),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: AIAgentCreateDialog(),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.commonDelete),
        content: Text(l10n.aiAgentsDeleteConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AgentsProvider>().deleteAgent(id);
    }
  }
}

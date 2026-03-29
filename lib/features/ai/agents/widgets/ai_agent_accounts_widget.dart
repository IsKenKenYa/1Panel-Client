import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ai/agent_models.dart';
import 'package:onepanel_client/features/ai/agents/agents_provider.dart';
import 'package:provider/provider.dart';

import 'ai_agent_account_dialog.dart';

class AIAgentAccountsWidget extends StatefulWidget {
  const AIAgentAccountsWidget({super.key});

  @override
  State<AIAgentAccountsWidget> createState() => _AIAgentAccountsWidgetState();
}

class _AIAgentAccountsWidgetState extends State<AIAgentAccountsWidget> {
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      value: provider.accountProvider.isEmpty
                          ? null
                          : provider.accountProvider,
                      decoration: InputDecoration(
                        labelText: l10n.aiAgentsProvider,
                        border: const OutlineInputBorder(),
                      ),
                      items: <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          value: '',
                          child: Text(l10n.aiAgentsAllProviders),
                        ),
                        ...provider.providers.map(
                          (item) => DropdownMenuItem<String>(
                            value: item.provider,
                            child: Text(item.displayName),
                          ),
                        ),
                      ],
                      onChanged: (value) => provider.filterAccounts(
                        provider: value ?? '',
                        keyword: _searchController.text.trim(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        labelText: l10n.commonSearch,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (value) => provider.filterAccounts(
                        keyword: value,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAccountDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.commonCreate),
                  ),
                  OutlinedButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.filterAccounts(
                              keyword: _searchController.text.trim(),
                            ),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.commonRefresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: provider.accounts.isEmpty && !provider.isLoading
                    ? Center(child: Text(l10n.commonEmpty))
                    : Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListView.separated(
                          itemCount: provider.accounts.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = provider.accounts[index];
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.providerName} · ${item.apiType} · '
                                '${item.verified ? l10n.aiAgentsVerified : l10n.aiAgentsUnverified}',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) => _handleAction(
                                  context,
                                  provider,
                                  item,
                                  action,
                                ),
                                itemBuilder: (_) => <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: 'verify',
                                    child: Text(l10n.aiAgentsVerify),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Text(l10n.commonEdit),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text(l10n.commonDelete),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAccountDialog(
    BuildContext context, {
    AgentAccountItem? account,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AIAgentAccountDialog(account: account),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    AgentsProvider provider,
    AgentAccountItem item,
    String action,
  ) async {
    final l10n = context.l10n;

    if (action == 'edit') {
      await _showAccountDialog(context, account: item);
      return;
    }

    if (action == 'verify') {
      await provider.verifyAccount(
        AgentAccountVerifyReq(
          provider: item.provider,
          apiKey: item.apiKey,
          baseURL: item.baseUrl,
        ),
      );
      if (context.mounted) {
        await provider.filterAccounts(keyword: _searchController.text.trim());
      }
      return;
    }

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
      await provider.deleteAccount(item.id);
    }
  }
}

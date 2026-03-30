import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ai/agent_models.dart';
import 'package:onepanel_client/features/ai/agents/agents_provider.dart';

import 'ai_agent_dialog_utils.dart';

class AIAgentCreateFormWidget extends StatelessWidget {
  const AIAgentCreateFormWidget({
    super.key,
    required this.provider,
    required this.submitting,
    required this.agentType,
    required this.accountId,
    required this.model,
    required this.nameController,
    required this.versionController,
    required this.portController,
    required this.tokenController,
    required this.onAgentTypeChanged,
    required this.onAccountChanged,
    required this.onModelChanged,
    required this.nameValidator,
    required this.versionValidator,
    required this.portValidator,
    required this.accountValidator,
    required this.modelValidator,
  });

  final AgentsProvider provider;
  final bool submitting;
  final String agentType;
  final int? accountId;
  final String model;
  final TextEditingController nameController;
  final TextEditingController versionController;
  final TextEditingController portController;
  final TextEditingController tokenController;
  final ValueChanged<String?> onAgentTypeChanged;
  final ValueChanged<int?> onAccountChanged;
  final ValueChanged<String?> onModelChanged;
  final FormFieldValidator<String> nameValidator;
  final FormFieldValidator<String> versionValidator;
  final FormFieldValidator<String> portValidator;
  final FormFieldValidator<int> accountValidator;
  final FormFieldValidator<String> modelValidator;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedAccount = provider.accounts
        .where((item) => item.id == accountId)
        .cast<AgentAccountItem?>()
        .firstOrNull;
    final models = selectedAccount?.models ?? const <AgentAccountModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: l10n.commonName,
            border: const OutlineInputBorder(),
          ),
          validator: nameValidator,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('agent-type-$agentType'),
          initialValue: agentType,
          decoration: InputDecoration(
            labelText: l10n.aiAgentsAgentType,
            border: const OutlineInputBorder(),
          ),
          items: <DropdownMenuItem<String>>[
            DropdownMenuItem(
              value: 'openclaw',
              child: Text(l10n.aiAgentsOpenclaw),
            ),
            DropdownMenuItem(
              value: 'copaw',
              child: Text(l10n.aiAgentsCopaw),
            ),
          ],
          onChanged: submitting ? null : onAgentTypeChanged,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: versionController,
          decoration: InputDecoration(
            labelText: l10n.aiAgentsAppVersion,
            border: const OutlineInputBorder(),
          ),
          validator: versionValidator,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: portController,
          decoration: InputDecoration(
            labelText: l10n.aiAgentsWebUiPort,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: portValidator,
        ),
        if (agentType == 'openclaw') ...<Widget>[
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            key: ValueKey<int?>(accountId),
            initialValue: accountId,
            decoration: InputDecoration(
              labelText: l10n.aiAgentsAccount,
              border: const OutlineInputBorder(),
            ),
            items: provider.accounts
                .map(
                  (item) => DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged: submitting ? null : onAccountChanged,
            validator: accountValidator,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey<String?>(model.isEmpty ? null : model),
            initialValue: model.isEmpty ? null : model,
            decoration: InputDecoration(
              labelText: l10n.aiAgentsModel,
              border: const OutlineInputBorder(),
            ),
            items: models
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged: submitting ? null : onModelChanged,
            validator: modelValidator,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: tokenController,
            decoration: InputDecoration(
              labelText: l10n.aiAgentsTokenOptional,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }
}

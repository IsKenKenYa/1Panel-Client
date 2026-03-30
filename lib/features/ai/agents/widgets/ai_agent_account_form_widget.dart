import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ai/agent_models.dart';
import 'package:onepanel_client/features/ai/agents/agents_provider.dart';

import 'ai_agent_dialog_utils.dart';

class AIAgentAccountFormWidget extends StatelessWidget {
  const AIAgentAccountFormWidget({
    super.key,
    required this.provider,
    required this.uiProvider,
    required this.submitting,
    required this.isEdit,
    required this.currentProvider,
    required this.nameController,
    required this.apiKeyController,
    required this.baseUrlController,
    required this.apiTypeController,
    required this.remarkController,
    required this.rememberApiKey,
    required this.syncAgents,
    required this.onProviderChanged,
    required this.onRememberApiKeyChanged,
    required this.onSyncAgentsChanged,
    required this.providerValidator,
    required this.nameValidator,
    required this.apiKeyValidator,
    required this.apiTypeValidator,
  });

  final AgentsProvider provider;
  final AgentsProvider uiProvider;
  final bool submitting;
  final bool isEdit;
  final String currentProvider;
  final TextEditingController nameController;
  final TextEditingController apiKeyController;
  final TextEditingController baseUrlController;
  final TextEditingController apiTypeController;
  final TextEditingController remarkController;
  final bool rememberApiKey;
  final bool syncAgents;
  final ValueChanged<String?> onProviderChanged;
  final ValueChanged<bool?> onRememberApiKeyChanged;
  final ValueChanged<bool?> onSyncAgentsChanged;
  final FormFieldValidator<String> providerValidator;
  final FormFieldValidator<String> nameValidator;
  final FormFieldValidator<String> apiKeyValidator;
  final FormFieldValidator<String> apiTypeValidator;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<String>(
          key: ValueKey<String?>('provider-$currentProvider'),
          initialValue: currentProvider.isEmpty ? null : currentProvider,
          decoration: InputDecoration(
            labelText: l10n.aiAgentsProvider,
            border: const OutlineInputBorder(),
          ),
          items: provider.providers
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item.provider,
                  child: Text(item.displayName),
                ),
              )
              .toList(),
          onChanged: submitting || isEdit ? null : onProviderChanged,
          validator: providerValidator,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: l10n.commonName,
            border: const OutlineInputBorder(),
          ),
          validator: nameValidator,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: apiKeyController,
          decoration: InputDecoration(
            labelText: l10n.aiAgentsApiKey,
            border: const OutlineInputBorder(),
          ),
          validator: apiKeyValidator,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: baseUrlController,
          decoration: InputDecoration(
            labelText: l10n.aiAgentsBaseUrl,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: apiTypeController,
          decoration: InputDecoration(
            labelText: l10n.aiAgentsApiType,
            border: const OutlineInputBorder(),
          ),
          validator: apiTypeValidator,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: remarkController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.commonDescription,
            border: const OutlineInputBorder(),
          ),
        ),
        CheckboxListTile(
          value: rememberApiKey,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.aiAgentsRememberApiKey),
          onChanged: onRememberApiKeyChanged,
        ),
        if (isEdit)
          CheckboxListTile(
            value: syncAgents,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.aiAgentsSyncAgents),
            onChanged: onSyncAgentsChanged,
          ),
      ],
    );
  }

  ProviderInfo? resolveProviderInfo(String value) {
    return uiProvider.providers
        .where((item) => item.provider == value)
        .cast<ProviderInfo?>()
        .firstOrNull;
  }
}

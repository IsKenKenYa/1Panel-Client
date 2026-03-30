import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/ai/agents/agents_provider.dart';

import 'ai_agent_shared_widgets.dart';

class AIAgentSkillsSection extends StatelessWidget {
  const AIAgentSkillsSection({
    super.key,
    required this.provider,
    required this.searchController,
    required this.skillSource,
    required this.onSkillSourceChanged,
  });

  final AgentsProvider provider;
  final TextEditingController searchController;
  final String skillSource;
  final ValueChanged<String> onSkillSourceChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AISection(
      title: l10n.aiAgentsSkills,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<String>(
                  key: ValueKey<String>('skill-source-$skillSource'),
                  initialValue: skillSource,
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'clawhub', child: Text('clawhub')),
                    DropdownMenuItem(value: 'skillhub', child: Text('skillhub')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onSkillSourceChanged(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.aiAgentsSkillSearchHint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => provider.searchSkills(
                  source: skillSource,
                  keyword: searchController.text,
                ),
                child: Text(l10n.commonSearch),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...provider.skillSearchResults.map(
            (item) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              subtitle: Text(item.summary),
              trailing: OutlinedButton(
                onPressed: () => provider.installSkill(
                  source: item.source,
                  slug: item.slug,
                ),
                child: Text(l10n.aiAgentsInstall),
              ),
            ),
          ),
          const Divider(height: 20),
          ...provider.skills.map(
            (item) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              subtitle: Text(item.description),
              value: !item.disabled,
              onChanged: (value) => provider.updateSkillEnabled(item, value),
            ),
          ),
        ],
      ),
    );
  }
}

class AIAgentSettingsSection extends StatelessWidget {
  const AIAgentSettingsSection({
    super.key,
    required this.provider,
    required this.allowedOriginsController,
    required this.timezoneController,
    required this.npmRegistryController,
    required this.configController,
    required this.browserEnabled,
    required this.onBrowserEnabledChanged,
    required this.onSaveSettings,
    required this.onSaveConfig,
  });

  final AgentsProvider provider;
  final TextEditingController allowedOriginsController;
  final TextEditingController timezoneController;
  final TextEditingController npmRegistryController;
  final TextEditingController configController;
  final bool browserEnabled;
  final ValueChanged<bool> onBrowserEnabledChanged;
  final Future<void> Function() onSaveSettings;
  final Future<void> Function() onSaveConfig;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AISection(
      title: l10n.aiAgentsSettings,
      child: Column(
        children: <Widget>[
          TextField(
            controller: allowedOriginsController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.aiAgentsAllowedOrigins,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: timezoneController,
                  decoration: InputDecoration(
                    labelText: l10n.aiAgentsTimezone,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: npmRegistryController,
                  decoration: InputDecoration(
                    labelText: l10n.aiAgentsNpmRegistry,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.aiAgentsBrowserEnabled),
            value: browserEnabled,
            onChanged: onBrowserEnabledChanged,
          ),
          Row(
            children: <Widget>[
              FilledButton(
                onPressed: onSaveSettings,
                child: Text(l10n.commonSave),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: configController,
            minLines: 8,
            maxLines: 16,
            decoration: InputDecoration(
              labelText: l10n.aiAgentsConfigFile,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              FilledButton(
                onPressed: onSaveConfig,
                child: Text(l10n.aiAgentsSaveConfig),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

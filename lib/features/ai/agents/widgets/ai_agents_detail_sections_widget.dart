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
    required this.browserExecutablePath,
    required this.browserProfileController,
    required this.browserConfigEnabled,
    required this.browserHeadless,
    required this.browserNoSandbox,
    required this.onBrowserConfigEnabledChanged,
    required this.onBrowserHeadlessChanged,
    required this.onBrowserNoSandboxChanged,
    required this.onSaveBrowserConfig,
    required this.feishuPairingCodeController,
    required this.onApproveFeishuPairing,
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
  final String browserExecutablePath;
  final TextEditingController browserProfileController;
  final bool browserConfigEnabled;
  final bool browserHeadless;
  final bool browserNoSandbox;
  final ValueChanged<bool> onBrowserConfigEnabledChanged;
  final ValueChanged<bool> onBrowserHeadlessChanged;
  final ValueChanged<bool> onBrowserNoSandboxChanged;
  final Future<void> Function() onSaveBrowserConfig;
  final TextEditingController feishuPairingCodeController;
  final Future<void> Function() onApproveFeishuPairing;

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
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.aiAgentsBrowserConfig,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: browserProfileController,
            decoration: InputDecoration(
              labelText: l10n.aiAgentsBrowserDefaultProfile,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.aiAgentsBrowserExecutablePath,
              border: const OutlineInputBorder(),
            ),
            child: SelectableText(
              browserExecutablePath.isEmpty ? '-' : browserExecutablePath,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.aiAgentsEnabled),
            value: browserConfigEnabled,
            onChanged: onBrowserConfigEnabledChanged,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.aiAgentsBrowserHeadless),
            value: browserHeadless,
            onChanged: onBrowserHeadlessChanged,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.aiAgentsBrowserNoSandbox),
            value: browserNoSandbox,
            onChanged: onBrowserNoSandboxChanged,
          ),
          Row(
            children: <Widget>[
              FilledButton(
                onPressed: onSaveBrowserConfig,
                child: Text(l10n.aiAgentsSaveBrowserConfig),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.aiAgentsFeishuPairing,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: feishuPairingCodeController,
            decoration: InputDecoration(
              labelText: l10n.aiAgentsPairingCode,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              FilledButton(
                onPressed: onApproveFeishuPairing,
                child: Text(l10n.aiAgentsApprovePairing),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

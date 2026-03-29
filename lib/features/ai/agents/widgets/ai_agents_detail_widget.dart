import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/ai/agents/agents_provider.dart';
import 'package:provider/provider.dart';

class AIAgentsDetailWidget extends StatefulWidget {
  const AIAgentsDetailWidget({super.key});

  @override
  State<AIAgentsDetailWidget> createState() => _AIAgentsDetailWidgetState();
}

class _AIAgentsDetailWidgetState extends State<AIAgentsDetailWidget> {
  final TextEditingController _allowedOriginsController =
      TextEditingController();
  final TextEditingController _timezoneController = TextEditingController();
  final TextEditingController _npmRegistryController = TextEditingController();
  final TextEditingController _configController = TextEditingController();
  final TextEditingController _skillSearchController = TextEditingController();

  String _skillSource = 'clawhub';
  bool _browserEnabled = false;
  int _boundAgentId = -1;

  @override
  void dispose() {
    _allowedOriginsController.dispose();
    _timezoneController.dispose();
    _npmRegistryController.dispose();
    _configController.dispose();
    _skillSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<AgentsProvider>(
      builder: (context, provider, _) {
        final selected = provider.selectedAgent;
        if (selected == null || selected.id == null) {
          return Center(child: Text(l10n.aiAgentsNoSelection));
        }

        _syncControllersIfNeeded(provider, selected.id!);

        final snapshot = provider.overview.snapshot;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(selected.name ?? '-', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('${selected.agentType ?? '-'} · ${selected.status ?? '-'}'),
                const SizedBox(height: 12),
                _Section(
                  title: l10n.aiAgentsOverview,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: <Widget>[
                      _InfoChip('Container', snapshot?.containerStatus ?? '-'),
                      _InfoChip('Version', snapshot?.appVersion ?? '-'),
                      _InfoChip('Model', snapshot?.defaultModel ?? '-'),
                      _InfoChip('Channels', '${snapshot?.channelCount ?? 0}'),
                      _InfoChip('Skills', '${snapshot?.skillCount ?? 0}'),
                      _InfoChip('Sessions', '${snapshot?.sessionCount ?? 0}'),
                    ],
                  ),
                ),
                _Section(
                  title: l10n.aiAgentsChannels,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provider.channels.entries
                        .map(
                          (entry) => Chip(
                            label: Text(
                              '${entry.key}: ${entry.value.enabled ? l10n.aiAgentsEnabled : l10n.aiAgentsDisabled}'
                              '${entry.value.installed ? '' : ' (${l10n.aiAgentsNotInstalled})'}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                _Section(
                  title: l10n.aiAgentsSkills,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          SizedBox(
                            width: 120,
                            child: DropdownButtonFormField<String>(
                              value: _skillSource,
                              items: const <DropdownMenuItem<String>>[
                                DropdownMenuItem(value: 'clawhub', child: Text('clawhub')),
                                DropdownMenuItem(value: 'skillhub', child: Text('skillhub')),
                              ],
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _skillSource = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _skillSearchController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: l10n.aiAgentsSkillSearchHint,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => provider.searchSkills(
                              source: _skillSource,
                              keyword: _skillSearchController.text,
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
                ),
                _Section(
                  title: l10n.aiAgentsSettings,
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: _allowedOriginsController,
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
                              controller: _timezoneController,
                              decoration: InputDecoration(
                                labelText: l10n.aiAgentsTimezone,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _npmRegistryController,
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
                        value: _browserEnabled,
                        onChanged: (value) {
                          setState(() {
                            _browserEnabled = value;
                          });
                        },
                      ),
                      Row(
                        children: <Widget>[
                          FilledButton(
                            onPressed: () => _saveSettings(context, provider),
                            child: Text(l10n.commonSave),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _configController,
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
                            onPressed: () => provider.saveConfigFile(_configController.text),
                            child: Text(l10n.aiAgentsSaveConfig),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _syncControllersIfNeeded(AgentsProvider provider, int agentId) {
    if (_boundAgentId == agentId) {
      return;
    }
    _boundAgentId = agentId;
    _allowedOriginsController.text = provider.securityConfig.allowedOrigins.join('\n');
    _timezoneController.text = provider.otherConfig.userTimezone;
    _browserEnabled = provider.otherConfig.browserEnabled;
    _npmRegistryController.text = provider.otherConfig.npmRegistry;
    _configController.text = provider.configFile.content;
  }

  Future<void> _saveSettings(BuildContext context, AgentsProvider provider) async {
    final origins = _allowedOriginsController.text
        .split(RegExp(r'[,\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    await provider.saveSecurityOrigins(origins);
    await provider.saveOtherConfig(
      timezone: _timezoneController.text.trim(),
      browserEnabled: _browserEnabled,
      npmRegistry: _npmRegistryController.text.trim(),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.commonSaveSuccess)),
      );
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

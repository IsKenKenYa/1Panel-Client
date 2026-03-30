import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/ai/agents/agents_provider.dart';
import 'package:provider/provider.dart';

import 'ai_agents_detail_sections_widget.dart';
import 'ai_agents_detail_top_sections_widget.dart';

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
                AIAgentOverviewSection(snapshot: snapshot),
                AIAgentChannelsSection(channels: provider.channels),
                AIAgentSkillsSection(
                  provider: provider,
                  searchController: _skillSearchController,
                  skillSource: _skillSource,
                  onSkillSourceChanged: (value) {
                    setState(() {
                      _skillSource = value;
                    });
                  },
                ),
                AIAgentSettingsSection(
                  provider: provider,
                  allowedOriginsController: _allowedOriginsController,
                  timezoneController: _timezoneController,
                  npmRegistryController: _npmRegistryController,
                  configController: _configController,
                  browserEnabled: _browserEnabled,
                  onBrowserEnabledChanged: (value) {
                    setState(() {
                      _browserEnabled = value;
                    });
                  },
                  onSaveSettings: () => _saveSettings(context, provider),
                  onSaveConfig: () => provider.saveConfigFile(_configController.text),
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

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ai/agent_models.dart';
import 'package:onepanel_client/features/ai/agents/agents_provider.dart';

import 'ai_agent_shared_widgets.dart';

class AIAgentOverviewSection extends StatelessWidget {
  const AIAgentOverviewSection({
    super.key,
    required this.snapshot,
  });

  final AgentOverviewSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    return AISection(
      title: context.l10n.aiAgentsOverview,
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: <Widget>[
          AIInfoChip('Container', snapshot?.containerStatus ?? '-'),
          AIInfoChip('Version', snapshot?.appVersion ?? '-'),
          AIInfoChip('Model', snapshot?.defaultModel ?? '-'),
          AIInfoChip('Channels', '${snapshot?.channelCount ?? 0}'),
          AIInfoChip('Skills', '${snapshot?.skillCount ?? 0}'),
          AIInfoChip('Sessions', '${snapshot?.sessionCount ?? 0}'),
        ],
      ),
    );
  }
}

class AIAgentChannelsSection extends StatelessWidget {
  const AIAgentChannelsSection({
    super.key,
    required this.channels,
  });

  final Map<String, AgentChannelSnapshot> channels;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AISection(
      title: l10n.aiAgentsChannels,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: channels.entries
            .map(
              (entry) => Chip(
                label: Text(
                  '${entry.key}: '
                  '${entry.value.enabled ? l10n.aiAgentsEnabled : l10n.aiAgentsDisabled}'
                  '${entry.value.installed ? '' : ' (${l10n.aiAgentsNotInstalled})'}',
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/data/models/docker_models.dart';
import 'package:onepanel_client/features/orchestration/widgets/compose_card_actions.dart';
import 'package:onepanel_client/features/orchestration/widgets/compose_card_dialogs.dart';
import 'package:onepanel_client/features/orchestration/providers/compose_provider.dart';
import 'package:provider/provider.dart';

class ComposeCard extends StatelessWidget {
  const ComposeCard({super.key, required this.compose});

  final ComposeProject compose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final provider = context.read<ComposeProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    compose.name,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.commonMore,
                  onPressed: () => ComposeCardDialogs.showDetailsSheet(
                    context,
                    compose: compose,
                  ),
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(
                    Icons.circle,
                    size: 10,
                    color: ComposeCardActions.statusColor(
                      compose.status,
                      theme.colorScheme,
                    ),
                  ),
                  label:
                      Text(compose.status ?? l10n.orchestrationStatusUnknown),
                  visualDensity: VisualDensity.compact,
                ),
                if (compose.createTime != null)
                  Chip(
                    label: Text(compose.createTime!),
                    visualDensity: VisualDensity.compact,
                  ),
                ...((compose.services ?? const <String>[])
                    .take(2)
                    .map((service) => Chip(
                          label: Text(service),
                          visualDensity: VisualDensity.compact,
                        ))),
              ],
            ),
            const SizedBox(height: 8),
            if ((compose.path ?? '').isNotEmpty)
              Text(
                '${l10n.commonPath}: ${compose.path}',
                style: theme.textTheme.bodySmall,
              ),
            const Divider(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () => ComposeCardActions.runAction(
                            context,
                            provider,
                            () => provider.upCompose(compose),
                          ),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(l10n.commonStart),
                ),
                TextButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () => ComposeCardActions.confirmAndRun(
                            context,
                            provider,
                            () => provider.downCompose(compose),
                          ),
                  icon: const Icon(Icons.stop, size: 18),
                  label: Text(l10n.commonStop),
                ),
                TextButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () => ComposeCardActions.runAction(
                            context,
                            provider,
                            () => provider.restartCompose(compose),
                          ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.commonRestart),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.commonMore,
                  onSelected: (value) {
                    if (value == 'update') {
                      ComposeCardDialogs.showComposeFormDialog(
                        context,
                        provider,
                        compose: compose,
                        title: l10n.orchestrationComposeUpdate,
                        onSubmit: (name, path, content, env) {
                          return provider.updateCompose(
                            ContainerComposeUpdateRequest(
                              name: name,
                              path: path,
                              content: content,
                              env: env,
                            ),
                          );
                        },
                      );
                    }
                    if (value == 'test') {
                      ComposeCardDialogs.showComposeFormDialog(
                        context,
                        provider,
                        compose: compose,
                        title: l10n.orchestrationComposeTest,
                        onSubmit: (name, path, content, env) {
                          return provider.testCompose(
                            ContainerComposeCreate(
                              from: 'edit',
                              name: name,
                              path: path,
                              file: content,
                              env: env,
                            ),
                          );
                        },
                      );
                    }
                    if (value == 'cleanLog') {
                      ComposeCardDialogs.showCleanLogDialog(
                        context,
                        provider,
                        compose: compose,
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'update',
                      child: Text(l10n.orchestrationComposeUpdate),
                    ),
                    PopupMenuItem(
                      value: 'test',
                      child: Text(l10n.orchestrationComposeTest),
                    ),
                    PopupMenuItem(
                      value: 'cleanLog',
                      child: Text(l10n.orchestrationComposeCleanLog),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

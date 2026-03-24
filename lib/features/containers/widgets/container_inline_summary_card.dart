import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/containers/containers_provider.dart';

class ContainerInlineSummaryCard extends StatelessWidget {
  const ContainerInlineSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<ContainersProvider>(
      builder: (context, provider, _) {
        final stats = provider.data.containerStats;
        final status = provider.data.status;
        final scheme = Theme.of(context).colorScheme;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.containerStatsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryMetric(
                        icon: Icons.layers_outlined,
                        label: l10n.containerStatsTotal,
                        value: stats.total.toString(),
                        color: scheme.primary,
                      ),
                    ),
                    Expanded(
                      child: _SummaryMetric(
                        icon: Icons.play_circle_outline,
                        label: l10n.containerStatsRunning,
                        value: stats.running.toString(),
                        color: scheme.tertiary,
                      ),
                    ),
                    Expanded(
                      child: _SummaryMetric(
                        icon: Icons.stop_circle_outlined,
                        label: l10n.containerStatsStopped,
                        value: stats.stopped.toString(),
                        color: scheme.secondary,
                      ),
                    ),
                  ],
                ),
                if (status != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SummaryStatusChip(
                        label:
                            '${l10n.containerStatsImages}: ${status.imageCount}',
                      ),
                      _SummaryStatusChip(
                        label:
                            '${l10n.containerStatsNetworks}: ${status.networkCount}',
                      ),
                      _SummaryStatusChip(
                        label:
                            '${l10n.containerStatsVolumes}: ${status.volumeCount}',
                      ),
                      _SummaryStatusChip(
                        label:
                            '${l10n.containerStatsRepos}: ${status.repoCount}',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SummaryStatusChip extends StatelessWidget {
  const _SummaryStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}

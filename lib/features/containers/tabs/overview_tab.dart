import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/data/models/container_models.dart' hide ContainerStats;
import '../containers_provider.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ContainersProvider>(
      builder: (context, provider, _) {
        final stats = provider.data.containerStats;
        final status = provider.data.status;

        if (provider.overviewState.isLoading && status == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.overviewState.error != null && status == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(provider.overviewState.error!),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: provider.loadStatus,
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCard(context, l10n, stats, colorScheme),
                const SizedBox(height: 16),
                if (status != null) _buildDetailStatsCard(context, l10n, status, colorScheme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    dynamic l10n,
    ContainerStats stats,
    ColorScheme colorScheme,
  ) {
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  l10n.containerStatsTotal,
                  stats.total.toString(),
                  colorScheme.primary,
                  Icons.inventory_2,
                ),
                _buildStatItem(
                  context,
                  l10n.containerStatsRunning,
                  stats.running.toString(),
                  colorScheme.tertiary,
                  Icons.play_circle,
                ),
                _buildStatItem(
                  context,
                  l10n.containerStatsStopped,
                  stats.stopped.toString(),
                  colorScheme.secondary,
                  Icons.stop_circle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStatsCard(
    BuildContext context,
    dynamic l10n,
    ContainerStatus status,
    ColorScheme colorScheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.containerStatsDetailTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildChip(context, l10n.containerStatsImages, status.imageCount.toString(), Icons.image),
                _buildChip(context, l10n.containerStatsNetworks, status.networkCount.toString(), Icons.hub),
                _buildChip(context, l10n.containerStatsVolumes, status.volumeCount.toString(), Icons.storage),
                _buildChip(context, l10n.containerStatsRepos, status.repoCount.toString(), Icons.store),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildChip(BuildContext context, String label, String value, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$label: $value'),
    );
  }
}

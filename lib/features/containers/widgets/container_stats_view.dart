import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/containers/providers/container_detail_provider.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

class ContainerStatsView extends StatelessWidget {
  const ContainerStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final cpuColor = colorScheme.primary;
    final memoryColor = colorScheme.tertiary;
    final networkColor = colorScheme.secondary;
    final blockColor = colorScheme.error;
    final provider = context.watch<ContainerDetailProvider>();

    if (provider.statsLoading && provider.stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.statsError != null && provider.stats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.containerOperateFailed(provider.statsError!),
              style: TextStyle(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: provider.loadStats,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (provider.stats == null) {
      return Center(child: Text(l10n.commonEmpty));
    }

    final stats = provider.stats!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: l10n.containerStatsCpu,
                  value: '${stats.cpuPercent.toStringAsFixed(2)}%',
                  progress: stats.cpuPercent / 100,
                  color: cpuColor,
                  icon: Icons.memory,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: l10n.containerStatsMemory,
                  value: _formatBytes(stats.memory),
                  subtitle:
                      '${l10n.monitorMetricCurrent}: ${_formatBytes(stats.memory)}',
                  color: memoryColor,
                  icon: Icons.sd_storage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: l10n.containerStatsNetwork,
                  value: 'RX: ${_formatBytes(stats.networkRX)}',
                  subtitle: 'TX: ${_formatBytes(stats.networkTX)}',
                  color: networkColor,
                  icon: Icons.network_check,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: l10n.containerStatsBlock,
                  value: 'Read: ${_formatBytes(stats.ioRead)}',
                  subtitle: 'Write: ${_formatBytes(stats.ioWrite)}',
                  color: blockColor,
                  icon: Icons.storage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: provider.loadStats,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.commonRefresh),
          ),
        ],
      ),
    );
  }

  String _formatBytes(num bytes) {
    if (bytes < 1024) {
      return '${bytes.toInt()} B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final double? progress;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.progress,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress!.clamp(0.0, 1.0),
              color: color,
              backgroundColor: color.withValues(alpha: 0.2),
            ),
          ],
        ],
      ),
    );
  }
}

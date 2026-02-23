import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/containers/container_service.dart';
import 'package:onepanelapp_app/data/models/container_models.dart';
import 'package:onepanelapp_app/shared/widgets/app_card.dart';

class ContainerStatsView extends StatefulWidget {
  final String containerId;

  const ContainerStatsView({
    super.key,
    required this.containerId,
  });

  @override
  State<ContainerStatsView> createState() => _ContainerStatsViewState();
}

class _ContainerStatsViewState extends State<ContainerStatsView> {
  final _service = ContainerService();
  ContainerStats? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _service.getContainerStats(widget.containerId);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.containerOperateFailed(_error!),
              style: TextStyle(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (_stats == null) {
      return const Center(child: Text('No data'));
    }

    final stats = _stats!;

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
                  color: Colors.blue,
                  icon: Icons.memory,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: l10n.containerStatsMemory,
                  value: _formatBytes(stats.memory),
                  subtitle: '${l10n.monitorMetricCurrent}: ${_formatBytes(stats.memory)}',
                  color: Colors.green,
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
                  color: Colors.orange,
                  icon: Icons.network_check,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: l10n.containerStatsBlock,
                  value: 'Read: ${_formatBytes(stats.ioRead)}',
                  subtitle: 'Write: ${_formatBytes(stats.ioWrite)}',
                  color: Colors.purple,
                  icon: Icons.storage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.commonRefresh),
          ),
        ],
      ),
    );
  }

  String _formatBytes(num bytes) {
    if (bytes < 1024) return '${bytes.toInt()} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/widgets/database_detail_error_widget.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

import 'databases_provider.dart';
import 'databases_service.dart';

class DatabaseRedisPage extends StatelessWidget {
  const DatabaseRedisPage({
    super.key,
    required this.item,
    this.service,
  });

  final DatabaseListItem item;
  final DatabasesService? service;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          DatabaseDetailProvider(item: item, service: service)..load(),
      child: const _DatabaseRedisPageView(),
    );
  }
}

class _DatabaseRedisPageView extends StatefulWidget {
  const _DatabaseRedisPageView();

  @override
  State<_DatabaseRedisPageView> createState() => _DatabaseRedisPageViewState();
}

class _DatabaseRedisPageViewState extends State<_DatabaseRedisPageView> {
  final _timeoutController = TextEditingController();
  final _maxClientsController = TextEditingController();
  final _appendOnlyController = TextEditingController();
  final _saveController = TextEditingController();

  @override
  void dispose() {
    _timeoutController.dispose();
    _maxClientsController.dispose();
    _appendOnlyController.dispose();
    _saveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DatabaseDetailProvider>();
    final detail = provider.detail;
    final item = provider.item;

    if (provider.isLoading && detail == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null && detail == null) {
      return Scaffold(
        appBar: AppBar(title: Text(item.name)),
        body: DatabaseDetailErrorWidget(
          error: provider.error!,
          onRetry: provider.load,
        ),
      );
    }

    final config = detail?.redisConfig ?? const <String, dynamic>{};
    final persistence = detail?.redisPersistence ?? const <String, dynamic>{};
    _timeoutController.text = config['timeout']?.toString() ?? '';
    _maxClientsController.text = config['maxclients']?.toString() ?? '';
    _appendOnlyController.text = persistence['appendonly']?.toString() ?? '';
    _saveController.text = persistence['save']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1080;
            final children = [
              _RedisOverviewCard(item: item, detail: detail),
              const SizedBox(height: AppDesignTokens.spacingMd),
              _RedisStatusCard(status: detail?.status),
              const SizedBox(height: AppDesignTokens.spacingMd),
              _RedisConfigCard(
                timeoutController: _timeoutController,
                maxClientsController: _maxClientsController,
                isSubmitting: provider.isSubmitting,
                onSubmit: () => _submitRedisConfig(provider, item),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              _RedisPersistenceCard(
                appendOnlyController: _appendOnlyController,
                saveController: _saveController,
                isSubmitting: provider.isSubmitting,
                onSubmit: () => _submitRedisPersistence(provider, item),
              ),
            ];

            if (!isWide) {
              return ListView(
                padding: AppDesignTokens.pagePadding,
                children: children,
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppDesignTokens.pagePadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 11,
                    child: Column(
                      children: [
                        children[0],
                        children[1],
                        children[2],
                        children[3],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDesignTokens.spacingMd),
                  Expanded(
                    flex: 9,
                    child: Column(
                      children: [
                        children[4],
                        children[5],
                        children[6],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitRedisConfig(
    DatabaseDetailProvider provider,
    DatabaseListItem item,
  ) async {
    final ok = await provider.updateRedisConfig({
      'dbType': item.engine,
      'timeout': _timeoutController.text.trim(),
      'maxclients': _maxClientsController.text.trim(),
    });
    if (!mounted) {
      return;
    }
    _showSaveResult(ok);
  }

  Future<void> _submitRedisPersistence(
    DatabaseDetailProvider provider,
    DatabaseListItem item,
  ) async {
    final ok = await provider.updateRedisPersistence({
      'type': item.engine,
      'dbType': item.engine,
      'appendonly': _appendOnlyController.text.trim(),
      'save': _saveController.text.trim(),
    });
    if (!mounted) {
      return;
    }
    _showSaveResult(ok);
  }

  void _showSaveResult(bool success) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? l10n.commonSaveSuccess : l10n.commonSaveFailed),
      ),
    );
  }
}

class _RedisOverviewCard extends StatelessWidget {
  const _RedisOverviewCard({
    required this.item,
    required this.detail,
  });

  final DatabaseListItem item;
  final DatabaseDetailData? detail;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Redis',
      child: Wrap(
        spacing: AppDesignTokens.spacingSm,
        runSpacing: AppDesignTokens.spacingSm,
        children: [
          _RedisMetricTile(
            label: context.l10n.commonName,
            value: item.name,
            icon: Icons.inventory_2_outlined,
          ),
          _RedisMetricTile(
            label: context.l10n.databaseEngineLabel,
            value: item.engine,
            icon: Icons.memory_outlined,
          ),
          _RedisMetricTile(
            label: 'Target',
            value: item.lookupName,
            icon: Icons.hub_outlined,
          ),
          _RedisMetricTile(
            label: context.l10n.databaseAddressLabel,
            value: item.address == null
                ? '-'
                : item.port == null
                    ? item.address!
                    : '${item.address}:${item.port}',
            icon: Icons.settings_ethernet_outlined,
          ),
          _RedisMetricTile(
            label: context.l10n.databaseContainerLabel,
            value: detail?.baseInfo?.containerName ?? '-',
            icon: Icons.widgets_outlined,
          ),
        ],
      ),
    );
  }
}

class _RedisStatusCard extends StatelessWidget {
  const _RedisStatusCard({required this.status});

  final Map<String, dynamic>? status;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: context.l10n.databaseStatusTitle,
      child: status == null || status!.isEmpty
          ? const Text('-')
          : Wrap(
              spacing: AppDesignTokens.spacingSm,
              runSpacing: AppDesignTokens.spacingSm,
              children: [
                _RedisMetricTile(
                  label: 'Port',
                  value: '${status!['tcp_port'] ?? '-'}',
                  icon: Icons.settings_ethernet_outlined,
                ),
                _RedisMetricTile(
                  label: 'Uptime',
                  value: '${status!['uptime_in_days'] ?? '-'} d',
                  icon: Icons.schedule_outlined,
                ),
                _RedisMetricTile(
                  label: 'Clients',
                  value: '${status!['connected_clients'] ?? '-'}',
                  icon: Icons.people_outline,
                ),
                _RedisMetricTile(
                  label: 'Ops/sec',
                  value: '${status!['instantaneous_ops_per_sec'] ?? '-'}',
                  icon: Icons.speed_outlined,
                ),
                _RedisMetricTile(
                  label: 'Used Memory',
                  value: _formatBytes(status!['used_memory']),
                  icon: Icons.memory_outlined,
                ),
                _RedisMetricTile(
                  label: 'Peak Memory',
                  value: _formatBytes(status!['used_memory_peak']),
                  icon: Icons.stacked_line_chart_outlined,
                ),
                _RedisMetricTile(
                  label: 'RSS',
                  value: _formatBytes(status!['used_memory_rss']),
                  icon: Icons.storage_outlined,
                ),
                _RedisMetricTile(
                  label: 'Fragmentation',
                  value: '${status!['mem_fragmentation_ratio'] ?? '-'}',
                  icon: Icons.pie_chart_outline,
                ),
                _RedisMetricTile(
                  label: 'Connections',
                  value: '${status!['total_connections_received'] ?? '-'}',
                  icon: Icons.compare_arrows_outlined,
                ),
                _RedisMetricTile(
                  label: 'Commands',
                  value: '${status!['total_commands_processed'] ?? '-'}',
                  icon: Icons.terminal_outlined,
                ),
              ],
            ),
    );
  }

  String _formatBytes(dynamic raw) {
    if (raw is! num) return '$raw';
    const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    double size = raw.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final digits = size >= 100 ? 0 : 2;
    return '${size.toStringAsFixed(digits)} ${units[unitIndex]}';
  }
}

class _RedisConfigCard extends StatelessWidget {
  const _RedisConfigCard({
    required this.timeoutController,
    required this.maxClientsController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController timeoutController;
  final TextEditingController maxClientsController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: context.l10n.databaseRedisConfigTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: timeoutController,
            decoration: InputDecoration(
              labelText: context.l10n.databaseRedisTimeoutLabel,
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          TextField(
            controller: maxClientsController,
            decoration: InputDecoration(
              labelText: context.l10n.databaseRedisMaxClientsLabel,
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: const Icon(Icons.save_outlined),
              label: Text(context.l10n.commonSave),
            ),
          ),
        ],
      ),
    );
  }
}

class _RedisPersistenceCard extends StatelessWidget {
  const _RedisPersistenceCard({
    required this.appendOnlyController,
    required this.saveController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController appendOnlyController;
  final TextEditingController saveController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: context.l10n.databaseRedisPersistenceTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: appendOnlyController,
            decoration: InputDecoration(
              labelText: context.l10n.databaseRedisAppendOnlyLabel,
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          TextField(
            controller: saveController,
            decoration: InputDecoration(
              labelText: context.l10n.databaseRedisSaveLabel,
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: const Icon(Icons.save_outlined),
              label: Text(context.l10n.commonSave),
            ),
          ),
        ],
      ),
    );
  }
}

class _RedisMetricTile extends StatelessWidget {
  const _RedisMetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
      padding: const EdgeInsets.all(AppDesignTokens.spacingMd),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: scheme.onSecondaryContainer, size: 20),
          ),
          const SizedBox(width: AppDesignTokens.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppDesignTokens.spacingXs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

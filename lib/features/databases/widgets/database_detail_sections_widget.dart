import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

class DatabaseDetailSectionsWidget extends StatelessWidget {
  const DatabaseDetailSectionsWidget({
    super.key,
    required this.item,
    required this.detail,
  });

  final DatabaseListItem item;
  final DatabaseDetailData? detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final detailData = detail;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        AppCard(
          title: l10n.databaseOverviewTitle,
          child: Wrap(
            spacing: AppDesignTokens.spacingSm,
            runSpacing: AppDesignTokens.spacingSm,
            children: [
              _InfoTile(
                label: l10n.commonName,
                value: item.name,
                icon: Icons.inventory_2_outlined,
              ),
              _InfoTile(
                label: l10n.databaseEngineLabel,
                value: item.engine,
                icon: Icons.storage_outlined,
              ),
              _InfoTile(
                label: 'Target',
                value: item.lookupName,
                icon: Icons.hub_outlined,
              ),
              _InfoTile(
                label: l10n.databaseSourceLabel,
                value: item.source,
                icon: Icons.hub_outlined,
              ),
              _InfoTile(
                label: l10n.databaseAddressLabel,
                value: item.address == null
                    ? '-'
                    : item.port == null
                        ? item.address!
                        : '${item.address}:${item.port}',
                icon: Icons.dns_outlined,
              ),
              _InfoTile(
                label: l10n.databaseUsernameLabel,
                value: item.username ?? '-',
                icon: Icons.person_outline,
              ),
            ],
          ),
        ),
        if (detailData?.rawConfigFile?.isNotEmpty == true) ...[
          const SizedBox(height: AppDesignTokens.spacingMd),
          AppCard(
            title: l10n.databaseConfigTitle,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDesignTokens.spacingMd),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
              ),
              child: SelectableText(
                detailData!.rawConfigFile!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.45,
                      fontFamily: 'monospace',
                    ),
              ),
            ),
          ),
        ],
        if (detail?.baseInfo != null) ...[
          const SizedBox(height: AppDesignTokens.spacingMd),
          AppCard(
            title: l10n.databaseBaseInfoTitle,
            child: Wrap(
              spacing: AppDesignTokens.spacingSm,
              runSpacing: AppDesignTokens.spacingSm,
              children: [
                _InfoTile(
                  label: l10n.databaseContainerLabel,
                  value: detail!.baseInfo!.containerName ?? '-',
                  icon: Icons.widgets_outlined,
                ),
                _InfoTile(
                  label: l10n.databasePortLabel,
                  value: detail!.baseInfo!.port?.toString() ?? '-',
                  icon: Icons.settings_ethernet_outlined,
                ),
                _InfoTile(
                  label: l10n.databaseRemoteAccessLabel,
                  value: detail!.baseInfo!.remoteConn == true
                      ? l10n.commonYes
                      : l10n.commonNo,
                  icon: Icons.shield_outlined,
                ),
              ],
            ),
          ),
        ],
        if (item.scope == DatabaseScope.redis &&
            detailData?.status != null) ...[
          const SizedBox(height: AppDesignTokens.spacingMd),
          AppCard(
            title: l10n.databaseStatusTitle,
            child: _RedisStatusGrid(data: detailData!.status!),
          ),
        ],
        if (detailData?.redisConfig != null) ...[
          const SizedBox(height: AppDesignTokens.spacingMd),
          AppCard(
            title: '${l10n.databaseConfigTitle} · Redis',
            child: _MapValueList(
              data: detailData!.redisConfig!,
              dense: false,
            ),
          ),
        ],
        if (detailData?.redisPersistence != null) ...[
          const SizedBox(height: AppDesignTokens.spacingMd),
          AppCard(
            title: '${l10n.databaseStatusTitle} · Redis Persistence',
            child: _MapValueList(
              data: detailData!.redisPersistence!,
              dense: false,
            ),
          ),
        ],
        if (item.scope != DatabaseScope.redis && detail?.status != null) ...[
          const SizedBox(height: AppDesignTokens.spacingMd),
          AppCard(
            title: l10n.databaseStatusTitle,
            child: _MapValueList(data: detail!.status!),
          ),
        ],
        if (detail?.variables != null) ...[
          const SizedBox(height: AppDesignTokens.spacingMd),
          AppCard(
            title: l10n.databaseVariablesTitle,
            child: _MapValueList(data: detail!.variables!),
          ),
        ],
      ],
    );
  }
}

class _MapValueList extends StatelessWidget {
  const _MapValueList({
    required this.data,
    this.dense = true,
  });

  final Map<String, dynamic> data;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries
        .where((entry) => '${entry.value}'.trim().isNotEmpty)
        .toList(growable: false);
    if (entries.isEmpty) {
      return const Text('-');
    }

    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppDesignTokens.spacingSm,
      runSpacing: AppDesignTokens.spacingSm,
      children: [
        for (final entry in entries)
          Container(
            constraints: BoxConstraints(
              minWidth: dense ? 180 : 220,
              maxWidth: dense ? 320 : 420,
            ),
            padding: EdgeInsets.all(
              dense ? AppDesignTokens.spacingSm : AppDesignTokens.spacingMd,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _prettifyKey(entry.key),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppDesignTokens.spacingXs),
                Text(
                  _formatValue(entry.key, entry.value),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _prettifyKey(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
  }

  String _formatValue(String key, dynamic value) {
    if (value == null) return '-';
    if (value is num) {
      final lowerKey = key.toLowerCase();
      if (lowerKey.contains('memory') || lowerKey.endsWith('rss')) {
        return _formatBytes(value);
      }
      if (lowerKey.contains('ratio')) {
        return value.toStringAsFixed(2);
      }
    }
    return '$value';
  }

  String _formatBytes(num value) {
    const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    double size = value.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final digits = size >= 100 ? 0 : 2;
    return '${size.toStringAsFixed(digits)} ${units[unitIndex]}';
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
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
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
      padding: const EdgeInsets.all(AppDesignTokens.spacingMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
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

class _RedisStatusGrid extends StatelessWidget {
  const _RedisStatusGrid({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final metrics = <({String label, String value, IconData icon})>[
      (
        label: 'Port',
        value: '${data['tcp_port'] ?? '-'}',
        icon: Icons.settings_ethernet_outlined,
      ),
      (
        label: 'Uptime',
        value: '${data['uptime_in_days'] ?? '-'} d',
        icon: Icons.schedule_outlined,
      ),
      (
        label: 'Clients',
        value: '${data['connected_clients'] ?? '-'}',
        icon: Icons.people_outline,
      ),
      (
        label: 'Ops/sec',
        value: '${data['instantaneous_ops_per_sec'] ?? '-'}',
        icon: Icons.speed_outlined,
      ),
      (
        label: 'Used Memory',
        value: _formatBytes(data['used_memory']),
        icon: Icons.memory_outlined,
      ),
      (
        label: 'Peak Memory',
        value: _formatBytes(data['used_memory_peak']),
        icon: Icons.stacked_line_chart_outlined,
      ),
      (
        label: 'RSS',
        value: _formatBytes(data['used_memory_rss']),
        icon: Icons.storage_outlined,
      ),
      (
        label: 'Fragmentation',
        value: '${data['mem_fragmentation_ratio'] ?? '-'}',
        icon: Icons.pie_chart_outline,
      ),
    ];

    return Wrap(
      spacing: AppDesignTokens.spacingSm,
      runSpacing: AppDesignTokens.spacingSm,
      children: [
        for (final metric in metrics)
          _InfoTile(
            label: metric.label,
            value: metric.value,
            icon: metric.icon,
          ),
      ],
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

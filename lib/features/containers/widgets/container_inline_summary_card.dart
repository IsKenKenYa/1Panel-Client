import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/containers/containers_provider.dart';

/// 容器模块顶部摘要条
/// 左侧：容器统计（总数/运行中/已停止）
/// 右侧：Compose 统计（总数/运行中）
/// 底部（可选）：CPU + 内存聚合指标
class ContainerInlineSummaryCard extends StatelessWidget {
  const ContainerInlineSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<ContainersProvider>(
      builder: (context, provider, _) {
        final stats = provider.data.containerStats;
        final scheme = Theme.of(context).colorScheme;

        final hasCpuMem = stats.totalCpuPercent > 0 ||
            stats.totalMemoryPercent > 0 ||
            stats.totalMemoryUsageBytes > 0;

        return Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- 上方：容器 | Compose 双栏 ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // 容器列
                    Expanded(
                      child: _SectionGroup(
                        icon: Icons.view_in_ar,
                        title: l10n.containerPruneTypeContainer,
                        iconColor: scheme.primary,
                        items: [
                          _StatBadge(
                            value: stats.total.toString(),
                            label: l10n.containerStatsTotal,
                            color: scheme.onSurfaceVariant,
                          ),
                          _StatBadge(
                            value: stats.running.toString(),
                            label: l10n.containerStatsRunning,
                            color: scheme.tertiary,
                            dot: true,
                          ),
                          _StatBadge(
                            value: stats.stopped.toString(),
                            label: l10n.containerStatsStopped,
                            color: scheme.onSurfaceVariant
                                .withValues(alpha: 0.45),
                            dot: true,
                          ),
                        ],
                      ),
                    ),

                    // 竖分隔线
                    Container(
                      width: 1,
                      height: 36,
                      color: scheme.outlineVariant,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),

                    // Compose 列
                    Expanded(
                      child: _SectionGroup(
                        icon: Icons.layers_outlined,
                        title: 'Compose',
                        iconColor: scheme.secondary,
                        items: [
                          _StatBadge(
                            value: stats.composeTotal.toString(),
                            label: l10n.containerStatsTotal,
                            color: scheme.onSurfaceVariant,
                          ),
                          _StatBadge(
                            value: stats.composeRunning.toString(),
                            label: l10n.containerStatsRunning,
                            color: scheme.tertiary,
                            dot: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- 下方：CPU + 内存（仅在有数据时显示）---
              if (hasCpuMem) ...[
                Divider(
                  height: 1,
                  thickness: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      _MetricBar(
                        icon: Icons.memory,
                        label: 'CPU',
                        value:
                            '${stats.totalCpuPercent.toStringAsFixed(1)}%',
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 16),
                      _MetricBar(
                        icon: Icons.storage,
                        label: l10n.containerStatsMemory,
                        value: _formatBytes(stats.totalMemoryUsageBytes),
                        color: scheme.tertiary,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

// ---------------------------------------------------------------------------
// 一组统计项（带标题图标）
// ---------------------------------------------------------------------------
class _SectionGroup extends StatelessWidget {
  const _SectionGroup({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.items,
  });

  final IconData icon;
  final String title;
  final Color iconColor;
  final List<_StatBadge> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题行
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              title,
              style: textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 数值行
        Wrap(
          spacing: 10,
          runSpacing: 2,
          children: items,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 单项统计数值
// ---------------------------------------------------------------------------
class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.value,
    required this.label,
    required this.color,
    this.dot = false,
  });

  final String value;
  final String label;
  final Color color;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 3),
        ],
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CPU / 内存指标行
// ---------------------------------------------------------------------------
class _MetricBar extends StatelessWidget {
  const _MetricBar({
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
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          '$label ',
          style: textTheme.labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/containers/containers_provider.dart';

/// 容器模块顶部摘要卡片（参考图一上半布局）
/// 左栏：容器统计  右栏：Compose 统计
/// 底部（有数据时）：CPU + 内存聚合指标
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
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 上半：容器 | Compose 双栏 ──
              IntrinsicHeight(
                child: Row(
                  children: [
                    // 容器栏
                    Expanded(
                      child: _StatSection(
                        icon: Icons.view_in_ar,
                        iconColor: scheme.primary,
                        iconBg: scheme.primaryContainer,
                        title: l10n.containerPruneTypeContainer,
                        items: [
                          _StatItem(
                            count: stats.total,
                            label: l10n.containerStatsTotal,
                            color: scheme.onSurface,
                          ),
                          _StatItem(
                            count: stats.running,
                            label: l10n.containerStatsRunning,
                            color: scheme.tertiary,
                            dot: true,
                          ),
                          _StatItem(
                            count: stats.stopped,
                            label: l10n.containerStatsStopped,
                            color: scheme.onSurfaceVariant,
                            dot: true,
                          ),
                        ],
                      ),
                    ),

                    // 竖分隔线
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                      indent: 12,
                      endIndent: 12,
                    ),

                    // Compose 栏
                    Expanded(
                      child: _StatSection(
                        icon: Icons.layers_outlined,
                        iconColor: scheme.secondary,
                        iconBg: scheme.secondaryContainer,
                        title: 'Compose',
                        items: [
                          _StatItem(
                            count: stats.composeTotal,
                            label: l10n.containerStatsTotal,
                            color: scheme.onSurface,
                          ),
                          _StatItem(
                            count: stats.composeRunning,
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

              // ── 下半：CPU + 内存（有数据时）──
              if (hasCpuMem) ...[
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 12,
                  endIndent: 12,
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.memory_outlined,
                          size: 13, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'CPU ',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        '${stats.totalCpuPercent.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.storage_outlined,
                          size: 13, color: scheme.tertiary),
                      const SizedBox(width: 4),
                      Text(
                        '${l10n.containerStatsMemory} ',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        _formatBytes(stats.totalMemoryUsageBytes),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
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

// ────────────────────────────────────────────────────────────────────────────
// 一个统计分区（带图标标题 + 数值列表）
// ────────────────────────────────────────────────────────────────────────────
class _StatSection extends StatelessWidget {
  const _StatSection({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题行
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 13, color: iconColor),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 数值列
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: items,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 单个统计数值
// ────────────────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.count,
    required this.label,
    required this.color,
    this.dot = false,
  });

  final int count;
  final String label;
  final Color color;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

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
          count.toString(),
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

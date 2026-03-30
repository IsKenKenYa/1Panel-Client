import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/containers/providers/container_detail_provider.dart';
import 'package:provider/provider.dart';

class ContainerStatsView extends StatelessWidget {
  const ContainerStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final provider = context.watch<ContainerDetailProvider>();

    if (provider.statsLoading && provider.stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.statsError != null && provider.stats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: scheme.error.withValues(alpha: 0.6)),
              const SizedBox(height: 12),
              Text(
                l10n.containerOperateFailed(provider.statsError!),
                style: TextStyle(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: provider.loadStats,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.stats == null) {
      return Center(child: Text(l10n.commonEmpty));
    }

    final stats = provider.stats!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 2x2 网格 ──
          _StatsGrid(
            children: [
              // CPU
              _MetricCard(
                icon: Icons.developer_board_outlined,
                iconColor: scheme.primary,
                iconBg: scheme.primaryContainer,
                title: l10n.containerStatsCpu,
                mainValue: '${stats.cpuPercent.toStringAsFixed(2)}%',
                progress: (stats.cpuPercent / 100).clamp(0.0, 1.0),
                progressColor: scheme.primary,
              ),
              // 内存
              _MetricCard(
                icon: Icons.memory_outlined,
                iconColor: scheme.tertiary,
                iconBg: scheme.tertiaryContainer,
                title: l10n.containerStatsMemory,
                mainValue: _fmt(stats.memory),
                subtitle: '${l10n.monitorMetricCurrent}: ${_fmt(stats.memory)}',
                progressColor: scheme.tertiary,
              ),
              // 网络 I/O
              _MetricCard(
                icon: Icons.swap_vert_outlined,
                iconColor: scheme.secondary,
                iconBg: scheme.secondaryContainer,
                title: l10n.containerStatsNetwork,
                mainValue: 'RX: ${_fmt(stats.networkRX)}',
                subtitle: 'TX: ${_fmt(stats.networkTX)}',
                progressColor: scheme.secondary,
              ),
              // 磁盘 I/O
              _MetricCard(
                icon: Icons.storage_outlined,
                iconColor: scheme.error,
                iconBg: scheme.errorContainer,
                title: l10n.containerStatsBlock,
                mainValue: 'Read: ${_fmt(stats.ioRead)}',
                subtitle: 'Write: ${_fmt(stats.ioWrite)}',
                progressColor: scheme.error,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── 刷新按钮 ──
          FilledButton.icon(
            onPressed: provider.loadStats,
            icon: provider.statsLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            label: Text(l10n.commonRefresh),
          ),
        ],
      ),
    );
  }

  static String _fmt(num bytes) {
    if (bytes < 1024) return '${bytes.toInt()} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 2x2 网格容器
// ────────────────────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // 使用两列布局，避免溢出
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: 12),
              if (i + 1 < children.length)
                Expanded(child: children[i + 1])
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
      if (i + 2 < children.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 单个指标卡片（参考图三风格）
// ────────────────────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.mainValue,
    this.subtitle,
    this.progress,
    required this.progressColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String mainValue;
  final String? subtitle;
  final double? progress;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题行
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 主数值（自适应字体大小，避免溢出）
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              mainValue,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),

          // 副数值
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // 进度条（CPU 使用）
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                color: progressColor,
                backgroundColor: progressColor.withValues(alpha: 0.15),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

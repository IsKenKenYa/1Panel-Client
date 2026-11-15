import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import '../dashboard_provider.dart';

/// 健康总览 2 列网格（2026 监控面板密度规范）：
/// 单卡 = 状态点 + 名称 + 关键数值 + 线性趋势条；状态色由阈值驱动，
/// 不使用品牌色表达状态。数值缺失时展示 '--' 并用中性色。
class HealthOverviewGrid extends StatelessWidget {
  const HealthOverviewGrid({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDesignTokens.spacingSm,
      crossAxisSpacing: AppDesignTokens.spacingSm,
      // 2.15：容纳 labelSmall + headlineSmall + 趋势条在系统大字体下不溢出。
      childAspectRatio: 2.15,
      children: [
        _HealthCard(
          label: context.l10n.dashboardCpuUsage,
          value: _percent(data.cpuPercent),
          percent: data.cpuPercent,
          icon: Icons.memory_outlined,
        ),
        _HealthCard(
          label: context.l10n.dashboardMemoryUsage,
          value: _percent(data.memoryPercent),
          percent: data.memoryPercent,
          icon: Icons.dns_outlined,
        ),
        _HealthCard(
          label: context.l10n.dashboardDiskUsage,
          value: _percent(data.diskPercent),
          percent: data.diskPercent,
          icon: Icons.save_outlined,
        ),
        _HealthCard(
          label: context.l10n.serverLoadLabel,
          value: data.load != null ? data.load!.toStringAsFixed(2) : '--',
          percent: null,
          icon: Icons.speed_outlined,
        ),
      ],
    );
  }

  String _percent(double? value) =>
      value != null ? '${value.toStringAsFixed(1)}%' : '--';
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({
    required this.label,
    required this.value,
    required this.percent,
    required this.icon,
  });

  final String label;
  final String value;
  final double? percent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(scheme);

    return Container(
      padding: const EdgeInsets.all(AppDesignTokens.spacingMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 状态点：阈值驱动的健康语义，绿色正常/琥珀告警/红故障。
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent != null ? percent! / 100 : 0,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(ColorScheme scheme) {
    if (percent == null) {
      return scheme.onSurfaceVariant.withValues(alpha: 0.4);
    }
    if (percent! >= 90) {
      return scheme.error;
    }
    if (percent! >= 70) {
      return const Color(0xFFF59E0B);
    }
    return scheme.primary;
  }
}

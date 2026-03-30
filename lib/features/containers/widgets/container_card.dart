import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/container_models.dart'
    hide Container;
import 'package:onepanel_client/shared/widgets/app_card.dart';

class ContainerCard extends StatelessWidget {
  final ContainerInfo container;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final VoidCallback? onRestart;
  final VoidCallback? onDelete;
  final VoidCallback? onLogs;
  final VoidCallback? onTerminal;
  final VoidCallback? onTap;
  final VoidCallback? onRename;
  final VoidCallback? onUpgrade;
  final VoidCallback? onCommit;
  final VoidCallback? onEdit;
  final VoidCallback? onCleanLog;

  const ContainerCard({
    super.key,
    required this.container,
    this.onStart,
    this.onStop,
    this.onRestart,
    this.onDelete,
    this.onLogs,
    this.onTerminal,
    this.onTap,
    this.onRename,
    this.onUpgrade,
    this.onCommit,
    this.onEdit,
    this.onCleanLog,
  });

  /// 从 labels 中提取 compose 项目名
  String? _projectName() {
    if (container.labels == null) return null;
    for (final label in container.labels!) {
      if (label.startsWith('com.docker.compose.project=')) {
        final value = label.split('=').skip(1).join('=').trim();
        return value.isEmpty ? null : value;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final containerState = container.state.toLowerCase();
    final isRunning = containerState == 'running';
    final statusColor = _statusColor(colorScheme, containerState);
    final statusLabel = _statusLabel(l10n, containerState);
    final projectName = _projectName();
    final ports = _formatPorts();

    return AppCard(
      onTap: onTap,
      // --- 顶部标题行：容器名 + 状态点 + 更多菜单 ---
      title: container.name,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.view_in_ar,
          color: colorScheme.primary,
          size: 20,
        ),
      ),
      subtitle: projectName != null
          ? Text(
              '${l10n.containerInfoProject}: $projectName',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            )
          : Text(
              container.image,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 小圆点状态指示器
          _StatusDot(color: statusColor, label: statusLabel),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: l10n.commonMore,
            onSelected: (value) {
              if (value == 'rename') onRename?.call();
              if (value == 'upgrade') onUpgrade?.call();
              if (value == 'edit') onEdit?.call();
              if (value == 'commit') onCommit?.call();
              if (value == 'cleanLog') onCleanLog?.call();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rename',
                child: Text(l10n.containerActionRename),
              ),
              PopupMenuItem(
                value: 'upgrade',
                child: Text(l10n.containerActionUpgrade),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Text(l10n.containerActionEdit),
              ),
              PopupMenuItem(
                value: 'commit',
                child: Text(l10n.containerActionCommit),
              ),
              PopupMenuItem(
                value: 'cleanLog',
                child: Text(l10n.containerActionCleanLog),
              ),
            ],
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- CPU / 内存两列次级信息（仅在有数据时显示）---
          if (container.cpuUsage != null || container.memoryUsage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  if (container.cpuUsage != null)
                    _MetricChip(
                      label: 'CPU',
                      value: container.cpuUsage!,
                      color: colorScheme.primary,
                    ),
                  if (container.cpuUsage != null &&
                      container.memoryUsage != null)
                    const SizedBox(width: 8),
                  if (container.memoryUsage != null)
                    _MetricChip(
                      label: l10n.containerStatsMemory,
                      value: container.memoryUsage!,
                      color: colorScheme.tertiary,
                    ),
                ],
              ),
            ),

          // --- 端口信息 ---
          if (ports.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 4,
                runSpacing: 3,
                children: ports
                    .map(
                      (p) => _PortChip(port: p, colorScheme: colorScheme),
                    )
                    .toList(),
              ),
            ),

          // --- 操作按钮行 ---
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isRunning) ...[
                _ActionButton(
                  icon: Icons.stop_rounded,
                  label: l10n.containerActionStop,
                  color: colorScheme.error,
                  onTap: onStop,
                ),
                _ActionButton(
                  icon: Icons.restart_alt,
                  label: l10n.containerActionRestart,
                  color: colorScheme.primary,
                  onTap: onRestart,
                ),
              ] else
                _ActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: l10n.containerActionStart,
                  color: colorScheme.tertiary,
                  onTap: onStart,
                ),
              if (onTerminal != null)
                _ActionButton(
                  icon: Icons.terminal,
                  label: l10n.containerActionTerminal,
                  color: colorScheme.secondary,
                  onTap: onTerminal,
                ),
              _ActionButton(
                icon: Icons.receipt_long_outlined,
                label: l10n.containerActionLogs,
                color: colorScheme.onSurfaceVariant,
                onTap: onLogs,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(ColorScheme colorScheme, String state) {
    switch (state) {
      case 'running':
        return colorScheme.tertiary;
      case 'restarting':
      case 'paused':
        return colorScheme.primary;
      case 'dead':
      case 'removing':
        return colorScheme.error;
      default:
        return colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    }
  }

  String _statusLabel(dynamic l10n, String state) {
    switch (state) {
      case 'running':
        return l10n.containerStatusRunning;
      case 'paused':
        return l10n.containerStatusPaused;
      case 'exited':
        return l10n.containerStatusExited;
      case 'restarting':
        return l10n.containerStatusRestarting;
      case 'removing':
        return l10n.containerStatusRemoving;
      case 'dead':
        return l10n.containerStatusDead;
      case 'created':
        return l10n.containerStatusCreated;
      default:
        return l10n.containerStatusStopped;
    }
  }

  List<String> _formatPorts() {
    if (container.portBindings != null && container.portBindings!.isNotEmpty) {
      return container.portBindings!
          .take(4)
          .map((p) => '${p.hostPort}:${p.containerPort}')
          .toList();
    }
    if (container.ports != null && container.ports!.isNotEmpty) {
      return container.ports!.take(4).toList();
    }
    return [];
  }
}

// ---------------------------------------------------------------------------
// 小圆点状态指示器（替代原来的大 Chip）
// ---------------------------------------------------------------------------
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CPU / 内存指标徽章
// ---------------------------------------------------------------------------
class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(5),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 端口 Chip
// ---------------------------------------------------------------------------
class _PortChip extends StatelessWidget {
  const _PortChip({required this.port, required this.colorScheme});

  final String port;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        port,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 操作按钮（紧凑版）
// ---------------------------------------------------------------------------
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minHeight: 30),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

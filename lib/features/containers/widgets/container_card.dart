import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/container_models.dart'
    hide Container;

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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final state = container.state.toLowerCase();
    final isRunning = state == 'running';
    final statusColor = _statusColor(scheme, state);
    final statusLabel = _statusLabel(l10n, state);
    final projectName = _projectName();
    final ports = _formatPorts();

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 头部：图标 + 名称 + 状态 + 菜单 ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 图标
              _ContainerIcon(scheme: scheme),
              const SizedBox(width: 10),
              // 名称 + 副标题
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      container.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        _StatusDot(color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: textTheme.labelSmall
                              ?.copyWith(color: statusColor),
                        ),
                        if (projectName != null) ...[
                          Text(
                            '  ${l10n.containerInfoProject}: ',
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              projectName,
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // 更多菜单
              _MoreMenu(
                l10n: l10n,
                onRename: onRename,
                onUpgrade: onUpgrade,
                onEdit: onEdit,
                onCommit: onCommit,
                onCleanLog: onCleanLog,
                onDelete: onDelete,
              ),
            ],
          ),

          // ── 镜像名（副行）──
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              container.image,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── CPU / 内存 / 网络（有数据时）──
          if (container.cpuUsage != null || container.memoryUsage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (container.cpuUsage != null)
                    _MetricChip(
                      icon: Icons.memory_outlined,
                      label: 'CPU',
                      value: container.cpuUsage!,
                      color: scheme.primary,
                    ),
                  if (container.memoryUsage != null)
                    _MetricChip(
                      icon: Icons.storage_outlined,
                      label: l10n.containerStatsMemory,
                      value: container.memoryUsage!,
                      color: scheme.tertiary,
                    ),
                ],
              ),
            ),

          // ── 端口映射 ──
          if (ports.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 5,
                runSpacing: 4,
                children:
                    ports.map((p) => _PortChip(port: p, scheme: scheme)).toList(),
              ),
            ),

          // ── 分隔线 ──
          Divider(
            height: 12,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),

          // ── 操作按钮行 ──
          Row(
            children: [
              if (isRunning) ...[
                _ActionButton(
                  icon: Icons.stop_rounded,
                  label: l10n.containerActionStop,
                  color: scheme.error,
                  onTap: onStop,
                ),
                const SizedBox(width: 6),
                _ActionButton(
                  icon: Icons.restart_alt,
                  label: l10n.containerActionRestart,
                  color: scheme.primary,
                  onTap: onRestart,
                ),
              ] else
                _ActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: l10n.containerActionStart,
                  color: scheme.tertiary,
                  onTap: onStart,
                ),
              if (onTerminal != null) ...[
                const SizedBox(width: 6),
                _ActionButton(
                  icon: Icons.terminal,
                  label: l10n.containerActionTerminal,
                  color: scheme.secondary,
                  onTap: onTerminal,
                ),
              ],
              const SizedBox(width: 6),
              _ActionButton(
                icon: Icons.receipt_long_outlined,
                label: l10n.containerActionLogs,
                color: scheme.onSurfaceVariant,
                onTap: onLogs,
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

  Color _statusColor(ColorScheme scheme, String state) {
    switch (state) {
      case 'running':
        return scheme.tertiary;
      case 'restarting':
      case 'paused':
        return scheme.primary;
      case 'dead':
      case 'removing':
        return scheme.error;
      default:
        return scheme.onSurfaceVariant.withValues(alpha: 0.5);
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

// ────────────────────────────────────────────────────────────────────────────
// 容器图标头像
// ────────────────────────────────────────────────────────────────────────────
class _ContainerIcon extends StatelessWidget {
  const _ContainerIcon({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.view_in_ar,
        color: scheme.onPrimaryContainer,
        size: 22,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 状态小圆点
// ────────────────────────────────────────────────────────────────────────────
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// CPU / 内存指标徽章
// ────────────────────────────────────────────────────────────────────────────
class _MetricChip extends StatelessWidget {
  const _MetricChip({
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            '$label ',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 端口 Chip（参考图二样式：border + 等宽字体）
// ────────────────────────────────────────────────────────────────────────────
class _PortChip extends StatelessWidget {
  const _PortChip({required this.port, required this.scheme});
  final String port;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_in_new, size: 10, color: scheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            port,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 更多菜单
// ────────────────────────────────────────────────────────────────────────────
class _MoreMenu extends StatelessWidget {
  const _MoreMenu({
    required this.l10n,
    this.onRename,
    this.onUpgrade,
    this.onEdit,
    this.onCommit,
    this.onCleanLog,
    this.onDelete,
  });

  final dynamic l10n;
  final VoidCallback? onRename;
  final VoidCallback? onUpgrade;
  final VoidCallback? onEdit;
  final VoidCallback? onCommit;
  final VoidCallback? onCleanLog;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: l10n.commonMore,
      iconSize: 18,
      onSelected: (value) {
        if (value == 'rename') onRename?.call();
        if (value == 'upgrade') onUpgrade?.call();
        if (value == 'edit') onEdit?.call();
        if (value == 'commit') onCommit?.call();
        if (value == 'cleanLog') onCleanLog?.call();
        if (value == 'delete') onDelete?.call();
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'rename', child: Text(l10n.containerActionRename)),
        PopupMenuItem(
            value: 'upgrade', child: Text(l10n.containerActionUpgrade)),
        PopupMenuItem(value: 'edit', child: Text(l10n.containerActionEdit)),
        PopupMenuItem(value: 'commit', child: Text(l10n.containerActionCommit)),
        PopupMenuItem(
            value: 'cleanLog', child: Text(l10n.containerActionCleanLog)),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            l10n.containerActionDelete,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 操作按钮（紧凑版）
// ────────────────────────────────────────────────────────────────────────────
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
          borderRadius: BorderRadius.circular(7),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 4),
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

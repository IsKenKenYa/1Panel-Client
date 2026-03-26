import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/data/models/container_models.dart' hide Container;
import 'package:onepanelapp_app/shared/widgets/app_card.dart';

class ContainerCard extends StatelessWidget {
  final ContainerInfo container;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final VoidCallback? onRestart;
  final VoidCallback? onDelete;
  final VoidCallback? onLogs;
  final VoidCallback? onTerminal;
  final VoidCallback? onTap;

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
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isRunning = container.state.toLowerCase() == 'running';
    final statusColor = isRunning ? Colors.green : Colors.orange;

    return AppCard(
      title: container.name,
      subtitle: Text(container.image),
      trailing: _StatusChip(
        status: isRunning ? l10n.containerStatusRunning : l10n.containerStatusStopped,
        color: statusColor,
      ),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (container.ports != null || (container.portBindings != null && container.portBindings!.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${l10n.containerInfoPorts}: ${_formatPorts(container)}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isRunning) ...[
                _IconActionButton(
                  icon: Icons.stop,
                  tooltip: l10n.containerActionStop,
                  color: Colors.orange,
                  onTap: onStop,
                ),
                _IconActionButton(
                  icon: Icons.restart_alt,
                  tooltip: l10n.containerActionRestart,
                  color: colorScheme.primary,
                  onTap: onRestart,
                ),
              ] else ...[
                _IconActionButton(
                  icon: Icons.play_arrow,
                  tooltip: l10n.containerActionStart,
                  color: Colors.green,
                  onTap: onStart,
                ),
              ],
              _IconActionButton(
                icon: Icons.terminal,
                tooltip: l10n.containerActionTerminal,
                color: colorScheme.secondary,
                onTap: onTerminal,
              ),
              _IconActionButton(
                icon: Icons.description_outlined,
                tooltip: l10n.containerActionLogs,
                color: colorScheme.tertiary,
                onTap: onLogs,
              ),
              _IconActionButton(
                icon: Icons.delete_outline,
                tooltip: l10n.containerActionDelete,
                color: colorScheme.error,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPorts(ContainerInfo container) {
    if (container.portBindings != null && container.portBindings!.isNotEmpty) {
      return container.portBindings!
          .take(3)
          .map((p) => '${p.hostPort}:${p.containerPort}')
          .join(', ');
    }
    if (container.ports != null && container.ports!.isNotEmpty) {
      return container.ports!.join(', ');
    }
    return '';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusChip({
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  const _IconActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

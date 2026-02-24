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
  final VoidCallback? onRename;
  final VoidCallback? onUpgrade;
  final VoidCallback? onCommit;
  final VoidCallback? onEdit;
  final VoidCallback? onCleanLog;
  final VoidCallback? onDownloadLog;

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
    this.onDownloadLog,
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusChip(
            status: isRunning ? l10n.containerStatusRunning : l10n.containerStatusStopped,
            color: statusColor,
          ),
          PopupMenuButton<String>(
            tooltip: l10n.commonMore,
            onSelected: (value) {
              if (value == 'rename') onRename?.call();
              if (value == 'upgrade') onUpgrade?.call();
              if (value == 'edit') onEdit?.call();
              if (value == 'commit') onCommit?.call();
              if (value == 'cleanLog') onCleanLog?.call();
              if (value == 'downloadLog') onDownloadLog?.call();
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
              PopupMenuItem(
                value: 'downloadLog',
                child: Text(l10n.containerActionDownloadLog),
              ),
            ],
          ),
        ],
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
                _ActionButton(
                  icon: Icons.stop,
                  label: l10n.containerActionStop,
                  color: Colors.orange,
                  onTap: onStop,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.restart_alt,
                  label: l10n.containerActionRestart,
                  color: colorScheme.primary,
                  onTap: onRestart,
                ),
              ] else ...[
                _ActionButton(
                  icon: Icons.play_arrow,
                  label: l10n.containerActionStart,
                  color: Colors.green,
                  onTap: onStart,
                ),
              ],
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.terminal,
                label: l10n.containerActionTerminal,
                color: colorScheme.secondary,
                onTap: onTerminal,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.description_outlined,
                label: l10n.containerActionLogs,
                color: colorScheme.tertiary,
                onTap: onLogs,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.delete_outline,
                label: l10n.containerActionDelete,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

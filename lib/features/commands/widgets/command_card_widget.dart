import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

class CommandCardWidget extends StatelessWidget {
  const CommandCardWidget({
    super.key,
    required this.command,
    required this.groupLabel,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
  });

  final CommandInfo command;
  final String groupLabel;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final preview = (command.command ?? '').trim();
    return AppCard(
      title: command.name ?? '',
      subtitle: Text(groupLabel),
      trailing: selectionMode
          ? Icon(
              isSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            )
          : null,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              preview.isEmpty ? '-' : preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: Text(l10n.commonCopy),
              ),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.commonEdit),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(l10n.commonDelete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

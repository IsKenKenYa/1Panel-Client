import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/data/models/container_models.dart';
import 'package:onepanelapp_app/features/containers/containers_provider.dart';

class ContainersPageContainerMaintenanceDialogs {
  static Future<void> showPruneDialog(BuildContext context) async {
    final l10n = context.l10n;
    ContainerPruneType type = ContainerPruneType.container;
    bool withTagAll = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.containerActionPrune),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ContainerPruneType>(
                initialValue: type,
                decoration: InputDecoration(
                  labelText: l10n.containerPruneType,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: ContainerPruneType.container,
                    child: Text(l10n.containerPruneTypeContainer),
                  ),
                  DropdownMenuItem(
                    value: ContainerPruneType.image,
                    child: Text(l10n.containerPruneTypeImage),
                  ),
                  DropdownMenuItem(
                    value: ContainerPruneType.volume,
                    child: Text(l10n.containerPruneTypeVolume),
                  ),
                  DropdownMenuItem(
                    value: ContainerPruneType.network,
                    child: Text(l10n.containerPruneTypeNetwork),
                  ),
                  DropdownMenuItem(
                    value: ContainerPruneType.buildcache,
                    child: Text(l10n.containerPruneTypeBuildCache),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => type = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: withTagAll,
                onChanged: (value) => setState(() => withTagAll = value),
                title: Text(l10n.containerPruneWithTagAll),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      final provider = context.read<ContainersProvider>();
      final report = await provider.pruneContainers(
        ContainerPrune(
          pruneType: type.value,
          withTagAll: withTagAll,
        ),
      );
      if (!context.mounted) return;
      final message = report?.message ?? l10n.containerOperateSuccess;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  static void showDeleteContainerDialog(
    BuildContext context,
    String containerId,
  ) {
    final parentContext = context;
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.delete_outline, color: colorScheme.error),
        title: Text(l10n.commonDelete),
        content: Text(l10n.containerDeleteConfirm(containerId)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final provider = context.read<ContainersProvider>();
              final success = await provider.deleteContainer(containerId);
              if (!parentContext.mounted) return;
              if (success) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text(l10n.containerOperateSuccess)),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }
}

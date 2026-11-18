import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/containers/containers_provider.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';

class ContainersPageContainerMaintenanceDialogs {
  static Future<void> showPruneDialog(BuildContext context) async {
    final l10n = context.l10n;
    ContainerPruneType type = ContainerPruneType.container;
    bool withTagAll = false;

    await showAppFormDialog(
      context,
      title: l10n.containerActionPrune,
      confirmLabel: l10n.commonConfirm,
      content: StatefulBuilder(
        builder: (context, setSheetState) => Column(
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
                  setSheetState(() => type = value);
                }
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: withTagAll,
              onChanged: (value) => setSheetState(() => withTagAll = value),
              title: Text(l10n.containerPruneWithTagAll),
            ),
          ],
        ),
      ),
      onConfirm: () async {
        final provider = context.read<ContainersProvider>();
        final report = await provider.pruneContainers(
          ContainerPrune(
            pruneType: type.value,
            withTagAll: withTagAll,
          ),
        );
        if (!context.mounted) return;
        final message = report?.message ?? l10n.containerOperateSuccess;
        SnackBarUtils.showSuccess(context, message);
      },
    );
  }

  static void showDeleteContainerDialog(
    BuildContext context,
    String containerId,
  ) {
    // Capture parent context before showing the dialog; the dialog's own context
    // becomes invalid after Navigator.pop(), but we need the parent to read the
    // provider and show the result snackbar.
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
                SnackBarUtils.showSuccess(parentContext, l10n.containerOperateSuccess);
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

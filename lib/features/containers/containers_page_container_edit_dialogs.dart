import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/containers/containers_provider.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';

class ContainersPageContainerEditDialogs {
  static Future<void> showRenameContainerDialog(
    BuildContext context,
    String name,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.containerActionRename),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.commonName,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (result != null &&
        result.isNotEmpty &&
        result != name &&
        context.mounted) {
      final provider = context.read<ContainersProvider>();
      final success = await provider.renameContainer(name, result);
      if (context.mounted) {
        if (success) {
          SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
        } else {
          SnackBarUtils.showError(context,
              l10n.containerOperateFailed(provider.data.error ?? l10n.commonUnknownError));
        }
      }
    }
  }

  static Future<void> showEditContainerDialog(
    BuildContext context,
    ContainerInfo container,
  ) async {
    final l10n = context.l10n;
    final cpuController = TextEditingController();
    final memoryController = TextEditingController();

    await showAppFormDialog(
      context,
      title: l10n.containerActionEdit,
      confirmLabel: l10n.commonConfirm,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cpuController,
              decoration: InputDecoration(
                labelText: l10n.containerCpuShares,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: memoryController,
              decoration: InputDecoration(
                labelText: l10n.containerMemory,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      onConfirm: () async {
        final provider = context.read<ContainersProvider>();
        final cpuShares = int.tryParse(cpuController.text);
        final memory = int.tryParse(memoryController.text);
        final request = ContainerOperate(
          name: container.name,
          image: container.image,
          cpuShares: cpuShares,
          memory: memory,
        );
        final success = await provider.updateContainer(request);
        if (!success) {
          throw Exception(
              l10n.containerOperateFailed(provider.data.error ?? l10n.commonUnknownError));
        }
        if (!context.mounted) {
          return;
        }
        SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
      },
    );
  }

  static Future<void> showCleanLogDialog(
    BuildContext context,
    String name,
  ) async {
    final l10n = context.l10n;
    final confirm = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.containerActionCleanLog,
      message: l10n.containerCleanLogConfirm(name),
      confirmLabel: l10n.commonConfirm,
      isDestructive: true,
    );

    if (confirm == true && context.mounted) {
      final provider = context.read<ContainersProvider>();
      final success = await provider.cleanContainerLog(name);
      if (context.mounted) {
        if (success) {
          SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
        } else {
          SnackBarUtils.showError(context,
              l10n.containerOperateFailed(provider.data.error ?? l10n.commonUnknownError));
        }
      }
    }
  }
}

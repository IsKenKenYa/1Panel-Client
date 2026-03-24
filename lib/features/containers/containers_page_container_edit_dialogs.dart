import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/containers/containers_provider.dart';

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

    if (result != null && result.isNotEmpty && result != name && context.mounted) {
      final provider = context.read<ContainersProvider>();
      final success = await provider.renameContainer(name, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? l10n.containerOperateSuccess
                  : l10n.containerOperateFailed(
                      provider.data.error ?? l10n.commonUnknownError,
                    ),
            ),
          ),
        );
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

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.containerActionEdit),
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
    );

    if (result == true && context.mounted) {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? l10n.containerOperateSuccess
                  : l10n.containerOperateFailed(
                      provider.data.error ?? l10n.commonUnknownError,
                    ),
            ),
          ),
        );
      }
    }
  }

  static Future<void> showCleanLogDialog(
    BuildContext context,
    String name,
  ) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.containerActionCleanLog),
        content: Text(l10n.containerCleanLogConfirm(name)),
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
    );

    if (confirm == true && context.mounted) {
      final provider = context.read<ContainersProvider>();
      final success = await provider.cleanContainerLog(name);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? l10n.containerOperateSuccess
                  : l10n.containerOperateFailed(
                      provider.data.error ?? l10n.commonUnknownError,
                    ),
            ),
          ),
        );
      }
    }
  }
}

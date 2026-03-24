import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/containers/containers_provider.dart';

class ContainersPageContainerImageDialogs {
  static Future<void> showUpgradeContainerDialog(
    BuildContext context,
    ContainerInfo container,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: container.image);
    bool forcePull = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.containerActionUpgrade),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: l10n.containerImage,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: forcePull,
                onChanged: (value) => setState(() => forcePull = value),
                title: Text(l10n.containerUpgradeForcePull),
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
      final request = ContainerUpgrade(
        name: container.name,
        image: controller.text,
        forcePull: forcePull,
      );
      final success = await provider.upgradeContainer(request);
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

  static Future<void> showCommitContainerDialog(
    BuildContext context,
    ContainerInfo container,
  ) async {
    final l10n = context.l10n;
    final imageController = TextEditingController();
    final authorController = TextEditingController();
    final commentController = TextEditingController();
    bool pause = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.containerActionCommit),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: imageController,
                  decoration: InputDecoration(
                    labelText: l10n.containerCommitImage,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorController,
                  decoration: InputDecoration(
                    labelText: l10n.containerCommitAuthor,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    labelText: l10n.containerCommitComment,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SwitchListTile(
                  value: pause,
                  onChanged: (value) => setState(() => pause = value),
                  title: Text(l10n.containerCommitPause),
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
      ),
    );

    if (result == true && context.mounted) {
      final provider = context.read<ContainersProvider>();
      final request = ContainerCommit(
        containerID: container.id,
        containerName: container.name,
        newImageName: imageController.text,
        author: authorController.text.isEmpty ? null : authorController.text,
        comment: commentController.text.isEmpty ? null : commentController.text,
        pause: pause,
      );
      final success = await provider.commitContainer(request);
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

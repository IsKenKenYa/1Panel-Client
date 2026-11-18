import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/containers/containers_provider.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';

class ContainersPageContainerImageDialogs {
  static Future<void> showUpgradeContainerDialog(
    BuildContext context,
    ContainerInfo container,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: container.image);
    bool forcePull = false;

    await showAppFormDialog(
      context,
      title: l10n.containerActionUpgrade,
      confirmLabel: l10n.commonConfirm,
      content: StatefulBuilder(
        builder: (context, setSheetState) => Column(
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
              onChanged: (value) => setSheetState(() => forcePull = value),
              title: Text(l10n.containerUpgradeForcePull),
            ),
          ],
        ),
      ),
      onConfirm: () async {
        final provider = context.read<ContainersProvider>();
        final request = ContainerUpgrade(
          names: <String>[container.name],
          image: controller.text,
          forcePull: forcePull,
        );
        final success = await provider.upgradeContainer(request);
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

  static Future<void> showCommitContainerDialog(
    BuildContext context,
    ContainerInfo container,
  ) async {
    final l10n = context.l10n;
    final imageController = TextEditingController();
    final authorController = TextEditingController();
    final commentController = TextEditingController();
    bool pause = false;

    await showAppFormDialog(
      context,
      title: l10n.containerActionCommit,
      confirmLabel: l10n.commonConfirm,
      content: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (context, setSheetState) => Column(
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
                onChanged: (value) => setSheetState(() => pause = value),
                title: Text(l10n.containerCommitPause),
              ),
            ],
          ),
        ),
      ),
      onConfirm: () async {
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
}

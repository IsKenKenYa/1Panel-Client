import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/data/models/docker_models.dart';
import 'package:onepanel_client/features/orchestration/providers/compose_provider.dart';
import 'package:onepanel_client/features/orchestration/widgets/compose_card_actions.dart';
import 'package:onepanel_client/features/orchestration/widgets/orchestration_detail_line_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';

class ComposeCardDialogs {
  static Future<void> showComposeFormDialog(
    BuildContext context,
    ComposeProvider provider, {
    required ComposeProject compose,
    required String title,
    required Future<bool> Function(
      String name,
      String path,
      String content,
      String? env,
    ) onSubmit,
  }) async {
    final l10n = context.l10n;
    final nameController = TextEditingController(text: compose.name);
    final pathController = TextEditingController(text: compose.path ?? '');
    final contentController = TextEditingController();
    final envController = TextEditingController();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.commonName,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pathController,
                decoration: InputDecoration(
                  labelText: l10n.commonPath,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                decoration: InputDecoration(
                  labelText: l10n.orchestrationComposeContentLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 8,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: envController,
                decoration: InputDecoration(
                  labelText: l10n.env,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 4,
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

    if (shouldSubmit != true || !context.mounted) return;

    await ComposeCardActions.runAction(
      context,
      provider,
      () => onSubmit(
        nameController.text.trim(),
        pathController.text.trim(),
        contentController.text,
        envController.text.trim().isEmpty ? null : envController.text.trim(),
      ),
    );
  }

  static Future<void> showDetailsSheet(
    BuildContext context, {
    required ComposeProject compose,
  }) async {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(compose.name, style: textTheme.titleLarge),
              const SizedBox(height: 12),
              OrchestrationDetailLineWidget(label: 'ID', value: compose.id),
              OrchestrationDetailLineWidget(
                label: l10n.commonPath,
                value: compose.path,
              ),
              OrchestrationDetailLineWidget(
                label: 'Status',
                value: compose.status,
              ),
              OrchestrationDetailLineWidget(
                label: 'Version',
                value: compose.version,
              ),
              OrchestrationDetailLineWidget(
                label: 'Created',
                value: compose.createTime,
              ),
              OrchestrationDetailLineWidget(
                label: 'Updated',
                value: compose.updateTime,
              ),
              if ((compose.services ?? const <String>[]).isNotEmpty)
                OrchestrationDetailLineWidget(
                  label: l10n.orchestrationServicesLabel,
                  value: (compose.services ?? const <String>[]).join(', '),
                ),
              if ((compose.networks ?? const <String>[]).isNotEmpty)
                OrchestrationDetailLineWidget(
                  label: l10n.orchestrationNetworks,
                  value: (compose.networks ?? const <String>[]).join(', '),
                ),
              if ((compose.volumes ?? const <String>[]).isNotEmpty)
                OrchestrationDetailLineWidget(
                  label: l10n.orchestrationVolumes,
                  value: (compose.volumes ?? const <String>[]).join(', '),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> showCleanLogDialog(
    BuildContext context,
    ComposeProvider provider, {
    required ComposeProject compose,
  }) async {
    final l10n = context.l10n;
    final shouldClean = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.orchestrationComposeCleanLog,
      message: l10n.orchestrationComposeCleanLogConfirm(compose.name),
      confirmLabel: l10n.commonConfirm,
      isDestructive: true,
    );

    if (shouldClean != true || !context.mounted) return;
    await ComposeCardActions.runAction(
      context,
      provider,
      () => provider.cleanComposeLog(
        ContainerComposeLogCleanRequest(
          name: compose.name,
          path: compose.path ?? '',
        ),
      ),
    );
  }

  static Future<void> showDeleteComposeDialog(
    BuildContext context,
    ComposeProvider provider, {
    required ComposeProject compose,
  }) async {
    final l10n = context.l10n;
    bool forceDelete = false;
    bool deleteFile = false;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.orchestrationComposeDelete),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.orchestrationComposeDeleteConfirm(compose.name)),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: forceDelete,
                onChanged: (value) {
                  setState(() => forceDelete = value ?? false);
                },
                title: Text(l10n.orchestrationComposeForceDelete),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                visualDensity: AdaptiveLayoutSpec.of(context).adaptiveDensity,
              ),
              CheckboxListTile(
                value: deleteFile,
                onChanged: (value) {
                  setState(() => deleteFile = value ?? false);
                },
                title: Text(l10n.orchestrationComposeDeleteFile),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                visualDensity: AdaptiveLayoutSpec.of(context).adaptiveDensity,
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
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.orchestrationComposeDelete),
            ),
          ],
        ),
      ),
    );

    if (shouldDelete != true || !context.mounted) return;
    await ComposeCardActions.runAction(
      context,
      provider,
      () => provider.deleteCompose(
        compose,
        force: forceDelete,
        withFile: deleteFile,
      ),
    );
  }
}

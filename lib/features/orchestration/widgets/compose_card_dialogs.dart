import 'package:flutter/material.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/data/models/docker_models.dart';
import 'package:onepanel_client/features/orchestration/providers/compose_provider.dart';
import 'package:onepanel_client/features/orchestration/widgets/compose_card_actions.dart';
import 'package:onepanel_client/features/orchestration/widgets/orchestration_detail_line_widget.dart';

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
    )
    onSubmit,
  }) async {
    final result =
        await showAdaptiveFormPanel<
          ({String name, String path, String content, String? env})
        >(
          context,
          builder: (_) => _ComposeForm(compose: compose, title: title),
        );

    if (result == null || !context.mounted) return;

    await ComposeCardActions.runAction(
      context,
      provider,
      () => onSubmit(result.name, result.path, result.content, result.env),
    );
  }

  static Future<void> showDetailsSheet(
    BuildContext context, {
    required ComposeProject compose,
  }) async {
    final l10n = context.l10n;
    await showAppDetailsSheet(
      context,
      title: compose.name,
      children: [
        OrchestrationDetailLineWidget(label: 'ID', value: compose.id),
        OrchestrationDetailLineWidget(
          label: l10n.commonPath,
          value: compose.path,
        ),
        OrchestrationDetailLineWidget(
          label: l10n.commonStatus,
          value: compose.status,
        ),
        OrchestrationDetailLineWidget(
          label: l10n.commonVersion,
          value: compose.version,
        ),
        OrchestrationDetailLineWidget(
          label: l10n.containerInfoCreated,
          value: compose.createTime,
        ),
        OrchestrationDetailLineWidget(
          label: l10n.commonUpdated,
          value: compose.updateTime,
        ),
        if (compose.services case final services? when services.isNotEmpty)
          OrchestrationDetailLineWidget(
            label: l10n.orchestrationServicesLabel,
            value: services.join(', '),
          ),
        if (compose.networks case final networks? when networks.isNotEmpty)
          OrchestrationDetailLineWidget(
            label: l10n.orchestrationNetworks,
            value: networks.join(', '),
          ),
        if (compose.volumes case final volumes? when volumes.isNotEmpty)
          OrchestrationDetailLineWidget(
            label: l10n.orchestrationVolumes,
            value: volumes.join(', '),
          ),
      ],
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

    final shouldDelete = await showAdaptiveFormPanel<bool>(
      context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AppFormPanel(
          title: l10n.orchestrationComposeDelete,
          confirmLabel: l10n.orchestrationComposeDelete,
          destructive: true,
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
          onConfirm: () async => Navigator.of(context).pop(true),
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

class _ComposeForm extends StatefulWidget {
  const _ComposeForm({required this.compose, required this.title});

  final ComposeProject compose;
  final String title;

  @override
  State<_ComposeForm> createState() => _ComposeFormState();
}

class _ComposeFormState extends State<_ComposeForm> {
  late final _nameController = TextEditingController(text: widget.compose.name);
  late final _pathController = TextEditingController(
    text: widget.compose.path ?? '',
  );
  final _contentController = TextEditingController();
  final _envController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    _contentController.dispose();
    _envController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: widget.title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.commonName,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pathController,
            decoration: InputDecoration(
              labelText: l10n.commonPath,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            decoration: InputDecoration(
              labelText: l10n.orchestrationComposeContentLabel,
              border: const OutlineInputBorder(),
            ),
            maxLines: 8,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _envController,
            decoration: InputDecoration(
              labelText: l10n.env,
              border: const OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
        ],
      ),
      onConfirm: () async {
        final env = _envController.text.trim();
        Navigator.of(context).pop((
          name: _nameController.text.trim(),
          path: _pathController.text.trim(),
          content: _contentController.text,
          env: env.isEmpty ? null : env,
        ));
      },
    );
  }
}

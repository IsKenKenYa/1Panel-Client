import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/ai/ai_provider.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

import '../../../core/utils/snackbar_utils.dart';

class AIOllamaTabActions {
  static Future<void> handleCreate(
    BuildContext context,
    AIProvider provider,
  ) async {
    final l10n = context.l10n;
    final input = await showAdaptiveFormPanel<({String name, String taskId})>(
      context,
      builder: (_) => const _OllamaCreateForm(),
    );
    if (input == null || !context.mounted) {
      return;
    }
    if (input.name.isEmpty) {
      SnackBarUtils.showSuccess(context, l10n.aiModelNameRequired);
      return;
    }

    await runAction(
      context,
      provider,
      () => provider.createOllamaModel(
        name: input.name,
        taskId: input.taskId.isEmpty ? null : input.taskId,
      ),
    );
  }

  static Future<void> handleDelete(
    BuildContext context,
    AIProvider provider,
    int modelId,
  ) async {
    final l10n = context.l10n;
    bool forceDelete = false;

    final shouldDelete = await showAppFormDialog(
      context,
      title: l10n.commonDelete,
      confirmLabel: l10n.commonDelete,
      destructive: true,
      onConfirm: () async {},
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.commonDeleteConfirm),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: forceDelete,
              onChanged: (value) {
                setState(() => forceDelete = value ?? false);
              },
              title: Text(l10n.aiForceDelete),
            ),
          ],
        ),
      ),
    );

    if (!shouldDelete || !context.mounted) {
      return;
    }
    await runAction(
      context,
      provider,
      () =>
          provider.deleteOllamaModel(ids: [modelId], forceDelete: forceDelete),
    );
  }

  static Future<void> runAction(
    BuildContext context,
    AIProvider provider,
    Future<bool> Function() action,
  ) async {
    final l10n = context.l10n;
    final success = await action();
    if (!context.mounted) {
      return;
    }

    if (success) {
      SnackBarUtils.showSuccess(context, l10n.aiOperationSuccess);
      return;
    }

    final error = provider.errorMessage ?? l10n.commonUnknownError;
    SnackBarUtils.showError(
      context,
      l10n.aiOperationFailed(error),
      action: SnackBarAction(
        label: l10n.commonRetry,
        onPressed: () => action(),
      ),
    );
  }
}

class _OllamaCreateForm extends StatefulWidget {
  const _OllamaCreateForm();

  @override
  State<_OllamaCreateForm> createState() => _OllamaCreateFormState();
}

class _OllamaCreateFormState extends State<_OllamaCreateForm> {
  final nameController = TextEditingController();
  final taskIdController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    taskIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.aiModelCreate,
      confirmLabel: l10n.commonCreate,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: l10n.aiModelNameLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: taskIdController,
            decoration: InputDecoration(
              labelText: l10n.aiTaskIdOptional,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      onConfirm: () async => Navigator.of(context).pop((
        name: nameController.text.trim(),
        taskId: taskIdController.text.trim(),
      )),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/ai/ai_provider.dart';

class AIOllamaTabActions {
  static Future<void> handleCreate(
    BuildContext context,
    AIProvider provider,
  ) async {
    final l10n = context.l10n;
    final nameController = TextEditingController();
    final taskIdController = TextEditingController();

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aiModelCreate),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonCreate),
          ),
        ],
      ),
    );

    if (shouldCreate != true || !context.mounted) return;
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiModelNameRequired)),
      );
      return;
    }

    await runAction(
      context,
      provider,
      () => provider.createOllamaModel(
        name: nameController.text.trim(),
        taskId: taskIdController.text.trim().isEmpty
            ? null
            : taskIdController.text.trim(),
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

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.commonDelete),
          content: Column(
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.commonDelete),
            ),
          ],
        ),
      ),
    );

    if (shouldDelete != true || !context.mounted) return;
    await runAction(
      context,
      provider,
      () => provider.deleteOllamaModel(
        ids: [modelId],
        forceDelete: forceDelete,
      ),
    );
  }

  static Future<void> runAction(
    BuildContext context,
    AIProvider provider,
    Future<bool> Function() action,
  ) async {
    final l10n = context.l10n;
    final success = await action();
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiOperationSuccess)),
      );
      return;
    }

    final error = provider.errorMessage ?? l10n.commonUnknownError;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.aiOperationFailed(error)),
        action: SnackBarAction(
          label: l10n.commonRetry,
          onPressed: () {
            action();
          },
        ),
      ),
    );
  }
}

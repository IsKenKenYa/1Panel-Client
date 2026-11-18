part of 'toolbox_clam_page.dart';

mixin _ToolboxClamPageActionsPart on State<ToolboxClamPage> {
  Future<void> _showTaskDialog(
    BuildContext context,
    ToolboxClamProvider provider, {
    ClamBaseInfo? existing,
  }) async {
    final l10n = context.l10n;
    final isEdit = existing != null;

    final nameController = TextEditingController(text: existing?.name ?? '');
    final pathController = TextEditingController(text: existing?.path ?? '');
    final specController = TextEditingController(text: existing?.spec ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    final timeoutController = TextEditingController(
      text: existing?.timeout?.toString() ?? '3600',
    );
    final infectedDirController =
        TextEditingController(text: existing?.infectedDir ?? '');
    var enabled = (existing?.status ?? 'enable') != 'disable';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? l10n.commonEdit : l10n.commonCreate),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.commonName),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pathController,
                  decoration: InputDecoration(labelText: l10n.commonPath),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specController,
                  decoration: InputDecoration(
                    labelText: l10n.toolboxClamCronExpression,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration:
                      InputDecoration(labelText: l10n.commonDescription),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeoutController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.commonTimeoutSeconds),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: infectedDirController,
                  decoration: InputDecoration(
                    labelText: l10n.toolboxClamInfectedDirectory,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: enabled,
                  onChanged: (value) => setState(() => enabled = value),
                  title: Text(l10n.toolboxStatusLabel),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final path = pathController.text.trim();
                final timeout = int.tryParse(timeoutController.text.trim());
                if (name.isEmpty || path.isEmpty || timeout == null) {
                  SnackBarUtils.showSuccess(context, l10n.websitesSslAccountsValidationRequiredFields);
                  return;
                }

                final status = enabled ? 'enable' : 'disable';
                bool success;
                if (isEdit) {
                  success = await provider.updateTask(
                    ClamUpdate(
                      id: existing.id,
                      name: name,
                      path: path,
                      spec: specController.text.trim(),
                      description: descriptionController.text.trim(),
                      timeout: timeout,
                      infectedDir: infectedDirController.text.trim(),
                      status: status,
                    ),
                  );
                } else {
                  success = await provider.createTask(
                    ClamCreate(
                      name: name,
                      path: path,
                      spec: specController.text.trim(),
                      description: descriptionController.text.trim(),
                      timeout: timeout,
                      infectedDir: infectedDirController.text.trim(),
                      status: status,
                    ),
                  );
                }

                if (!context.mounted) {
                  return;
                }
                if (success) {
                  Navigator.pop(dialogContext);
                }
                SnackBarUtils.showSuccess(context, 
                      success
                          ? l10n.commonSaveSuccess
                          : (provider.error ?? l10n.commonSaveFailed),
                );
              },
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTaskAction(
    BuildContext context,
    ToolboxClamProvider provider,
    ClamBaseInfo task,
    String action,
  ) async {
    final id = task.id;
    if (id == null) {
      return;
    }

    switch (action) {
      case 'handle':
        await _showResult(context, provider.handleTask(id), provider);
        break;
      case 'edit':
        await _showTaskDialog(context, provider, existing: task);
        break;
      case 'delete':
        await _confirmDeleteTask(context, provider, id);
        break;
      case 'clean':
        await _confirmCleanRecords(context, provider, id);
        break;
    }
  }

  Future<void> _confirmDeleteTask(
    BuildContext context,
    ToolboxClamProvider provider,
    int id,
  ) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.commonDelete,
      message: l10n.commonDeleteConfirm,
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );
    if (!confirmed) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    await _showResult(context, provider.deleteTask(id), provider);
  }

  Future<void> _confirmCleanRecords(
    BuildContext context,
    ToolboxClamProvider provider,
    int id,
  ) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.cronjobRecordsCleanAction,
      message: l10n.cronjobRecordsCleanConfirm,
      confirmLabel: l10n.commonConfirm,
      isDestructive: true,
    );
    if (!confirmed) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    await _showResult(context, provider.cleanRecords(id), provider);
  }

  Future<void> _operateService(
    BuildContext context,
    ToolboxClamProvider provider,
    String operation,
  ) async {
    await _showResult(
      context,
      provider.operateService(operation),
      provider,
    );
  }

  Future<void> _showResult(
    BuildContext context,
    Future<bool> result,
    ToolboxClamProvider provider,
  ) async {
    final l10n = context.l10n;
    final success = await result;
    if (!context.mounted) {
      return;
    }
    SnackBarUtils.showSuccess(context, 
          success
              ? l10n.commonSaveSuccess
              : (provider.error ?? l10n.commonSaveFailed),
    );
  }
}

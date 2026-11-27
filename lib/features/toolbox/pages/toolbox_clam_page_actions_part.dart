part of 'toolbox_clam_page.dart';

mixin _ToolboxClamPageActionsPart on State<ToolboxClamPage> {
  Future<void> _showTaskDialog(
    BuildContext context,
    ToolboxClamProvider provider, {
    ClamBaseInfo? existing,
  }) async {
    await showAdaptiveFormPanel<void>(
      context,
      builder: (_) => _ClamTaskForm(provider: provider, existing: existing),
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
    await _showResult(context, provider.operateService(operation), provider);
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
    SnackBarUtils.showSuccess(
      context,
      success
          ? l10n.commonSaveSuccess
          : (provider.error ?? l10n.commonSaveFailed),
    );
  }
}

class _ClamTaskForm extends StatefulWidget {
  const _ClamTaskForm({required this.provider, this.existing});

  final ToolboxClamProvider provider;
  final ClamBaseInfo? existing;

  @override
  State<_ClamTaskForm> createState() => _ClamTaskFormState();
}

class _ClamTaskFormState extends State<_ClamTaskForm> {
  late final _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final _pathController = TextEditingController(
    text: widget.existing?.path ?? '',
  );
  late final _specController = TextEditingController(
    text: widget.existing?.spec ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late final _timeoutController = TextEditingController(
    text: widget.existing?.timeout?.toString() ?? '3600',
  );
  late final _infectedDirController = TextEditingController(
    text: widget.existing?.infectedDir ?? '',
  );
  late bool _enabled = (widget.existing?.status ?? 'enable') != 'disable';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    _specController.dispose();
    _descriptionController.dispose();
    _timeoutController.dispose();
    _infectedDirController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    final path = _pathController.text.trim();
    final timeout = int.tryParse(_timeoutController.text.trim());
    if (name.isEmpty || path.isEmpty || timeout == null) {
      SnackBarUtils.showSuccess(
        context,
        l10n.websitesSslAccountsValidationRequiredFields,
      );
      return;
    }

    final existing = widget.existing;
    final provider = widget.provider;
    final status = _enabled ? 'enable' : 'disable';
    setState(() => _saving = true);
    try {
      final bool success;
      if (existing != null) {
        success = await provider.updateTask(
          ClamUpdate(
            id: existing.id,
            name: name,
            path: path,
            spec: _specController.text.trim(),
            description: _descriptionController.text.trim(),
            timeout: timeout,
            infectedDir: _infectedDirController.text.trim(),
            status: status,
          ),
        );
      } else {
        success = await provider.createTask(
          ClamCreate(
            name: name,
            path: path,
            spec: _specController.text.trim(),
            description: _descriptionController.text.trim(),
            timeout: timeout,
            infectedDir: _infectedDirController.text.trim(),
            status: status,
          ),
        );
      }
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      if (success) Navigator.of(context).pop();
      SnackBarUtils.showSuccess(
        context,
        success
            ? l10n.commonSaveSuccess
            : (provider.error ?? l10n.commonSaveFailed),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: widget.existing == null ? l10n.commonCreate : l10n.commonEdit,
      confirmLabel: l10n.commonSave,
      isSaving: _saving,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.commonName),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pathController,
            decoration: InputDecoration(labelText: l10n.commonPath),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _specController,
            decoration: InputDecoration(
              labelText: l10n.toolboxClamCronExpression,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: l10n.commonDescription),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _timeoutController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.commonTimeoutSeconds),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _infectedDirController,
            decoration: InputDecoration(
              labelText: l10n.toolboxClamInfectedDirectory,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
            title: Text(l10n.toolboxStatusLabel),
          ),
        ],
      ),
      onConfirm: _submit,
    );
  }
}

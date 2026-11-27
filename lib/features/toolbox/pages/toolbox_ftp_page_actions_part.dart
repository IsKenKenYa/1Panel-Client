part of 'toolbox_ftp_page.dart';

mixin _ToolboxFtpPageActionsPart on State<ToolboxFtpPage> {
  Future<void> _operateService(
    BuildContext context,
    ToolboxFtpProvider provider,
    String operation,
  ) async {
    final l10n = context.l10n;
    final success = await provider.operateService(operation);
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

  Future<void> _showUserDialog(
    BuildContext context,
    ToolboxFtpProvider provider, {
    FtpInfo? existing,
  }) async {
    await showAdaptiveFormPanel<void>(
      context,
      builder: (_) => _FtpUserForm(
        provider: provider,
        existing: existing,
        pageContext: context,
      ),
    );
  }

  Future<void> _confirmDeleteUser(
    BuildContext context,
    ToolboxFtpProvider provider,
    FtpInfo user,
  ) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.commonDelete,
      message: l10n.commonDeleteConfirm,
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );

    if (!confirmed || user.id == null) {
      return;
    }
    final success = await provider.deleteUser(user.id!);
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

class _FtpUserForm extends StatefulWidget {
  const _FtpUserForm({
    required this.provider,
    this.existing,
    required this.pageContext,
  });

  final ToolboxFtpProvider provider;
  final FtpInfo? existing;
  final BuildContext pageContext;

  @override
  State<_FtpUserForm> createState() => _FtpUserFormState();
}

class _FtpUserFormState extends State<_FtpUserForm> {
  late final _userController = TextEditingController(
    text: widget.existing?.user ?? '',
  );
  late final _pathController = TextEditingController(
    text: widget.existing?.path ?? '',
  );
  late final _baseDirController = TextEditingController(
    text: widget.existing?.baseDir ?? widget.provider.baseInfo.baseDir ?? '',
  );
  final _passwordController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _userController.dispose();
    _pathController.dispose();
    _baseDirController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final l10n = context.l10n;
    final existing = widget.existing;
    final provider = widget.provider;
    final pageContext = widget.pageContext;
    final user = _userController.text.trim();
    final password = _passwordController.text.trim();
    if (user.isEmpty) {
      SnackBarUtils.showSuccess(pageContext, l10n.authUsernameRequired);
      return;
    }
    if (existing == null && password.isEmpty) {
      SnackBarUtils.showSuccess(pageContext, l10n.authPasswordRequired);
      return;
    }

    setState(() => _saving = true);
    try {
      final bool success;
      if (existing != null) {
        success = await provider.updateUser(
          FtpUpdate(
            id: existing.id,
            user: user,
            path: _pathController.text.trim(),
            baseDir: _baseDirController.text.trim(),
            password: password.isEmpty ? null : password,
          ),
        );
      } else {
        success = await provider.createUser(
          FtpCreate(
            user: user,
            path: _pathController.text.trim(),
            baseDir: _baseDirController.text.trim(),
            password: password,
          ),
        );
      }
      if (!pageContext.mounted || !mounted) return;
      if (success && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
      SnackBarUtils.showSuccess(
        pageContext,
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
            controller: _userController,
            decoration: InputDecoration(labelText: l10n.commonUsername),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pathController,
            decoration: InputDecoration(labelText: l10n.commonPath),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _baseDirController,
            decoration: InputDecoration(labelText: l10n.toolboxFtpBaseDir),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.commonPassword),
          ),
        ],
      ),
      onConfirm: _submit,
    );
  }
}

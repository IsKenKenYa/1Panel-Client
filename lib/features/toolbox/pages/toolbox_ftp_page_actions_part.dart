part of 'toolbox_ftp_page.dart';

mixin _ToolboxFtpPageActionsPart on State<ToolboxFtpPage> {
  Future<void> _operateService(
    BuildContext context,
    ToolboxFtpProvider provider,
    String operation,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.operateService(operation);
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? l10n.commonSaveSuccess
              : (provider.error ?? l10n.commonSaveFailed),
        ),
      ),
    );
  }

  Future<void> _showUserDialog(
    BuildContext context,
    ToolboxFtpProvider provider, {
    FtpInfo? existing,
  }) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final isEdit = existing != null;
    final userController = TextEditingController(text: existing?.user ?? '');
    final pathController = TextEditingController(text: existing?.path ?? '');
    final baseDirController = TextEditingController(
      text: existing?.baseDir ?? provider.baseInfo.baseDir ?? '',
    );
    final passwordController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEdit ? l10n.commonEdit : l10n.commonCreate),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userController,
                decoration: InputDecoration(labelText: l10n.commonUsername),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pathController,
                decoration: InputDecoration(labelText: l10n.commonPath),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: baseDirController,
                decoration: InputDecoration(labelText: l10n.toolboxFtpBaseDir),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.commonPassword,
                ),
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
              if (userController.text.trim().isEmpty) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.authUsernameRequired)),
                );
                return;
              }
              if (!isEdit && passwordController.text.trim().isEmpty) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.authPasswordRequired)),
                );
                return;
              }

              bool success;
              if (isEdit) {
                success = await provider.updateUser(
                  FtpUpdate(
                    id: existing.id,
                    user: userController.text.trim(),
                    path: pathController.text.trim(),
                    baseDir: baseDirController.text.trim(),
                    password: passwordController.text.trim().isEmpty
                        ? null
                        : passwordController.text.trim(),
                  ),
                );
              } else {
                success = await provider.createUser(
                  FtpCreate(
                    user: userController.text.trim(),
                    path: pathController.text.trim(),
                    baseDir: baseDirController.text.trim(),
                    password: passwordController.text.trim(),
                  ),
                );
              }

              if (!context.mounted) {
                return;
              }
              if (!dialogContext.mounted) {
                return;
              }
              if (success) {
                Navigator.pop(dialogContext);
              }
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? l10n.commonSaveSuccess
                        : (provider.error ?? l10n.commonSaveFailed),
                  ),
                ),
              );
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteUser(
    BuildContext context,
    ToolboxFtpProvider provider,
    FtpInfo user,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.commonDelete),
            content: Text(l10n.commonDeleteConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.commonDelete),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || user.id == null) {
      return;
    }
    final success = await provider.deleteUser(user.id!);
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? l10n.commonSaveSuccess
              : (provider.error ?? l10n.commonSaveFailed),
        ),
      ),
    );
  }
}

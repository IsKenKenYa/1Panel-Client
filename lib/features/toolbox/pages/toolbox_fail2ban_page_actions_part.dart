part of 'toolbox_fail2ban_page.dart';

mixin _ToolboxFail2banPageActionsPart on State<ToolboxFail2banPage> {
  Future<void> _operateService(
    BuildContext context,
    ToolboxFail2banProvider provider,
    String operation,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    bool success;
    switch (operation) {
      case 'start':
        success = await provider.start();
        break;
      case 'stop':
        success = await provider.stop();
        break;
      default:
        success = await provider.restart();
        break;
    }
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(success
            ? l10n.commonSaveSuccess
            : (provider.error ?? l10n.commonSaveFailed)),
      ),
    );
  }

  Future<void> _toggleEnable(
    BuildContext context,
    ToolboxFail2banProvider provider,
    bool enabled,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.toggle(enabled);
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(success
            ? l10n.commonSaveSuccess
            : (provider.error ?? l10n.commonSaveFailed)),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    ToolboxFail2banProvider provider,
  ) async {
    final l10n = context.l10n;
    final base = provider.baseInfo;
    final bantimeController = TextEditingController(text: base.bantime ?? '');
    final findtimeController = TextEditingController(text: base.findtime ?? '');
    final maxretryController = TextEditingController(text: base.maxretry ?? '');
    final portController = TextEditingController(text: base.port ?? '');
    var enabled = base.isEnable ?? false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.toolboxFail2banEditConfig),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: enabled,
                  onChanged: (value) => setState(() => enabled = value),
                  title: Text(l10n.toolboxStatusLabel),
                ),
                TextField(
                  controller: bantimeController,
                  decoration:
                      InputDecoration(labelText: l10n.toolboxFail2banBantime),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: findtimeController,
                  decoration:
                      InputDecoration(labelText: l10n.toolboxFail2banFindtime),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxretryController,
                  decoration:
                      InputDecoration(labelText: l10n.toolboxFail2banMaxretry),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: portController,
                  decoration:
                      InputDecoration(labelText: l10n.toolboxFail2banPort),
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
                Navigator.pop(dialogContext);
                final success = await provider.saveConfig(
                  bantime: bantimeController.text,
                  findtime: findtimeController.text,
                  maxretry: maxretryController.text,
                  port: portController.text,
                  isEnable: enabled,
                );
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
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
      ),
    );
  }
}

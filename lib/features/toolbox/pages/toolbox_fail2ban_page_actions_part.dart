part of 'toolbox_fail2ban_page.dart';

mixin _ToolboxFail2banPageActionsPart on State<ToolboxFail2banPage> {
  Future<void> _operateService(
    BuildContext context,
    ToolboxFail2banProvider provider,
    String operation,
  ) async {
    final l10n = context.l10n;
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
    if (success) {
      SnackBarUtils.showSuccess(context, l10n.commonSaveSuccess);
    } else {
      SnackBarUtils.showError(context, provider.error ?? l10n.commonSaveFailed);
    }
  }

  Future<void> _toggleEnable(
    BuildContext context,
    ToolboxFail2banProvider provider,
    bool enabled,
  ) async {
    final l10n = context.l10n;
    final success = await provider.toggle(enabled);
    if (!context.mounted) {
      return;
    }
    if (success) {
      SnackBarUtils.showSuccess(context, l10n.commonSaveSuccess);
    } else {
      SnackBarUtils.showError(context, provider.error ?? l10n.commonSaveFailed);
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    ToolboxFail2banProvider provider,
  ) async {
    final l10n = context.l10n;
    final result =
        await showAdaptiveFormPanel<
          ({
            String bantime,
            String findtime,
            String maxretry,
            String port,
            bool enabled,
          })
        >(context, builder: (_) => _Fail2banConfigForm(provider: provider));
    if (result == null || !context.mounted) return;
    final success = await provider.saveConfig(
      bantime: result.bantime,
      findtime: result.findtime,
      maxretry: result.maxretry,
      port: result.port,
      isEnable: result.enabled,
    );
    if (!context.mounted) return;
    if (success) {
      SnackBarUtils.showSuccess(context, l10n.commonSaveSuccess);
    } else {
      SnackBarUtils.showError(context, provider.error ?? l10n.commonSaveFailed);
    }
  }
}

class _Fail2banConfigForm extends StatefulWidget {
  const _Fail2banConfigForm({required this.provider});

  final ToolboxFail2banProvider provider;

  @override
  State<_Fail2banConfigForm> createState() => _Fail2banConfigFormState();
}

class _Fail2banConfigFormState extends State<_Fail2banConfigForm> {
  late final _bantimeController = TextEditingController(
    text: widget.provider.baseInfo.bantime ?? '',
  );
  late final _findtimeController = TextEditingController(
    text: widget.provider.baseInfo.findtime ?? '',
  );
  late final _maxretryController = TextEditingController(
    text: widget.provider.baseInfo.maxretry ?? '',
  );
  late final _portController = TextEditingController(
    text: widget.provider.baseInfo.port ?? '',
  );
  late bool _enabled = widget.provider.baseInfo.isEnable ?? false;

  @override
  void dispose() {
    _bantimeController.dispose();
    _findtimeController.dispose();
    _maxretryController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.toolboxFail2banEditConfig,
      confirmLabel: l10n.commonSave,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
            title: Text(l10n.toolboxStatusLabel),
          ),
          TextField(
            controller: _bantimeController,
            decoration: InputDecoration(labelText: l10n.toolboxFail2banBantime),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _findtimeController,
            decoration: InputDecoration(
              labelText: l10n.toolboxFail2banFindtime,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxretryController,
            decoration: InputDecoration(
              labelText: l10n.toolboxFail2banMaxretry,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portController,
            decoration: InputDecoration(labelText: l10n.toolboxFail2banPort),
          ),
        ],
      ),
      onConfirm: () async => Navigator.of(context).pop((
        bantime: _bantimeController.text,
        findtime: _findtimeController.text,
        maxretry: _maxretryController.text,
        port: _portController.text,
        enabled: _enabled,
      )),
    );
  }
}

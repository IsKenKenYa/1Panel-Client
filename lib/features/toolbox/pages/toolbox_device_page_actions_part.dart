part of 'toolbox_device_page.dart';

mixin _ToolboxDevicePageActionsPart on State<ToolboxDevicePage> {
  Future<void> _showEditDialog(
    BuildContext context,
    ToolboxDeviceProvider provider,
  ) async {
    final l10n = context.l10n;
    final result =
        await showAdaptiveFormPanel<
          ({String hostname, String dns, String ntp, String swap})
        >(context, builder: (_) => _DeviceConfigForm(provider: provider));
    if (result == null || !context.mounted) return;
    final success = await provider.saveConfig(
      hostname: result.hostname,
      dns: result.dns,
      ntp: result.ntp,
      swap: result.swap,
    );
    if (!context.mounted) return;
    SnackBarUtils.showSuccess(
      context,
      success
          ? l10n.commonSaveSuccess
          : (provider.error ?? l10n.commonSaveFailed),
    );
  }

  Future<void> _checkDns(
    BuildContext context,
    ToolboxDeviceProvider provider,
  ) async {
    final l10n = context.l10n;
    final success = await provider.checkDns(
      provider.dns == '-' ? '' : provider.dns,
    );
    if (!context.mounted) {
      return;
    }
    SnackBarUtils.showSuccess(
      context,
      success
          ? l10n.toolboxDeviceCheckDnsSuccess
          : (provider.error == 'dns-empty'
                ? l10n.toolboxDeviceDnsRequired
                : l10n.toolboxDeviceCheckDnsFailed),
    );
  }

  Future<void> _showPasswordDialog(
    BuildContext context,
    ToolboxDeviceProvider provider,
  ) async {
    final l10n = context.l10n;
    await showAdaptiveFormPanel<void>(
      context,
      builder: (_) => _DevicePasswordForm(
        onSubmit: (oldPassword, newPassword, confirmPassword) async {
          final success = await provider.changePassword(
            oldPassword: oldPassword,
            newPassword: newPassword,
            confirmPassword: confirmPassword,
          );
          if (context.mounted) {
            if (success) {
              SnackBarUtils.showSuccess(context, l10n.commonSaveSuccess);
            } else {
              SnackBarUtils.showError(
                context,
                _localizedError(
                  context,
                  provider.error ?? l10n.commonSaveFailed,
                ),
              );
            }
          }
          return success;
        },
      ),
    );
  }

  Future<void> _showSwapDialog(
    BuildContext context,
    ToolboxDeviceProvider provider,
  ) async {
    final l10n = context.l10n;
    await showAppTextInputDialog(
      context,
      title: l10n.toolboxDeviceSwap,
      initialValue: provider.swap == '-' ? '' : provider.swap,
      labelText: l10n.toolboxDeviceSwap,
      confirmLabel: l10n.commonSave,
      autofocus: false,
      trim: false,
      allowEmpty: true,
      onSubmit: (value) async {
        final success = await provider.updateSwap(value);
        if (context.mounted) {
          if (success) {
            SnackBarUtils.showSuccess(context, l10n.commonSaveSuccess);
          } else {
            SnackBarUtils.showError(
              context,
              _localizedError(context, provider.error ?? l10n.commonSaveFailed),
            );
          }
        }
        return success;
      },
    );
  }

  String _localizedError(BuildContext context, String error) {
    final l10n = context.l10n;
    switch (error) {
      case 'dns-empty':
        return l10n.toolboxDeviceDnsRequired;
      case 'swap-empty':
        return l10n.toolboxDeviceSwap;
      case 'password-empty':
        return l10n.authPasswordRequired;
      case 'password-too-short':
        return l10n.securitySettingsPasswordPolicy;
      case 'password-mismatch':
        return l10n.securitySettingsPasswordMismatch;
      default:
        return error;
    }
  }
}

class _DeviceConfigForm extends StatefulWidget {
  const _DeviceConfigForm({required this.provider});

  final ToolboxDeviceProvider provider;

  @override
  State<_DeviceConfigForm> createState() => _DeviceConfigFormState();
}

class _DeviceConfigFormState extends State<_DeviceConfigForm> {
  late final _hostnameController = TextEditingController(
    text: widget.provider.hostname == '-' ? '' : widget.provider.hostname,
  );
  late final _dnsController = TextEditingController(
    text: widget.provider.dns == '-' ? '' : widget.provider.dns,
  );
  late final _ntpController = TextEditingController(
    text: widget.provider.ntp == '-' ? '' : widget.provider.ntp,
  );
  late final _swapController = TextEditingController(
    text: widget.provider.swap == '-' ? '' : widget.provider.swap,
  );

  @override
  void dispose() {
    _hostnameController.dispose();
    _dnsController.dispose();
    _ntpController.dispose();
    _swapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.toolboxDeviceEditConfig,
      confirmLabel: l10n.commonSave,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _hostnameController,
            decoration: InputDecoration(labelText: l10n.toolboxDeviceHostname),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dnsController,
            decoration: InputDecoration(labelText: l10n.toolboxDeviceDns),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ntpController,
            decoration: InputDecoration(labelText: l10n.toolboxDeviceNtp),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _swapController,
            decoration: InputDecoration(labelText: l10n.toolboxDeviceSwap),
          ),
        ],
      ),
      onConfirm: () async => Navigator.of(context).pop((
        hostname: _hostnameController.text,
        dns: _dnsController.text,
        ntp: _ntpController.text,
        swap: _swapController.text,
      )),
    );
  }
}

class _DevicePasswordForm extends StatefulWidget {
  const _DevicePasswordForm({required this.onSubmit});

  final Future<bool> Function(
    String oldPassword,
    String newPassword,
    String confirmPassword,
  )
  onSubmit;

  @override
  State<_DevicePasswordForm> createState() => _DevicePasswordFormState();
}

class _DevicePasswordFormState extends State<_DevicePasswordForm> {
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.securitySettingsChangePassword,
      confirmLabel: l10n.commonSave,
      isSaving: _saving,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _oldController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.securitySettingsOldPassword,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.securitySettingsNewPassword,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.securitySettingsConfirmPassword,
            ),
          ),
        ],
      ),
      onConfirm: () async {
        if (_saving) return;
        setState(() => _saving = true);
        try {
          final success = await widget.onSubmit(
            _oldController.text,
            _newController.text,
            _confirmController.text,
          );
          if (success &&
              context.mounted &&
              ModalRoute.of(context)?.isCurrent == true) {
            Navigator.of(context).pop();
          }
        } finally {
          if (mounted) setState(() => _saving = false);
        }
      },
    );
  }
}

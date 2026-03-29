part of 'toolbox_device_page.dart';

mixin _ToolboxDevicePageActionsPart on State<ToolboxDevicePage> {
  Future<void> _showEditDialog(
    BuildContext context,
    ToolboxDeviceProvider provider,
  ) async {
    final l10n = context.l10n;
    final hostnameController = TextEditingController(
      text: provider.hostname == '-' ? '' : provider.hostname,
    );
    final dnsController = TextEditingController(
      text: provider.dns == '-' ? '' : provider.dns,
    );
    final ntpController = TextEditingController(
      text: provider.ntp == '-' ? '' : provider.ntp,
    );
    final swapController = TextEditingController(
      text: provider.swap == '-' ? '' : provider.swap,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.toolboxDeviceEditConfig),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hostnameController,
                decoration: InputDecoration(labelText: l10n.toolboxDeviceHostname),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dnsController,
                decoration: InputDecoration(labelText: l10n.toolboxDeviceDns),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ntpController,
                decoration: InputDecoration(labelText: l10n.toolboxDeviceNtp),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: swapController,
                decoration: InputDecoration(labelText: l10n.toolboxDeviceSwap),
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
                hostname: hostnameController.text,
                dns: dnsController.text,
                ntp: ntpController.text,
                swap: swapController.text,
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
    );
  }

  Future<void> _checkDns(
    BuildContext context,
    ToolboxDeviceProvider provider,
  ) async {
    final l10n = context.l10n;
    final success =
        await provider.checkDns(provider.dns == '-' ? '' : provider.dns);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? l10n.toolboxDeviceCheckDnsSuccess
              : (provider.error == 'dns-empty'
                  ? l10n.toolboxDeviceDnsRequired
                  : l10n.toolboxDeviceCheckDnsFailed),
        ),
      ),
    );
  }

  Future<void> _showPasswordDialog(
    BuildContext context,
    ToolboxDeviceProvider provider,
  ) async {
    final l10n = context.l10n;
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.securitySettingsChangePassword),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldController,
                obscureText: true,
                decoration:
                    InputDecoration(labelText: l10n.securitySettingsOldPassword),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                decoration:
                    InputDecoration(labelText: l10n.securitySettingsNewPassword),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.securitySettingsConfirmPassword,
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
              final success = await provider.changePassword(
                oldPassword: oldController.text,
                newPassword: newController.text,
                confirmPassword: confirmController.text,
              );
              if (!context.mounted) {
                return;
              }
              if (success) {
                Navigator.pop(dialogContext);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? l10n.commonSaveSuccess
                        : _localizedError(
                            context,
                            provider.error ?? l10n.commonSaveFailed,
                          ),
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

  Future<void> _showSwapDialog(
    BuildContext context,
    ToolboxDeviceProvider provider,
  ) async {
    final l10n = context.l10n;
    final swapController = TextEditingController(
      text: provider.swap == '-' ? '' : provider.swap,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.toolboxDeviceSwap),
        content: TextField(
          controller: swapController,
          decoration: InputDecoration(labelText: l10n.toolboxDeviceSwap),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final success = await provider.updateSwap(swapController.text);
              if (!context.mounted) {
                return;
              }
              if (success) {
                Navigator.pop(dialogContext);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? l10n.commonSaveSuccess
                        : _localizedError(
                            context,
                            provider.error ?? l10n.commonSaveFailed,
                          ),
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

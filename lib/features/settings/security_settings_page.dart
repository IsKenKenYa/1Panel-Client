import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';
import 'package:provider/provider.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SettingsProvider>().loadPasskeys();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final provider = context.watch<SettingsProvider>();
    final settings = provider.data.systemSettings;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.securitySettingsTitle)),
      body: ListView(
        padding: AppDesignTokens.pagePadding,
        children: [
          _buildSectionTitle(
              context, l10n.securitySettingsPasswordSection, theme),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(l10n.securitySettingsChangePassword),
                  subtitle: Text(l10n.securitySettingsChangePasswordDesc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPasswordDialog(context, provider, l10n),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _buildSectionTitle(context, l10n.securitySettingsMfaSection, theme),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.security_outlined),
                  title: Text(l10n.securitySettingsMfaStatus),
                  subtitle: Text(
                    _isEnabled(settings?.mfaStatus)
                        ? l10n.systemSettingsEnabled
                        : l10n.systemSettingsDisabled,
                  ),
                  value: _isEnabled(settings?.mfaStatus),
                  onChanged: (value) =>
                      _showMfaToggleDialog(context, provider, l10n, value),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _buildSectionTitle(
              context, l10n.securitySettingsPasskeySection, theme),
          _buildPasskeyCard(context, provider, l10n),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _buildSectionTitle(
              context, l10n.securitySettingsAccessControl, theme),
          Card(
            child: Column(
              children: [
                _buildInfoListTile(
                  title: l10n.securitySettingsSecurityEntrance,
                  value: settings?.securityEntrance ?? '-',
                  icon: Icons.login_outlined,
                  onTap: () => _showSystemSettingEditDialog(
                    context,
                    provider,
                    l10n,
                    title: l10n.securitySettingsSecurityEntrance,
                    settingKey: 'SecurityEntrance',
                    currentValue: settings?.securityEntrance ?? '',
                  ),
                ),
                _buildInfoListTile(
                  title: l10n.securitySettingsBindDomain,
                  value: settings?.bindDomain ?? '-',
                  icon: Icons.domain_outlined,
                  onTap: () => _showSystemSettingEditDialog(
                    context,
                    provider,
                    l10n,
                    title: l10n.securitySettingsBindDomain,
                    settingKey: 'BindDomain',
                    currentValue: settings?.bindDomain ?? '',
                  ),
                ),
                _buildInfoListTile(
                  title: l10n.securitySettingsAllowIPs,
                  value: settings?.allowIPs ?? '-',
                  icon: Icons.list_alt_outlined,
                  onTap: () => _showSystemSettingEditDialog(
                    context,
                    provider,
                    l10n,
                    title: l10n.securitySettingsAllowIPs,
                    settingKey: 'AllowIPs',
                    currentValue: settings?.allowIPs ?? '',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _buildSectionTitle(
              context, l10n.securitySettingsPasswordPolicy, theme),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.password_outlined),
                  title: Text(l10n.securitySettingsComplexityVerification),
                  subtitle: Text(
                    _isEnabled(settings?.complexityVerification)
                        ? l10n.systemSettingsEnabled
                        : l10n.systemSettingsDisabled,
                  ),
                  value: _isEnabled(settings?.complexityVerification),
                  onChanged: (value) => _updateSystemSwitch(
                    context,
                    provider,
                    settingKey: 'ComplexityVerification',
                    value: value,
                  ),
                ),
                _buildInfoListTile(
                  title: l10n.securitySettingsExpirationDays,
                  value: settings?.expirationDays ?? '-',
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _showSystemSettingEditDialog(
                    context,
                    provider,
                    l10n,
                    title: l10n.securitySettingsExpirationDays,
                    settingKey: 'ExpirationDays',
                    currentValue: settings?.expirationDays ?? '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasskeyCard(
    BuildContext context,
    SettingsProvider provider,
    AppLocalizations l10n,
  ) {
    final data = provider.data;
    final deletingId = data.passkeyDeletingId;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.phonelink_lock_outlined),
            title: Text(l10n.securitySettingsPasskeyRegister),
            subtitle: Text(
              data.isPasskeySupported
                  ? l10n.securitySettingsPasskeyRegisterDesc
                  : (data.passkeyUnsupportedReason ??
                      l10n.securitySettingsPasskeyUnsupported),
            ),
            trailing: data.isPasskeyRegistering
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            onTap: data.isPasskeySupported && !data.isPasskeyRegistering
                ? () => _showPasskeyRegisterDialog(context, provider, l10n)
                : null,
          ),
          if (data.isPasskeysLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (!data.isPasskeySupported)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.securitySettingsPasskeyUnsupported),
              subtitle: Text(
                data.passkeyUnsupportedReason ??
                    l10n.securitySettingsPasskeyUnsupportedDesc,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.refresh_outlined),
                onPressed: () => provider.loadPasskeys(),
                tooltip: l10n.systemSettingsRefresh,
              ),
            )
          else if (data.passkeys.isEmpty)
            ListTile(
              leading: const Icon(Icons.key_off_outlined),
              title: Text(l10n.securitySettingsPasskeyEmpty),
              trailing: IconButton(
                icon: const Icon(Icons.refresh_outlined),
                onPressed: () => provider.loadPasskeys(),
                tooltip: l10n.systemSettingsRefresh,
              ),
            )
          else
            ...data.passkeys.map(
              (item) => ListTile(
                leading: const Icon(Icons.key_outlined),
                title: Text(item.name?.trim().isNotEmpty == true
                    ? item.name!
                    : (item.id ?? '-')),
                subtitle: Text(_formatPasskeySubtitle(item, l10n)),
                trailing: deletingId == item.id
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: item.id == null
                            ? null
                            : () => _showDeletePasskeyDialog(
                                  context,
                                  provider,
                                  l10n,
                                  item,
                                ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatPasskeySubtitle(PasskeyInfo item, AppLocalizations l10n) {
    final createdAt = item.createdAt ?? '-';
    final lastUsedAt = item.lastUsedAt ?? '-';
    return '${l10n.securitySettingsPasskeyCreatedAt}: $createdAt\n'
        '${l10n.securitySettingsPasskeyLastUsedAt}: $lastUsedAt';
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignTokens.spacingSm),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoListTile({
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  bool _isEnabled(String? value) {
    if (value == null) return false;
    return value.toLowerCase() == 'enable' || value.toLowerCase() == 'true';
  }

  Future<void> _updateSystemSwitch(
    BuildContext context,
    SettingsProvider provider, {
    required String settingKey,
    required bool value,
  }) async {
    final success = await provider.updateSystemSetting(
      settingKey,
      value ? 'Enable' : 'Disable',
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? context.l10n.commonSaveSuccess
              : context.l10n.commonSaveFailed,
        ),
      ),
    );
  }

  void _showPasskeyRegisterDialog(
    BuildContext context,
    SettingsProvider provider,
    AppLocalizations l10n,
  ) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.securitySettingsPasskeyRegister),
        content: TextField(
          controller: controller,
          maxLength: 64,
          decoration: InputDecoration(
            labelText: l10n.securitySettingsPasskeyName,
            hintText: l10n.securitySettingsPasskeyNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final success = await provider.registerPasskey(controller.text);
              if (!dialogContext.mounted) {
                return;
              }
              final message = success
                  ? l10n.commonSaveSuccess
                  : (provider.data.error ?? l10n.commonSaveFailed);
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text(message)),
              );
              if (success) {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
  }

  void _showDeletePasskeyDialog(
    BuildContext context,
    SettingsProvider provider,
    AppLocalizations l10n,
    PasskeyInfo item,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.securitySettingsPasskeyDeleteTitle),
        content: Text(
          l10n.securitySettingsPasskeyDeleteMessage(
            item.name?.trim().isNotEmpty == true
                ? item.name!
                : (item.id ?? '-'),
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
              final id = item.id;
              if (id == null || id.isEmpty) {
                return;
              }
              final success = await provider.deletePasskey(id);
              if (!context.mounted) {
                return;
              }
              final message = success
                  ? l10n.commonDelete
                  : (provider.data.error ?? l10n.commonSaveFailed);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }

  void _showSystemSettingEditDialog(
    BuildContext context,
    SettingsProvider provider,
    AppLocalizations l10n, {
    required String title,
    required String settingKey,
    required String currentValue,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: title),
          keyboardType: keyboardType,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final value = controller.text.trim();
              final success = await provider.updateSystemSetting(
                settingKey,
                value,
              );
              if (!dialogContext.mounted) {
                return;
              }
              Navigator.pop(dialogContext);
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? l10n.commonSaveSuccess : l10n.commonSaveFailed,
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

  void _showPasswordDialog(
    BuildContext context,
    SettingsProvider provider,
    AppLocalizations l10n,
  ) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.securitySettingsChangePassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: obscureOld,
                decoration: InputDecoration(
                  labelText: l10n.securitySettingsOldPassword,
                  suffixIcon: IconButton(
                    icon: Icon(obscureOld
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => obscureOld = !obscureOld),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: l10n.securitySettingsNewPassword,
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: l10n.securitySettingsConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.securitySettingsPasswordMismatch),
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                final success = await provider.updatePassword(
                  oldPasswordController.text,
                  newPasswordController.text,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? l10n.commonSaveSuccess
                            : l10n.commonSaveFailed,
                      ),
                    ),
                  );
                }
              },
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  void _showMfaToggleDialog(
    BuildContext context,
    SettingsProvider provider,
    AppLocalizations l10n,
    bool enable,
  ) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          enable
              ? l10n.securitySettingsMfaBind
              : l10n.securitySettingsMfaUnbind,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(enable
                ? l10n.securitySettingsEnableMfaConfirm
                : l10n.securitySettingsMfaUnbindDesc),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: l10n.securitySettingsMfaCode,
                hintText: l10n.securitySettingsMfaCodeHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success;
              if (enable) {
                success = await provider.bindMfaWithCode(
                  codeController.text,
                  '',
                  '30',
                );
              } else {
                success = await provider.unbindMfa(codeController.text);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? l10n.commonSaveSuccess : l10n.commonSaveFailed,
                    ),
                  ),
                );
              }
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
  }
}

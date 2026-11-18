import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';
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
    final l10n = context.l10n;
    final provider = context.watch<SettingsProvider>();
    final settings = provider.data.systemSettings;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text(l10n.securitySettingsTitle)),
      body: ListView(
        padding: AppDesignTokens.pagePadding,
        children: [
          SectionEntryList(
            title: l10n.securitySettingsPasswordSection,
            items: [
              SectionEntryItem(
                icon: Icons.lock_outlined,
                title: l10n.securitySettingsChangePassword,
                subtitle: l10n.securitySettingsChangePasswordDesc,
                onTap: () => _showPasswordDialog(context, provider, l10n),
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          SectionCard(
            title: l10n.securitySettingsMfaSection,
            child: SwitchListTile(
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
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          SectionCard(
            title: l10n.securitySettingsPasskeySection,
            child: _buildPasskeyContent(context, provider, l10n),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          SectionEntryList(
            title: l10n.securitySettingsAccessControl,
            items: [
              _buildInfoEntry(
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
              _buildInfoEntry(
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
              _buildInfoEntry(
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
          const SizedBox(height: AppDesignTokens.spacingMd),
          SectionCard(
            title: l10n.securitySettingsPasswordPolicy,
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
                const Divider(height: 1),
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

  Widget _buildPasskeyContent(
    BuildContext context,
    SettingsProvider provider,
    AppLocalizations l10n,
  ) {
    final data = provider.data;
    final deletingId = data.passkeyDeletingId;

    return Column(
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
              : const Icon(Icons.add_outlined),
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
            leading: const Icon(Icons.info_outlined),
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
                      tooltip: context.l10n.commonDelete,
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
    );
  }

  /// 访问控制节条目：值 + 编辑图标（覆盖默认 chevron）。
  SectionEntryItem _buildInfoEntry({
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return SectionEntryItem(
      icon: icon,
      title: title,
      onTap: onTap,
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
    );
  }

  String _formatPasskeySubtitle(PasskeyInfo item, AppLocalizations l10n) {
    final createdAt = item.createdAt ?? '-';
    final lastUsedAt = item.lastUsedAt ?? '-';
    return '${l10n.securitySettingsPasskeyCreatedAt}: $createdAt\n'
        '${l10n.securitySettingsPasskeyLastUsedAt}: $lastUsedAt';
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

  // Server API uses both 'Enable'/'Disable' and 'true'/'false' across different settings.
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
    if (success) {
      SnackBarUtils.showSuccess(context, context.l10n.commonSaveSuccess);
    } else {
      SnackBarUtils.showError(context, context.l10n.commonSaveFailed);
    }
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
              if (success) {
                SnackBarUtils.showSuccess(
                    dialogContext, l10n.commonSaveSuccess);
              } else {
                SnackBarUtils.showError(
                    dialogContext, provider.data.error ?? l10n.commonSaveFailed);
              }
              if (success) {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
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
              if (success) {
                SnackBarUtils.showSuccess(context, l10n.commonDelete);
              } else {
                SnackBarUtils.showError(
                    context, provider.data.error ?? l10n.commonSaveFailed);
              }
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
              if (success) {
                SnackBarUtils.showSuccess(context, l10n.commonSaveSuccess);
              } else {
                SnackBarUtils.showError(context, l10n.commonSaveFailed);
              }
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
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
                    tooltip: context.l10n.commonShow,
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
                    tooltip: context.l10n.commonShow,
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
                    tooltip: context.l10n.commonShow,
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
                  SnackBarUtils.showError(
                      context, l10n.securitySettingsPasswordMismatch);
                  return;
                }
                Navigator.pop(context);
                final success = await provider.updatePassword(
                  oldPasswordController.text,
                  newPasswordController.text,
                );
                if (context.mounted) {
                  if (success) {
                    SnackBarUtils.showSuccess(
                        context, l10n.commonSaveSuccess);
                  } else {
                    SnackBarUtils.showError(
                        context, l10n.commonSaveFailed);
                  }
                }
              },
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      oldPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
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
                // Secret and interval are server-determined; client passes empty/defaults.
                success = await provider.bindMfaWithCode(
                  codeController.text,
                  '',
                  '30',
                );
              } else {
                success = await provider.unbindMfa(codeController.text);
              }
              if (context.mounted) {
                if (success) {
                  SnackBarUtils.showSuccess(
                      context, l10n.commonSaveSuccess);
                } else {
                  SnackBarUtils.showError(
                      context, l10n.commonSaveFailed);
                }
              }
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    ).whenComplete(codeController.dispose);
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';

class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

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
              context, l10n.securitySettingsAccessControl, theme),
          Card(
            child: Column(
              children: [
                _buildInfoListTile(
                  title: l10n.securitySettingsSecurityEntrance,
                  value: settings?.securityEntrance ?? '-',
                  icon: Icons.login_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.securitySettingsBindDomain,
                  value: settings?.bindDomain ?? '-',
                  icon: Icons.domain_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.securitySettingsAllowIPs,
                  value: settings?.allowIPs ?? '-',
                  icon: Icons.list_alt_outlined,
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
                _buildInfoListTile(
                  title: l10n.securitySettingsComplexityVerification,
                  value: _isEnabled(settings?.complexityVerification)
                      ? l10n.systemSettingsEnabled
                      : l10n.systemSettingsDisabled,
                  icon: Icons.password_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.securitySettingsExpirationDays,
                  value: settings?.expirationDays ?? '-',
                  icon: Icons.calendar_today_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      BuildContext context, String title, ThemeData theme) {
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
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(value, style: const TextStyle(color: Colors.grey)),
    );
  }

  bool _isEnabled(String? value) {
    if (value == null) return false;
    return value.toLowerCase() == 'enable' || value.toLowerCase() == 'true';
  }

  void _showPasswordDialog(
      BuildContext context, SettingsProvider provider, AppLocalizations l10n) {
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
                        content: Text(l10n.securitySettingsPasswordMismatch)),
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
                        content: Text(success
                            ? l10n.commonSaveSuccess
                            : l10n.commonSaveFailed)),
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

  void _showMfaToggleDialog(BuildContext context, SettingsProvider provider,
      AppLocalizations l10n, bool enable) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(enable
            ? l10n.securitySettingsMfaBind
            : l10n.securitySettingsMfaUnbind),
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
                    codeController.text, '', '30');
              } else {
                success = await provider.unbindMfa(codeController.text);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(success
                          ? l10n.commonSaveSuccess
                          : l10n.commonSaveFailed)),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';

class ApiKeySettingsPage extends StatelessWidget {
  const ApiKeySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final provider = context.watch<SettingsProvider>();
    final settings = provider.data.systemSettings;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.apiKeySettingsTitle)),
      body: ListView(
        padding: AppDesignTokens.pagePadding,
        children: [
          _buildSectionTitle(context, l10n.apiKeySettingsStatus, theme),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.key_outlined),
                  title: Text(l10n.apiKeySettingsEnabled),
                  subtitle: Text(
                    _isEnabled(settings?.apiInterfaceStatus)
                        ? l10n.systemSettingsEnabled
                        : l10n.systemSettingsDisabled,
                  ),
                  value: _isEnabled(settings?.apiInterfaceStatus),
                  onChanged: (value) =>
                      _toggleApiKey(context, provider, l10n, value),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _buildSectionTitle(context, l10n.apiKeySettingsInfo, theme),
          Card(
            child: Column(
              children: [
                _buildCopyListTile(
                  context,
                  title: l10n.apiKeySettingsKey,
                  value: settings?.apiKey ?? '-',
                  icon: Icons.vpn_key_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.apiKeySettingsIpWhitelist,
                  value: settings?.ipWhiteList ?? '-',
                  icon: Icons.list_alt_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.apiKeySettingsValidityTime,
                  value: settings?.apiKeyValidityTime ?? '-',
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _buildSectionTitle(context, l10n.apiKeySettingsActions, theme),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh_outlined),
                  title: Text(l10n.apiKeySettingsRegenerate),
                  subtitle: Text(l10n.apiKeySettingsRegenerateDesc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _regenerateApiKey(context, provider, l10n),
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

  Widget _buildCopyListTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.commonCopied)),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isEnabled(String? value) {
    if (value == null) return false;
    return value.toLowerCase() == 'enable' || value.toLowerCase() == 'true';
  }

  void _toggleApiKey(BuildContext context, SettingsProvider provider,
      AppLocalizations l10n, bool enable) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            enable ? l10n.apiKeySettingsEnable : l10n.apiKeySettingsDisable),
        content: Text(enable
            ? l10n.apiKeySettingsEnableConfirm
            : l10n.apiKeySettingsDisableConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final validityTimeStr =
          provider.data.systemSettings?.apiKeyValidityTime ?? '0';
      final validityTimeInt = int.tryParse(validityTimeStr) ?? 0;
      final success = await provider.updateApiConfig(
        status: enable ? 'Enable' : 'Disable',
        ipWhiteList: provider.data.systemSettings?.ipWhiteList ?? '0.0.0.0/0',
        validityTime: validityTimeInt,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  success ? l10n.commonSaveSuccess : l10n.commonSaveFailed)),
        );
      }
    }
  }

  void _regenerateApiKey(BuildContext context, SettingsProvider provider,
      AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.apiKeySettingsRegenerate),
        content: Text(l10n.apiKeySettingsRegenerateConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.generateApiKey();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(success
                  ? l10n.apiKeySettingsRegenerateSuccess
                  : l10n.commonSaveFailed)),
        );
      }
    }
  }
}

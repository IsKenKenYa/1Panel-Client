import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/theme/app_design_tokens.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/settings/settings_provider.dart';

class SslSettingsPage extends StatelessWidget {
  const SslSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final provider = context.watch<SettingsProvider>();
    final sslInfo = provider.data.sslInfo;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sslSettingsTitle)),
      body: ListView(
        padding: AppDesignTokens.pagePadding,
        children: [
          _buildSectionTitle(context, l10n.sslSettingsInfo, theme),
          Card(
            child: Column(
              children: [
                _buildInfoListTile(
                  title: l10n.sslSettingsDomain,
                  value: sslInfo?.domain ?? '-',
                  icon: Icons.domain_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.sslSettingsStatus,
                  value: sslInfo?.status ?? '-',
                  icon: Icons.verified_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.sslSettingsType,
                  value: sslInfo?.sslType ?? '-',
                  icon: Icons.category_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.sslSettingsProvider,
                  value: sslInfo?.provider ?? '-',
                  icon: Icons.business_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.sslSettingsExpiration,
                  value: sslInfo?.expirationDate ?? '-',
                  icon: Icons.calendar_today_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _buildSectionTitle(context, l10n.sslSettingsActions, theme),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_outlined),
                  title: Text(l10n.sslSettingsUpload),
                  subtitle: Text(l10n.sslSettingsUploadDesc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showUploadDialog(context, provider, l10n),
                ),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: Text(l10n.sslSettingsDownload),
                  subtitle: Text(l10n.sslSettingsDownloadDesc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _downloadSsl(context, provider, l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, ThemeData theme) {
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
      trailing: Text(value),
    );
  }

  void _showUploadDialog(BuildContext context, SettingsProvider provider, AppLocalizations l10n) {
    final domainController = TextEditingController();
    final certController = TextEditingController();
    final keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sslSettingsUpload),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: domainController,
                decoration: InputDecoration(
                  labelText: l10n.sslSettingsDomain,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: certController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l10n.sslSettingsCert,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l10n.sslSettingsKey,
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.updateSSL(
                domain: domainController.text,
                sslType: 'selfSigned',
                cert: certController.text,
                key: keyController.text,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? l10n.commonSaveSuccess : l10n.commonSaveFailed)),
                );
              }
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  void _downloadSsl(BuildContext context, SettingsProvider provider, AppLocalizations l10n) async {
    final success = await provider.downloadSSL();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? l10n.sslSettingsDownloadSuccess : l10n.commonSaveFailed)),
      );
    }
  }
}

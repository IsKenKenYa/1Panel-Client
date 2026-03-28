import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/monitoring/monitoring_provider.dart';

class MonitorSettingsPage extends StatelessWidget {
  const MonitorSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final provider = context.watch<MonitoringProvider>();
    final settings = provider.data.settings;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.monitorSettingsTitle)),
      body: ListView(
        padding: AppDesignTokens.pagePadding,
        children: [
          _buildSectionTitle(context, l10n.monitorSettings, theme),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.monitor_heart_outlined),
                  title: Text(l10n.monitorSettingsEnable),
                  value: settings?.enabled ?? true,
                  onChanged: (value) async {
                    final success =
                        await provider.updateSettings(enabled: value);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(success
                                ? l10n.monitorSettingsSaved
                                : l10n.monitorSettingsFailed)),
                      );
                    }
                  },
                ),
                _buildEditableListTile(
                  context,
                  title: l10n.monitorSettingsInterval,
                  value:
                      '${settings?.interval ?? 300} ${l10n.monitorIntervalUnit}',
                  icon: Icons.timer_outlined,
                  onTap: () => _showEditDialog(
                    context,
                    provider,
                    l10n.monitorSettingsInterval,
                    'interval',
                    settings?.interval ?? 300,
                  ),
                ),
                _buildEditableListTile(
                  context,
                  title: l10n.monitorSettingsStoreDays,
                  value:
                      '${settings?.retention ?? 30} ${l10n.monitorRetentionUnit}',
                  icon: Icons.storage_outlined,
                  onTap: () => _showEditDialog(
                    context,
                    provider,
                    l10n.monitorSettingsStoreDays,
                    'retention',
                    settings?.retention ?? 30,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(l10n.monitorCleanData,
                  style: const TextStyle(color: Colors.red)),
              onTap: () => _showCleanConfirmDialog(context, provider),
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

  Widget _buildEditableListTile(
    BuildContext context, {
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
          Text(value, style: const TextStyle(color: Colors.grey)),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  void _showEditDialog(
    BuildContext context,
    MonitoringProvider provider,
    String title,
    String key,
    int currentValue,
  ) {
    final controller = TextEditingController(text: currentValue.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: title),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final value = int.tryParse(controller.text);
              if (value == null) return;

              bool success;
              if (key == 'interval') {
                success = await provider.updateSettings(interval: value);
              } else if (key == 'retention') {
                success = await provider.updateSettings(retention: value);
              } else {
                return;
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(success
                          ? context.l10n.monitorSettingsSaved
                          : context.l10n.monitorSettingsFailed)),
                );
              }
            },
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
  }

  void _showCleanConfirmDialog(
      BuildContext context, MonitoringProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.monitorCleanData),
        content: Text(context.l10n.monitorCleanConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.cleanData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(success
                          ? context.l10n.monitorCleanSuccess
                          : context.l10n.monitorCleanFailed)),
                );
              }
            },
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
  }
}

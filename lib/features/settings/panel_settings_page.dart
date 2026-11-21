import 'package:flutter/material.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';

class PanelSettingsPage extends StatelessWidget {
  const PanelSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<SettingsProvider>();
    final settings = provider.data.systemSettings;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text(l10n.panelSettingsTitle)),
      body: ListView(
        padding: AppDesignTokens.pagePadding,
        children: [
          SectionTitle(l10n.panelSettingsBasicInfo),
          Card(
            child: Column(
              children: [
                _buildInfoListTile(
                  title: l10n.panelSettingsPanelName,
                  value: settings?.panelName ?? '-',
                  icon: Icons.label_outline,
                ),
                _buildInfoListTile(
                  title: l10n.panelSettingsVersion,
                  value: settings?.systemVersion ?? '-',
                  icon: Icons.info_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.panelSettingsPort,
                  value: settings?.serverPort ?? '-',
                  icon: Icons.router_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.panelSettingsBindAddress,
                  value: settings?.bindAddress ?? '-',
                  icon: Icons.lan_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          SectionTitle(l10n.panelSettingsAdvanced),
          Card(
            child: Column(
              children: [
                _buildInfoListTile(
                  title: l10n.panelSettingsDeveloperMode,
                  value: _isEnabled(settings?.developerMode)
                      ? l10n.systemSettingsEnabled
                      : l10n.systemSettingsDisabled,
                  icon: Icons.code_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.panelSettingsIpv6,
                  value: _isEnabled(settings?.ipv6)
                      ? l10n.systemSettingsEnabled
                      : l10n.systemSettingsDisabled,
                  icon: Icons.network_check_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.panelSettingsSessionTimeout,
                  value: l10n
                      .panelSettingsMinutes(settings?.sessionTimeout ?? '30'),
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
          ),
        ],
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
}

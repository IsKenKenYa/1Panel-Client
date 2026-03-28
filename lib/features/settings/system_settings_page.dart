import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/settings/menu_settings_page.dart';
import 'package:onepanel_client/features/settings/panel_settings_page.dart';
import 'package:onepanel_client/features/settings/security_settings_page.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';
import 'package:onepanel_client/features/settings/snapshot_page.dart';
import 'package:onepanel_client/features/settings/terminal_settings_page.dart';
import 'package:onepanel_client/features/settings/api_key_settings_page.dart';
import 'package:onepanel_client/features/settings/ssl_settings_page.dart';
import 'package:onepanel_client/features/settings/upgrade_page.dart';
import 'package:onepanel_client/features/settings/monitor_settings_page.dart';
import 'package:onepanel_client/features/settings/proxy_settings_page.dart';
import 'package:onepanel_client/features/settings/backup_account_page.dart';
import 'package:onepanel_client/features/monitoring/monitoring_provider.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  late SettingsProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = SettingsProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.load();
    });
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.systemSettingsTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () => _provider.refresh(),
              tooltip: l10n.systemSettingsRefresh,
            ),
          ],
        ),
        body: Consumer<SettingsProvider>(
          builder: (context, provider, child) {
            if (provider.data.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.data.error != null) {
              return _buildErrorView(context, provider, l10n);
            }

            return _buildSettingsList(context, provider, theme, l10n);
          },
        ),
      ),
    );
  }

  Widget _buildErrorView(
      BuildContext context, SettingsProvider provider, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(l10n.systemSettingsLoadFailed),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => provider.load(),
            child: Text(l10n.commonRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(
    BuildContext context,
    SettingsProvider provider,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final settings = provider.data.systemSettings;
    final lastUpdated = provider.data.lastUpdated;

    return ListView(
      padding: AppDesignTokens.pagePadding,
      children: [
        if (settings != null) ...[
          _buildInfoCard(context, settings, theme, l10n),
          const SizedBox(height: AppDesignTokens.spacingMd),
        ],
        _buildSectionTitle(context, l10n.systemSettingsPanelSection, theme),
        Card(
          child: Column(
            children: [
              _buildSettingTile(
                context,
                icon: Icons.dns_outlined,
                title: l10n.systemSettingsPanelConfig,
                subtitle: l10n.systemSettingsPanelConfigDesc,
                onTap: () => _navigateTo(context, const PanelSettingsPage()),
              ),
              _buildSettingTile(
                context,
                icon: Icons.terminal_outlined,
                title: l10n.systemSettingsTerminal,
                subtitle: l10n.systemSettingsTerminalDesc,
                onTap: () => _navigateTo(context, const TerminalSettingsPage()),
              ),
              _buildSettingTile(
                context,
                icon: Icons.vpn_lock_outlined,
                title: l10n.proxySettingsTitle,
                subtitle:
                    settings?.proxyUrl != null && settings!.proxyUrl!.isNotEmpty
                        ? l10n.systemSettingsEnabled
                        : l10n.systemSettingsDisabled,
                onTap: () => _navigateTo(context, const ProxySettingsPage()),
              ),
              _buildSettingTile(
                context,
                icon: Icons.view_sidebar_outlined,
                title: l10n.menuSettingsTitle,
                subtitle: l10n.menuSettingsDescription,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.menuSettings),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDesignTokens.spacingMd),
        _buildSectionTitle(context, l10n.systemSettingsSecuritySection, theme),
        Card(
          child: Column(
            children: [
              _buildSettingTile(
                context,
                icon: Icons.security_outlined,
                title: l10n.systemSettingsSecurityConfig,
                subtitle: l10n.systemSettingsSecurityConfigDesc,
                onTap: () => _navigateTo(context, const SecuritySettingsPage()),
              ),
              _buildSettingTile(
                context,
                icon: Icons.key_outlined,
                title: l10n.systemSettingsApiKey,
                subtitle: _isEnabled(settings?.apiInterfaceStatus)
                    ? l10n.systemSettingsEnabled
                    : l10n.systemSettingsDisabled,
                onTap: () => _navigateTo(context, const ApiKeySettingsPage()),
              ),
              _buildSettingTile(
                context,
                icon: Icons.lock_outlined,
                title: l10n.sslSettingsTitle,
                subtitle: _isEnabled(settings?.ssl)
                    ? l10n.systemSettingsEnabled
                    : l10n.systemSettingsDisabled,
                onTap: () => _navigateTo(context, const SslSettingsPage()),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDesignTokens.spacingMd),
        _buildSectionTitle(context, l10n.systemSettingsSystemSection, theme),
        Card(
          child: Column(
            children: [
              _buildSettingTile(
                context,
                icon: Icons.system_update_outlined,
                title: l10n.systemSettingsUpgrade,
                subtitle: settings?.systemVersion ?? '-',
                onTap: () => _navigateTo(context, const UpgradePage()),
              ),
              _buildSettingTile(
                context,
                icon: Icons.monitor_heart_outlined,
                title: l10n.monitorSettingsTitle,
                subtitle: l10n.monitorSettings,
                onTap: () => _navigateToWithProvider<MonitoringProvider>(
                  context,
                  const MonitorSettingsPage(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDesignTokens.spacingMd),
        _buildSectionTitle(context, l10n.systemSettingsBackupSection, theme),
        Card(
          child: Column(
            children: [
              _buildSettingTile(
                context,
                icon: Icons.backup_outlined,
                title: l10n.systemSettingsSnapshot,
                subtitle: l10n.systemSettingsSnapshotDesc,
                onTap: () => _navigateTo(context, const SnapshotPage()),
              ),
              _buildSettingTile(
                context,
                icon: Icons.cloud_outlined,
                title: '备份账户',
                subtitle: '管理备份存储账户',
                onTap: () => _navigateTo(context, const BackupAccountPage()),
              ),
            ],
          ),
        ),
        if (lastUpdated != null) ...[
          const SizedBox(height: AppDesignTokens.spacingMd),
          Text(
            l10n.systemSettingsLastUpdated(_formatTime(lastUpdated)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppDesignTokens.spacingLg),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    dynamic settings,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: AppDesignTokens.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  settings.panelName ?? l10n.systemSettingsPanelName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.systemSettingsSystemVersion}: ${settings.systemVersion ?? "-"}',
              style: theme.textTheme.bodyMedium,
            ),
            if (settings.mfaStatus != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${l10n.systemSettingsMfaStatus}: ',
                    style: theme.textTheme.bodyMedium,
                  ),
                  _buildStatusChip(
                    context,
                    _isEnabled(settings.mfaStatus),
                    l10n,
                  ),
                ],
              ),
            ],
          ],
        ),
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

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  Widget _buildStatusChip(
      BuildContext context, bool isEnabled, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isEnabled
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isEnabled ? l10n.systemSettingsEnabled : l10n.systemSettingsDisabled,
        style: TextStyle(
          fontSize: 12,
          color: isEnabled ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  bool _isEnabled(String? value) {
    if (value == null) return false;
    return value.toLowerCase() == 'enable' || value.toLowerCase() == 'true';
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: _provider,
          child: page,
        ),
      ),
    );
  }

  void _navigateToWithProvider<T extends ChangeNotifier>(
      BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<T>.value(
          value: context.read<T>(),
          child: page,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

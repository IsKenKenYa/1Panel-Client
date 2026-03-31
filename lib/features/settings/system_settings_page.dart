import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
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
import 'package:onepanel_client/core/services/logger/log_export_service.dart';
import 'package:onepanel_client/core/services/logger/log_file_manager_service.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key, this.provider});

  final SettingsProvider? provider;

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  late SettingsProvider _provider;
  late bool _ownsProvider;

  @override
  void initState() {
    super.initState();
    _ownsProvider = widget.provider == null;
    _provider = widget.provider ?? SettingsProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.load();
    });
  }

  @override
  void dispose() {
    if (_ownsProvider) {
      _provider.dispose();
    }
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
                icon: Icons.storefront_outlined,
                title: l10n.appStoreTitle,
                subtitle:
                    _extractAppStoreUrl(provider.data.appStoreConfig) ??
                        l10n.systemSettingsNotSet,
                onTap: () => _showAppStoreConfigDialog(context, provider, l10n),
              ),
              _buildSettingTile(
                context,
                icon: Icons.settings_ethernet_outlined,
                title: l10n.operationsSshTitle,
                subtitle: _formatSshConnectionSummary(
                  provider.data.sshConnection,
                  l10n,
                ),
                onTap: () => _showSshConnectionDialog(context, provider, l10n),
              ),
              _buildSettingTile(
                context,
                icon: Icons.device_hub_outlined,
                title: l10n.sshSettingsNetworkSectionTitle,
                subtitle:
                    _formatNetworkInterfacesSummary(provider.data.networkInterfaces, l10n),
                onTap: () => _showNetworkInterfacesDialog(context, provider, l10n),
              ),
              _buildSettingTile(
                context,
                icon: Icons.view_sidebar_outlined,
                title: l10n.menuSettingsTitle,
                subtitle: l10n.menuSettingsDescription,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.menuSettings),
              ),
              _buildSettingTile(
                context,
                icon: Icons.sticky_note_2_outlined,
                title: l10n.systemSettingsDashboardMemo,
                subtitle: _formatMemoSummary(provider.data.dashboardMemo, l10n),
                onTap: () => _showDashboardMemoDialog(context, provider, l10n),
              ),
              _buildSettingTile(
                context,
                icon: Icons.download_outlined,
                title: '导出应用日志',
                subtitle: '导出本地调试日志文件',
                onTap: () => _exportAppLogs(context),
              ),
              _buildSettingTile(
                context,
                icon: Icons.delete_sweep_outlined,
                title: '清理应用日志',
                subtitle: '删除本地持久化日志',
                onTap: () => _clearAppLogs(context),
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

  String? _extractAppStoreUrl(dynamic config) {
    if (config is! Map) {
      return null;
    }
    final map = config.cast<dynamic, dynamic>();
    final value = map['storeUrl'] ?? map['url'] ?? map['storeURL'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  String _formatSshConnectionSummary(
    dynamic connection,
    AppLocalizations l10n,
  ) {
    if (connection is! Map) {
      return l10n.systemSettingsNotSet;
    }

    final map = connection.cast<dynamic, dynamic>();
    final host = map['host']?.toString();
    final port = map['port']?.toString();
    final user = map['user']?.toString();

    if (host == null || host.isEmpty) {
      return l10n.systemSettingsNotSet;
    }
    final portText = (port == null || port.isEmpty) ? '' : ':$port';
    final userText = (user == null || user.isEmpty) ? '' : ' ($user)';
    return '$host$portText$userText';
  }

  String _formatNetworkInterfacesSummary(
    List<String>? interfaces,
    AppLocalizations l10n,
  ) {
    if (interfaces == null || interfaces.isEmpty) {
      return l10n.commonEmpty;
    }
    if (interfaces.length <= 2) {
      return interfaces.join(', ');
    }
    final preview = interfaces.take(2).join(', ');
    final remain = interfaces.length - 2;
    return '$preview +$remain';
  }

  String _formatMemoSummary(String? memo, AppLocalizations l10n) {
    final value = memo?.trim() ?? '';
    if (value.isEmpty) {
      return l10n.systemSettingsNotSet;
    }
    if (value.length <= 36) {
      return value;
    }
    return '${value.substring(0, 36)}...';
  }

  Future<void> _showDashboardMemoDialog(
    BuildContext context,
    SettingsProvider provider,
    AppLocalizations l10n,
  ) async {
    await provider.loadDashboardMemo();
    if (!context.mounted) {
      return;
    }

    final controller = TextEditingController(text: provider.data.dashboardMemo);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.systemSettingsDashboardMemo),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: l10n.systemSettingsDashboardMemoHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await provider.updateDashboardMemo(controller.text);
              if (!dialogContext.mounted) {
                return;
              }
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content:
                      Text(ok ? l10n.commonSaveSuccess : l10n.commonSaveFailed),
                ),
              );
              if (ok) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  Future<void> _showAppStoreConfigDialog(
    BuildContext context,
    SettingsProvider provider,
    AppLocalizations l10n,
  ) async {
    await provider.loadAppStoreConfig();
    if (!context.mounted) {
      return;
    }

    final initialUrl = _extractAppStoreUrl(provider.data.appStoreConfig) ?? '';
    final controller = TextEditingController(text: initialUrl);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.appStoreTitle),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Store URL',
            hintText: 'https://',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await provider.updateAppStoreConfig(
                controller.text.trim().isEmpty ? null : controller.text.trim(),
              );
              if (!dialogContext.mounted) {
                return;
              }
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content:
                      Text(ok ? l10n.commonSaveSuccess : l10n.commonSaveFailed),
                ),
              );
              if (ok) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  Future<void> _showSshConnectionDialog(
    BuildContext context,
    SettingsProvider provider,
    AppLocalizations l10n,
  ) async {
    await provider.loadSSHConnection();
    if (!context.mounted) {
      return;
    }

    final connection = provider.data.sshConnection;
    final map = connection is Map ? connection.cast<dynamic, dynamic>() : null;

    final hostController =
        TextEditingController(text: map?['host']?.toString() ?? '');
    final portController =
        TextEditingController(text: map?['port']?.toString() ?? '22');
    final userController =
        TextEditingController(text: map?['user']?.toString() ?? '');
    final passwordController =
        TextEditingController(text: map?['password']?.toString() ?? '');
    final privateKeyController =
        TextEditingController(text: map?['privateKey']?.toString() ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.operationsSshTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hostController,
                decoration: const InputDecoration(
                  labelText: 'Host',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Port',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: userController,
                decoration: const InputDecoration(
                  labelText: 'User',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: privateKeyController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Private Key',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await provider.saveSSHConnection(
                host: hostController.text.trim().isEmpty
                    ? null
                    : hostController.text.trim(),
                port: int.tryParse(portController.text.trim()),
                user: userController.text.trim().isEmpty
                    ? null
                    : userController.text.trim(),
                password: passwordController.text,
                privateKey: privateKeyController.text.trim().isEmpty
                    ? null
                    : privateKeyController.text.trim(),
              );
              if (!dialogContext.mounted) {
                return;
              }
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content:
                      Text(ok ? l10n.commonSaveSuccess : l10n.commonSaveFailed),
                ),
              );
              if (ok) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );

    hostController.dispose();
    portController.dispose();
    userController.dispose();
    passwordController.dispose();
    privateKeyController.dispose();
  }

  Future<void> _showNetworkInterfacesDialog(
    BuildContext context,
    SettingsProvider provider,
    AppLocalizations l10n,
  ) async {
    await provider.loadNetworkInterfaces();
    if (!context.mounted) {
      return;
    }
    final interfaces = provider.data.networkInterfaces ?? const <String>[];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.sshSettingsNetworkSectionTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: interfaces.isEmpty
              ? Text(l10n.commonEmpty)
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: interfaces.length,
                  itemBuilder: (context, index) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.lan_outlined),
                    title: Text(interfaces[index]),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonClose),
          ),
        ],
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

  Future<void> _exportAppLogs(BuildContext context) async {
    final l10n = context.l10n;
    final result = await LogExportService().exportLogs();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? '${l10n.commonSaveSuccess}: ${result.filePath ?? ''}'
              : '${l10n.commonSaveFailed}: ${result.errorMessage ?? ''}',
        ),
      ),
    );
  }

  Future<void> _clearAppLogs(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('清理应用日志'),
            content: const Text('确定删除本地应用日志吗？此操作不可恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.commonConfirm),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await LogFileManagerService().clearLogs();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('应用日志已清理')),
    );
  }
}

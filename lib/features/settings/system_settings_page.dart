import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/settings/panel_settings_page.dart';
import 'package:onepanel_client/features/settings/security_settings_page.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';
import 'package:onepanel_client/features/settings/snapshot_page.dart';
import 'package:onepanel_client/features/settings/terminal_settings_page.dart';
import 'package:onepanel_client/features/settings/upgrade_page.dart';
import 'package:onepanel_client/features/settings/monitor_settings_page.dart';
import 'package:onepanel_client/features/settings/proxy_settings_page.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';
import 'package:onepanel_client/data/models/setting_models.dart';

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
    _provider = widget.provider ??
        SettingsProvider.forServer(context.read<CurrentServerController>().currentServer!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _provider.load();
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
        backgroundColor: Theme.of(context).colorScheme.surface,
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
            final loaded = provider.data.lastUpdated != null;
            return PartialErrorToastListener(
              errorMessage: provider.loadError,
              hasCachedData: loaded,
              onRetry: provider.refresh,
              child: AsyncStatePageBodyWidget(
                isLoading: !loaded && provider.loadError == null,
                errorMessage: loaded ? null : provider.loadError,
                onRetry: provider.refresh,
                child: AdaptiveWidthContainer(
                  maxWidth: AdaptiveLayoutSpec.of(context).settingsBodyMaxWidth,
                  child: _buildSettingsList(context, provider, theme, l10n),
                ),
              ),
            );
          },
        ),
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
        SectionEntryList(
          title: l10n.systemSettingsPanelSection,
          items: [
            SectionEntryItem(
              icon: Icons.dns_outlined,
              title: l10n.systemSettingsPanelConfig,
              subtitle: l10n.systemSettingsPanelConfigDesc,
              onTap: () => _navigateTo(context, const PanelSettingsPage()),
            ),
            SectionEntryItem(
              icon: Icons.storefront_outlined,
              title: l10n.appStoreTitle,
              subtitle: _extractAppStoreUrl(provider.data.appStoreConfig),
              onTap: () => _showAppStoreConfigDialog(context, provider, l10n),
            ),
            SectionEntryItem(
              icon: Icons.view_sidebar_outlined,
              title: l10n.menuSettingsTitle,
              subtitle: l10n.menuSettingsDescription,
              onTap: () =>
                  openRouteRespectingShell(context, AppRoutes.menuSettings),
            ),
            SectionEntryItem(
              icon: Icons.sticky_note_2_outlined,
              title: l10n.systemSettingsDashboardMemo,
              subtitle: provider.data.dashboardMemo == null
                  ? null : _formatMemoSummary(provider.data.dashboardMemo, l10n),
              onTap: () => _showDashboardMemoDialog(context, provider, l10n),
            ),
          ],
        ),
        const SizedBox(height: AppDesignTokens.spacingMd),
        SectionEntryList(
          title: l10n.systemSettingsConnectionsSection,
          items: [
            SectionEntryItem(
              icon: Icons.terminal_outlined,
              title: l10n.systemSettingsTerminal,
              subtitle: l10n.systemSettingsTerminalDesc,
              onTap: () =>
                  _navigateTo(context, TerminalSettingsPage(provider: provider)),
            ),
            SectionEntryItem(
              icon: Icons.vpn_lock_outlined,
              title: l10n.proxySettingsTitle,
              subtitle:
                  settings?.proxyUrl != null && settings!.proxyUrl!.isNotEmpty
                      ? l10n.systemSettingsEnabled
                      : l10n.systemSettingsDisabled,
              onTap: () => _navigateTo(context, const ProxySettingsPage()),
            ),
            SectionEntryItem(
              icon: Icons.settings_ethernet_outlined,
              title: l10n.operationsSshTitle,
              subtitle: provider.data.sshConnection?.summary,
              onTap: () => showTerminalConnectionDialog(context, provider),
            ),
            SectionEntryItem(
              icon: Icons.device_hub_outlined,
              title: l10n.sshSettingsNetworkSectionTitle,
              subtitle: provider.data.networkInterfaces == null
                  ? null : _formatNetworkInterfacesSummary(provider.data.networkInterfaces, l10n),
              onTap: () =>
                  _showNetworkInterfacesDialog(context, provider, l10n),
            ),
          ],
        ),
        const SizedBox(height: AppDesignTokens.spacingMd),
        SectionEntryList(
          title: l10n.systemSettingsSecuritySection,
          items: [
            SectionEntryItem(
              icon: Icons.security_outlined,
              title: l10n.systemSettingsSecurityConfig,
              subtitle: l10n.systemSettingsSecurityConfigDesc,
              onTap: () => _navigateTo(context, const SecuritySettingsPage()),
            ),
            SectionEntryItem(
              icon: Icons.lock_outlined,
              title: l10n.sslSettingsTitle,
              subtitle: settings?.ssl == 'Mux' || _isEnabled(settings?.ssl)
                  ? l10n.systemSettingsEnabled
                  : l10n.systemSettingsDisabled,
              onTap: () => openRouteRespectingShell(context, AppRoutes.panelSsl),
            ),
          ],
        ),
        const SizedBox(height: AppDesignTokens.spacingMd),
        SectionEntryList(
          title: l10n.systemSettingsSystemSection,
          items: [
            SectionEntryItem(
              icon: Icons.system_update_outlined,
              title: l10n.systemSettingsUpgrade,
              subtitle: settings?.systemVersion ?? '-',
              onTap: () => _navigateTo(context, const UpgradePage()),
            ),
            SectionEntryItem(
              icon: Icons.monitor_heart_outlined,
              title: l10n.monitorSettingsTitle,
              onTap: () => MonitorSettingsPage.open(context),
            ),
          ],
        ),
        const SizedBox(height: AppDesignTokens.spacingMd),
        SectionEntryList(
          title: l10n.systemSettingsBackupSection,
          items: [
            SectionEntryItem(
              icon: Icons.backup_outlined,
              title: l10n.systemSettingsSnapshot,
              subtitle: l10n.systemSettingsSnapshotDesc,
              onTap: () => _navigateTo(context, const SnapshotPage()),
            ),
            SectionEntryItem(
              icon: Icons.cloud_outlined,
              title: l10n.systemSettingsBackupAccountTitle,
              subtitle: l10n.systemSettingsBackupAccountDesc,
              onTap: () => openRouteRespectingShell(context, AppRoutes.backups),
            ),
          ],
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
    SystemSettingInfo settings,
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
                  Icons.info_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    settings.panelName ?? l10n.systemSettingsPanelName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.systemSettingsSystemVersion}: ${settings.systemVersion ?? "-"}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // Server API uses inconsistent field names across versions for the store URL.
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
    final loaded = await provider.loadDashboardMemo();
    if (!context.mounted) {
      return;
    }
    if (!loaded) {
      SnackBarUtils.showError(context, provider.data.error ?? l10n.systemSettingsLoadFailed);
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
              if (ok) {
                SnackBarUtils.showSuccess(
                    dialogContext, l10n.commonSaveSuccess);
                Navigator.of(dialogContext).pop();
              } else {
                SnackBarUtils.showError(
                    dialogContext, l10n.commonSaveFailed);
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
    final loaded = await provider.loadAppStoreConfig();
    if (!context.mounted) {
      return;
    }

    if (!loaded) {
      SnackBarUtils.showError(context, provider.data.error ?? l10n.systemSettingsLoadFailed);
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
          decoration: InputDecoration(
            labelText: l10n.appStoreTitle,
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
              if (ok) {
                SnackBarUtils.showSuccess(
                    dialogContext, l10n.commonSaveSuccess);
                Navigator.of(dialogContext).pop();
              } else {
                SnackBarUtils.showError(
                    dialogContext, l10n.commonSaveFailed);
              }
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  Future<void> _showNetworkInterfacesDialog(
    BuildContext context,
    SettingsProvider provider,
    AppLocalizations l10n,
  ) async {
    final loaded = await provider.loadNetworkInterfaces();
    if (!context.mounted) {
      return;
    }
    if (!loaded) {
      SnackBarUtils.showError(context, provider.data.error ?? l10n.systemSettingsLoadFailed);
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

  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

}

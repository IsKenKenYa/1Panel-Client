import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_device_provider.dart';
import 'package:onepanel_client/features/toolbox/widgets/toolbox_device_info_widget.dart';
import 'package:provider/provider.dart';

part 'toolbox_device_page_actions_part.dart';

class ToolboxDevicePage extends StatefulWidget {
  const ToolboxDevicePage({super.key});

  @override
  State<ToolboxDevicePage> createState() => _ToolboxDevicePageState();
}

class _ToolboxDevicePageState extends State<ToolboxDevicePage>
  with _ToolboxDevicePageActionsPart {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ToolboxDeviceProvider>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<ToolboxDeviceProvider>();

    return ServerAwarePageScaffold(
      title: l10n.toolboxDeviceTitle,
      onServerChanged: () => context.read<ToolboxDeviceProvider>().load(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (provider.isLoading) const LinearProgressIndicator(),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _localizedError(context, provider.error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ToolboxDeviceSectionCardWidget(
            title: l10n.toolboxDeviceOverviewTitle,
            child: Column(
              children: [
                ToolboxDeviceInfoRowWidget(
                    label: l10n.toolboxDeviceHostname,
                    value: provider.hostname),
                ToolboxDeviceInfoRowWidget(
                    label: l10n.toolboxDeviceDns, value: provider.dns),
                ToolboxDeviceInfoRowWidget(
                    label: l10n.toolboxDeviceNtp, value: provider.ntp),
                ToolboxDeviceInfoRowWidget(
                    label: l10n.toolboxDeviceSwap, value: provider.swap),
                ToolboxDeviceInfoRowWidget(
                  label: l10n.toolboxDeviceTimeLabel,
                  value: provider.baseInfo.localTime ?? '-',
                ),
                ToolboxDeviceInfoRowWidget(
                  label: l10n.toolboxDeviceSystemLabel,
                  value: provider.baseInfo.systemName ?? '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ToolboxDeviceSectionCardWidget(
            title: l10n.toolboxDeviceConfigTitle,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: provider.isBusy
                      ? null
                      : () => _showEditDialog(context, provider),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.toolboxDeviceEditConfig),
                ),
                OutlinedButton.icon(
                  onPressed: provider.isCheckingDns
                      ? null
                      : () => _checkDns(context, provider),
                  icon: const Icon(Icons.network_check_outlined),
                  label: Text(l10n.toolboxDeviceCheckDns),
                ),
                OutlinedButton.icon(
                  onPressed: provider.isUpdatingPassword
                      ? null
                      : () => _showPasswordDialog(context, provider),
                  icon: const Icon(Icons.password_outlined),
                  label: Text(l10n.securitySettingsChangePassword),
                ),
                OutlinedButton.icon(
                  onPressed: provider.isUpdatingSwap
                      ? null
                      : () => _showSwapDialog(context, provider),
                  icon: const Icon(Icons.swap_horiz_outlined),
                  label: Text(l10n.toolboxDeviceSwap),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ToolboxDeviceSectionCardWidget(
            title: l10n.toolboxDeviceUsersTitle,
            child: provider.users.isEmpty
                ? Text(l10n.commonEmpty)
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final user in provider.users)
                        Chip(label: Text(user)),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          ToolboxDeviceSectionCardWidget(
            title: l10n.toolboxDeviceZoneOptionsTitle,
            child: provider.zoneOptions.isEmpty
                ? Text(l10n.commonEmpty)
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final zone in provider.zoneOptions.take(12))
                        Chip(label: Text(zone)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

}

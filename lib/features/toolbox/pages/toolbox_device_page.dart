import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_device_provider.dart';
import 'package:provider/provider.dart';

class ToolboxDevicePage extends StatefulWidget {
  const ToolboxDevicePage({super.key});

  @override
  State<ToolboxDevicePage> createState() => _ToolboxDevicePageState();
}

class _ToolboxDevicePageState extends State<ToolboxDevicePage> {
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
          _SectionCard(
            title: l10n.toolboxDeviceOverviewTitle,
            child: Column(
              children: [
                _InfoRow(
                    label: l10n.toolboxDeviceHostname,
                    value: provider.hostname),
                _InfoRow(label: l10n.toolboxDeviceDns, value: provider.dns),
                _InfoRow(label: l10n.toolboxDeviceNtp, value: provider.ntp),
                _InfoRow(label: l10n.toolboxDeviceSwap, value: provider.swap),
                _InfoRow(
                  label: l10n.toolboxDeviceTimeLabel,
                  value: provider.baseInfo.localTime ?? '-',
                ),
                _InfoRow(
                  label: l10n.toolboxDeviceSystemLabel,
                  value: provider.baseInfo.systemName ?? '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.toolboxDeviceConfigTitle,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: provider.isSaving
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
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
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
          _SectionCard(
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

  Future<void> _showEditDialog(
    BuildContext context,
    ToolboxDeviceProvider provider,
  ) async {
    final l10n = context.l10n;
    final hostnameController = TextEditingController(
      text: provider.hostname == '-' ? '' : provider.hostname,
    );
    final dnsController = TextEditingController(
      text: provider.dns == '-' ? '' : provider.dns,
    );
    final ntpController = TextEditingController(
      text: provider.ntp == '-' ? '' : provider.ntp,
    );
    final swapController = TextEditingController(
      text: provider.swap == '-' ? '' : provider.swap,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.toolboxDeviceEditConfig),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hostnameController,
                decoration:
                    InputDecoration(labelText: l10n.toolboxDeviceHostname),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dnsController,
                decoration: InputDecoration(labelText: l10n.toolboxDeviceDns),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ntpController,
                decoration: InputDecoration(labelText: l10n.toolboxDeviceNtp),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: swapController,
                decoration: InputDecoration(labelText: l10n.toolboxDeviceSwap),
              ),
            ],
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
              final success = await provider.saveConfig(
                hostname: hostnameController.text,
                dns: dnsController.text,
                ntp: ntpController.text,
                swap: swapController.text,
              );
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? l10n.commonSaveSuccess
                        : (provider.error ?? l10n.commonSaveFailed),
                  ),
                ),
              );
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Future<void> _checkDns(
    BuildContext context,
    ToolboxDeviceProvider provider,
  ) async {
    final l10n = context.l10n;
    final success =
        await provider.checkDns(provider.dns == '-' ? '' : provider.dns);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? l10n.toolboxDeviceCheckDnsSuccess
              : (provider.error == 'dns-empty'
                  ? l10n.toolboxDeviceDnsRequired
                  : l10n.toolboxDeviceCheckDnsFailed),
        ),
      ),
    );
  }

  String _localizedError(BuildContext context, String error) {
    if (error == 'dns-empty') {
      return context.l10n.toolboxDeviceDnsRequired;
    }
    return error;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

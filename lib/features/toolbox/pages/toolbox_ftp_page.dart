import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_ftp_provider.dart';
import 'package:onepanel_client/features/toolbox/widgets/toolbox_sections_widget.dart';
import 'package:provider/provider.dart';

class ToolboxFtpPage extends StatefulWidget {
  const ToolboxFtpPage({super.key});

  @override
  State<ToolboxFtpPage> createState() => _ToolboxFtpPageState();
}

class _ToolboxFtpPageState extends State<ToolboxFtpPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ToolboxFtpProvider>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<ToolboxFtpProvider>();
    final base = provider.baseInfo;

    return ServerAwarePageScaffold(
      title: l10n.toolboxFtpTitle,
      onServerChanged: () => context.read<ToolboxFtpProvider>().load(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (provider.isLoading) const LinearProgressIndicator(),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                provider.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ToolboxSectionCardWidget(
            title: l10n.toolboxCommonOverviewTitle,
            child: Column(
              children: [
                ToolboxInfoRowWidget(
                  label: l10n.toolboxStatusLabel,
                  value: base.status ?? '-',
                ),
                ToolboxInfoRowWidget(
                  label: l10n.toolboxVersionLabel,
                  value: base.version ?? '-',
                ),
                ToolboxInfoRowWidget(
                  label: l10n.toolboxFtpBaseDir,
                  value: base.baseDir ?? '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ToolboxSectionCardWidget(
            title: l10n.toolboxFtpUsersTitle,
            child: provider.users.isEmpty
                ? Text(l10n.commonEmpty)
                : Column(
                    children: [
                      for (final user in provider.users.take(12))
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(user.user ?? '-'),
                          subtitle: Text(user.path ?? '-'),
                          trailing: Text(user.status ?? '-'),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () => context.read<ToolboxFtpProvider>().load(),
                icon: const Icon(Icons.refresh_outlined),
                label: Text(l10n.commonRefresh),
              ),
              FilledButton.icon(
                onPressed: provider.isSyncing
                    ? null
                    : () async {
                        final success = await context
                            .read<ToolboxFtpProvider>()
                            .syncUsers();
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? l10n.toolboxFtpSyncSuccess
                                  : (provider.error ??
                                      l10n.toolboxFtpSyncFailed),
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.sync_outlined),
                label: Text(l10n.toolboxFtpSyncAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

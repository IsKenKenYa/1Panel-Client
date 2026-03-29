import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_fail2ban_provider.dart';
import 'package:onepanel_client/features/toolbox/widgets/toolbox_sections_widget.dart';
import 'package:provider/provider.dart';

part 'toolbox_fail2ban_page_actions_part.dart';

class ToolboxFail2banPage extends StatefulWidget {
  const ToolboxFail2banPage({super.key});

  @override
  State<ToolboxFail2banPage> createState() => _ToolboxFail2banPageState();
}

class _ToolboxFail2banPageState extends State<ToolboxFail2banPage>
  with _ToolboxFail2banPageActionsPart {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ToolboxFail2banProvider>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<ToolboxFail2banProvider>();
    final baseInfo = provider.baseInfo;

    return ServerAwarePageScaffold(
      title: l10n.toolboxFail2banTitle,
      onServerChanged: () => context.read<ToolboxFail2banProvider>().load(),
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
                  value: (baseInfo.isEnable ?? false)
                      ? l10n.toolboxStatusEnabled
                      : l10n.toolboxStatusDisabled,
                ),
                ToolboxInfoRowWidget(
                  label: l10n.toolboxVersionLabel,
                  value: baseInfo.version ?? '-',
                ),
                ToolboxInfoRowWidget(
                  label: l10n.toolboxFail2banBantime,
                  value: baseInfo.bantime ?? '-',
                ),
                ToolboxInfoRowWidget(
                  label: l10n.toolboxFail2banFindtime,
                  value: baseInfo.findtime ?? '-',
                ),
                ToolboxInfoRowWidget(
                  label: l10n.toolboxFail2banMaxretry,
                  value: baseInfo.maxretry ?? '-',
                ),
                ToolboxInfoRowWidget(
                  label: l10n.toolboxFail2banPort,
                  value: baseInfo.port ?? '-',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: provider.isBusy
                          ? null
                          : () => _operateService(context, provider, 'start'),
                      child: Text(l10n.commonStart),
                    ),
                    OutlinedButton(
                      onPressed: provider.isBusy
                          ? null
                          : () => _operateService(context, provider, 'stop'),
                      child: Text(l10n.commonStop),
                    ),
                    FilledButton(
                      onPressed: provider.isBusy
                          ? null
                          : () => _operateService(
                                context,
                                provider,
                                'restart',
                              ),
                      child: Text(l10n.commonRestart),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: baseInfo.isEnable ?? false,
                  onChanged: provider.isBusy
                      ? null
                      : (value) => _toggleEnable(context, provider, value),
                  title: Text(l10n.toolboxStatusLabel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ToolboxSectionCardWidget(
            title: l10n.toolboxFail2banConfigTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: provider.isBusy
                      ? null
                      : () => _showEditDialog(context, provider),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.toolboxFail2banEditConfig),
                ),
                const SizedBox(height: 12),
                Text(
                  provider.configText.isEmpty ? '-' : provider.configText,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ToolboxSectionCardWidget(
            title: l10n.toolboxCommonRecentRecordsTitle,
            child: provider.records.isEmpty
                ? Text(l10n.commonEmpty)
                : Column(
                    children: [
                      for (final record in provider.records.take(8))
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(record.ip ?? '-'),
                          subtitle: Text(record.createdAt ?? '-'),
                          trailing: Text(record.status ?? '-'),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

}

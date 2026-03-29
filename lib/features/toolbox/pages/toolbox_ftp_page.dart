import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_ftp_provider.dart';
import 'package:onepanel_client/features/toolbox/widgets/toolbox_sections_widget.dart';
import 'package:provider/provider.dart';

part 'toolbox_ftp_page_actions_part.dart';

class ToolboxFtpPage extends StatefulWidget {
  const ToolboxFtpPage({super.key});

  @override
  State<ToolboxFtpPage> createState() => _ToolboxFtpPageState();
}

class _ToolboxFtpPageState extends State<ToolboxFtpPage>
  with _ToolboxFtpPageActionsPart {
  final TextEditingController _keywordController = TextEditingController();

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _keywordController,
                        decoration: InputDecoration(
                          hintText: l10n.commonSearch,
                          isDense: true,
                        ),
                        onSubmitted: (value) async {
                          provider.setKeyword(value);
                          await provider.load();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: provider.isBusy
                          ? null
                          : () async {
                              provider.setKeyword(_keywordController.text);
                              await provider.load();
                            },
                      icon: const Icon(Icons.search),
                      tooltip: l10n.commonSearch,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (provider.users.isEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.commonEmpty),
                  )
                else
                  ...provider.users.map(
                    (user) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(user.user ?? '-'),
                      subtitle: Text(
                        '${l10n.commonPath}: ${user.path ?? '-'}\n'
                        '${l10n.toolboxFtpBaseDir}: ${user.baseDir ?? '-'}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showUserDialog(context, provider, existing: user);
                            return;
                          }
                          _confirmDeleteUser(context, provider, user);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text(l10n.commonEdit),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(l10n.commonDelete),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: provider.page > 1 && !provider.isBusy
                          ? () => provider.previousPage()
                          : null,
                      child: const Icon(Icons.chevron_left),
                    ),
                    const SizedBox(width: 12),
                    Text('${provider.page}'),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: provider.hasMoreUsers && !provider.isBusy
                          ? () => provider.nextPage()
                          : null,
                      child: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: provider.isBusy
                    ? null
                    : () => _showUserDialog(context, provider),
                icon: const Icon(Icons.add),
                label: Text(l10n.commonCreate),
              ),
              OutlinedButton.icon(
                onPressed: provider.isBusy
                    ? null
                    : () => context.read<ToolboxFtpProvider>().load(),
                icon: const Icon(Icons.refresh_outlined),
                label: Text(l10n.commonRefresh),
              ),
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
              OutlinedButton(
                onPressed: provider.isBusy
                    ? null
                    : () => _operateService(context, provider, 'restart'),
                child: Text(l10n.commonRestart),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ssh_log_models.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_logs_provider.dart';
import 'package:onepanel_client/features/ssh/widgets/ssh_log_card_widget.dart';
import 'package:onepanel_client/features/ssh/widgets/ssh_section_nav_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:provider/provider.dart';

class SshLogsPage extends StatefulWidget {
  const SshLogsPage({super.key});

  @override
  State<SshLogsPage> createState() => _SshLogsPageState();
}

class _SshLogsPageState extends State<SshLogsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<SshLogsProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<SshLogsProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: l10n.operationsSshLogsTitle,
          onServerChanged: () => context.read<SshLogsProvider>().load(),
          actions: <Widget>[
            IconButton(
              onPressed: provider.isExporting ? null : _exportLogs,
              icon: const Icon(Icons.download_outlined),
              tooltip: l10n.commonExport,
            ),
            IconButton(
              onPressed: provider.isLoading ? null : provider.load,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
          ],
          body: Column(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SshSectionNavWidget(currentRoute: '/ssh/logs'),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _searchController,
                      onChanged: provider.updateKeyword,
                      onSubmitted: (_) => provider.load(),
                      decoration: InputDecoration(
                        hintText: l10n.sshLogsSearchHint,
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        _statusChip(
                            provider, SshLogStatus.all, l10n.sshLogsStatusAll),
                        _statusChip(provider, SshLogStatus.success,
                            l10n.sshLogsStatusSuccess),
                        _statusChip(provider, SshLogStatus.failed,
                            l10n.sshLogsStatusFailed),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AsyncStatePageBodyWidget(
                  isLoading: provider.isLoading,
                  isEmpty: provider.isEmpty,
                  errorMessage: provider.errorMessage,
                  onRetry: provider.load,
                  emptyTitle: l10n.sshLogsEmptyTitle,
                  emptyDescription: l10n.sshLogsEmptyDescription,
                  child: RefreshIndicator(
                    onRefresh: provider.load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: provider.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = provider.items[index];
                        return SshLogCardWidget(
                          item: item,
                          onCopy: () => _copyItem(item),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(
      SshLogsProvider provider, SshLogStatus status, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: provider.statusFilter == status,
      onSelected: (_) async {
        provider.updateStatus(status);
        await provider.load();
      },
    );
  }

  Future<void> _copyItem(SshLogEntry item) async {
    await Clipboard.setData(
      ClipboardData(
        text:
            '${item.address}:${item.port}\n${item.user}\n${item.authMode}\n${item.status}\n${item.message}',
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.sshLogCopied)));
  }

  Future<void> _exportLogs() async {
    final result = await context.read<SshLogsProvider>().exportLogs();
    if (!mounted || result == null) return;
    final message = result.success
        ? context.l10n.sshLogsExportSaved(result.filePath ?? '')
        : (result.errorMessage ?? context.l10n.commonSaveFailed);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

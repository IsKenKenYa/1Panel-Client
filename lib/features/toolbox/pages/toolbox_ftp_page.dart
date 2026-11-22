import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_ftp_provider.dart';
import 'package:onepanel_client/features/toolbox/widgets/toolbox_sections_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/module_empty_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/snackbar_utils.dart';
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
      body: PartialErrorToastListener(
        errorMessage: provider.error,
        hasCachedData: provider.users.isNotEmpty || base.status != null,
        onRetry: () => context.read<ToolboxFtpProvider>().load(),
        child: ListView(
        padding: AppDesignTokens.cardPadding,
        children: [
          if (provider.isLoading) const LinearProgressIndicator(),
          SectionCard(
            title: l10n.toolboxCommonOverviewTitle,
            padding: AppDesignTokens.cardPadding,
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
          SectionCard(
            title: l10n.toolboxFtpUsersTitle,
            padding: AppDesignTokens.cardPadding,
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
                  ModuleEmptyStateWidget(
                    title: l10n.commonEmpty,
                    description: l10n.toolboxFtpUsersEmptyDesc,
                    icon: Icons.person_outline,
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
                            child: Text(
                              l10n.commonDelete,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (provider.users.isNotEmpty)
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
                icon: const Icon(Icons.add_outlined),
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
              OutlinedButton.icon(
                onPressed: provider.isSyncing
                    ? null
                    : () async {
                        final success = await context
                            .read<ToolboxFtpProvider>()
                            .syncUsers();
                        if (!context.mounted) {
                          return;
                        }
                        if (success) {
                          SnackBarUtils.showSuccess(
                            context,
                            l10n.toolboxFtpSyncSuccess,
                          );
                        } else {
                          SnackBarUtils.showError(
                            context,
                            provider.error ?? l10n.toolboxFtpSyncFailed,
                          );
                        }
                      },
                icon: const Icon(Icons.sync_outlined),
                label: Text(l10n.toolboxFtpSyncAction),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

}

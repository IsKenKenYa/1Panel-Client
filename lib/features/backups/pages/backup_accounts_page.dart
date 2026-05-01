import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/features/backups/models/backup_account_form_args.dart';
import 'package:onepanel_client/features/backups/models/backup_records_args.dart';
import 'package:onepanel_client/features/backups/models/backup_recover_args.dart';
import 'package:onepanel_client/features/backups/providers/backup_accounts_provider.dart';
import 'package:onepanel_client/features/backups/services/backup_account_service.dart';
import 'package:onepanel_client/features/backups/widgets/backup_account_card_widget.dart';
import 'package:onepanel_client/features/backups/widgets/backup_files_sheet_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/i18n/backup_l10n_helper.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

class BackupAccountsPage extends StatefulWidget {
  const BackupAccountsPage({super.key});

  @override
  State<BackupAccountsPage> createState() => _BackupAccountsPageState();
}

class _BackupAccountsPageState extends State<BackupAccountsPage> {
  late final TextEditingController _searchController;
  late final BackupAccountService _accountService;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _accountService = BackupAccountService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<BackupAccountsProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BackupAccountsProvider>(
      builder: (context, provider, _) {
        final l10n = context.l10n;
        return ServerAwarePageScaffold(
          title: l10n.operationsBackupsTitle,
          onServerChanged: () => context.read<BackupAccountsProvider>().load(),
          actions: <Widget>[
            PopupMenuButton<String?>(
              onSelected: (value) async {
                provider.updateTypeFilter(value);
                await provider.load();
              },
              itemBuilder: (context) => <PopupMenuEntry<String?>>[
                PopupMenuItem<String?>(
                  value: null,
                  child: Text(l10n.backupAccountsFilterAllTypes),
                ),
                for (final item in provider.availableTypes)
                  PopupMenuItem<String?>(
                    value: item,
                    child: Text(backupProviderLabel(l10n, item)),
                  ),
              ],
              icon: const Icon(Icons.filter_alt_outlined),
            ),
            IconButton(
              onPressed: provider.isLoading ? null : provider.load,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'backup_accounts_create_fab',
            onPressed: _openCreate,
            icon: const Icon(Icons.add),
            label: Text(l10n.commonCreate),
          ),
          body: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _searchController,
                      onChanged: provider.updateSearchQuery,
                      onSubmitted: (_) => provider.load(),
                      decoration: InputDecoration(
                        hintText: l10n.backupAccountsSearchHint,
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openRecords,
                            icon: const Icon(Icons.article_outlined),
                            label: Text(l10n.operationsBackupRecordsTitle),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openRecover,
                            icon: const Icon(Icons.restore_outlined),
                            label: Text(l10n.operationsBackupRecoverTitle),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AsyncStatePageBodyWidget(
                  isLoading: provider.isLoading,
                  isEmpty: provider.isEmpty,
                  errorMessage:
                      localizeBackupError(l10n, provider.errorMessage),
                  onRetry: provider.load,
                  emptyTitle: l10n.backupAccountsEmptyTitle,
                  emptyDescription: l10n.backupAccountsEmptyDescription,
                  child: RefreshIndicator(
                    onRefresh: provider.load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: provider.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final account = provider.items[index];
                        final readOnly =
                            _accountService.isReadOnlyLocal(account);
                        return BackupAccountCardWidget(
                          account: account,
                          endpoint: _accountService.endpointText(account),
                          scopeLabel: account.isPublic
                              ? l10n.backupAccountsScopePublic
                              : l10n.backupAccountsScopePrivate,
                          onEdit: readOnly ? null : () => _openEdit(account),
                          onTest: () => _test(account),
                          onBrowseFiles: () => _browseFiles(account),
                          onDelete: readOnly ? null : () => _delete(account),
                          onRefreshToken:
                              _accountService.supportsRefreshToken(account.type)
                                  ? () => _refreshToken(account)
                                  : null,
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

  Future<void> _openCreate() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.backupAccountForm,
      arguments: const BackupAccountFormArgs(),
    );
    if (!mounted) return;
    await context.read<BackupAccountsProvider>().load();
  }

  Future<void> _openEdit(BackupAccountInfo account) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.backupAccountForm,
      arguments: BackupAccountFormArgs(initialValue: account),
    );
    if (!mounted) return;
    await context.read<BackupAccountsProvider>().load();
  }

  Future<void> _openRecords() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.backupRecords,
      arguments: const BackupRecordsArgs(),
    );
  }

  Future<void> _openRecover() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.backupRecover,
      arguments: const BackupRecoverArgs(),
    );
  }

  Future<void> _test(BackupAccountInfo account) async {
    final result =
        await context.read<BackupAccountsProvider>().testAccount(account);
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localizeBackupError(context.l10n, result.msg) ??
              (result.isOk
                  ? context.l10n.backupAccountsConnectionOk
                  : context.l10n.backupAccountsConnectionFailed),
        ),
      ),
    );
  }

  Future<void> _refreshToken(BackupAccountInfo account) async {
    final success =
        await context.read<BackupAccountsProvider>().refreshToken(account);
    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.backupAccountsTokenRefreshed)),
    );
  }

  Future<void> _browseFiles(BackupAccountInfo account) async {
    final files =
        await context.read<BackupAccountsProvider>().loadFiles(account);
    if (!mounted || files == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => BackupFilesSheetWidget(
        title: account.name,
        items: files,
      ),
    );
  }

  Future<void> _delete(BackupAccountInfo account) async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.commonDelete,
      message: context.l10n.backupAccountsDeleteConfirm(account.name),
      confirmLabel: context.l10n.commonDelete,
      confirmIcon: Icons.delete_outline,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<BackupAccountsProvider>().deleteAccount(account);
  }
}

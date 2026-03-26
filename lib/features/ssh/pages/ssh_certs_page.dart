import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ssh_cert_models.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_certs_provider.dart';
import 'package:onepanel_client/features/ssh/widgets/ssh_cert_card_widget.dart';
import 'package:onepanel_client/features/ssh/widgets/ssh_cert_form_sheet_widget.dart';
import 'package:onepanel_client/features/ssh/widgets/ssh_section_nav_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

class SshCertsPage extends StatefulWidget {
  const SshCertsPage({super.key});

  @override
  State<SshCertsPage> createState() => _SshCertsPageState();
}

class _SshCertsPageState extends State<SshCertsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) return;
      context.read<SshCertsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<SshCertsProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: l10n.operationsSshCertsTitle,
          onServerChanged: () => context.read<SshCertsProvider>().load(),
          actions: <Widget>[
            IconButton(
              onPressed: provider.isMutating ? null : _syncCerts,
              icon: const Icon(Icons.sync),
              tooltip: l10n.commonRefresh,
            ),
            IconButton(
              onPressed: provider.isLoading ? null : provider.load,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreateSheet,
            icon: const Icon(Icons.add),
            label: Text(l10n.commonCreate),
          ),
          body: Column(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SshSectionNavWidget(currentRoute: '/ssh/certs'),
              ),
              Expanded(
                child: AsyncStatePageBodyWidget(
                  isLoading: provider.isLoading,
                  isEmpty: provider.isEmpty,
                  errorMessage: provider.errorMessage,
                  onRetry: provider.load,
                  emptyTitle: l10n.sshCertsEmptyTitle,
                  emptyDescription: l10n.sshCertsEmptyDescription,
                  emptyActionLabel: l10n.commonCreate,
                  onEmptyAction: _openCreateSheet,
                  child: RefreshIndicator(
                    onRefresh: provider.load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = provider.items[index];
                        return SshCertCardWidget(
                          item: item,
                          onEdit: () => _openEditSheet(item),
                          onDelete: () => _deleteCert(item),
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

  Future<void> _openCreateSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SshCertFormSheetWidget(
        title: context.l10n.sshCertCreateTitle,
        onSubmit: (request) => context.read<SshCertsProvider>().createCert(request),
      ),
    );
  }

  Future<void> _openEditSheet(SshCertInfo item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SshCertFormSheetWidget(
        title: context.l10n.sshCertEditTitle,
        initialValue: SshCertOperate(
          id: item.id,
          name: item.name,
          mode: 'input',
          encryptionMode: item.encryptionMode,
          passPhrase: item.passPhrase,
          publicKey: item.publicKey,
          privateKey: item.privateKey,
          description: item.description,
        ),
        onSubmit: (request) => context.read<SshCertsProvider>().updateCert(request),
      ),
    );
  }

  Future<void> _deleteCert(SshCertInfo item) async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.commonDelete,
      message: context.l10n.sshCertDeleteConfirm(item.name),
      confirmLabel: context.l10n.commonDelete,
      confirmIcon: Icons.delete_outline,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<SshCertsProvider>().deleteCert(item);
  }

  Future<void> _syncCerts() async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.operationsSshCertsTitle,
      message: context.l10n.sshCertSyncConfirm,
      confirmLabel: context.l10n.commonConfirm,
    );
    if (!confirmed || !mounted) return;
    await context.read<SshCertsProvider>().syncCerts();
  }
}

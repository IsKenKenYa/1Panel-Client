import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ssh_session_models.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_sessions_provider.dart';
import 'package:onepanel_client/features/ssh/widgets/ssh_section_nav_widget.dart';
import 'package:onepanel_client/features/ssh/widgets/ssh_session_card_widget.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';
import 'package:onepanel_client/shared/widgets/operations/page_visibility_listener.dart';
import 'package:provider/provider.dart';

class SshSessionsPage extends StatefulWidget {
  const SshSessionsPage({super.key});

  @override
  State<SshSessionsPage> createState() => _SshSessionsPageState();
}

class _SshSessionsPageState extends State<SshSessionsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connection = context.select(
      (CurrentServerController state) =>
          (state.currentServerId, state.currentServer?.revision),
    );
    return Consumer<SshSessionsProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: l10n.operationsSshSessionsTitle,
          actions: <Widget>[
            IconButton(
              onPressed: _openFilterSheet,
              icon: const Icon(Icons.filter_list_outlined),
              tooltip: l10n.commonSearch,
            ),
            IconButton(
              onPressed: provider.isLoading ? null : provider.refresh,
              icon: const Icon(Icons.refresh_outlined),
              tooltip: l10n.commonRefresh,
            ),
          ],
          body: PageVisibilityListener(
            key: ValueKey(connection),
            onChanged: provider.setPageVisible,
            child: Column(
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SshSectionNavWidget(currentRoute: '/ssh/sessions'),
                ),
                Expanded(
                  child: AsyncStatePageBodyWidget(
                    isLoading: provider.isLoading,
                    isEmpty: provider.isEmpty,
                    errorMessage: provider.errorMessage,
                    onRetry: provider.load,
                    emptyTitle: l10n.sshSessionsEmptyTitle,
                    emptyDescription: l10n.sshSessionsEmptyDescription,
                    child: RefreshIndicator(
                      onRefresh: provider.refresh,
                      child: ListView.separated(
                        padding: AppDesignTokens.cardPadding,
                        itemCount: provider.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = provider.items[index];
                          return SshSessionCardWidget(
                            item: item,
                            onDisconnect: () => _disconnect(item),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openFilterSheet() async {
    final provider = context.read<SshSessionsProvider>();
    final result = await showAdaptiveFormPanel<SshSessionQuery>(
      context,
      builder: (_) => _SshSessionFilterForm(initialQuery: provider.query),
    );
    if (result == null || !mounted) {
      return;
    }
    await provider.applyFilters(result);
  }

  Future<void> _disconnect(SshSessionInfo item) async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.commonStop,
      message: context.l10n.sshSessionDisconnectConfirm(item.username),
      confirmLabel: context.l10n.commonStop,
      confirmIcon: Icons.power_settings_new_outlined,
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    await context.read<SshSessionsProvider>().disconnectSession(item);
  }
}

class _SshSessionFilterForm extends StatefulWidget {
  const _SshSessionFilterForm({required this.initialQuery});

  final SshSessionQuery initialQuery;

  @override
  State<_SshSessionFilterForm> createState() => _SshSessionFilterFormState();
}

class _SshSessionFilterFormState extends State<_SshSessionFilterForm> {
  late final _loginUserController = TextEditingController(
    text: widget.initialQuery.loginUser,
  );
  late final _loginIpController = TextEditingController(
    text: widget.initialQuery.loginIP,
  );

  @override
  void dispose() {
    _loginUserController.dispose();
    _loginIpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.commonSearch,
      onConfirm: () async => Navigator.of(context).pop(
        SshSessionQuery(
          loginUser: _loginUserController.text.trim(),
          loginIP: _loginIpController.text.trim(),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _loginUserController,
            decoration: InputDecoration(
              labelText: l10n.sshSessionsLoginUserLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _loginIpController,
            decoration: InputDecoration(
              labelText: l10n.sshSessionsLoginIpLabel,
            ),
          ),
        ],
      ),
    );
  }
}

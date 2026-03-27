import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_detail_args.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_form_args.dart';
import 'package:onepanel_client/features/runtimes/providers/runtime_detail_provider.dart';
import 'package:onepanel_client/features/runtimes/utils/runtime_l10n_helper.dart';
import 'package:onepanel_client/features/runtimes/widgets/runtime_detail_advanced_tab_widget.dart';
import 'package:onepanel_client/features/runtimes/widgets/runtime_detail_config_tab_widget.dart';
import 'package:onepanel_client/features/runtimes/widgets/runtime_detail_overview_tab_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

class RuntimeDetailPage extends StatefulWidget {
  const RuntimeDetailPage({
    super.key,
    required this.args,
  });

  final RuntimeDetailArgs args;

  @override
  State<RuntimeDetailPage> createState() => _RuntimeDetailPageState();
}

class _RuntimeDetailPageState extends State<RuntimeDetailPage> {
  late final TextEditingController _remarkController;

  @override
  void initState() {
    super.initState();
    _remarkController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<RuntimeDetailProvider>().initialize(widget.args);
    });
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<RuntimeDetailProvider>(
      builder: (context, provider, _) {
        final runtime = provider.runtime;
        if (runtime != null &&
            _remarkController.text != (runtime.remark ?? '')) {
          _remarkController.text = runtime.remark ?? '';
        }
        return DefaultTabController(
          length: 3,
          child: ServerAwarePageScaffold(
            title: runtime?.name ?? l10n.operationsRuntimeDetailTitle,
            onServerChanged: () =>
                context.read<RuntimeDetailProvider>().initialize(widget.args),
            actions: <Widget>[
              if (runtime != null)
                IconButton(
                  onPressed: provider.canEdit()
                      ? () => Navigator.pushNamed(
                            context,
                            AppRoutes.runtimeForm,
                            arguments: RuntimeFormArgs(runtimeId: runtime.id),
                          )
                      : null,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.commonEdit,
                ),
              IconButton(
                onPressed: provider.isSyncing ? null : _sync,
                icon: const Icon(Icons.sync),
                tooltip: l10n.runtimeActionSync,
              ),
            ],
            bottom: TabBar(
              tabs: <Tab>[
                Tab(text: l10n.runtimeOverviewTab),
                Tab(text: l10n.runtimeConfigTab),
                Tab(text: l10n.runtimeAdvancedTab),
              ],
            ),
            body: AsyncStatePageBodyWidget(
              isLoading: provider.isLoading,
              isEmpty: provider.isEmpty,
              errorMessage: localizeRuntimeError(l10n, provider.errorMessage),
              onRetry: provider.load,
              emptyTitle: l10n.runtimeEmptyTitle,
              emptyDescription: l10n.runtimeEmptyDescription,
              child: runtime == null
                  ? const SizedBox.shrink()
                  : TabBarView(
                      children: <Widget>[
                        RuntimeDetailOverviewTabWidget(
                          runtime: runtime,
                          canStart: provider.canStart(),
                          canStop: provider.canStop(),
                          canRestart: provider.canRestart(),
                          onStart: () => _operate('up'),
                          onStop: () => _operate('down'),
                          onRestart: () => _operate('restart'),
                        ),
                        RuntimeDetailConfigTabWidget(runtime: runtime),
                        RuntimeDetailAdvancedTabWidget(
                          runtime: runtime,
                          remarkController: _remarkController,
                          onSaveRemark: _saveRemark,
                          canOpenAdvanced: provider.canOpenAdvanced(),
                          isSavingRemark: provider.isSavingRemark,
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sync() async {
    await context.read<RuntimeDetailProvider>().syncStatus();
  }

  Future<void> _operate(String action) async {
    final l10n = context.l10n;
    final provider = context.read<RuntimeDetailProvider>();
    final runtime = provider.runtime;
    if (runtime == null) return;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: runtimeOperateLabel(l10n, action),
      message: l10n.runtimeOperateConfirm(
        runtimeOperateLabel(l10n, action),
        runtime.name ?? '-',
      ),
      confirmLabel: runtimeOperateLabel(l10n, action),
      confirmIcon: action == 'up'
          ? Icons.play_arrow_outlined
          : action == 'down'
              ? Icons.stop_outlined
              : Icons.restart_alt_outlined,
    );
    if (!confirmed || !mounted) return;
    await provider.operate(action);
  }

  Future<void> _saveRemark() async {
    await context
        .read<RuntimeDetailProvider>()
        .updateRemark(_remarkController.text);
  }
}

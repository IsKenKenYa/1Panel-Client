import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_detail_args.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_form_args.dart';
import 'package:onepanel_client/features/runtimes/providers/runtimes_provider.dart';
import 'package:onepanel_client/features/runtimes/utils/runtime_l10n_helper.dart';
import 'package:onepanel_client/features/runtimes/widgets/runtime_summary_card_widget.dart';
import 'package:onepanel_client/features/runtimes/widgets/runtime_type_selector_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

class RuntimesCenterPage extends StatefulWidget {
  const RuntimesCenterPage({super.key});

  @override
  State<RuntimesCenterPage> createState() => _RuntimesCenterPageState();
}

class _RuntimesCenterPageState extends State<RuntimesCenterPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<RuntimesProvider>().load();
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
    return Consumer<RuntimesProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: l10n.operationsRuntimesTitle,
          onServerChanged: () => context.read<RuntimesProvider>().load(),
          actions: <Widget>[
            IconButton(
              onPressed: provider.isSyncing ? null : _sync,
              icon: const Icon(Icons.sync),
              tooltip: l10n.runtimeActionSync,
            ),
            IconButton(
              onPressed: provider.isLoading ? null : provider.load,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.runtimeForm,
                arguments: RuntimeFormArgs(initialType: provider.selectedType),
              ),
              icon: const Icon(Icons.add),
              tooltip: l10n.commonCreate,
            ),
          ],
          body: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    RuntimeTypeSelectorWidget(
                      selectedType: provider.selectedType,
                      onChanged: (value) async {
                        provider.updateType(value);
                        await provider.load();
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: provider.updateKeyword,
                      onSubmitted: (_) => provider.load(),
                      decoration: InputDecoration(
                        hintText: l10n.runtimeSearchHint,
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        _statusChip(provider, '', runtimeStatusLabel(l10n, '')),
                        _statusChip(
                          provider,
                          'Running',
                          runtimeStatusLabel(l10n, 'Running'),
                        ),
                        _statusChip(
                          provider,
                          'Stopped',
                          runtimeStatusLabel(l10n, 'Stopped'),
                        ),
                        _statusChip(
                          provider,
                          'Error',
                          runtimeStatusLabel(l10n, 'Error'),
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
                      localizeRuntimeError(l10n, provider.errorMessage),
                  onRetry: provider.load,
                  emptyTitle: l10n.runtimeEmptyTitle,
                  emptyDescription: l10n.runtimeEmptyDescription,
                  child: RefreshIndicator(
                    onRefresh: provider.load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: provider.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = provider.items[index];
                        return RuntimeSummaryCardWidget(
                          item: item,
                          onOpenDetail: () => Navigator.pushNamed(
                            context,
                            AppRoutes.runtimeDetail,
                            arguments:
                                RuntimeDetailArgs(runtimeId: item.id ?? 0),
                          ),
                          onEdit: () => Navigator.pushNamed(
                            context,
                            AppRoutes.runtimeForm,
                            arguments: RuntimeFormArgs(runtimeId: item.id),
                          ),
                          onDelete: () => _delete(item),
                          onStart: () => _operate(item, 'up'),
                          onStop: () => _operate(item, 'down'),
                          onRestart: () => _operate(item, 'restart'),
                          canEdit: provider.canEdit(item),
                          canStart: provider.canStart(item),
                          canStop: provider.canStop(item),
                          canRestart: provider.canRestart(item),
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

  Widget _statusChip(RuntimesProvider provider, String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: provider.statusFilter == value,
      onSelected: (_) async {
        provider.updateStatus(value);
        await provider.load();
      },
    );
  }

  Future<void> _sync() async {
    await context.read<RuntimesProvider>().syncStatus();
  }

  Future<void> _operate(RuntimeInfo item, String action) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: runtimeOperateLabel(l10n, action),
      message: l10n.runtimeOperateConfirm(
        runtimeOperateLabel(l10n, action),
        item.name ?? '-',
      ),
      confirmLabel: runtimeOperateLabel(l10n, action),
      confirmIcon: action == 'up'
          ? Icons.play_arrow_outlined
          : action == 'down'
              ? Icons.stop_outlined
              : Icons.restart_alt_outlined,
    );
    if (!confirmed || !mounted) return;
    await context.read<RuntimesProvider>().operate(item, action);
  }

  Future<void> _delete(RuntimeInfo item) async {
    final provider = context.read<RuntimesProvider>();
    final dependencies = await provider.checkDeleteDependency(item);
    if (!mounted) return;
    if (dependencies == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.commonLoadFailedTitle)),
      );
      return;
    }

    final dependencyNames = _extractDependencyNames(dependencies);
    final message = dependencyNames.isEmpty
        ? context.l10n.runtimeDeleteConfirm(item.name ?? '-')
        : '${context.l10n.runtimeDeleteConfirm(item.name ?? '-')}\n\n${context.l10n.openrestyRiskDependencyChangeTitle}\n${dependencyNames.join('\n')}';

    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.commonDelete,
      message: message,
      confirmLabel: context.l10n.commonDelete,
      isDestructive: true,
      confirmIcon: Icons.delete_outline,
    );
    if (!confirmed || !mounted) return;
    await provider.delete(item);
  }

  List<String> _extractDependencyNames(List<Map<String, dynamic>> dependencies) {
    final names = <String>[];
    for (final item in dependencies) {
      final rawName = item['name'] ??
          item['appName'] ??
          item['resourceName'] ??
          item['label'] ??
          item['id'];
      final name = rawName?.toString().trim() ?? '';
      if (name.isNotEmpty) {
        names.add('• $name');
      }
    }
    return names;
  }
}

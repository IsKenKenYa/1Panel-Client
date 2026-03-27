import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/script_library_models.dart';
import 'package:onepanel_client/features/group/widgets/group_selector_sheet_widget.dart';
import 'package:onepanel_client/features/script_library/providers/script_library_provider.dart';
import 'package:onepanel_client/features/script_library/widgets/script_code_preview_sheet_widget.dart';
import 'package:onepanel_client/features/script_library/widgets/script_library_card_widget.dart';
import 'package:onepanel_client/features/script_library/widgets/script_run_output_sheet_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

class ScriptLibraryPage extends StatefulWidget {
  const ScriptLibraryPage({super.key});

  @override
  State<ScriptLibraryPage> createState() => _ScriptLibraryPageState();
}

class _ScriptLibraryPageState extends State<ScriptLibraryPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<ScriptLibraryProvider>().load();
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
    return Consumer<ScriptLibraryProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: l10n.operationsScriptsTitle,
          onServerChanged: () => context.read<ScriptLibraryProvider>().load(),
          actions: <Widget>[
            IconButton(
              onPressed: () => _pickGroupFilter(provider),
              icon: const Icon(Icons.folder_outlined),
              tooltip: l10n.scriptLibraryGroupFilterAction,
            ),
            IconButton(
              onPressed: provider.isSyncing ? null : _syncScripts,
              icon: const Icon(Icons.sync),
              tooltip: l10n.scriptLibrarySyncAction,
            ),
            IconButton(
              onPressed: provider.isLoading ? null : provider.load,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
          ],
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
                        hintText: l10n.scriptLibrarySearchHint,
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilterChip(
                        label: Text(
                          provider.selectedGroupId == null
                              ? l10n.scriptLibraryFilterAllGroups
                              : _groupName(provider),
                        ),
                        selected: provider.selectedGroupId != null,
                        onSelected: (_) => _pickGroupFilter(provider),
                      ),
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
                  emptyTitle: l10n.scriptLibraryEmptyTitle,
                  emptyDescription: l10n.scriptLibraryEmptyDescription,
                  child: RefreshIndicator(
                    onRefresh: provider.load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: provider.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = provider.items[index];
                        return ScriptLibraryCardWidget(
                          item: item,
                          interactiveLabel: item.isInteractive
                              ? context.l10n.scriptLibraryInteractiveYes
                              : context.l10n.scriptLibraryInteractiveNo,
                          onViewCode: () => _viewCode(item),
                          onRun: () => _runScript(item),
                          onSync: _syncScripts,
                          onDelete:
                              item.isSystem ? null : () => _deleteScript(item),
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

  String _groupName(ScriptLibraryProvider provider) {
    if (provider.groups.isEmpty) {
      return context.l10n.scriptLibraryFilterAllGroups;
    }
    final match = provider.groups.firstWhere(
      (group) => group.id == provider.selectedGroupId,
      orElse: () => provider.groups.first,
    );
    final name = match.name?.trim();
    return name == null || name.isEmpty
        ? context.l10n.operationsGroupDefaultLabel
        : name;
  }

  Future<void> _pickGroupFilter(ScriptLibraryProvider provider) async {
    final groupId = await GroupSelectorSheetWidget.show(
      context,
      groupType: 'script',
      initialSelectedGroupId: provider.selectedGroupId,
      allowClearSelection: true,
      clearOptionLabel: context.l10n.scriptLibraryFilterAllGroups,
    );
    if (!mounted) return;
    provider.updateGroupFilter(groupId);
    await provider.load();
  }

  Future<void> _viewCode(ScriptLibraryInfo item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ScriptCodePreviewSheetWidget(
        title: context.l10n.scriptLibraryCodeTitle,
        content: item.script,
      ),
    );
  }

  Future<void> _runScript(ScriptLibraryInfo item) async {
    final provider = context.read<ScriptLibraryProvider>();
    await provider.startRun(item);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => Consumer<ScriptLibraryProvider>(
        builder: (context, state, _) {
          return ScriptRunOutputSheetWidget(
            title: context.l10n.scriptLibraryRunTitle,
            output: state.runOutput,
            isRunning: state.isRunning,
            error: state.runError,
          );
        },
      ),
    );
    await provider.stopRun();
  }

  Future<void> _syncScripts() async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.scriptLibrarySyncAction,
      message: context.l10n.scriptLibrarySyncConfirm,
      confirmLabel: context.l10n.commonConfirm,
    );
    if (!confirmed || !mounted) return;
    await context.read<ScriptLibraryProvider>().syncScripts();
  }

  Future<void> _deleteScript(ScriptLibraryInfo item) async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.commonDelete,
      message: context.l10n.scriptLibraryDeleteConfirm(item.name),
      confirmLabel: context.l10n.commonDelete,
      confirmIcon: Icons.delete_outline,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<ScriptLibraryProvider>().deleteScript(item);
  }
}

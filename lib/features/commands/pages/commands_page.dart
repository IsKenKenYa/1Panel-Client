import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/platform/services/platform_file_service.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/features/commands/providers/commands_provider.dart';
import 'package:onepanel_client/features/commands/widgets/command_card_widget.dart';
import 'package:onepanel_client/features/commands/widgets/commands_page_header_widget.dart';
import 'package:onepanel_client/features/group/widgets/group_selector_sheet_widget.dart';
import 'package:onepanel_client/shared/mixins/server_aware_page_mixin.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';

class CommandsPage extends StatefulWidget {
  const CommandsPage({super.key});

  @override
  State<CommandsPage> createState() => _CommandsPageState();
}

class _CommandsPageState extends State<CommandsPage> with ServerAwarePageMixin {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkServerAndLoad();
    });
  }

  @override
  void onServerReady() {
    context.read<CommandsProvider>().load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<CommandsProvider>(
      builder: (context, provider, _) {
        final selectionMode = provider.hasSelection;
        return ServerAwarePageScaffold(
          title: l10n.operationsCommandsTitle,
          onServerChanged: () =>
              context.read<CommandsProvider>().load(forceRefresh: true),
          actions: <Widget>[
            if (selectionMode)
              IconButton(
                onPressed: provider.isDeleting ? null : _deleteSelected,
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.commonDelete,
              )
            else ...<Widget>[
              IconButton(
                onPressed: provider.isImporting ? null : _pickImportFile,
                icon: const Icon(Icons.upload_file_outlined),
                tooltip: l10n.commonImport,
              ),
              IconButton(
                onPressed: provider.isExporting ? null : _exportCommands,
                icon: const Icon(Icons.download_outlined),
                tooltip: l10n.commonExport,
              ),
            ],
            IconButton(
              onPressed: () => _pickGroupFilter(provider),
              icon: const Icon(Icons.folder_outlined),
              tooltip: l10n.commandsGroupFilterAction,
            ),
            IconButton(
              onPressed: provider.isLoading
                  ? null
                  : () => provider.load(forceRefresh: true),
              icon: const Icon(Icons.refresh_outlined),
              tooltip: l10n.commonRefresh,
            ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'commands_create_fab',
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add_outlined),
            label: Text(l10n.commonCreate),
          ),
          body: Column(
            children: <Widget>[
              CommandsPageHeaderWidget(
                controller: _searchController,
                searchHint: l10n.commandsSearchHint,
                selectedGroupLabel: _groupName(provider),
                allGroupsLabel: l10n.commandsFilterAllGroups,
                isGroupSelected: provider.selectedGroupId != null,
                isImporting: provider.isImporting,
                importingLabel: l10n.commandsImportingLabel,
                onSearchChanged: provider.updateSearchQuery,
                onSearchSubmitted: provider.load,
                onSearchTap: provider.load,
                onPickGroup: () => _pickGroupFilter(provider),
              ),
              Expanded(
                child: AsyncStatePageBodyWidget(
                  isLoading: provider.isLoading,
                  isEmpty: provider.isEmpty,
                  errorMessage: provider.errorMessage,
                  onRetry: () => provider.load(forceRefresh: true),
                  emptyTitle: l10n.commandsEmptyTitle,
                  emptyDescription: l10n.commandsEmptyDescription,
                  emptyActionLabel: l10n.commonCreate,
                  onEmptyAction: _openForm,
                  child: RefreshIndicator(
                    onRefresh: () => provider.load(forceRefresh: true),
                    child: ListView.separated(
                      itemCount: provider.commands.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = provider.commands[index];
                        final id = item.id;
                        return GestureDetector(
                          onLongPress: id == null
                              ? null
                              : () => provider.toggleSelection(id),
                          // 桌面端右键与移动端长按等价：切换选中状态。
                          onSecondaryTapDown: id == null
                              ? null
                              : (_) => provider.toggleSelection(id),
                          child: CommandCardWidget(
                            command: item,
                            groupLabel: _commandGroupLabel(item, l10n),
                            isSelected:
                                id != null && provider.selectedIds.contains(id),
                            selectionMode: selectionMode,
                            onTap: () {
                              if (selectionMode && id != null) {
                                provider.toggleSelection(id);
                              }
                            },
                            onCopy: () => _copyCommand(item),
                            onEdit: () => _openForm(item),
                            onDelete: () => _deleteSingle(item),
                          ),
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

  String _groupName(CommandsProvider provider) {
    if (provider.groups.isEmpty) {
      return context.l10n.operationsGroupDefaultLabel;
    }
    final match = provider.groups.firstWhere(
      (group) => group.id == provider.selectedGroupId,
      orElse: () => provider.groups.first,
    );
    return match.name?.trim().isNotEmpty == true
        ? match.name!
        : context.l10n.operationsGroupDefaultLabel;
  }

  String _commandGroupLabel(CommandInfo item, dynamic l10n) {
    final name = item.groupBelong?.trim();
    return name == null || name.isEmpty
        ? l10n.operationsGroupDefaultLabel
        : name;
  }

  Future<void> _copyCommand(CommandInfo item) async {
    await Clipboard.setData(ClipboardData(text: item.command ?? ''));
    if (!mounted) {
      return;
    }
    SnackBarUtils.showSuccess(context, context.l10n.commonCopySuccess);
  }

  Future<void> _pickImportFile() async {
    final provider = context.read<CommandsProvider>();
    final pageContext = context;
    final result = await PlatformFileService().selectFiles(
      allowedExtensions: const <String>['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    await provider.loadImportPreview(bytes: bytes, fileName: file.name);
    if (!mounted || provider.importPreviewItems.isEmpty) {
      if (mounted) {
        SnackBarUtils.showInfo(
          context,
          context.l10n.commandsImportPreviewEmpty,
        );
      }
      return;
    }
    await showAppFormSheet<void>(
      context,
      title: context.l10n.commonImport,
      builder: (_) => ListenableBuilder(
        listenable: provider,
        builder: (context, _) {
          final l10n = context.l10n;
          final items = provider.importPreviewItems;
          return LayoutBuilder(
            builder: (context, constraints) => ListView(
              shrinkWrap: true,
              primary: false,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: items.isEmpty
                          ? null
                          : provider.selectAllPreview,
                      icon: const Icon(Icons.done_all_outlined),
                      label: Text(l10n.commandsSelectAll),
                    ),
                    OutlinedButton.icon(
                      onPressed: items.isEmpty
                          ? null
                          : () => _pickPreviewGroup(provider),
                      icon: const Icon(Icons.folder_outlined),
                      label: Text(l10n.commandsApplyGroup),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: (constraints.maxHeight * 0.7)
                      .clamp(120.0, 420.0)
                      .toDouble(),
                  child: AsyncStatePageBodyWidget(
                    isLoading: provider.isImporting && items.isEmpty,
                    isEmpty: items.isEmpty,
                    emptyTitle: l10n.commandsImportPreviewEmptyTitle,
                    emptyDescription: l10n.commandsImportPreviewEmpty,
                    child: ListView.separated(
                      shrinkWrap: true,
                      primary: false,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return CheckboxListTile(
                          value: provider.selectedPreviewIds.contains(item.id),
                          onChanged: provider.isImporting
                              ? null
                              : (_) => provider.togglePreviewSelection(item.id),
                          title: Text(item.name ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.groupBelong ?? '-'),
                              const SizedBox(height: 4),
                              Text(
                                item.command ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.standard,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed:
                      provider.isImporting ||
                          provider.selectedPreviewIds.isEmpty
                      ? null
                      : () async {
                          final success = await provider
                              .importSelectedPreview();
                          if (success && context.mounted) {
                            Navigator.of(context).pop();
                          }
                          if (success && pageContext.mounted) {
                            SnackBarUtils.showSuccess(
                              pageContext,
                              l10n.commonImport,
                            );
                          }
                        },
                  icon: provider.isImporting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: Text(l10n.commonImport),
                ),
              ],
            ),
          );
        },
      ),
    );
    provider.clearImportPreview();
  }

  Future<void> _pickPreviewGroup(CommandsProvider provider) async {
    final groupId = await GroupSelectorSheetWidget.show(
      context,
      groupType: 'command',
      initialSelectedGroupId: provider.selectedGroupId,
    );
    if (groupId != null) {
      provider.applyGroupToPreview(groupId);
    }
  }

  Future<void> _exportCommands() async {
    final result = await context.read<CommandsProvider>().exportAllCommands();
    if (!mounted || result == null) {
      return;
    }
    final message = result.success
        ? context.l10n.commandsExportSaved(result.filePath ?? '')
        : (result.errorMessage ?? context.l10n.commonSaveFailed);
    result.success
        ? SnackBarUtils.showSuccess(context, message)
        : SnackBarUtils.showError(context, message);
  }

  Future<void> _pickGroupFilter(CommandsProvider provider) async {
    final groupId = await GroupSelectorSheetWidget.show(
      context,
      groupType: 'command',
      initialSelectedGroupId: provider.selectedGroupId,
      allowClearSelection: true,
      clearOptionLabel: context.l10n.commandsFilterAllGroups,
    );
    if (!mounted) {
      return;
    }
    provider.updateGroupFilter(groupId);
    await provider.load();
  }

  Future<void> _deleteSingle(CommandInfo item) async {
    final provider = context.read<CommandsProvider>();
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.commonDelete,
      message: context.l10n.commandsDeleteConfirm(item.name ?? ''),
      confirmLabel: context.l10n.commonDelete,
      confirmIcon: Icons.delete_outline,
      isDestructive: true,
    );
    if (!confirmed) {
      return;
    }
    await provider.deleteCommand(item);
  }

  Future<void> _deleteSelected() async {
    final provider = context.read<CommandsProvider>();
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.commonDelete,
      message: context.l10n.commandsDeleteSelectedConfirm(
        provider.selectedIds.length,
      ),
      confirmLabel: context.l10n.commonDelete,
      confirmIcon: Icons.delete_outline,
      isDestructive: true,
    );
    if (!confirmed) {
      return;
    }
    await provider.deleteSelected();
  }

  Future<void> _openForm([CommandInfo? item]) async {
    final refreshed = await Navigator.pushNamed(
      context,
      AppRoutes.commandForm,
      arguments: item,
    );
    if (refreshed == true && mounted) {
      await context.read<CommandsProvider>().load(forceRefresh: true);
    }
  }
}

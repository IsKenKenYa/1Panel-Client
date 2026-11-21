import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/toolbox/widgets/toolbox_snapshot_list.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_clam_provider.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';
import 'package:provider/provider.dart';

part 'toolbox_clam_page_actions_part.dart';

class ToolboxClamPage extends StatefulWidget {
  const ToolboxClamPage({super.key});

  @override
  State<ToolboxClamPage> createState() => _ToolboxClamPageState();
}

class _ToolboxClamPageState extends State<ToolboxClamPage>
  with _ToolboxClamPageActionsPart {
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _fileController = TextEditingController();

  @override
  void dispose() {
    _keywordController.dispose();
    _fileController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<ToolboxClamProvider>();
      provider.load();
      await provider.loadClamFile();
      if (!mounted) return;
      _fileController.text = provider.clamFileContent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<ToolboxClamProvider>();

    return ServerAwarePageScaffold(
      title: l10n.toolboxClamTitle,
      body: ToolboxSnapshotList(
        hasSnapshot: provider.hasSnapshot,
        isLoading: provider.isLoading,
        loadError: provider.loadError,
        onRetry: provider.load,
        children: [
          SectionCard(
            title: l10n.toolboxClamTasksTitle,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: provider.isMutating
                          ? null
                          : () => _showTaskDialog(context, provider),
                      icon: const Icon(Icons.add_outlined),
                      label: Text(l10n.commonCreate),
                    ),
                    PopupMenuButton<String>(
                      enabled: !provider.isMutating,
                      onSelected: (value) => _operateService(
                        context,
                        provider,
                        value,
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'start',
                          child: Text(l10n.commonStart),
                        ),
                        PopupMenuItem(
                          value: 'stop',
                          child: Text(l10n.commonStop),
                        ),
                        PopupMenuItem(
                          value: 'restart',
                          child: Text(l10n.commonRestart),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'fresh-start',
                          child: Text(l10n.toolboxClamFreshStart),
                        ),
                        PopupMenuItem(
                          value: 'fresh-stop',
                          child: Text(l10n.toolboxClamFreshStop),
                        ),
                        PopupMenuItem(
                          value: 'fresh-restart',
                          child: Text(l10n.toolboxClamFreshRestart),
                        ),
                      ],
                      child: OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.tune_outlined),
                        label: Text(l10n.toolboxStatusLabel),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _keywordController,
                        decoration: InputDecoration(
                          hintText: l10n.commonSearch,
                          isDense: true,
                        ),
                        onSubmitted: (value) => provider.setTaskKeyword(value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: provider.isMutating
                          ? null
                          : () => provider.setTaskKeyword(
                                _keywordController.text,
                              ),
                      icon: const Icon(Icons.search),
                      tooltip: l10n.commonSearch,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (provider.tasks.isEmpty)
                  Text(l10n.commonEmpty)
                else
                  ...provider.tasks.map(
                    (task) => ListTile(
                      dense: true,
                      selected: provider.selectedTaskId == task.id,
                      contentPadding: EdgeInsets.zero,
                      title: Text(task.name ?? '-'),
                      subtitle: Text(
                        '${l10n.commonPath}: ${task.path ?? '-'}\n'
                        '${l10n.commonDescription}: ${task.description ?? '-'}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) =>
                            _onTaskAction(context, provider, task, value),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'handle',
                            child: Text(l10n.cronjobsHandleOnceAction),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(l10n.commonEdit),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(l10n.commonDelete),
                          ),
                          PopupMenuItem(
                            value: 'clean',
                            child: Text(l10n.cronjobRecordsCleanAction),
                          ),
                        ],
                      ),
                      onTap: task.id == null
                          ? null
                          : () => provider.selectTask(task.id),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: provider.taskPage > 1 && !provider.isMutating
                          ? () => provider.previousTaskPage()
                          : null,
                      child: const Icon(Icons.chevron_left),
                    ),
                    const SizedBox(width: 12),
                    Text('${provider.taskPage}'),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: provider.hasMoreTasks && !provider.isMutating
                          ? () => provider.nextTaskPage()
                          : null,
                      child: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: l10n.toolboxClamRecordsTitle,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.selectedTaskId == null)
                  Text(l10n.commonEmpty)
                else if (provider.records.isEmpty)
                  Text(l10n.commonEmpty)
                else
                  ...provider.records.map(
                    (record) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(record.name ?? '-'),
                      subtitle: Text(record.path ?? '-'),
                      trailing: Text(record.status ?? '-'),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed:
                          provider.recordPage > 1 && !provider.isMutating
                              ? () => provider.previousRecordPage()
                              : null,
                      child: const Icon(Icons.chevron_left),
                    ),
                    const SizedBox(width: 12),
                    Text('${provider.recordPage}'),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed:
                          provider.hasMoreRecords && !provider.isMutating
                              ? () => provider.nextRecordPage()
                              : null,
                      child: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: l10n.toolboxClamFilesTitle,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final name in ToolboxClamProvider.clamFileNames)
                      ChoiceChip(
                        label: Text(name),
                        selected: provider.selectedClamFileName == name,
                        onSelected: provider.isLoadingFile
                            ? null
                            : (_) async {
                                await provider.selectClamFile(name);
                                if (!mounted) return;
                                _fileController.text =
                                    provider.clamFileContent;
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (provider.isLoadingFile)
                  const LinearProgressIndicator()
                else ...[
                  TextField(
                    controller: _fileController,
                    maxLines: provider.isClamLogFile ? 6 : 12,
                    readOnly: provider.isClamLogFile,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: provider.isClamLogFile
                          ? l10n.toolboxClamFileReadonly
                          : l10n.toolboxClamFileContent,
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (!provider.isClamLogFile) ...[
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: provider.isSavingFile
                          ? null
                          : () async {
                              final ok = await provider.saveClamFile(
                                _fileController.text,
                              );
                              if (!context.mounted) return;
                              if (ok) {
                                SnackBarUtils.showSuccess(
                                  context,
                                  l10n.commonSaveSuccess,
                                );
                              } else {
                                SnackBarUtils.showError(
                                  context,
                                  provider.error ?? l10n.commonSaveFailed,
                                );
                              }
                            },
                      icon: const Icon(Icons.save_outlined),
                      label: Text(l10n.commonSave),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: provider.isLoading || provider.isMutating
                  ? null
                  : () => context.read<ToolboxClamProvider>().load(),
              icon: const Icon(Icons.refresh_outlined),
              label: Text(l10n.commonRefresh),
            ),
          ),
        ],
      ),
    );
  }

}

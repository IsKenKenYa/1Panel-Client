import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';
import 'package:onepanel_client/features/runtimes/providers/php_supervisor_provider.dart';
import 'package:onepanel_client/features/runtimes/utils/runtime_l10n_helper.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:provider/provider.dart';

class PhpSupervisorPage extends StatefulWidget {
  const PhpSupervisorPage({
    super.key,
    required this.args,
  });

  final RuntimeManageArgs args;

  @override
  State<PhpSupervisorPage> createState() => _PhpSupervisorPageState();
}

class _PhpSupervisorPageState extends State<PhpSupervisorPage> {
  late final TextEditingController _fileEditorController;

  @override
  void initState() {
    super.initState();
    _fileEditorController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<PhpSupervisorProvider>().initialize(widget.args);
    });
  }

  @override
  void dispose() {
    _fileEditorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<PhpSupervisorProvider>(
      builder: (context, provider, _) {
        final title = provider.runtimeName.trim().isEmpty
            ? l10n.operationsSupervisorTitle
            : '${provider.runtimeName} · ${l10n.operationsSupervisorTitle}';
        return ServerAwarePageScaffold(
          title: title,
          onServerChanged: () =>
              context.read<PhpSupervisorProvider>().initialize(widget.args),
          actions: <Widget>[
            IconButton(
              onPressed: provider.isLoading ? null : provider.load,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
            IconButton(
              onPressed: provider.isLoading || provider.isOperating
                  ? null
                  : () => _openProcessEditor(),
              icon: const Icon(Icons.add),
              tooltip: l10n.commonAdd,
            ),
          ],
          body: AsyncStatePageBodyWidget(
            isLoading: provider.isLoading,
            isEmpty: provider.isEmpty,
            errorMessage: localizeRuntimeError(l10n, provider.errorMessage),
            onRetry: provider.load,
            emptyTitle: l10n.runtimeEmptyTitle,
            emptyDescription: l10n.runtimeEmptyDescription,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = provider.items[index];
                final state = provider.processState(item);
                return _buildProcessCard(context, provider, item, state);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProcessCard(
    BuildContext context,
    PhpSupervisorProvider provider,
    SupervisorProcessInfo item,
    String state,
  ) {
    final l10n = context.l10n;
    final isBuiltin = item.name == 'php-fpm';
    final action = _buildMainAction(state);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _buildStateChip(context, state),
              ],
            ),
            if (item.command.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(item.command),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _buildInfoChip(context, Icons.person_outline, item.user),
                _buildInfoChip(context, Icons.folder_outlined, item.dir),
                _buildInfoChip(
                    context, Icons.view_list_outlined, item.numprocs),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (!isBuiltin)
                  OutlinedButton(
                    onPressed: provider.isOperating
                        ? null
                        : () => _openFile(
                              processName: item.name,
                              fileName: 'config',
                            ),
                    child: Text(l10n.runtimeFieldSource),
                  ),
                if (!isBuiltin)
                  OutlinedButton(
                    onPressed: provider.isOperating
                        ? null
                        : () => _openFile(
                              processName: item.name,
                              fileName: 'out.log',
                            ),
                    child: Text(l10n.commonLogs),
                  ),
                if (action != null)
                  FilledButton.tonal(
                    onPressed: provider.isOperating
                        ? null
                        : () => _operate(item.name, action.$1),
                    child: Text(action.$2),
                  ),
                if (!isBuiltin && state != 'WARNING')
                  TextButton(
                    onPressed: provider.isOperating
                        ? null
                        : () => _operate(item.name, 'restart'),
                    child: Text(l10n.commonRestart),
                  ),
                if (!isBuiltin)
                  TextButton(
                    onPressed: provider.isOperating
                        ? null
                        : () => _openProcessEditor(initial: item),
                    child: Text(l10n.commonEdit),
                  ),
                if (!isBuiltin)
                  TextButton(
                    onPressed: provider.isOperating
                        ? null
                        : () => _operate(item.name, 'delete'),
                    child: Text(l10n.commonDelete),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateChip(BuildContext context, String state) {
    final l10n = context.l10n;
    late final Color color;
    late final String text;

    switch (state) {
      case 'RUNNING':
        color = Colors.green;
        text = l10n.runtimeStatusRunning;
        break;
      case 'STARTING':
        color = Colors.orange;
        text = l10n.runtimeStatusStarting;
        break;
      case 'WARNING':
        color = Colors.amber;
        text = l10n.runtimeSupervisorStatusWarning;
        break;
      default:
        color = Colors.grey;
        text = l10n.runtimeStatusStopped;
        break;
    }

    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      label: Text(
        text,
        style: TextStyle(color: color),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String value) {
    final resolved = value.trim().isEmpty ? '-' : value.trim();
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16),
      label: Text(resolved),
    );
  }

  (String, String)? _buildMainAction(String state) {
    final l10n = context.l10n;
    if (state == 'RUNNING') {
      return ('stop', l10n.commonStop);
    }
    if (state == 'WARNING') {
      return ('restart', l10n.commonRestart);
    }
    return ('start', l10n.commonStart);
  }

  Future<void> _operate(String processName, String operation) async {
    final success = await context.read<PhpSupervisorProvider>().operateProcess(
          processName: processName,
          operation: operation,
        );
    if (!mounted) {
      return;
    }
    final provider = context.read<PhpSupervisorProvider>();
    final message = success
        ? context.l10n.commonSaveSuccess
        : (localizeRuntimeError(context.l10n, provider.errorMessage) ??
            context.l10n.commonSaveFailed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openFile({
    required String processName,
    required String fileName,
  }) async {
    final provider = context.read<PhpSupervisorProvider>();
    final opened = await provider.openFile(
      processName: processName,
      fileName: fileName,
    );
    if (!mounted) {
      return;
    }
    if (!opened) {
      final message =
          localizeRuntimeError(context.l10n, provider.fileErrorMessage) ??
              context.l10n.commonSaveFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    if (provider.activeFileName == 'config') {
      _fileEditorController.text = provider.activeFileContent;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.78,
            child: Consumer<PhpSupervisorProvider>(
              builder: (context, fileProvider, _) {
                final l10n = context.l10n;
                final fileError =
                    localizeRuntimeError(l10n, fileProvider.fileErrorMessage);
                final isConfig = fileProvider.activeFileName == 'config';
                final isLog = fileProvider.activeFileName == 'out.log' ||
                    fileProvider.activeFileName == 'err.log';

                if (isConfig &&
                    !fileProvider.isFileLoading &&
                    _fileEditorController.text !=
                        fileProvider.activeFileContent) {
                  _fileEditorController.text = fileProvider.activeFileContent;
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${fileProvider.activeProcessName} · ${_fileLabel(l10n, fileProvider.activeFileName)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            onPressed: fileProvider.isFileLoading
                                ? null
                                : fileProvider.refreshActiveFile,
                            icon: const Icon(Icons.refresh),
                            tooltip: l10n.commonRefresh,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (fileProvider.isFileLoading)
                        const LinearProgressIndicator(minHeight: 3),
                      if (fileError != null &&
                          fileError.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(fileError),
                      ],
                      const SizedBox(height: 8),
                      Expanded(
                        child: isConfig
                            ? TextField(
                                controller: _fileEditorController,
                                expands: true,
                                maxLines: null,
                                enabled: !fileProvider.isFileSaving,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              )
                            : Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SingleChildScrollView(
                                  child: SelectableText(
                                    fileProvider.activeFileContent.isEmpty
                                        ? '-'
                                        : fileProvider.activeFileContent,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          if (isLog)
                            OutlinedButton(
                              onPressed: fileProvider.isFileSaving
                                  ? null
                                  : _clearActiveLog,
                              child: Text(l10n.commonDelete),
                            ),
                          const Spacer(),
                          if (isConfig)
                            FilledButton(
                              onPressed: fileProvider.isFileSaving
                                  ? null
                                  : _saveActiveConfig,
                              child: fileProvider.isFileSaving
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(l10n.commonSave),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (mounted) {
      context.read<PhpSupervisorProvider>().closeFile();
    }
  }

  String _fileLabel(AppLocalizations l10n, String fileName) {
    return switch (fileName) {
      'config' => l10n.runtimeFieldSource,
      'out.log' || 'err.log' => l10n.commonLogs,
      _ => fileName,
    };
  }

  Future<void> _saveActiveConfig() async {
    final success = await context
        .read<PhpSupervisorProvider>()
        .saveActiveConfig(_fileEditorController.text);
    if (!mounted) {
      return;
    }
    final provider = context.read<PhpSupervisorProvider>();
    final message = success
        ? context.l10n.commonSaveSuccess
        : (localizeRuntimeError(context.l10n, provider.fileErrorMessage) ??
            context.l10n.commonSaveFailed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _clearActiveLog() async {
    final success =
        await context.read<PhpSupervisorProvider>().clearActiveLog();
    if (!mounted) {
      return;
    }
    final provider = context.read<PhpSupervisorProvider>();
    final message = success
        ? context.l10n.commonSaveSuccess
        : (localizeRuntimeError(context.l10n, provider.fileErrorMessage) ??
            context.l10n.commonSaveFailed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openProcessEditor({
    SupervisorProcessInfo? initial,
  }) async {
    final l10n = context.l10n;
    final isEdit = initial != null;

    final nameController = TextEditingController(text: initial?.name ?? '');
    final commandController =
        TextEditingController(text: initial?.command ?? '');
    final userController = TextEditingController(
      text: initial == null
          ? 'www-data'
          : (initial.user.trim().isEmpty ? 'www-data' : initial.user),
    );
    final dirController = TextEditingController(text: initial?.dir ?? '');
    final numprocsController = TextEditingController(
      text: initial == null
          ? '1'
          : (initial.numprocs.trim().isEmpty ? '1' : initial.numprocs),
    );
    final environmentController =
        TextEditingController(text: initial?.environment ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            ),
            child: Consumer<PhpSupervisorProvider>(
              builder: (_, provider, __) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        isEdit
                            ? '${l10n.commonEdit} ${l10n.operationsSupervisorTitle}'
                            : '${l10n.commonAdd} ${l10n.operationsSupervisorTitle}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: l10n.commonName,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: commandController,
                        decoration: InputDecoration(
                          labelText: l10n.containerInfoCommand,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: userController,
                        decoration: InputDecoration(
                          labelText: l10n.commonUsername,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dirController,
                        decoration: InputDecoration(
                          labelText: l10n.commonPath,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: numprocsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.runtimeFieldParams,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: environmentController,
                        decoration: InputDecoration(
                          labelText: l10n.processDetailEnvironmentSectionTitle,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          TextButton(
                            onPressed: provider.isOperating
                                ? null
                                : () => Navigator.of(sheetContext).pop(),
                            child: Text(l10n.commonCancel),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: provider.isOperating
                                ? null
                                : () async {
                                    final supervisorProvider =
                                        context.read<PhpSupervisorProvider>();
                                    final success = await supervisorProvider
                                        .saveProcessDefinition(
                                      operate: isEdit ? 'update' : 'create',
                                      name: nameController.text,
                                      command: commandController.text,
                                      user: userController.text,
                                      dir: dirController.text,
                                      numprocs: numprocsController.text,
                                      environment: environmentController.text,
                                    );
                                    if (!sheetContext.mounted) {
                                      return;
                                    }
                                    final localized = sheetContext.l10n;
                                    final message = success
                                        ? localized.commonSaveSuccess
                                        : (localizeRuntimeError(
                                              localized,
                                              supervisorProvider.errorMessage,
                                            ) ??
                                            localized.commonSaveFailed);
                                    if (success &&
                                        Navigator.of(sheetContext).canPop()) {
                                      Navigator.of(sheetContext).pop();
                                    }
                                    ScaffoldMessenger.of(sheetContext)
                                        .showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                  },
                            child: provider.isOperating
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.commonSave),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    nameController.dispose();
    commandController.dispose();
    userController.dispose();
    dirController.dispose();
    numprocsController.dispose();
    environmentController.dispose();
  }
}

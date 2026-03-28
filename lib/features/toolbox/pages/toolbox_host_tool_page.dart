import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/host_tool_models.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_host_tool_provider.dart';
import 'package:onepanel_client/features/toolbox/widgets/toolbox_sections_widget.dart';
import 'package:provider/provider.dart';

class ToolboxHostToolPage extends StatefulWidget {
  const ToolboxHostToolPage({super.key});

  @override
  State<ToolboxHostToolPage> createState() => _ToolboxHostToolPageState();
}

class _ToolboxHostToolPageState extends State<ToolboxHostToolPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ToolboxHostToolProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<ToolboxHostToolProvider>();

    return ServerAwarePageScaffold(
      title: l10n.toolboxHostToolTitle,
      onServerChanged: () => context.read<ToolboxHostToolProvider>().load(),
      actions: <Widget>[
        IconButton(
          onPressed: provider.isLoading ? null : provider.load,
          icon: const Icon(Icons.refresh),
          tooltip: l10n.commonRefresh,
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (provider.isLoading) const LinearProgressIndicator(),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                provider.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ToolboxSectionCardWidget(
            title: l10n.toolboxHostToolServiceSectionTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ToolboxInfoRowWidget(
                  label: l10n.toolboxHostToolStatusLabel,
                  value: provider.serviceInfo.status.isEmpty
                      ? '-'
                      : provider.serviceInfo.status,
                ),
                ToolboxInfoRowWidget(
                  label: l10n.toolboxHostToolVersionLabel,
                  value: provider.serviceInfo.version.isEmpty
                      ? '-'
                      : provider.serviceInfo.version,
                ),
                ToolboxInfoRowWidget(
                  label: l10n.toolboxHostToolConfigPathLabel,
                  value: provider.serviceInfo.configPath.isEmpty
                      ? '-'
                      : provider.serviceInfo.configPath,
                ),
                ToolboxInfoRowWidget(
                  label: l10n.toolboxHostToolServiceNameLabel,
                  value: provider.serviceInfo.serviceName.isEmpty
                      ? '-'
                      : provider.serviceInfo.serviceName,
                ),
                if (provider.serviceInfo.msg.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(provider.serviceInfo.msg),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: provider.isMutating
                          ? null
                          : () => _showInitDialog(context, provider),
                      icon: const Icon(Icons.settings_suggest_outlined),
                      label: Text(l10n.toolboxHostToolInitAction),
                    ),
                    OutlinedButton(
                      onPressed: provider.isMutating
                          ? null
                          : () => provider.operateSupervisor('start'),
                      child: Text(l10n.toolboxHostToolStartAction),
                    ),
                    OutlinedButton(
                      onPressed: provider.isMutating
                          ? null
                          : () => provider.operateSupervisor('stop'),
                      child: Text(l10n.toolboxHostToolStopAction),
                    ),
                    OutlinedButton(
                      onPressed: provider.isMutating
                          ? null
                          : () => provider.operateSupervisor('restart'),
                      child: Text(l10n.commonRestart),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ToolboxSectionCardWidget(
            title: l10n.toolboxHostToolConfigSectionTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SelectableText(
                  provider.configContent.isEmpty
                      ? l10n.commonEmpty
                      : provider.configContent,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: provider.isMutating
                      ? null
                      : () => _showConfigDialog(context, provider),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.commonEdit),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ToolboxSectionCardWidget(
            title: l10n.toolboxHostToolProcessSectionTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: provider.isMutating
                        ? null
                        : () => _showProcessDialog(context, provider),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.commonCreate),
                  ),
                ),
                const SizedBox(height: 12),
                if (provider.processes.isEmpty)
                  Text(l10n.commonEmpty)
                else
                  ...provider.processes.map(
                    (HostToolProcessConfig process) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(process.name.isEmpty ? '-' : process.name),
                        subtitle: Text(
                          '${l10n.toolboxHostToolCommandLabel}: ${process.command.isEmpty ? '-' : process.command}\n'
                          '${l10n.toolboxHostToolNumprocsLabel}: ${process.numprocs.isEmpty ? '-' : process.numprocs}\n'
                          '${l10n.toolboxHostToolStatusLabel}: ${process.status.isEmpty ? '-' : process.status.map((HostToolProcessStatus item) => item.status).join(', ')}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (String value) => _handleProcessAction(
                              context, provider, process, value),
                          itemBuilder: (_) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Text(l10n.commonEdit),
                            ),
                            PopupMenuItem<String>(
                              value: 'start',
                              child: Text(l10n.toolboxHostToolStartAction),
                            ),
                            PopupMenuItem<String>(
                              value: 'stop',
                              child: Text(l10n.toolboxHostToolStopAction),
                            ),
                            PopupMenuItem<String>(
                              value: 'restart',
                              child: Text(l10n.commonRestart),
                            ),
                            PopupMenuItem<String>(
                              value: 'config',
                              child: Text(l10n.toolboxHostToolConfigFileAction),
                            ),
                            PopupMenuItem<String>(
                              value: 'out.log',
                              child: Text(l10n.toolboxHostToolOutLogAction),
                            ),
                            PopupMenuItem<String>(
                              value: 'err.log',
                              child: Text(l10n.toolboxHostToolErrLogAction),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showInitDialog(
    BuildContext context,
    ToolboxHostToolProvider provider,
  ) async {
    final l10n = context.l10n;
    final configPathController =
        TextEditingController(text: provider.serviceInfo.configPath);
    final serviceNameController =
        TextEditingController(text: provider.serviceInfo.serviceName);
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.toolboxHostToolInitAction),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: configPathController,
              decoration: InputDecoration(
                labelText: l10n.toolboxHostToolConfigPathLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: serviceNameController,
              decoration: InputDecoration(
                labelText: l10n.toolboxHostToolServiceNameLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final success =
                  await context.read<ToolboxHostToolProvider>().initSupervisor(
                        configPath: configPathController.text.trim(),
                        serviceName: serviceNameController.text.trim(),
                      );
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? l10n.toolboxHostToolSaveSuccess
                        : (this.context.read<ToolboxHostToolProvider>().error ??
                            l10n.commonSaveFailed),
                  ),
                ),
              );
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfigDialog(
    BuildContext context,
    ToolboxHostToolProvider provider,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: provider.configContent);
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.toolboxHostToolConfigSectionTitle),
        content: TextField(
          controller: controller,
          maxLines: 14,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final success = await context
                  .read<ToolboxHostToolProvider>()
                  .saveSupervisorConfig(controller.text);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? l10n.toolboxHostToolSaveSuccess
                        : (this.context.read<ToolboxHostToolProvider>().error ??
                            l10n.commonSaveFailed),
                  ),
                ),
              );
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Future<void> _showProcessDialog(
    BuildContext context,
    ToolboxHostToolProvider provider, {
    HostToolProcessConfig? initialValue,
  }) async {
    final l10n = context.l10n;
    final nameController =
        TextEditingController(text: initialValue?.name ?? '');
    final commandController =
        TextEditingController(text: initialValue?.command ?? '');
    final userController =
        TextEditingController(text: initialValue?.user ?? '');
    final dirController = TextEditingController(text: initialValue?.dir ?? '');
    final numprocsController = TextEditingController(
        text: initialValue?.numprocs.isNotEmpty == true
            ? initialValue!.numprocs
            : '1');
    final environmentController =
        TextEditingController(text: initialValue?.environment ?? '');
    bool autoStart = (initialValue?.autoStart ?? 'true') == 'true';
    bool autoRestart = (initialValue?.autoRestart ?? 'true') == 'true';

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder:
            (BuildContext context, void Function(void Function()) setState) {
          return AlertDialog(
            title: Text(
              initialValue == null
                  ? l10n.toolboxHostToolProcessCreateTitle
                  : l10n.toolboxHostToolProcessEditTitle,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _HostToolField(
                      controller: nameController, label: l10n.commonName),
                  _HostToolField(
                    controller: commandController,
                    label: l10n.toolboxHostToolCommandLabel,
                  ),
                  _HostToolField(
                    controller: userController,
                    label: l10n.toolboxHostToolUserLabel,
                  ),
                  _HostToolField(
                    controller: dirController,
                    label: l10n.toolboxHostToolDirLabel,
                  ),
                  _HostToolField(
                    controller: numprocsController,
                    label: l10n.toolboxHostToolNumprocsLabel,
                  ),
                  _HostToolField(
                    controller: environmentController,
                    label: l10n.toolboxHostToolEnvironmentLabel,
                    maxLines: 3,
                  ),
                  SwitchListTile(
                    value: autoStart,
                    onChanged: (bool value) =>
                        setState(() => autoStart = value),
                    title: Text(l10n.toolboxHostToolAutoStartLabel),
                  ),
                  SwitchListTile(
                    value: autoRestart,
                    onChanged: (bool value) =>
                        setState(() => autoRestart = value),
                    title: Text(l10n.toolboxHostToolAutoRestartLabel),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () async {
                  final success = await context
                      .read<ToolboxHostToolProvider>()
                      .saveProcess(
                        HostToolProcessConfigRequest(
                          name: nameController.text.trim(),
                          operate: initialValue == null ? 'create' : 'update',
                          command: commandController.text.trim(),
                          user: userController.text.trim(),
                          dir: dirController.text.trim(),
                          numprocs: numprocsController.text.trim(),
                          autoRestart: autoRestart ? 'true' : 'false',
                          autoStart: autoStart ? 'true' : 'false',
                          environment: environmentController.text.trim(),
                        ),
                      );
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? l10n.toolboxHostToolSaveSuccess
                            : (this
                                    .context
                                    .read<ToolboxHostToolProvider>()
                                    .error ??
                                l10n.commonSaveFailed),
                      ),
                    ),
                  );
                },
                child: Text(l10n.commonSave),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleProcessAction(
    BuildContext context,
    ToolboxHostToolProvider provider,
    HostToolProcessConfig process,
    String action,
  ) async {
    final l10n = context.l10n;
    if (action == 'edit') {
      await _showProcessDialog(context, provider, initialValue: process);
      return;
    }
    if (action == 'start' || action == 'stop' || action == 'restart') {
      await provider.operateProcess(name: process.name, operate: action);
      return;
    }
    final content =
        await provider.loadProcessFile(name: process.name, file: action);
    if (!mounted || content == null) return;
    final controller = TextEditingController(text: content);
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(action == 'config'
            ? l10n.toolboxHostToolConfigFileAction
            : action == 'out.log'
                ? l10n.toolboxHostToolOutLogAction
                : l10n.toolboxHostToolErrLogAction),
        content: TextField(
          controller: controller,
          maxLines: 14,
          readOnly: action != 'config',
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: <Widget>[
          if (action != 'config')
            TextButton(
              onPressed: () async {
                final success = await context
                    .read<ToolboxHostToolProvider>()
                    .clearProcessFile(
                      name: process.name,
                      file: action,
                    );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? l10n.toolboxHostToolSaveSuccess
                          : (this
                                  .context
                                  .read<ToolboxHostToolProvider>()
                                  .error ??
                              l10n.commonSaveFailed),
                    ),
                  ),
                );
              },
              child: Text(l10n.commonClear),
            ),
          if (action == 'config')
            FilledButton(
              onPressed: () async {
                final success = await context
                    .read<ToolboxHostToolProvider>()
                    .updateProcessFile(
                      name: process.name,
                      file: action,
                      content: controller.text,
                    );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? l10n.toolboxHostToolSaveSuccess
                          : (this
                                  .context
                                  .read<ToolboxHostToolProvider>()
                                  .error ??
                              l10n.commonSaveFailed),
                    ),
                  ),
                );
              },
              child: Text(l10n.commonSave),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }
}

class _HostToolField extends StatelessWidget {
  const _HostToolField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

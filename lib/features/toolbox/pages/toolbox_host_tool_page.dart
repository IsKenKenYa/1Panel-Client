import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/toolbox/widgets/toolbox_snapshot_list.dart';
import 'package:onepanel_client/data/models/host_tool_models.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_host_tool_provider.dart';
import 'package:onepanel_client/features/toolbox/widgets/toolbox_sections_widget.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/snackbar_utils.dart';

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
      actions: <Widget>[
        IconButton(
          onPressed: provider.isLoading ? null : provider.load,
          icon: const Icon(Icons.refresh_outlined),
          tooltip: l10n.commonRefresh,
        ),
      ],
      body: ToolboxSnapshotList(
        hasSnapshot: provider.hasSnapshot,
        isLoading: provider.isLoading,
        loadError: provider.loadError,
        onRetry: provider.load,
        children: <Widget>[
          SectionCard(
            title: l10n.toolboxHostToolServiceSectionTitle,
            padding: AppDesignTokens.cardPadding,
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
          SectionCard(
            title: l10n.toolboxHostToolConfigSectionTitle,
            padding: AppDesignTokens.cardPadding,
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
          SectionCard(
            title: l10n.toolboxHostToolProcessSectionTitle,
            padding: AppDesignTokens.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: provider.isMutating
                        ? null
                        : () => _showProcessDialog(context, provider),
                    icon: const Icon(Icons.add_outlined),
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
                            context,
                            provider,
                            process,
                            value,
                          ),
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
    final success = await showAdaptiveFormPanel<bool>(
      context,
      builder: (_) => _HostToolInitForm(provider: provider),
    );
    if (!context.mounted || success == null) return;
    SnackBarUtils.showSuccess(
      context,
      success
          ? l10n.toolboxHostToolSaveSuccess
          : (provider.error ?? l10n.commonSaveFailed),
    );
  }

  Future<void> _showConfigDialog(
    BuildContext context,
    ToolboxHostToolProvider provider,
  ) async {
    final l10n = context.l10n;
    await showAppTextInputDialog(
      context,
      title: l10n.toolboxHostToolConfigSectionTitle,
      initialValue: provider.configContent,
      maxLines: 14,
      autofocus: false,
      trim: false,
      allowEmpty: true,
      confirmLabel: l10n.commonSave,
      onSubmit: (value) async {
        final success = await provider.saveSupervisorConfig(value);
        if (context.mounted) {
          SnackBarUtils.showSuccess(
            context,
            success
                ? l10n.toolboxHostToolSaveSuccess
                : (provider.error ?? l10n.commonSaveFailed),
          );
        }
        return true;
      },
    );
  }

  Future<void> _showProcessDialog(
    BuildContext context,
    ToolboxHostToolProvider provider, {
    HostToolProcessConfig? initialValue,
  }) async {
    final l10n = context.l10n;
    final success = await showAdaptiveFormPanel<bool>(
      context,
      builder: (_) =>
          _HostToolProcessForm(provider: provider, initialValue: initialValue),
    );
    if (!context.mounted || success == null) return;
    SnackBarUtils.showSuccess(
      context,
      success
          ? l10n.toolboxHostToolSaveSuccess
          : (provider.error ?? l10n.commonSaveFailed),
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
    final content = await provider.loadProcessFile(
      name: process.name,
      file: action,
    );
    if (!context.mounted || content == null) return;
    if (action == 'config') {
      await showAppTextInputDialog(
        context,
        title: l10n.toolboxHostToolConfigFileAction,
        initialValue: content,
        maxLines: 14,
        autofocus: false,
        trim: false,
        allowEmpty: true,
        confirmLabel: l10n.commonSave,
        onSubmit: (value) async {
          final success = await provider.updateProcessFile(
            name: process.name,
            file: action,
            content: value,
          );
          if (context.mounted) {
            SnackBarUtils.showSuccess(
              context,
              success
                  ? l10n.toolboxHostToolSaveSuccess
                  : (provider.error ?? l10n.commonSaveFailed),
            );
          }
          return true;
        },
      );
    } else {
      await showAppFormDialog(
        context,
        title: action == 'out.log'
            ? l10n.toolboxHostToolOutLogAction
            : l10n.toolboxHostToolErrLogAction,
        content: SizedBox(
          width: double.maxFinite,
          child: SelectableText(content),
        ),
        confirmLabel: l10n.commonClear,
        destructive: true,
        onConfirm: () async {
          final success = await provider.clearProcessFile(
            name: process.name,
            file: action,
          );
          if (!context.mounted) return;
          SnackBarUtils.showSuccess(
            context,
            success
                ? l10n.toolboxHostToolSaveSuccess
                : (provider.error ?? l10n.commonSaveFailed),
          );
        },
      );
    }
  }
}

class _HostToolInitForm extends StatefulWidget {
  const _HostToolInitForm({required this.provider});

  final ToolboxHostToolProvider provider;

  @override
  State<_HostToolInitForm> createState() => _HostToolInitFormState();
}

class _HostToolInitFormState extends State<_HostToolInitForm> {
  late final _configPathController = TextEditingController(
    text: widget.provider.serviceInfo.configPath,
  );
  late final _serviceNameController = TextEditingController(
    text: widget.provider.serviceInfo.serviceName,
  );
  bool _saving = false;

  @override
  void dispose() {
    _configPathController.dispose();
    _serviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.toolboxHostToolInitAction,
      isSaving: _saving,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _configPathController,
            decoration: InputDecoration(
              labelText: l10n.toolboxHostToolConfigPathLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _serviceNameController,
            decoration: InputDecoration(
              labelText: l10n.toolboxHostToolServiceNameLabel,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      onConfirm: () async {
        if (_saving) return;
        setState(() => _saving = true);
        try {
          final success = await widget.provider.initSupervisor(
            configPath: _configPathController.text.trim(),
            serviceName: _serviceNameController.text.trim(),
          );
          if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
            Navigator.of(context).pop(success);
          }
        } finally {
          if (mounted) setState(() => _saving = false);
        }
      },
    );
  }
}

class _HostToolProcessForm extends StatefulWidget {
  const _HostToolProcessForm({required this.provider, this.initialValue});

  final ToolboxHostToolProvider provider;
  final HostToolProcessConfig? initialValue;

  @override
  State<_HostToolProcessForm> createState() => _HostToolProcessFormState();
}

class _HostToolProcessFormState extends State<_HostToolProcessForm> {
  late final _nameController = TextEditingController(
    text: widget.initialValue?.name ?? '',
  );
  late final _commandController = TextEditingController(
    text: widget.initialValue?.command ?? '',
  );
  late final _userController = TextEditingController(
    text: widget.initialValue?.user ?? '',
  );
  late final _dirController = TextEditingController(
    text: widget.initialValue?.dir ?? '',
  );
  late final _numprocsController = TextEditingController(
    text: widget.initialValue?.numprocs.isNotEmpty == true
        ? widget.initialValue!.numprocs
        : '1',
  );
  late final _environmentController = TextEditingController(
    text: widget.initialValue?.environment ?? '',
  );
  late bool _autoStart = (widget.initialValue?.autoStart ?? 'true') == 'true';
  late bool _autoRestart =
      (widget.initialValue?.autoRestart ?? 'true') == 'true';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _userController.dispose();
    _dirController.dispose();
    _numprocsController.dispose();
    _environmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: widget.initialValue == null
          ? l10n.toolboxHostToolProcessCreateTitle
          : l10n.toolboxHostToolProcessEditTitle,
      confirmLabel: l10n.commonSave,
      isSaving: _saving,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _HostToolField(controller: _nameController, label: l10n.commonName),
          _HostToolField(
            controller: _commandController,
            label: l10n.toolboxHostToolCommandLabel,
          ),
          _HostToolField(
            controller: _userController,
            label: l10n.toolboxHostToolUserLabel,
          ),
          _HostToolField(
            controller: _dirController,
            label: l10n.toolboxHostToolDirLabel,
          ),
          _HostToolField(
            controller: _numprocsController,
            label: l10n.toolboxHostToolNumprocsLabel,
          ),
          _HostToolField(
            controller: _environmentController,
            label: l10n.toolboxHostToolEnvironmentLabel,
            maxLines: 3,
          ),
          SwitchListTile(
            value: _autoStart,
            onChanged: (value) => setState(() => _autoStart = value),
            title: Text(l10n.toolboxHostToolAutoStartLabel),
          ),
          SwitchListTile(
            value: _autoRestart,
            onChanged: (value) => setState(() => _autoRestart = value),
            title: Text(l10n.toolboxHostToolAutoRestartLabel),
          ),
        ],
      ),
      onConfirm: () async {
        if (_saving) return;
        setState(() => _saving = true);
        try {
          final success = await widget.provider.saveProcess(
            HostToolProcessConfigRequest(
              name: _nameController.text.trim(),
              operate: widget.initialValue == null ? 'create' : 'update',
              command: _commandController.text.trim(),
              user: _userController.text.trim(),
              dir: _dirController.text.trim(),
              numprocs: _numprocsController.text.trim(),
              autoRestart: _autoRestart ? 'true' : 'false',
              autoStart: _autoStart ? 'true' : 'false',
              environment: _environmentController.text.trim(),
            ),
          );
          if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
            Navigator.of(context).pop(success);
          }
        } finally {
          if (mounted) setState(() => _saving = false);
        }
      },
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

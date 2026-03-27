import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/logs/models/system_log_viewer_args.dart';
import 'package:onepanel_client/features/logs/providers/system_logs_provider.dart';
import 'package:onepanel_client/features/logs/utils/logs_l10n_helper.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/log_viewer/log_viewer.dart';
import 'package:onepanel_client/shared/widgets/operations/module_empty_state_widget.dart';
import 'package:provider/provider.dart';

class SystemLogViewerPage extends StatefulWidget {
  const SystemLogViewerPage({
    super.key,
    this.args,
  });

  final SystemLogViewerArgs? args;

  @override
  State<SystemLogViewerPage> createState() => _SystemLogViewerPageState();
}

class _SystemLogViewerPageState extends State<SystemLogViewerPage> {
  final LogViewerController _controller = LogViewerController();
  String _lastContent = '';
  Timer? _watchTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<SystemLogsProvider>().initialize(widget.args);
    });
  }

  @override
  void dispose() {
    _watchTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _syncWatchTimer(SystemLogsProvider provider) {
    if (!provider.watchEnabled) {
      _watchTimer?.cancel();
      _watchTimer = null;
      return;
    }
    _watchTimer ??= Timer.periodic(const Duration(seconds: 3), (_) {
      provider.loadSelectedFile(latest: true);
    });
  }

  Future<void> _copyContent(SystemLogsProvider provider) async {
    await Clipboard.setData(ClipboardData(text: provider.content));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.commonCopySuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<SystemLogsProvider>(
      builder: (context, provider, _) {
        _syncWatchTimer(provider);
        if (provider.content != _lastContent) {
          _lastContent = provider.content;
          _controller.setLogs(provider.content);
        }
        return ServerAwarePageScaffold(
          title: l10n.operationsSystemLogViewerTitle,
          onServerChanged: () =>
              context.read<SystemLogsProvider>().initialize(widget.args),
          actions: <Widget>[
            IconButton(
              onPressed: provider.content.isEmpty
                  ? null
                  : () => _copyContent(provider),
              icon: const Icon(Icons.copy_outlined),
              tooltip: l10n.commonCopy,
            ),
            IconButton(
              onPressed: provider.hasSelectedFile
                  ? () => provider.loadSelectedFile(latest: true)
                  : null,
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
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        ChoiceChip(
                          label: Text(l10n.logsSystemSourceAgent),
                          selected: provider.source == SystemLogSource.agent,
                          onSelected: (_) =>
                              provider.updateSource(SystemLogSource.agent),
                        ),
                        ChoiceChip(
                          label: Text(l10n.logsSystemSourceCore),
                          selected: provider.source == SystemLogSource.core,
                          onSelected: (_) =>
                              provider.updateSource(SystemLogSource.core),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: provider.selectedFile,
                      decoration: InputDecoration(
                        labelText: l10n.logsSystemFilesLabel,
                      ),
                      items: provider.files
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          provider.selectFile(value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: provider.watchEnabled,
                      onChanged: provider.updateWatchEnabled,
                      title: Text(l10n.logsSystemWatchLabel),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBody(provider, l10n)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(SystemLogsProvider provider, dynamic l10n) {
    if (provider.filesLoading && provider.files.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.filesError != null && provider.files.isEmpty) {
      return Center(
        child: FilledButton.icon(
          onPressed: () => provider.initialize(widget.args),
          icon: const Icon(Icons.refresh),
          label: Text(localizeLogsError(l10n, provider.filesError)!),
        ),
      );
    }
    if (provider.filesEmpty) {
      return ModuleEmptyStateWidget(
        title: l10n.logsSystemEmptyTitle,
        description: l10n.logsSystemEmptyDescription,
        icon: Icons.article_outlined,
      );
    }
    if (!provider.hasSelectedFile) {
      return ModuleEmptyStateWidget(
        title: l10n.logsSystemFilesLabel,
        description: l10n.logsSystemViewerNoFileSelected,
        icon: Icons.description_outlined,
      );
    }
    if (provider.contentLoading && _controller.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.contentError != null && _controller.logs.isEmpty) {
      return Center(
        child: FilledButton.icon(
          onPressed: () => provider.loadSelectedFile(latest: true),
          icon: const Icon(Icons.refresh),
          label: Text(localizeLogsError(l10n, provider.contentError)!),
        ),
      );
    }
    if (provider.content.trim().isEmpty) {
      return ModuleEmptyStateWidget(
        title: l10n.logsSystemFilesLabel,
        description: l10n.logNoLogs,
        icon: Icons.article_outlined,
      );
    }
    return LogViewer(
      controller: _controller,
      onRefresh: () => provider.loadSelectedFile(latest: true),
      emptyMessage: l10n.logNoLogs,
    );
  }
}

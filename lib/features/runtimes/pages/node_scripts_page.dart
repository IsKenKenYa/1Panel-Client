import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';
import 'package:onepanel_client/features/runtimes/providers/node_scripts_provider.dart';
import 'package:onepanel_client/features/runtimes/utils/runtime_l10n_helper.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:provider/provider.dart';

class NodeScriptsPage extends StatefulWidget {
  const NodeScriptsPage({
    super.key,
    required this.args,
  });

  final RuntimeManageArgs args;

  @override
  State<NodeScriptsPage> createState() => _NodeScriptsPageState();
}

class _NodeScriptsPageState extends State<NodeScriptsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<NodeScriptsProvider>().initialize(widget.args);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<NodeScriptsProvider>(
      builder: (context, provider, _) {
        final title = provider.runtimeName.trim().isEmpty
            ? l10n.operationsNodeScriptsTitle
            : '${provider.runtimeName} · ${l10n.operationsNodeScriptsTitle}';
        return ServerAwarePageScaffold(
          title: title,
          onServerChanged: () =>
              context.read<NodeScriptsProvider>().initialize(widget.args),
          actions: <Widget>[
            IconButton(
              onPressed: provider.isLoading ? null : provider.load,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
          ],
          body: AsyncStatePageBodyWidget(
            isLoading: provider.isLoading,
            isEmpty: provider.isEmpty,
            errorMessage: localizeRuntimeError(l10n, provider.errorMessage),
            onRetry: provider.load,
            emptyTitle: l10n.runtimeEmptyTitle,
            emptyDescription: provider.codeDir.isEmpty
                ? l10n.runtimeFormCodeDirRequired
                : l10n.runtimeEmptyDescription,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                if (provider.codeDir.isNotEmpty)
                  Text('${l10n.runtimeFieldCodeDir}: ${provider.codeDir}'),
                if (provider.isRunning ||
                    provider.hasExecutionFeedback ||
                    provider.runErrorMessage != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _buildExecutionFeedbackCard(context, provider),
                ],
                const SizedBox(height: 8),
                ...provider.items.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(item.script),
                      trailing: FilledButton.tonal(
                        onPressed: provider.isRunning
                            ? null
                            : () => _runScript(item.name),
                        child: Text(l10n.scriptLibraryRunAction),
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

  Future<void> _runScript(String name) async {
    final success = await context.read<NodeScriptsProvider>().runScript(name);
    if (!mounted) {
      return;
    }
    final provider = context.read<NodeScriptsProvider>();
    final runError =
        localizeRuntimeError(context.l10n, provider.runErrorMessage);
    final statusText = provider.executionStatus.isEmpty
        ? context.l10n.runtimeStatusUnknown('-')
        : runtimeStatusLabel(context.l10n, provider.executionStatus);

    final message = switch (success) {
      true => context.l10n.runtimeNodeScriptCompletedWithStatus(statusText),
      false when runError != null => runError,
      _ => context.l10n.runtimeNodeScriptFailedWithStatus(statusText),
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget _buildExecutionFeedbackCard(
    BuildContext context,
    NodeScriptsProvider provider,
  ) {
    final l10n = context.l10n;
    final statusText = provider.executionStatus.isEmpty
        ? l10n.runtimeStatusUnknown('-')
        : runtimeStatusLabel(l10n, provider.executionStatus);
    final localizedError = localizeRuntimeError(l10n, provider.runErrorMessage);
    final subtitleLines = <String>[];

    if (provider.executionStatus.isNotEmpty) {
      subtitleLines.add(l10n.runtimeNodeScriptRuntimeStatus(statusText));
    }
    if (provider.pollAttempts > 0) {
      subtitleLines
          .add(l10n.runtimeNodeScriptPollAttempts(provider.pollAttempts));
    }
    if (provider.executionMessage?.isNotEmpty ?? false) {
      subtitleLines.add(
        l10n.runtimeNodeScriptRuntimeMessage(provider.executionMessage!),
      );
    }
    if (localizedError != null && localizedError.isNotEmpty) {
      subtitleLines.add(localizedError);
    }

    final title = provider.isRunning
        ? l10n.runtimeNodeScriptExecuting(provider.activeScriptName)
        : (provider.lastRunSuccess == true
            ? l10n.runtimeNodeScriptCompleted
            : l10n.runtimeNodeScriptFailed);

    final leading = provider.isRunning
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        : Icon(
            provider.lastRunSuccess == true
                ? Icons.check_circle_outline
                : Icons.error_outline,
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                leading,
                const SizedBox(width: 8),
                Expanded(child: Text(title)),
              ],
            ),
            if (provider.isRunning) ...<Widget>[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 3),
            ],
            if (subtitleLines.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text(subtitleLines.join('\n')),
            ],
          ],
        ),
      ),
    );
  }
}

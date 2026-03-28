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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? context.l10n.commonSaveSuccess : context.l10n.commonSaveFailed),
      ),
    );
  }
}

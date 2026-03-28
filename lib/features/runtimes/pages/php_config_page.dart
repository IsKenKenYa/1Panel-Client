import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';
import 'package:onepanel_client/features/runtimes/providers/php_config_provider.dart';
import 'package:onepanel_client/features/runtimes/utils/runtime_l10n_helper.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:provider/provider.dart';

class PhpConfigPage extends StatefulWidget {
  const PhpConfigPage({
    super.key,
    required this.args,
  });

  final RuntimeManageArgs args;

  @override
  State<PhpConfigPage> createState() => _PhpConfigPageState();
}

class _PhpConfigPageState extends State<PhpConfigPage> {
  late final TextEditingController _uploadMaxSizeController;
  late final TextEditingController _maxExecutionTimeController;
  late final TextEditingController _disableFunctionsController;

  @override
  void initState() {
    super.initState();
    _uploadMaxSizeController = TextEditingController();
    _maxExecutionTimeController = TextEditingController();
    _disableFunctionsController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<PhpConfigProvider>().initialize(widget.args);
    });
  }

  @override
  void dispose() {
    _uploadMaxSizeController.dispose();
    _maxExecutionTimeController.dispose();
    _disableFunctionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<PhpConfigProvider>(
      builder: (context, provider, _) {
        if (_uploadMaxSizeController.text != provider.uploadMaxSize) {
          _uploadMaxSizeController.text = provider.uploadMaxSize;
        }
        if (_maxExecutionTimeController.text != provider.maxExecutionTime) {
          _maxExecutionTimeController.text = provider.maxExecutionTime;
        }
        if (_disableFunctionsController.text != provider.disableFunctions) {
          _disableFunctionsController.text = provider.disableFunctions;
        }
        final title = provider.runtimeName.trim().isEmpty
            ? l10n.operationsPhpConfigTitle
            : '${provider.runtimeName} · ${l10n.operationsPhpConfigTitle}';
        return ServerAwarePageScaffold(
          title: title,
          onServerChanged: () =>
              context.read<PhpConfigProvider>().initialize(widget.args),
          actions: <Widget>[
            IconButton(
              onPressed: provider.isLoading ? null : provider.load,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
          ],
          body: AsyncStatePageBodyWidget(
            isLoading: provider.isLoading,
            errorMessage: localizeRuntimeError(l10n, provider.errorMessage),
            onRetry: provider.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                TextFormField(
                  controller: _uploadMaxSizeController,
                  onChanged: provider.updateUploadMaxSize,
                  decoration: InputDecoration(
                    labelText: l10n.runtimeFieldSource,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maxExecutionTimeController,
                  onChanged: provider.updateMaxExecutionTime,
                  decoration: InputDecoration(
                    labelText: l10n.runtimeFieldExecScript,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _disableFunctionsController,
                  onChanged: provider.updateDisableFunctions,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.runtimeFieldParams,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '${l10n.runtimeTypePhp} ${l10n.runtimeFieldStatus}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (provider.fpmStatus.isEmpty)
                  Text(l10n.runtimeEmptyDescription)
                else
                  ...provider.fpmStatus.map(
                    (item) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.key),
                      subtitle: Text('${item.value ?? '-'}'),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FilledButton(
              onPressed: provider.isSaving ? null : _save,
              child: provider.isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonSave),
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final success = await context.read<PhpConfigProvider>().save();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? context.l10n.commonSaveSuccess : context.l10n.commonSaveFailed,
        ),
      ),
    );
  }
}

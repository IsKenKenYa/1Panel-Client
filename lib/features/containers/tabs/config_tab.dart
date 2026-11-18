import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';
import '../containers_provider.dart';

class ConfigTab extends StatefulWidget {
  const ConfigTab({super.key});

  @override
  State<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends State<ConfigTab> {
  final _controller = TextEditingController();
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContainersProvider>().loadConfig();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<ContainersProvider>(
      builder: (context, provider, _) {
        final config = provider.data.daemonJson;

        // Sync controller text only once from provider data; subsequent
        // rebuilds must preserve user edits in the text field.
        if (!_isLoaded && config.isNotEmpty) {
          _controller.text = config;
          _isLoaded = true;
        }

        if (provider.configState.isLoading && config.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.configState.error != null && config.isEmpty) {
          return ModuleErrorStateWidget(
            message: provider.configState.error,
            onRetry: provider.loadConfig,
          );
        }

        return PartialErrorToastListener(
          errorMessage: provider.configState.error,
          hasCachedData: config.isNotEmpty,
          onRetry: provider.loadConfig,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                maxLines: null,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.containerTabConfig,
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final success =
                      await provider.updateDaemonJson(_controller.text);
                  if (!mounted) return;
                  if (success) {
                    SnackBarUtils.showSuccess(context, l10n.commonSaveSuccess);
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: Text(l10n.commonSave),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}

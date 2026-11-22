import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/api/v2/container_v2.dart';
import 'package:onepanel_client/data/models/container_models.dart';

/// Docker daemon configuration page.
/// Mirrors frontend's container/setting page: view/edit daemon.json.
class DockerConfigPage extends StatefulWidget {
  const DockerConfigPage({super.key});

  @override
  State<DockerConfigPage> createState() => _DockerConfigPageState();
}

class _DockerConfigPageState extends State<DockerConfigPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = ContainerV2Api(await ApiClientManager.instance.getCurrentClient());
      final response = await api.getDaemonJsonFile();
      final content = response.data ?? '';
      _controller.text = content;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final api = ContainerV2Api(await ApiClientManager.instance.getCurrentClient());
      await api.updateDaemonJsonByFile(DaemonJsonUpdateByFile(file: _controller.text));
      if (mounted) SnackBarUtils.showSuccess(context, context.l10n.commonSaveSuccess);
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.commonSaveFailed);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title:  Text(context.l10n.dockerConfigTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _isSaving ? null : _save,
            tooltip: context.l10n.commonSave,
          ),
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh_outlined), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ModuleErrorStateWidget(message: _error, onRetry: _load)
              : Padding(
                  padding: AppDesignTokens.cardPadding,
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      labelText: 'daemon.json',
                      border: OutlineInputBorder(),
                      hintText: '{\n  "registry-mirrors": []\n}',
                    ),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  ),
                ),
    );
  }
}

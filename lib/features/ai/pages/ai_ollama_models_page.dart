import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/ai/ai_repository.dart';
import 'package:onepanel_client/data/models/ai_models.dart';

/// Ollama model management page (deep).
/// Mirrors frontend's ai/model/ollama page: list/load/delete/sync models.
class AiOllamaModelsPage extends StatefulWidget {
  const AiOllamaModelsPage({super.key});

  @override
  State<AiOllamaModelsPage> createState() => _AiOllamaModelsPageState();
}

class _AiOllamaModelsPageState extends State<AiOllamaModelsPage> {
  final AIRepository _repo = AIRepository();
  List<OllamaModel> _models = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _repo.searchOllamaModels(page: 1, pageSize: 100);
      if (mounted) setState(() { _models = result.items; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _deleteModel(int id) async {
    try {
      await _repo.deleteOllamaModel(ids: [id]);
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, context.l10n.commonDeleted);
      _load();
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.commonDeleteFailed);
    }
  }

  Future<void> _loadModel(String name) async {
    try {
      await _repo.loadOllamaModel(name: name, taskID: '');
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, context.l10n.aiOllamaLoading);
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.aiOllamaLoadFailed);
    }
  }

  Future<void> _syncModels() async {
    try {
      await _repo.syncOllamaModels();
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, context.l10n.aiOllamaSynced);
      _load();
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.aiOllamaSyncFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title:  Text(context.l10n.aiOllamaTitle),
        actions: [
          IconButton(icon: const Icon(Icons.sync), onPressed: _syncModels, tooltip: context.l10n.aiOllamaSync),
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _models.isEmpty
                  ?  Center(child: Text(context.l10n.aiOllamaEmpty))
                  : ListView.builder(
                      itemCount: _models.length,
                      itemBuilder: (context, index) {
                        final m = _models[index];
                        return Card(
                          child: ListTile(
                            title: Text(m.name ?? 'Unknown'),
                            subtitle: Text('${context.l10n.aiOllamaSizeWith(m.size ?? 'N/A')} | ${context.l10n.aiOllamaModified}: ${m.modified ?? 'N/A'}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.download_for_offline),
                                  tooltip: context.l10n.commonLoad,
                                  onPressed: () => _loadModel(m.name ?? ''),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: context.l10n.commonDelete,
                                  onPressed: () => _deleteModel(m.id ?? 0),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

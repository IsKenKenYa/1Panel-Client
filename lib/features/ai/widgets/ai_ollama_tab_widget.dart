import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/ai/ai_provider.dart';
import 'package:onepanel_client/features/ai/widgets/ai_ollama_tab_actions.dart';
import 'package:provider/provider.dart';

class AIOllamaTabWidget extends StatefulWidget {
  const AIOllamaTabWidget({super.key});

  @override
  State<AIOllamaTabWidget> createState() => _AIOllamaTabWidgetState();
}

class _AIOllamaTabWidgetState extends State<AIOllamaTabWidget> {
  final _searchController = TextEditingController();
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AIProvider>().searchOllamaModels();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<AIProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: () => provider.searchOllamaModels(
            info: _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () => provider.searchOllamaModels(
                      info: _searchController.text.trim().isEmpty
                          ? null
                          : _searchController.text.trim(),
                    ),
                    icon: const Icon(Icons.search),
                  ),
                  labelText: l10n.commonSearch,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (value) => provider.searchOllamaModels(
                  info: value.trim().isEmpty ? null : value.trim(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () =>
                            AIOllamaTabActions.handleCreate(context, provider),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.aiModelCreate),
                  ),
                  OutlinedButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () => AIOllamaTabActions.runAction(
                              context,
                              provider,
                              provider.syncOllamaModels,
                            ),
                    icon: const Icon(Icons.sync),
                    label: Text(l10n.aiModelSync),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (provider.ollamaModelList.isEmpty && !provider.isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Text(l10n.commonEmpty),
                  ),
                )
              else
                ...provider.ollamaModelList.map((model) {
                  final modelName = model.name ?? '-';
                  final modelId = model.id ?? 0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(modelName),
                      subtitle: Text(
                        '${model.size ?? '-'}  ${model.modified ?? ''}'.trim(),
                      ),
                      trailing: PopupMenuButton<String>(
                        tooltip: l10n.commonMore,
                        onSelected: (value) {
                          if (value == 'load') {
                            AIOllamaTabActions.runAction(
                              context,
                              provider,
                              () => provider.loadOllamaModel(name: modelName),
                            );
                          }
                          if (value == 'close') {
                            AIOllamaTabActions.runAction(
                              context,
                              provider,
                              () => provider.closeOllamaModel(name: modelName),
                            );
                          }
                          if (value == 'recreate') {
                            AIOllamaTabActions.runAction(
                              context,
                              provider,
                              () =>
                                  provider.recreateOllamaModel(name: modelName),
                            );
                          }
                          if (value == 'delete' && modelId > 0) {
                            AIOllamaTabActions.handleDelete(
                              context,
                              provider,
                              modelId,
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'load',
                            child: Text(l10n.commonLoad),
                          ),
                          PopupMenuItem(
                            value: 'close',
                            child: Text(l10n.commonClose),
                          ),
                          PopupMenuItem(
                            value: 'recreate',
                            child: Text(l10n.aiModelRecreate),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(l10n.commonDelete),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              if (provider.lastOperationMessage != null &&
                  provider.lastOperationMessage!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.aiOperationResult),
                    subtitle: SelectableText(provider.lastOperationMessage!),
                    trailing: IconButton(
                      onPressed: provider.clearLastOperationMessage,
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

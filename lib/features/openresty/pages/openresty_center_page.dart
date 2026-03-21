import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/data/models/openresty_models.dart';
import 'package:onepanelapp_app/features/openresty/pages/openresty_source_editor_page.dart';
import 'package:onepanelapp_app/features/openresty/providers/openresty_provider.dart';
import 'package:onepanelapp_app/features/openresty/widgets/openresty_error_view.dart';
import 'package:onepanelapp_app/features/openresty/widgets/openresty_json_editor.dart';
import 'package:onepanelapp_app/features/openresty/widgets/openresty_json_view.dart';

class OpenRestyCenterPage extends StatefulWidget {
  const OpenRestyCenterPage({super.key});

  @override
  State<OpenRestyCenterPage> createState() => _OpenRestyCenterPageState();
}

class _OpenRestyCenterPageState extends State<OpenRestyCenterPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _buildMirrorController = TextEditingController();
  final TextEditingController _buildTaskIdController = TextEditingController();
  final TextEditingController _scopeWebsiteIdController = TextEditingController();

  NginxKey _scopeKey = NginxKey.indexKey;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buildMirrorController.dispose();
    _buildTaskIdController.dispose();
    _scopeWebsiteIdController.dispose();
    super.dispose();
  }

  Future<void> _runWithFeedback(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await action();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.commonSaveSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openSourceEditor(OpenRestyProvider provider) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<OpenRestyProvider>.value(
          value: provider,
          child: const OpenRestySourceEditorPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<OpenRestyProvider>(
      builder: (context, provider, _) {
        if (provider.error != null && !provider.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.openrestyPageTitle)),
            body: OpenRestyErrorView(
              message: provider.error!,
              onRetry: provider.loadAll,
            ),
          );
        }

        if (provider.isLoading && !provider.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.openrestyPageTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final mirror = provider.modules?['mirror']?.toString();
        if (_buildMirrorController.text.isEmpty && mirror != null && mirror.isNotEmpty) {
          _buildMirrorController.text = mirror;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.openrestyPageTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.commonRefresh,
                onPressed: provider.refresh,
              ),
              IconButton(
                icon: const Icon(Icons.edit_note),
                tooltip: l10n.openrestyTabConfig,
                onPressed: () => _openSourceEditor(provider),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                Tab(text: l10n.openrestyTabStatus),
                Tab(text: l10n.openrestyTabHttps),
                Tab(text: l10n.openrestyTabModules),
                Tab(text: l10n.openrestyTabConfig),
                Tab(text: l10n.openrestyTabBuild),
                Tab(text: l10n.openrestyTabScope),
              ],
            ),
          ),
          body: Column(
            children: [
              if (provider.isLoading) const LinearProgressIndicator(),
              if (provider.error != null && provider.hasData)
                MaterialBanner(
                  content: Text(provider.error!),
                  actions: [
                    TextButton(
                      onPressed: provider.refresh,
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    OpenRestyJsonView(text: provider.statusJson),
                    OpenRestyJsonEditor(
                      initialText: provider.httpsJson,
                      saveLabel: l10n.commonSave,
                      hintText: l10n.websitesJsonHint,
                      isSaving: provider.isSaving,
                      onSave: (value) => _runWithFeedback(() => provider.updateHttpsFromJson(value)),
                    ),
                    OpenRestyJsonEditor(
                      initialText: provider.modulesJson,
                      saveLabel: l10n.commonSave,
                      hintText: l10n.websitesJsonHint,
                      isSaving: provider.isSaving,
                      onSave: (value) => _runWithFeedback(() => provider.updateModulesFromJson(value)),
                    ),
                    _ConfigTab(
                      content: provider.configContent,
                      onOpenSourceEditor: () => _openSourceEditor(provider),
                    ),
                    _BuildTab(
                      mirrorController: _buildMirrorController,
                      taskIdController: _buildTaskIdController,
                      onBuild: () => _runWithFeedback(
                        () => provider.buildOpenResty(
                          mirror: _buildMirrorController.text.trim(),
                          taskId: _buildTaskIdController.text.trim(),
                        ),
                      ),
                    ),
                    _ScopeTab(
                      scopeKey: _scopeKey,
                      onScopeChanged: (value) => setState(() => _scopeKey = value),
                      websiteIdController: _scopeWebsiteIdController,
                      resultText: provider.scopeParamsJson,
                      onLoad: () => _runWithFeedback(() async {
                        final websiteId = int.tryParse(_scopeWebsiteIdController.text.trim());
                        await provider.loadScope(scope: _scopeKey, websiteId: websiteId);
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConfigTab extends StatelessWidget {
  final String content;
  final VoidCallback onOpenSourceEditor;

  const _ConfigTab({
    required this.content,
    required this.onOpenSourceEditor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed: onOpenSourceEditor,
                icon: const Icon(Icons.code),
                label: Text(l10n.commonEdit),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: SingleChildScrollView(
                child: SelectableText(content.isEmpty ? '-' : content),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildTab extends StatelessWidget {
  final TextEditingController mirrorController;
  final TextEditingController taskIdController;
  final Future<void> Function() onBuild;

  const _BuildTab({
    required this.mirrorController,
    required this.taskIdController,
    required this.onBuild,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: mirrorController,
            decoration: InputDecoration(
              labelText: l10n.openrestyBuildMirrorLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: taskIdController,
            decoration: InputDecoration(
              labelText: l10n.openrestyBuildTaskIdLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: onBuild,
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.openrestyBuildAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScopeTab extends StatelessWidget {
  final NginxKey scopeKey;
  final ValueChanged<NginxKey> onScopeChanged;
  final TextEditingController websiteIdController;
  final String resultText;
  final Future<void> Function() onLoad;

  const _ScopeTab({
    required this.scopeKey,
    required this.onScopeChanged,
    required this.websiteIdController,
    required this.resultText,
    required this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<NginxKey>(
            initialValue: scopeKey,
            decoration: InputDecoration(
              labelText: l10n.openrestyScopeLabel,
              border: const OutlineInputBorder(),
            ),
            items: NginxKey.values
                .map((key) => DropdownMenuItem(
                      value: key,
                      child: Text(key.value),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onScopeChanged(value);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: websiteIdController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.openrestyScopeWebsiteIdLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: onLoad,
                icon: const Icon(Icons.search),
                label: Text(l10n.openrestyScopeLoad),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  resultText.trim().isEmpty ? l10n.openrestyScopeResultHint : resultText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

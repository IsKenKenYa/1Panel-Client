import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/v2/openresty_v2.dart';
import '../../core/network/api_client_manager.dart';
import '../../data/models/openresty_models.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';

class OpenRestyPage extends StatelessWidget {
  const OpenRestyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OpenRestyProvider()..loadAll(),
      child: const _OpenRestyBody(),
    );
  }
}

class OpenRestyProvider extends ChangeNotifier {
  OpenRestyV2Api? _api;
  bool isLoading = false;
  String? error;

  Map<String, dynamic>? status;
  Map<String, dynamic>? modules;
  Map<String, dynamic>? https;
  Map<String, dynamic>? config;
  List<OpenrestyParam> scopeParams = const [];

  Future<void> _ensureApi() async {
    if (_api != null) return;
    _api = await ApiClientManager.instance.getOpenRestyApi();
  }

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _ensureApi();
      final results = await Future.wait([
        _api!.getOpenRestyStatus(),
        _api!.getOpenRestyModules(),
        _api!.getOpenRestyHttps(),
        _api!.getOpenRestyConfig(),
      ]);

      status = (results[0].data as OpenrestyStatus?)?.toJson() ?? <String, dynamic>{};
      modules = (results[1].data as OpenrestyBuildConfig?)?.toJson() ?? <String, dynamic>{};
      https = (results[2].data as OpenrestyHttpsConfig?)?.toJson() ?? <String, dynamic>{};
      config = (results[3].data as OpenrestyFile?)?.toJson() ?? <String, dynamic>{};
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateHttps(Map<String, dynamic> request) async {
    await _ensureApi();
    await _api!.updateOpenRestyHttps(OpenrestyDefaultHttpsUpdateRequest.fromJson(request));
    await loadAll();
  }

  Future<void> updateModules(Map<String, dynamic> request) async {
    await _ensureApi();
    await _api!.updateOpenRestyModules(OpenrestyModuleUpdateRequest.fromJson(request));
    await loadAll();
  }

  Future<void> updateConfig(String content) async {
    await _ensureApi();
    await _api!.updateOpenRestyConfigByFile(OpenrestyConfigFileUpdateRequest(content: content));
    await loadAll();
  }

  Future<void> buildOpenResty({
    required String mirror,
    required String taskId,
  }) async {
    await _ensureApi();
    await _api!.buildOpenResty(OpenrestyBuildRequest(mirror: mirror, taskId: taskId));
  }

  Future<void> loadScope({
    required NginxKey scope,
    int? websiteId,
  }) async {
    await _ensureApi();
    final response = await _api!.getOpenRestyScope(OpenrestyScopeRequest(scope: scope, websiteId: websiteId));
    scopeParams = response.data ?? const [];
    notifyListeners();
  }
}

class _OpenRestyBody extends StatefulWidget {
  const _OpenRestyBody();

  @override
  State<_OpenRestyBody> createState() => _OpenRestyBodyState();
}

class _OpenRestyBodyState extends State<_OpenRestyBody> with SingleTickerProviderStateMixin {
  late final TabController _controller;

  final TextEditingController _httpsController = TextEditingController();
  final TextEditingController _modulesController = TextEditingController();
  final TextEditingController _configController = TextEditingController();
  final TextEditingController _buildMirrorController = TextEditingController();
  final TextEditingController _buildTaskIdController = TextEditingController();
  final TextEditingController _scopeWebsiteIdController = TextEditingController();
  final TextEditingController _scopeResultController = TextEditingController();

  NginxKey _scopeKey = NginxKey.indexKey;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _httpsController.dispose();
    _modulesController.dispose();
    _configController.dispose();
    _buildMirrorController.dispose();
    _buildTaskIdController.dispose();
    _scopeWebsiteIdController.dispose();
    _scopeResultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<OpenRestyProvider>(
      builder: (context, provider, _) {
        if (provider.error != null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.openrestyPageTitle)),
            body: _ErrorSection(
              message: provider.error!,
              onRetry: provider.loadAll,
            ),
          );
        }

        if (provider.isLoading && provider.status == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.openrestyPageTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        _httpsController.text = provider.https == null ? '' : const JsonEncoder.withIndent('  ').convert(provider.https);
        _modulesController.text =
            provider.modules == null ? '' : const JsonEncoder.withIndent('  ').convert(provider.modules);
        _configController.text = provider.config == null ? '' : const JsonEncoder.withIndent('  ').convert(provider.config);
        _scopeResultController.text =
            provider.scopeParams.isEmpty ? '' : const JsonEncoder.withIndent('  ').convert(provider.scopeParams.map((e) => e.toJson()).toList());
        if (_buildMirrorController.text.isEmpty && provider.modules != null) {
          final mirror = provider.modules?['mirror']?.toString();
          if (mirror != null && mirror.isNotEmpty) {
            _buildMirrorController.text = mirror;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.openrestyPageTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.commonRefresh,
                onPressed: provider.loadAll,
              ),
            ],
            bottom: TabBar(
              controller: _controller,
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
          body: TabBarView(
            controller: _controller,
            children: [
              _JsonViewTab(
                jsonMap: provider.status,
              ),
              _JsonEditTab(
                controller: _httpsController,
                onSave: () async {
                  final map = jsonDecode(_httpsController.text) as Map<String, dynamic>;
                  await provider.updateHttps(map);
                },
              ),
              _JsonEditTab(
                controller: _modulesController,
                onSave: () async {
                  final map = jsonDecode(_modulesController.text) as Map<String, dynamic>;
                  await provider.updateModules(map);
                },
              ),
              _JsonEditTab(
                controller: _configController,
                onSave: () async {
                  final map = jsonDecode(_configController.text) as Map<String, dynamic>;
                  await provider.updateConfig(jsonEncode(map));
                },
              ),
              _BuildTab(
                mirrorController: _buildMirrorController,
                taskIdController: _buildTaskIdController,
                onBuild: () async {
                  await provider.buildOpenResty(
                    mirror: _buildMirrorController.text.trim(),
                    taskId: _buildTaskIdController.text.trim(),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.commonSaveSuccess)),
                  );
                },
              ),
              _ScopeTab(
                scopeKey: _scopeKey,
                onScopeChanged: (value) => setState(() => _scopeKey = value),
                websiteIdController: _scopeWebsiteIdController,
                resultController: _scopeResultController,
                onLoad: () async {
                  final websiteId = int.tryParse(_scopeWebsiteIdController.text.trim());
                  await provider.loadScope(scope: _scopeKey, websiteId: websiteId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.commonSaveSuccess)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _JsonViewTab extends StatelessWidget {
  final Map<String, dynamic>? jsonMap;

  const _JsonViewTab({required this.jsonMap});

  @override
  Widget build(BuildContext context) {
    final text = jsonMap == null ? '' : const JsonEncoder.withIndent('  ').convert(jsonMap);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SelectableText(text),
    );
  }
}

class _JsonEditTab extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function() onSave;

  const _JsonEditTab({
    required this.controller,
    required this.onSave,
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
                onPressed: onSave,
                icon: const Icon(Icons.save),
                label: Text(l10n.commonSave),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: controller,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: l10n.websitesJsonHint,
                border: const OutlineInputBorder(),
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
  final TextEditingController resultController;
  final Future<void> Function() onLoad;

  const _ScopeTab({
    required this.scopeKey,
    required this.onScopeChanged,
    required this.websiteIdController,
    required this.resultController,
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
            value: scopeKey,
            decoration: InputDecoration(
              labelText: l10n.openrestyScopeLabel,
              border: const OutlineInputBorder(),
            ),
            items: NginxKey.values
                .map((key) => DropdownMenuItem(value: key, child: Text(key.value)))
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
            child: TextField(
              controller: resultController,
              readOnly: true,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: l10n.openrestyScopeResultHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorSection({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(l10n.commonLoadFailedTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

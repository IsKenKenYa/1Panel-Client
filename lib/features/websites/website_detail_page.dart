import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../api/v2/ssl_v2.dart';
import '../../api/v2/website_v2.dart';
import '../../core/network/api_client_manager.dart';
import '../../data/models/file/file_info.dart';
import '../../data/models/openresty_models.dart';
import '../../data/models/ssl_models.dart' as ssl_models;
import '../../data/models/website_models.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';

class WebsiteDetailPage extends StatelessWidget {
  final int websiteId;

  const WebsiteDetailPage({super.key, required this.websiteId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebsiteDetailProvider(websiteId: websiteId)..loadAll(),
      child: const _WebsiteDetailBody(),
    );
  }
}

class WebsiteDetailProvider extends ChangeNotifier {
  final int websiteId;

  WebsiteV2Api? _api;
  SSLV2Api? _sslApi;

  bool isLoading = false;
  String? error;

  WebsiteInfo? website;
  FileInfo? nginxConfigFile;
  List<WebsiteDomain> domains = const [];
  ssl_models.WebsiteSSL? ssl;
  String? sslError;
  Map<String, dynamic>? https;
  Map<String, dynamic>? rewrite;
  Map<String, dynamic>? proxy;

  String rewriteName = 'default';
  String proxyName = 'default';

  WebsiteDetailProvider({required this.websiteId});

  Future<void> _ensureApi() async {
    if (_api != null) return;
    _api = await ApiClientManager.instance.getWebsiteApi();
  }

  Future<void> _ensureSslApi() async {
    if (_sslApi != null) return;
    _sslApi = await ApiClientManager.instance.getSslApi();
  }

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _ensureApi();
      website = await _api!.getWebsiteDetail(websiteId);
      await Future.wait([
        loadConfig(),
        loadDomains(),
        loadHttps(),
        loadWebsiteSsl(),
      ]);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadConfig() async {
    await _ensureApi();
    nginxConfigFile = await _api!.getWebsiteConfigFile(id: websiteId, type: 'nginx');
    notifyListeners();
  }

  Future<void> saveConfig(String content) async {
    await _ensureApi();
    await _api!.updateWebsiteNginxConfig(id: websiteId, content: content);
    await loadConfig();
  }

  Future<Map<String, dynamic>> loadWebsiteNginxConfig(Map<String, dynamic> request) async {
    await _ensureApi();
    return await _api!.loadWebsiteNginxConfig(request);
  }

  Future<void> updateWebsiteNginxConfigByRequest(Map<String, dynamic> request) async {
    await _ensureApi();
    await _api!.updateWebsiteNginxConfigByRequest(request);
  }

  Future<void> loadDomains() async {
    await _ensureApi();
    domains = await _api!.getWebsiteDomains(websiteId);
    notifyListeners();
  }

  Future<void> addDomain(String domain) async {
    await _ensureApi();
    await _api!.addWebsiteDomains(
      websiteId: websiteId,
      domains: [
        {'domain': domain},
      ],
    );
    await loadDomains();
  }

  Future<void> deleteDomain(int domainId) async {
    await _ensureApi();
    await _api!.deleteWebsiteDomain(id: domainId);
    await loadDomains();
  }

  Future<void> updateDomainSsl({
    required int domainId,
    required bool ssl,
  }) async {
    await _ensureApi();
    await _api!.updateWebsiteDomainSsl(id: domainId, ssl: ssl);
    await loadDomains();
  }

  Future<void> loadHttps() async {
    await _ensureApi();
    https = await _api!.getWebsiteHttps(websiteId);
    notifyListeners();
  }

  Future<void> updateHttps(Map<String, dynamic> request) async {
    await _ensureApi();
    final next = await _api!.updateWebsiteHttps(websiteId: websiteId, request: request);
    https = next;
    notifyListeners();
  }

  Future<void> loadWebsiteSsl() async {
    try {
      await _ensureSslApi();
      final response = await _sslApi!.getWebsiteSSLByWebsiteId(websiteId);
      ssl = response.data;
      sslError = null;
    } catch (e) {
      ssl = null;
      sslError = e.toString();
    }
    notifyListeners();
  }

  Future<String?> downloadWebsiteSsl() async {
    final id = ssl?.id;
    if (id == null) return null;
    await _ensureSslApi();
    final response = await _sslApi!.downloadSSLFile(id);
    return response.data;
  }

  Future<bool> setWebsiteSslAutoRenew(bool value) async {
    final id = ssl?.id;
    if (id == null) return false;
    await _ensureSslApi();
    await _sslApi!.updateWebsiteSSL(ssl_models.WebsiteSSLUpdate(id: id, autoRenew: value));
    await loadWebsiteSsl();
    return true;
  }

  Future<void> loadRewrite(String name) async {
    await _ensureApi();
    rewriteName = name;
    rewrite = await _api!.getWebsiteRewrite(websiteId: websiteId, name: name);
    notifyListeners();
  }

  Future<void> saveRewrite({required String name, required String content}) async {
    await _ensureApi();
    await _api!.updateWebsiteRewrite(websiteId: websiteId, name: name, content: content);
    await loadRewrite(name);
  }

  Future<void> loadProxy() async {
    await _ensureApi();
    proxy = await _api!.getWebsiteProxy(id: websiteId);
    notifyListeners();
  }

  Future<void> saveProxy({required String name, required String content}) async {
    await _ensureApi();
    await _api!.updateWebsiteProxy(websiteId: websiteId, name: name, content: content);
    await loadProxy();
  }
}

class _WebsiteDetailBody extends StatefulWidget {
  const _WebsiteDetailBody();

  @override
  State<_WebsiteDetailBody> createState() => _WebsiteDetailBodyState();
}

class _WebsiteDetailBodyState extends State<_WebsiteDetailBody> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _configController = TextEditingController();
  final TextEditingController _rewriteNameController = TextEditingController();
  final TextEditingController _rewriteContentController = TextEditingController();
  final TextEditingController _proxyNameController = TextEditingController();
  final TextEditingController _proxyContentController = TextEditingController();
  final TextEditingController _httpsController = TextEditingController();
  final TextEditingController _nginxScopeWebsiteIdController = TextEditingController();
  final TextEditingController _nginxScopeResultController = TextEditingController();
  final TextEditingController _nginxUpdateWebsiteIdController = TextEditingController();
  final TextEditingController _nginxUpdateParamsController = TextEditingController();

  NginxKey _nginxScopeKey = NginxKey.indexKey;
  NginxKey _nginxUpdateScopeKey = NginxKey.indexKey;
  String _nginxUpdateOperate = 'update';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = context.l10n;
      if (_rewriteNameController.text.isEmpty) {
        _rewriteNameController.text = l10n.websitesDefaultName;
      }
      if (_proxyNameController.text.isEmpty) {
        _proxyNameController.text = l10n.websitesDefaultName;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _configController.dispose();
    _rewriteNameController.dispose();
    _rewriteContentController.dispose();
    _proxyNameController.dispose();
    _proxyContentController.dispose();
    _httpsController.dispose();
    _nginxScopeWebsiteIdController.dispose();
    _nginxScopeResultController.dispose();
    _nginxUpdateWebsiteIdController.dispose();
    _nginxUpdateParamsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<WebsiteDetailProvider>(
      builder: (context, provider, _) {
        final title = provider.website?.domain ?? '${l10n.websitesDetailTitle} #${provider.websiteId}';

        if (provider.error != null) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: _ErrorSection(
              message: provider.error!,
              onRetry: provider.loadAll,
            ),
          );
        }

        if (provider.isLoading && provider.website == null) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        _configController.text = provider.nginxConfigFile?.content ?? _configController.text;
        if (provider.https != null) {
          _httpsController.text = const JsonEncoder.withIndent('  ').convert(provider.https);
        }
        if (provider.rewrite != null) {
          _rewriteContentController.text = const JsonEncoder.withIndent('  ').convert(provider.rewrite);
        }
        if (provider.proxy != null) {
          _proxyContentController.text = const JsonEncoder.withIndent('  ').convert(provider.proxy);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                Tab(text: l10n.websitesTabOverview),
                Tab(text: l10n.websitesTabConfig),
                Tab(text: l10n.websitesTabDomains),
                Tab(text: l10n.websitesTabSsl),
                Tab(text: l10n.websitesTabRewrite),
                Tab(text: l10n.websitesTabProxy),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(website: provider.website),
              _ConfigTab(
                controller: _configController,
                onReload: provider.loadConfig,
                onSave: () async => provider.saveConfig(_configController.text),
                onAdvanced: () => _showNginxAdvancedDialog(context, provider),
              ),
              _DomainsTab(
                domains: provider.domains,
                onReload: provider.loadDomains,
                onAdd: () => _showAddDomainDialog(context, provider),
                onDelete: (id) => provider.deleteDomain(id),
                onToggleSsl: (id, value) => provider.updateDomainSsl(domainId: id, ssl: value),
              ),
              _SslTab(
                ssl: provider.ssl,
                sslError: provider.sslError,
                onReloadSsl: provider.loadWebsiteSsl,
                onToggleAutoRenew: provider.setWebsiteSslAutoRenew,
                onDownload: provider.downloadWebsiteSsl,
                httpsController: _httpsController,
                onReloadHttps: provider.loadHttps,
                onSaveHttps: () async {
                  final map = jsonDecode(_httpsController.text) as Map<String, dynamic>;
                  map['websiteId'] = provider.websiteId;
                  await provider.updateHttps(map);
                },
              ),
              _RewriteTab(
                nameController: _rewriteNameController,
                contentController: _rewriteContentController,
                onLoad: () async => provider.loadRewrite(_rewriteNameController.text.trim()),
                onSave: () async => provider.saveRewrite(
                  name: _rewriteNameController.text.trim(),
                  content: _rewriteContentController.text,
                ),
              ),
              _ProxyTab(
                nameController: _proxyNameController,
                contentController: _proxyContentController,
                onLoad: provider.loadProxy,
                onSave: () async => provider.saveProxy(
                  name: _proxyNameController.text.trim(),
                  content: _proxyContentController.text,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showNginxAdvancedDialog(
    BuildContext context,
    WebsiteDetailProvider provider,
  ) async {
    final l10n = context.l10n;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.websitesNginxAdvancedTitle),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.websitesNginxScopeTitle, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<NginxKey>(
                    value: _nginxScopeKey,
                    decoration: InputDecoration(
                      labelText: l10n.websitesNginxScopeLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: NginxKey.values
                        .map((key) => DropdownMenuItem(value: key, child: Text(key.value)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _nginxScopeKey = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nginxScopeWebsiteIdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.websitesNginxScopeWebsiteIdLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          try {
                            final websiteId = int.tryParse(_nginxScopeWebsiteIdController.text.trim());
                            final response = await provider.loadWebsiteNginxConfig({
                              'scope': _nginxScopeKey.value,
                              if (websiteId != null) 'websiteId': websiteId,
                            });
                            _nginxScopeResultController.text = const JsonEncoder.withIndent('  ').convert(response);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.commonSaveSuccess)),
                            );
                          } catch (_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.commonSaveFailed)),
                            );
                          }
                        },
                        icon: const Icon(Icons.search),
                        label: Text(l10n.websitesNginxScopeLoad),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nginxScopeResultController,
                    readOnly: true,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: l10n.websitesNginxScopeResultLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.websitesNginxUpdateTitle, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _nginxUpdateOperate,
                    decoration: InputDecoration(
                      labelText: l10n.websitesNginxUpdateOperateLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'add', child: Text('add')),
                      DropdownMenuItem(value: 'update', child: Text('update')),
                      DropdownMenuItem(value: 'delete', child: Text('delete')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _nginxUpdateOperate = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<NginxKey>(
                    value: _nginxUpdateScopeKey,
                    decoration: InputDecoration(
                      labelText: l10n.websitesNginxUpdateScopeLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: NginxKey.values
                        .map((key) => DropdownMenuItem(value: key, child: Text(key.value)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _nginxUpdateScopeKey = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nginxUpdateWebsiteIdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.websitesNginxUpdateWebsiteIdLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nginxUpdateParamsController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: l10n.websitesNginxUpdateParamsLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          try {
                            final paramsText = _nginxUpdateParamsController.text.trim();
                            final websiteId = int.tryParse(_nginxUpdateWebsiteIdController.text.trim());
                            final request = <String, dynamic>{
                              'operate': _nginxUpdateOperate,
                              'scope': _nginxUpdateScopeKey.value,
                              if (websiteId != null) 'websiteId': websiteId,
                              if (paramsText.isNotEmpty) 'params': jsonDecode(paramsText),
                            };
                            await provider.updateWebsiteNginxConfigByRequest(request);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.commonSaveSuccess)),
                            );
                          } catch (_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.commonSaveFailed)),
                            );
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: Text(l10n.websitesNginxUpdateAction),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.commonClose),
            ),
          ],
        );
      },
    );
  }


  Future<void> _showAddDomainDialog(BuildContext context, WebsiteDetailProvider provider) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.websitesDomainAddTitle),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.websitesDomainLabel,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                final value = controller.text.trim();
                Navigator.of(ctx).pop();
                if (value.isEmpty) return;
                await provider.addDomain(value);
              },
              child: Text(l10n.commonAdd),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }
}

class _OverviewTab extends StatelessWidget {
  final WebsiteInfo? website;

  const _OverviewTab({required this.website});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final w = website;
    if (w == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.domain ?? l10n.websitesUnknownDomain,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('${l10n.websitesStatusLabel}: ${w.status ?? '-'}'),
                Text('${l10n.websitesTypeLabel}: ${w.type ?? '-'}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfigTab extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function() onReload;
  final Future<void> Function() onSave;
  final VoidCallback onAdvanced;

  const _ConfigTab({
    required this.controller,
    required this.onReload,
    required this.onSave,
    required this.onAdvanced,
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
                onPressed: onReload,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRefresh),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save),
                label: Text(l10n.commonSave),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onAdvanced,
                icon: const Icon(Icons.tune),
                label: Text(l10n.websitesNginxAdvancedAction),
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
                hintText: l10n.websitesConfigHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DomainsTab extends StatelessWidget {
  final List<WebsiteDomain> domains;
  final Future<void> Function() onReload;
  final VoidCallback onAdd;
  final Future<void> Function(int id) onDelete;
  final Future<void> Function(int id, bool value) onToggleSsl;

  const _DomainsTab({
    required this.domains,
    required this.onReload,
    required this.onAdd,
    required this.onDelete,
    required this.onToggleSsl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            FilledButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRefresh),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.commonAdd),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (domains.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Center(child: Text(l10n.websitesDomainEmpty)),
          )
        else
          ...domains.map((d) {
            final title = d.domain ?? '-';
            final subtitleItems = <Widget>[];
            if (d.isDefault == true) {
              subtitleItems.add(Text(l10n.websitesDomainDefault));
            }
            subtitleItems.add(
              Text(
                '${l10n.websitesDomainSslLabel}: ${d.ssl == true ? l10n.systemSettingsEnabled : l10n.systemSettingsDisabled}',
              ),
            );
            return Card(
              child: ListTile(
                title: Text(title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: subtitleItems,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: d.ssl ?? false,
                      onChanged: d.id == null ? null : (value) => onToggleSsl(d.id!, value),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: d.id == null ? null : () => onDelete(d.id!),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _JsonEditTab extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function() onReload;
  final Future<void> Function() onSave;

  const _JsonEditTab({
    required this.controller,
    required this.onReload,
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
                onPressed: onReload,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRefresh),
              ),
              const SizedBox(width: 12),
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

class _RewriteTab extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController contentController;
  final Future<void> Function() onLoad;
  final Future<void> Function() onSave;

  const _RewriteTab({
    required this.nameController,
    required this.contentController,
    required this.onLoad,
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
              SizedBox(
                width: 220,
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.websitesRewriteNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: onLoad,
                child: Text(l10n.commonLoad),
              ),
              const SizedBox(width: 12),
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
              controller: contentController,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: l10n.websitesRewriteHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProxyTab extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController contentController;
  final Future<void> Function() onLoad;
  final Future<void> Function() onSave;

  const _ProxyTab({
    required this.nameController,
    required this.contentController,
    required this.onLoad,
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
              SizedBox(
                width: 220,
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.websitesProxyNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: onLoad,
                child: Text(l10n.commonLoad),
              ),
              const SizedBox(width: 12),
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
              controller: contentController,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: l10n.websitesProxyHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SslTab extends StatelessWidget {
  final ssl_models.WebsiteSSL? ssl;
  final String? sslError;
  final Future<void> Function() onReloadSsl;
  final Future<bool> Function(bool value) onToggleAutoRenew;
  final Future<String?> Function() onDownload;
  final TextEditingController httpsController;
  final Future<void> Function() onReloadHttps;
  final Future<void> Function() onSaveHttps;

  const _SslTab({
    required this.ssl,
    required this.sslError,
    required this.onReloadSsl,
    required this.onToggleAutoRenew,
    required this.onDownload,
    required this.httpsController,
    required this.onReloadHttps,
    required this.onSaveHttps,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_outlined),
                  title: Text(l10n.websitesSslInfoTitle),
                  trailing: IconButton(
                    onPressed: onReloadSsl,
                    icon: const Icon(Icons.refresh),
                    tooltip: l10n.commonRefresh,
                  ),
                ),
                if (ssl == null && (sslError == null || sslError!.isEmpty))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(l10n.websitesSslNoCert),
                    ),
                  )
                else if (ssl == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(sslError ?? ''),
                    ),
                  )
                else
                  Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.domain_outlined),
                        title: Text(l10n.websitesSslPrimaryDomain),
                        trailing: Text(ssl!.primaryDomain ?? '-'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.event_outlined),
                        title: Text(l10n.websitesSslExpireDate),
                        trailing: Text(ssl!.expireDate ?? '-'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: Text(l10n.websitesSslStatus),
                        trailing: Text(ssl!.status ?? '-'),
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.autorenew_outlined),
                        title: Text(l10n.websitesSslAutoRenew),
                        value: ssl!.autoRenew ?? false,
                        onChanged: (value) async {
                          final ok = await onToggleAutoRenew(value);
                          if (!context.mounted) return;
                          if (!ok) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.commonSaveSuccess)),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            FilledButton.icon(
                              onPressed: () async {
                                final link = await onDownload();
                                if (!context.mounted) return;
                                if (link == null || link.isEmpty) return;
                                await Clipboard.setData(ClipboardData(text: link));
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.commonCopied)),
                                );
                              },
                              icon: const Icon(Icons.download_outlined),
                              label: Text(l10n.websitesSslDownload),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _JsonEditTab(
              controller: httpsController,
              onReload: onReloadHttps,
              onSave: onSaveHttps,
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

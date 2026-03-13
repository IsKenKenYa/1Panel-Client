import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/v2/website_v2.dart';
import '../../core/network/api_client_manager.dart';
import '../../data/models/website_models.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';

class WebsiteDomainPage extends StatelessWidget {
  final int websiteId;
  final String? primaryDomain;

  const WebsiteDomainPage({super.key, required this.websiteId, this.primaryDomain});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebsiteDomainProvider(websiteId: websiteId)..loadDomains(),
      child: _WebsiteDomainBody(primaryDomain: primaryDomain),
    );
  }
}

class WebsiteDomainProvider extends ChangeNotifier {
  final int websiteId;
  WebsiteV2Api? _api;

  bool isLoading = false;
  String? error;
  List<WebsiteDomain> domains = const [];

  WebsiteDomainProvider({required this.websiteId});

  Future<void> _ensureApi() async {
    if (_api != null) return;
    _api = await ApiClientManager.instance.getWebsiteApi();
  }

  Future<void> loadDomains() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _ensureApi();
      domains = await _api!.getWebsiteDomains(websiteId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDomain({required String domain, required int port, bool ssl = false}) async {
    await _ensureApi();
    await _api!.addWebsiteDomains(
      websiteId: websiteId,
      domains: [
        {
          'domain': domain,
          'port': port,
          'ssl': ssl,
        },
      ],
    );
    await loadDomains();
  }

  Future<void> updateDomainSsl({required int id, required bool ssl}) async {
    await _ensureApi();
    await _api!.updateWebsiteDomainSsl(id: id, ssl: ssl);
    await loadDomains();
  }

  Future<void> deleteDomain(int id) async {
    await _ensureApi();
    await _api!.deleteWebsiteDomain(id: id);
    await loadDomains();
  }
}

class _WebsiteDomainBody extends StatelessWidget {
  final String? primaryDomain;

  const _WebsiteDomainBody({this.primaryDomain});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<WebsiteDomainProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.domains.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.websitesDomainsPageTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null && provider.domains.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.websitesDomainsPageTitle)),
            body: _ErrorSection(message: provider.error!, onRetry: provider.loadDomains),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.websitesDomainsPageTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.loadDomains,
                tooltip: l10n.commonRefresh,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddDomainDialog(context, provider),
            icon: const Icon(Icons.add),
            label: Text(l10n.commonAdd),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (provider.domains.isEmpty)
                _EmptyCard(title: l10n.websitesDomainEmpty)
              else
                ...provider.domains.map(
                  (domain) => _DomainCard(
                    domain: domain,
                    isPrimary: primaryDomain != null && domain.domain != null
                        ? primaryDomain!.startsWith(domain.domain!)
                        : false,
                    onToggleSsl: (value) => provider.updateDomainSsl(id: domain.id!, ssl: value),
                    onDelete: () => provider.deleteDomain(domain.id!),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddDomainDialog(BuildContext context, WebsiteDomainProvider provider) async {
    final l10n = context.l10n;
    final domainController = TextEditingController();
    final portController = TextEditingController(text: '80');
    bool ssl = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(l10n.websitesDomainAddTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: domainController,
                  decoration: InputDecoration(
                    labelText: l10n.websitesDomainLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: portController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.websitesDomainPortLabel,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.websitesDomainSslLabel),
                  value: ssl,
                  onChanged: (value) => setState(() => ssl = value),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () async {
                  final domain = domainController.text.trim();
                  final port = int.tryParse(portController.text.trim()) ?? 80;
                  Navigator.of(ctx).pop();
                  if (domain.isEmpty) return;
                  await provider.addDomain(domain: domain, port: port, ssl: ssl);
                },
                child: Text(l10n.commonAdd),
              ),
            ],
          ),
        );
      },
    );

    domainController.dispose();
    portController.dispose();
  }
}

class _DomainCard extends StatelessWidget {
  final WebsiteDomain domain;
  final bool isPrimary;
  final ValueChanged<bool> onToggleSsl;
  final VoidCallback onDelete;

  const _DomainCard({
    required this.domain,
    required this.isPrimary,
    required this.onToggleSsl,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        title: Text(domain.domain ?? '-'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.websitesDomainPortLabel}: ${domain.port ?? '-'}'),
            if (isPrimary) Text(l10n.websitesDomainPrimary),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: domain.ssl ?? false,
              onChanged: (value) => onToggleSsl(value),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String title;

  const _EmptyCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(title)),
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
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(l10n.commonLoadFailedTitle, style: Theme.of(context).textTheme.titleLarge),
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

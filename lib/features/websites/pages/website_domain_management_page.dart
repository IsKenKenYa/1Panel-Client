import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/website_models.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import '../providers/website_domain_provider.dart';
import '../widgets/website_common_widgets.dart';

class WebsiteDomainManagementPage extends StatelessWidget {
  final int websiteId;
  final String? primaryDomain;

  const WebsiteDomainManagementPage({
    super.key,
    required this.websiteId,
    this.primaryDomain,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebsiteDomainProvider(websiteId: websiteId)..loadDomains(),
      child: _WebsiteDomainBody(primaryDomain: primaryDomain),
    );
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
            body: WebsiteErrorSection(
              message: provider.error!,
              onRetry: provider.loadDomains,
            ),
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
                WebsiteEmptyCard(title: l10n.websitesDomainEmpty)
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
    var ssl = false;

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
              onChanged: onToggleSsl,
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

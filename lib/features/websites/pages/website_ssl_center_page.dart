import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import '../../../data/models/ssl_models.dart';

import '../providers/website_ssl_center_provider.dart';
import '../widgets/website_async_state_view.dart';
import 'website_certificate_detail_page.dart';
import 'website_ssl_accounts_page.dart';

class WebsiteSslCenterPage extends StatelessWidget {
  const WebsiteSslCenterPage({
    super.key,
    this.initialWebsiteId,
  });

  final int? initialWebsiteId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebsiteSslCenterProvider()..load(),
      child: _WebsiteSslCenterBody(initialWebsiteId: initialWebsiteId),
    );
  }
}

class _WebsiteSslCenterBody extends StatelessWidget {
  const _WebsiteSslCenterBody({this.initialWebsiteId});

  final int? initialWebsiteId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.websitesSslPageTitle),
        actions: [
          IconButton(
            onPressed: () => context.read<WebsiteSslCenterProvider>().load(),
            icon: const Icon(Icons.refresh),
            tooltip: l10n.commonRefresh,
          ),
          IconButton(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add),
            tooltip: l10n.websitesSslCreateAction,
          ),
          IconButton(
            onPressed: () => _showUploadDialog(context),
            icon: const Icon(Icons.upload_file),
            tooltip: l10n.websitesSslUploadAction,
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WebsiteSslAccountsPage()),
            ),
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.commonEdit,
          ),
        ],
      ),
      body: Consumer<WebsiteSslCenterProvider>(
        builder: (context, provider, _) {
          return WebsiteAsyncStateView(
            isLoading: provider.isLoading,
            error: provider.error,
            onRetry: () => provider.load(),
            child: provider.certificates.isEmpty
                ? Center(child: Text(l10n.websitesSslListEmpty))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.certificates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final cert = provider.certificates[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.workspace_premium_outlined),
                          title: Text(cert.primaryDomain ?? '-'),
                          subtitle: Text(
                            '${l10n.websitesSslProviderLabel}: ${cert.provider ?? '-'}\n'
                            '${l10n.websitesSslExpireDate}: ${cert.expireDate ?? '-'}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'detail' && cert.id != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => WebsiteCertificateDetailPage(certificateId: cert.id!),
                                  ),
                                );
                                return;
                              }
                              if (value == 'delete' && cert.id != null) {
                                await context.read<WebsiteSslCenterProvider>().deleteCertificate(cert.id!);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'detail',
                                child: Text(l10n.websitesSslInfoTitle),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(l10n.commonDelete),
                              ),
                            ],
                          ),
                          onTap: cert.id == null
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => WebsiteCertificateDetailPage(certificateId: cert.id!),
                                    ),
                                  ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: Text(initialWebsiteId == null ? l10n.websitesSslCreateAction : l10n.websitesSslApplyAction),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final l10n = context.l10n;
    final acmeController = TextEditingController();
    final domainController = TextEditingController();
    final providerController = TextEditingController();
    var autoRenew = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.websitesSslCreateAction),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: acmeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.websitesSslAcmeAccountIdLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: domainController,
                  decoration: InputDecoration(labelText: l10n.websitesSslPrimaryDomain),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: providerController,
                  decoration: InputDecoration(labelText: l10n.websitesSslProviderLabel),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.websitesSslAutoRenew),
                  value: autoRenew,
                  onChanged: (value) => setState(() => autoRenew = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.commonCancel)),
            FilledButton(
              onPressed: () async {
                final acmeId = int.tryParse(acmeController.text.trim()) ?? 0;
                final domain = domainController.text.trim();
                final providerName = providerController.text.trim();
                Navigator.of(ctx).pop();
                if (acmeId == 0 || domain.isEmpty || providerName.isEmpty) return;
                await context.read<WebsiteSslCenterProvider>().createCertificate(
                      WebsiteSSLCreate(
                        acmeAccountId: acmeId,
                        primaryDomain: domain,
                        provider: providerName,
                        autoRenew: autoRenew,
                      ),
                    );
              },
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      ),
    );

    acmeController.dispose();
    domainController.dispose();
    providerController.dispose();
  }

  Future<void> _showUploadDialog(BuildContext context) async {
    final l10n = context.l10n;
    var type = 'paste';
    final certController = TextEditingController();
    final keyController = TextEditingController();
    final certPathController = TextEditingController();
    final keyPathController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.websitesSslUploadAction),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: InputDecoration(labelText: l10n.websitesSslUploadTypeLabel),
                  items: [
                    DropdownMenuItem(value: 'paste', child: Text(l10n.websitesSslUploadTypePaste)),
                    DropdownMenuItem(value: 'local', child: Text(l10n.websitesSslUploadTypeLocal)),
                  ],
                  onChanged: (value) => setState(() => type = value ?? 'paste'),
                ),
                const SizedBox(height: 12),
                if (type == 'paste') ...[
                  TextField(
                    controller: certController,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: l10n.websitesSslCertificateLabel),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyController,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: l10n.websitesSslPrivateKeyLabel),
                  ),
                ] else ...[
                  TextField(
                    controller: certPathController,
                    decoration: InputDecoration(labelText: l10n.websitesSslCertificatePathLabel),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyPathController,
                    decoration: InputDecoration(labelText: l10n.websitesSslPrivateKeyPathLabel),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.commonCancel)),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await context.read<WebsiteSslCenterProvider>().uploadCertificate(
                      WebsiteSSLUpload(
                        type: type,
                        certificate: type == 'paste' ? certController.text.trim() : null,
                        privateKey: type == 'paste' ? keyController.text.trim() : null,
                        certificatePath: type == 'local' ? certPathController.text.trim() : null,
                        privateKeyPath: type == 'local' ? keyPathController.text.trim() : null,
                      ),
                    );
              },
              child: Text(l10n.commonUpload),
            ),
          ],
        ),
      ),
    );

    certController.dispose();
    keyController.dispose();
    certPathController.dispose();
    keyPathController.dispose();
  }
}

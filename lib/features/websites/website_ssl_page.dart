import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/ssl_models.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'providers/website_ssl_provider.dart';

class WebsiteSslPage extends StatelessWidget {
  final int websiteId;
  final String? primaryDomain;

  const WebsiteSslPage({super.key, required this.websiteId, this.primaryDomain});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebsiteSslProvider(websiteId: websiteId)..loadAll(),
      child: _WebsiteSslBody(primaryDomain: primaryDomain),
    );
  }
}

class _WebsiteSslBody extends StatelessWidget {
  final String? primaryDomain;

  const _WebsiteSslBody({this.primaryDomain});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<WebsiteSslProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.httpsConfig == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.websitesSslPageTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null && provider.httpsConfig == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.websitesSslPageTitle)),
            body: _ErrorSection(message: provider.error!, onRetry: provider.loadAll),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.websitesSslPageTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.loadAll,
                tooltip: l10n.commonRefresh,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showCreateDialog(context, provider),
                tooltip: l10n.websitesSslCreateAction,
              ),
              IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: () => _showUploadDialog(context, provider),
                tooltip: l10n.websitesSslUploadAction,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HttpsCard(
                config: provider.httpsConfig,
                onEdit: () => _showHttpsDialog(context, provider),
              ),
              const SizedBox(height: 12),
              _WebsiteSslCard(
                ssl: provider.websiteSsl,
                onToggleAutoRenew: (ssl, value) => _updateAutoRenew(context, provider, ssl, value),
              ),
              const SizedBox(height: 12),
              _CertificateList(
                certificates: provider.certificates,
                onApply: (cert) => _showApplyDialog(context, provider, cert),
                onResolve: (cert) => _showResolveDialog(context, provider, cert),
                onUpdate: (cert) => _showUpdateDialog(context, provider, cert),
                onDelete: (cert) => _confirmDelete(context, provider, cert),
                onDownload: (cert) => _downloadCertificate(context, provider, cert),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateAutoRenew(
    BuildContext context,
    WebsiteSslProvider provider,
    WebsiteSSL ssl,
    bool value,
  ) async {
    final l10n = context.l10n;
    if ((ssl.primaryDomain ?? '').isEmpty || (ssl.provider ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.websitesSslAutoRenewMissingFields)),
      );
      return;
    }

    await provider.updateCertificate(
      WebsiteSSLUpdate(
        id: ssl.id ?? 0,
        primaryDomain: ssl.primaryDomain ?? '',
        provider: ssl.provider ?? '',
        autoRenew: value,
      ),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.commonSaveSuccess)),
    );
  }

  Future<void> _downloadCertificate(
    BuildContext context,
    WebsiteSslProvider provider,
    WebsiteSSL ssl,
  ) async {
    final l10n = context.l10n;
    final id = ssl.id;
    if (id == null) return;
    final link = await provider.downloadCertificate(id);
    if (!context.mounted || link == null || link.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.websitesSslDownloadHint(link))),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WebsiteSslProvider provider, WebsiteSSL ssl) async {
    final l10n = context.l10n;
    final id = ssl.id;
    if (id == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.websitesSslDeleteTitle),
        content: Text(l10n.websitesSslDeleteMessage(ssl.primaryDomain ?? '-')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await provider.deleteCertificate(id);
            },
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WebsiteSslProvider provider) async {
    final l10n = context.l10n;
    final acmeController = TextEditingController();
    final domainController = TextEditingController(text: primaryDomain ?? '');
    final providerController = TextEditingController();
    final otherDomainsController = TextEditingController();
    bool autoRenew = false;

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
                const SizedBox(height: 12),
                TextField(
                  controller: otherDomainsController,
                  decoration: InputDecoration(labelText: l10n.websitesSslOtherDomainsLabel),
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
                final otherDomains = otherDomainsController.text.trim();
                Navigator.of(ctx).pop();
                if (acmeId == 0 || domain.isEmpty || providerName.isEmpty) return;
                await provider.createCertificate(
                  WebsiteSSLCreate(
                    acmeAccountId: acmeId,
                    primaryDomain: domain,
                    provider: providerName,
                    autoRenew: autoRenew,
                    otherDomains: otherDomains.isEmpty ? null : otherDomains,
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
    otherDomainsController.dispose();
  }

  Future<void> _showApplyDialog(BuildContext context, WebsiteSslProvider provider, WebsiteSSL cert) async {
    final l10n = context.l10n;
    final id = cert.id ?? 0;
    final nameserverController = TextEditingController();
    bool disableLog = false;
    bool skipDNSCheck = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.websitesSslApplyAction),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.websitesSslDisableLogLabel),
                value: disableLog,
                onChanged: (value) => setState(() => disableLog = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.websitesSslSkipDnsCheckLabel),
                value: skipDNSCheck,
                onChanged: (value) => setState(() => skipDNSCheck = value),
              ),
              TextField(
                controller: nameserverController,
                decoration: InputDecoration(labelText: l10n.websitesSslNameserversLabel),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.commonCancel)),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final nameservers = nameserverController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                await provider.applyCertificate(
                  WebsiteSSLApply(
                    id: id,
                    disableLog: disableLog,
                    skipDNSCheck: skipDNSCheck,
                    nameservers: nameservers.isEmpty ? null : nameservers,
                  ),
                );
              },
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      ),
    );

    nameserverController.dispose();
  }

  Future<void> _showResolveDialog(BuildContext context, WebsiteSslProvider provider, WebsiteSSL cert) async {
    final l10n = context.l10n;
    final acmeController = TextEditingController(text: cert.acmeAccountId?.toString() ?? '');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.websitesSslResolveAction),
        content: TextField(
          controller: acmeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.websitesSslAcmeAccountIdLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final acmeId = int.tryParse(acmeController.text.trim()) ?? 0;
              if (acmeId == 0 || cert.id == null) return;
              await provider.resolveCertificate(
                WebsiteSSLResolve(acmeAccountId: acmeId, websiteSSLId: cert.id!),
              );
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    acmeController.dispose();
  }

  Future<void> _showUpdateDialog(BuildContext context, WebsiteSslProvider provider, WebsiteSSL cert) async {
    final l10n = context.l10n;
    final primaryController = TextEditingController(text: cert.primaryDomain ?? '');
    final providerController = TextEditingController(text: cert.provider ?? '');
    final descriptionController = TextEditingController(text: cert.description ?? '');
    bool autoRenew = cert.autoRenew ?? false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.websitesSslUpdateAction),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: primaryController,
                  decoration: InputDecoration(labelText: l10n.websitesSslPrimaryDomain),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: providerController,
                  decoration: InputDecoration(labelText: l10n.websitesSslProviderLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: l10n.websitesSslDescriptionLabel),
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
                final primary = primaryController.text.trim();
                final providerName = providerController.text.trim();
                if (primary.isEmpty || providerName.isEmpty || cert.id == null) {
                  Navigator.of(ctx).pop();
                  return;
                }
                Navigator.of(ctx).pop();
                await provider.updateCertificate(
                  WebsiteSSLUpdate(
                    id: cert.id!,
                    primaryDomain: primary,
                    provider: providerName,
                    autoRenew: autoRenew,
                    description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                  ),
                );
              },
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );

    primaryController.dispose();
    providerController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showUploadDialog(BuildContext context, WebsiteSslProvider provider) async {
    final l10n = context.l10n;
    String type = 'paste';
    final certController = TextEditingController();
    final keyController = TextEditingController();
    final certPathController = TextEditingController();
    final keyPathController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.websitesSslUploadAction),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: type,
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
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: l10n.websitesSslDescriptionLabel),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.commonCancel)),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await provider.uploadCertificate(
                  WebsiteSSLUpload(
                    type: type,
                    certificate: type == 'paste' ? certController.text.trim() : null,
                    privateKey: type == 'paste' ? keyController.text.trim() : null,
                    certificatePath: type == 'local' ? certPathController.text.trim() : null,
                    privateKeyPath: type == 'local' ? keyPathController.text.trim() : null,
                    description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
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
    descriptionController.dispose();
  }

  Future<void> _showHttpsDialog(BuildContext context, WebsiteSslProvider provider) async {
    final l10n = context.l10n;
    final config = provider.httpsConfig;
    bool enable = config?.enable ?? false;
    String httpConfig = config?.httpConfig ?? 'HTTPAlso';
    String type = 'existed';
    final sslIdController = TextEditingController();
    final certController = TextEditingController();
    final keyController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.websitesHttpsConfigTitle),
          content: SingleChildScrollView(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.websitesHttpsEnableLabel),
                  value: enable,
                  onChanged: (value) => setState(() => enable = value),
                ),
                DropdownButtonFormField<String>(
                  value: httpConfig,
                  decoration: InputDecoration(labelText: l10n.websitesHttpsModeLabel),
                  items: const [
                    DropdownMenuItem(value: 'HTTPAlso', child: Text('HTTPAlso')),
                    DropdownMenuItem(value: 'HTTPToHTTPS', child: Text('HTTPToHTTPS')),
                    DropdownMenuItem(value: 'HTTPSOnly', child: Text('HTTPSOnly')),
                  ],
                  onChanged: (value) => setState(() => httpConfig = value ?? 'HTTPAlso'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: InputDecoration(labelText: l10n.websitesHttpsTypeLabel),
                  items: const [
                    DropdownMenuItem(value: 'existed', child: Text('existed')),
                    DropdownMenuItem(value: 'manual', child: Text('manual')),
                    DropdownMenuItem(value: 'auto', child: Text('auto')),
                  ],
                  onChanged: (value) => setState(() => type = value ?? 'existed'),
                ),
                const SizedBox(height: 12),
                if (type == 'existed')
                  TextField(
                    controller: sslIdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.websitesHttpsSslIdLabel),
                  )
                else if (type == 'manual') ...[
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
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.commonCancel)),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final sslId = int.tryParse(sslIdController.text.trim());
                await provider.updateHttpsConfig(
                  WebsiteHttpsUpdateRequest(
                    websiteId: provider.websiteId,
                    enable: enable,
                    httpConfig: httpConfig,
                    type: type,
                    websiteSSLId: sslId,
                    certificate: type == 'manual' ? certController.text.trim() : null,
                    privateKey: type == 'manual' ? keyController.text.trim() : null,
                  ),
                );
              },
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );

    sslIdController.dispose();
    certController.dispose();
    keyController.dispose();
  }
}

class _HttpsCard extends StatelessWidget {
  final WebsiteHttpsConfig? config;
  final VoidCallback onEdit;

  const _HttpsCard({required this.config, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enable = config?.enable ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.websitesHttpsConfigTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('${l10n.websitesHttpsEnableLabel}: ${enable ? l10n.systemSettingsEnabled : l10n.systemSettingsDisabled}'),
            Text('${l10n.websitesHttpsModeLabel}: ${config?.httpConfig ?? '-'}'),
            Text('${l10n.websitesSslPrimaryDomain}: ${config?.ssl?.primaryDomain ?? '-'}'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.tune),
              label: Text(l10n.commonEdit),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebsiteSslCard extends StatelessWidget {
  final WebsiteSSL? ssl;
  final Future<void> Function(WebsiteSSL ssl, bool value) onToggleAutoRenew;

  const _WebsiteSslCard({required this.ssl, required this.onToggleAutoRenew});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.websitesSslInfoTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (ssl == null)
              Text(l10n.websitesSslNoCert)
            else ...[
              Text('${l10n.websitesSslPrimaryDomain}: ${ssl?.primaryDomain ?? '-'}'),
              Text('${l10n.websitesSslExpireDate}: ${ssl?.expireDate ?? '-'}'),
              Text('${l10n.websitesSslStatus}: ${ssl?.status ?? '-'}'),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.websitesSslAutoRenew),
                value: ssl?.autoRenew ?? false,
                onChanged: (value) => onToggleAutoRenew(ssl!, value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CertificateList extends StatelessWidget {
  final List<WebsiteSSL> certificates;
  final ValueChanged<WebsiteSSL> onApply;
  final ValueChanged<WebsiteSSL> onResolve;
  final ValueChanged<WebsiteSSL> onUpdate;
  final ValueChanged<WebsiteSSL> onDelete;
  final ValueChanged<WebsiteSSL> onDownload;

  const _CertificateList({
    required this.certificates,
    required this.onApply,
    required this.onResolve,
    required this.onUpdate,
    required this.onDelete,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.websitesSslListTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (certificates.isEmpty)
              Text(l10n.websitesSslListEmpty)
            else
              ...certificates.map((cert) => _CertificateItem(
                    cert: cert,
                    onApply: onApply,
                    onResolve: onResolve,
                    onUpdate: onUpdate,
                    onDelete: onDelete,
                    onDownload: onDownload,
                  )),
          ],
        ),
      ),
    );
  }
}

class _CertificateItem extends StatelessWidget {
  final WebsiteSSL cert;
  final ValueChanged<WebsiteSSL> onApply;
  final ValueChanged<WebsiteSSL> onResolve;
  final ValueChanged<WebsiteSSL> onUpdate;
  final ValueChanged<WebsiteSSL> onDelete;
  final ValueChanged<WebsiteSSL> onDownload;

  const _CertificateItem({
    required this.cert,
    required this.onApply,
    required this.onResolve,
    required this.onUpdate,
    required this.onDelete,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cert.primaryDomain ?? '-'),
          Text('${l10n.websitesSslExpireDate}: ${cert.expireDate ?? '-'}'),
          Text('${l10n.websitesSslStatus}: ${cert.status ?? '-'}'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(onPressed: () => onApply(cert), child: Text(l10n.websitesSslApplyAction)),
              OutlinedButton(onPressed: () => onResolve(cert), child: Text(l10n.websitesSslResolveAction)),
              OutlinedButton(onPressed: () => onUpdate(cert), child: Text(l10n.commonEdit)),
              OutlinedButton(onPressed: () => onDownload(cert), child: Text(l10n.websitesSslDownload)),
              TextButton(onPressed: () => onDelete(cert), child: Text(l10n.commonDelete)),
            ],
          ),
          const Divider(),
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

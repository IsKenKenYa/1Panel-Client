import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/shared/widgets/app_widgets.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../data/models/ssl_models.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'providers/website_ssl_provider.dart';
import 'widgets/website_ssl_upload_dialog.dart';

class WebsiteSslPage extends StatelessWidget {
  final int websiteId;
  final String? primaryDomain;

  const WebsiteSslPage({
    super.key,
    required this.websiteId,
    this.primaryDomain,
  });

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
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(title: Text(l10n.websitesSslPageTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null && provider.httpsConfig == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(title: Text(l10n.websitesSslPageTitle)),
            body: ModuleErrorStateWidget(
              message: provider.error,
              onRetry: provider.loadAll,
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(l10n.websitesSslPageTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                onPressed: provider.loadAll,
                tooltip: l10n.commonRefresh,
              ),
              IconButton(
                icon: const Icon(Icons.add_outlined),
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
            padding: AppDesignTokens.cardPadding,
            children: [
              _HttpsCard(
                config: provider.httpsConfig,
                onEdit: () => _showHttpsDialog(context, provider),
              ),
              const SizedBox(height: 12),
              _WebsiteSslCard(
                ssl: provider.websiteSsl,
                onToggleAutoRenew: (ssl, value) =>
                    _updateAutoRenew(context, provider, ssl, value),
              ),
              const SizedBox(height: 12),
              _CertificateList(
                certificates: provider.certificates,
                onApply: (cert) => _showApplyDialog(context, provider, cert),
                onResolve: (cert) =>
                    _showResolveDialog(context, provider, cert),
                onUpdate: (cert) => _showUpdateDialog(context, provider, cert),
                onDelete: (cert) => _confirmDelete(context, provider, cert),
                onDownload: (cert) =>
                    _downloadCertificate(context, provider, cert),
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
      SnackBarUtils.showWarning(
        context,
        l10n.websitesSslAutoRenewMissingFields,
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
    SnackBarUtils.showSuccess(context, l10n.commonSaveSuccess);
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
    SnackBarUtils.showInfo(context, l10n.websitesSslDownloadHint(link));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WebsiteSslProvider provider,
    WebsiteSSL ssl,
  ) async {
    final l10n = context.l10n;
    final id = ssl.id;
    if (id == null) return;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.websitesSslDeleteTitle,
      message: l10n.websitesSslDeleteMessage(ssl.primaryDomain ?? '-'),
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );
    if (confirmed) await provider.deleteCertificate(id);
  }

  Future<void> _showCreateDialog(
    BuildContext context,
    WebsiteSslProvider provider,
  ) async {
    await showAdaptiveFormPanel<void>(
      context,
      builder: (_) =>
          _SslCreateForm(provider: provider, primaryDomain: primaryDomain),
    );
  }

  Future<void> _showApplyDialog(
    BuildContext context,
    WebsiteSslProvider provider,
    WebsiteSSL cert,
  ) async {
    await showAdaptiveFormPanel<void>(
      context,
      builder: (_) => _SslApplyForm(provider: provider, cert: cert),
    );
  }

  Future<void> _showResolveDialog(
    BuildContext context,
    WebsiteSslProvider provider,
    WebsiteSSL cert,
  ) async {
    final l10n = context.l10n;
    final input = await showAppTextInputDialog(
      context,
      title: l10n.websitesSslResolveAction,
      initialValue: cert.acmeAccountId?.toString() ?? '',
      labelText: l10n.websitesSslAcmeAccountIdLabel,
      keyboardType: TextInputType.number,
      allowEmpty: true,
      autofocus: false,
    );
    if (input == null) return;
    final acmeId = int.tryParse(input) ?? 0;
    if (acmeId == 0 || cert.id == null) return;
    await provider.resolveCertificate(
      WebsiteSSLResolve(acmeAccountId: acmeId, websiteSSLId: cert.id!),
    );
  }

  Future<void> _showUpdateDialog(
    BuildContext context,
    WebsiteSslProvider provider,
    WebsiteSSL cert,
  ) async {
    await showAdaptiveFormPanel<void>(
      context,
      builder: (_) => _SslUpdateForm(provider: provider, cert: cert),
    );
  }

  Future<void> _showUploadDialog(
    BuildContext context,
    WebsiteSslProvider provider,
  ) async {
    await showAdaptiveFormPanel<bool>(
      context,
      builder: (_) => WebsiteSslUploadDialog(
        onUpload: provider.uploadCertificate,
        includeDescription: true,
      ),
    );
  }

  Future<void> _showHttpsDialog(
    BuildContext context,
    WebsiteSslProvider provider,
  ) async {
    await showAdaptiveFormPanel<void>(
      context,
      builder: (_) => _HttpsConfigForm(provider: provider),
    );
  }
}

class _SslCreateForm extends StatefulWidget {
  const _SslCreateForm({required this.provider, this.primaryDomain});

  final WebsiteSslProvider provider;
  final String? primaryDomain;

  @override
  State<_SslCreateForm> createState() => _SslCreateFormState();
}

class _SslCreateFormState extends State<_SslCreateForm> {
  final acmeController = TextEditingController();
  late final domainController = TextEditingController(
    text: widget.primaryDomain ?? '',
  );
  final providerController = TextEditingController();
  final otherDomainsController = TextEditingController();
  bool autoRenew = false;

  @override
  void dispose() {
    acmeController.dispose();
    domainController.dispose();
    providerController.dispose();
    otherDomainsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.websitesSslCreateAction,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: acmeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.websitesSslAcmeAccountIdLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: domainController,
            decoration: InputDecoration(
              labelText: l10n.websitesSslPrimaryDomain,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: providerController,
            decoration: InputDecoration(
              labelText: l10n.websitesSslProviderLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: otherDomainsController,
            decoration: InputDecoration(
              labelText: l10n.websitesSslOtherDomainsLabel,
            ),
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
      onConfirm: () async {
        final acmeId = int.tryParse(acmeController.text.trim()) ?? 0;
        final domain = domainController.text.trim();
        final providerName = providerController.text.trim();
        final otherDomains = otherDomainsController.text.trim();
        Navigator.of(context).pop();
        if (acmeId == 0 || domain.isEmpty || providerName.isEmpty) {
          return;
        }
        await widget.provider.createCertificate(
          WebsiteSSLCreate(
            acmeAccountId: acmeId,
            primaryDomain: domain,
            provider: providerName,
            autoRenew: autoRenew,
            otherDomains: otherDomains.isEmpty ? null : otherDomains,
          ),
        );
      },
    );
  }
}

class _SslApplyForm extends StatefulWidget {
  const _SslApplyForm({required this.provider, required this.cert});

  final WebsiteSslProvider provider;
  final WebsiteSSL cert;

  @override
  State<_SslApplyForm> createState() => _SslApplyFormState();
}

class _SslApplyFormState extends State<_SslApplyForm> {
  final nameserverController = TextEditingController();
  bool disableLog = false;
  bool skipDNSCheck = false;

  @override
  void dispose() {
    nameserverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = widget.cert.id ?? 0;
    return AppFormPanel(
      title: l10n.websitesSslApplyAction,
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
            decoration: InputDecoration(
              labelText: l10n.websitesSslNameserversLabel,
            ),
          ),
        ],
      ),
      onConfirm: () async {
        final nameservers = nameserverController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        Navigator.of(context).pop();
        await widget.provider.applyCertificate(
          WebsiteSSLApply(
            id: id,
            disableLog: disableLog,
            skipDNSCheck: skipDNSCheck,
            nameservers: nameservers.isEmpty ? null : nameservers,
          ),
        );
      },
    );
  }
}

class _SslUpdateForm extends StatefulWidget {
  const _SslUpdateForm({required this.provider, required this.cert});

  final WebsiteSslProvider provider;
  final WebsiteSSL cert;

  @override
  State<_SslUpdateForm> createState() => _SslUpdateFormState();
}

class _SslUpdateFormState extends State<_SslUpdateForm> {
  late final primaryController = TextEditingController(
    text: widget.cert.primaryDomain ?? '',
  );
  late final providerController = TextEditingController(
    text: widget.cert.provider ?? '',
  );
  late final descriptionController = TextEditingController(
    text: widget.cert.description ?? '',
  );
  late bool autoRenew = widget.cert.autoRenew ?? false;

  @override
  void dispose() {
    primaryController.dispose();
    providerController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cert = widget.cert;
    return AppFormPanel(
      title: l10n.websitesSslUpdateAction,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: primaryController,
            decoration: InputDecoration(
              labelText: l10n.websitesSslPrimaryDomain,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: providerController,
            decoration: InputDecoration(
              labelText: l10n.websitesSslProviderLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: l10n.websitesSslDescriptionLabel,
            ),
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
      confirmLabel: l10n.commonSave,
      onConfirm: () async {
        final primary = primaryController.text.trim();
        final providerName = providerController.text.trim();
        if (primary.isEmpty || providerName.isEmpty || cert.id == null) {
          Navigator.of(context).pop();
          return;
        }
        final request = WebsiteSSLUpdate(
          id: cert.id!,
          primaryDomain: primary,
          provider: providerName,
          autoRenew: autoRenew,
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
        );
        Navigator.of(context).pop();
        await widget.provider.updateCertificate(request);
      },
    );
  }
}

class _HttpsConfigForm extends StatefulWidget {
  const _HttpsConfigForm({required this.provider});

  final WebsiteSslProvider provider;

  @override
  State<_HttpsConfigForm> createState() => _HttpsConfigFormState();
}

class _HttpsConfigFormState extends State<_HttpsConfigForm> {
  late bool enable = widget.provider.httpsConfig?.enable ?? false;
  late String httpConfig =
      widget.provider.httpsConfig?.httpConfig ?? 'HTTPAlso';
  String type = 'existed';
  final sslIdController = TextEditingController();
  final certController = TextEditingController();
  final keyController = TextEditingController();

  @override
  void dispose() {
    sslIdController.dispose();
    certController.dispose();
    keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = widget.provider;
    return AppFormPanel(
      title: l10n.websitesHttpsConfigTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.websitesHttpsEnableLabel),
            value: enable,
            onChanged: (value) => setState(() => enable = value),
          ),
          DropdownButtonFormField<String>(
            initialValue: httpConfig,
            decoration: InputDecoration(labelText: l10n.websitesHttpsModeLabel),
            items: const [
              DropdownMenuItem(value: 'HTTPAlso', child: Text('HTTPAlso')),
              DropdownMenuItem(
                value: 'HTTPToHTTPS',
                child: Text('HTTPToHTTPS'),
              ),
              DropdownMenuItem(value: 'HTTPSOnly', child: Text('HTTPSOnly')),
            ],
            onChanged: (value) =>
                setState(() => httpConfig = value ?? 'HTTPAlso'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: type,
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
              decoration: InputDecoration(
                labelText: l10n.websitesHttpsSslIdLabel,
              ),
            )
          else if (type == 'manual') ...[
            TextField(
              controller: certController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.websitesSslCertificateLabel,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.websitesSslPrivateKeyLabel,
              ),
            ),
          ],
        ],
      ),
      confirmLabel: l10n.commonSave,
      onConfirm: () async {
        final sslId = int.tryParse(sslIdController.text.trim());
        final request = WebsiteHttpsUpdateRequest(
          websiteId: provider.websiteId,
          enable: enable,
          httpConfig: httpConfig,
          type: type,
          websiteSSLId: sslId,
          certificate: type == 'manual' ? certController.text.trim() : null,
          privateKey: type == 'manual' ? keyController.text.trim() : null,
        );
        Navigator.of(context).pop();
        await provider.updateHttpsConfig(request);
      },
    );
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
        padding: AppDesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.websitesHttpsConfigTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '${l10n.websitesHttpsEnableLabel}: ${enable ? l10n.systemSettingsEnabled : l10n.systemSettingsDisabled}',
            ),
            Text(
              '${l10n.websitesHttpsModeLabel}: ${config?.httpConfig ?? '-'}',
            ),
            Text(
              '${l10n.websitesSslPrimaryDomain}: ${config?.ssl?.primaryDomain ?? '-'}',
            ),
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
        padding: AppDesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.websitesSslInfoTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (ssl == null)
              Text(l10n.websitesSslNoCert)
            else ...[
              Text(
                '${l10n.websitesSslPrimaryDomain}: ${ssl?.primaryDomain ?? '-'}',
              ),
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
        padding: AppDesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.websitesSslListTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (certificates.isEmpty)
              Text(l10n.websitesSslListEmpty)
            else
              ...certificates.map(
                (cert) => _CertificateItem(
                  cert: cert,
                  onApply: onApply,
                  onResolve: onResolve,
                  onUpdate: onUpdate,
                  onDelete: onDelete,
                  onDownload: onDownload,
                ),
              ),
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
              OutlinedButton(
                onPressed: () => onApply(cert),
                child: Text(l10n.websitesSslApplyAction),
              ),
              OutlinedButton(
                onPressed: () => onResolve(cert),
                child: Text(l10n.websitesSslResolveAction),
              ),
              OutlinedButton(
                onPressed: () => onUpdate(cert),
                child: Text(l10n.commonEdit),
              ),
              OutlinedButton(
                onPressed: () => onDownload(cert),
                child: Text(l10n.websitesSslDownload),
              ),
              TextButton(
                onPressed: () => onDelete(cert),
                child: Text(l10n.commonDelete),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}

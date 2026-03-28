import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import '../../../data/models/ssl_models.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';
import 'package:onepanel_client/shared/security_gateway/utils/security_gateway_utils.dart';
import 'package:onepanel_client/shared/security_gateway/widgets/security_status_chip.dart';

import '../providers/website_ssl_center_provider.dart';
import '../widgets/website_async_state_view.dart';
import 'website_certificate_detail_page.dart';
import 'website_site_ssl_page.dart';
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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.websitesSslExpirationViewTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(l10n.websitesSslFilterAllCount(
                                  provider.certificates.length)),
                              selected: provider.expiryWindow ==
                                  CertificateExpiryWindow.all,
                              onSelected: (_) => provider
                                  .setExpiryWindow(CertificateExpiryWindow.all),
                            ),
                            ChoiceChip(
                              label: Text(l10n.websitesSslFilterExpiredCount(
                                  provider.expiredCount)),
                              selected: provider.expiryWindow ==
                                  CertificateExpiryWindow.expired,
                              onSelected: (_) => provider.setExpiryWindow(
                                  CertificateExpiryWindow.expired),
                            ),
                            ChoiceChip(
                              label: Text(
                                l10n.websitesSslFilterWithin7DaysCount(
                                    provider.within7DaysCount),
                              ),
                              selected: provider.expiryWindow ==
                                  CertificateExpiryWindow.within7Days,
                              onSelected: (_) => provider.setExpiryWindow(
                                  CertificateExpiryWindow.within7Days),
                            ),
                            ChoiceChip(
                              label: Text(
                                l10n.websitesSslFilterWithin30DaysCount(
                                    provider.within30DaysCount),
                              ),
                              selected: provider.expiryWindow ==
                                  CertificateExpiryWindow.within30Days,
                              onSelected: (_) => provider.setExpiryWindow(
                                  CertificateExpiryWindow.within30Days),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          onChanged: provider.setSearchQuery,
                          decoration: InputDecoration(
                            labelText: l10n.commonSearch,
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: provider.providerFilter,
                          decoration: InputDecoration(
                            labelText: l10n.websitesSslProviderLabel,
                          ),
                          items: provider.providerOptions
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(
                                    item ==
                                            WebsiteSslCenterProvider
                                                .providerFilterAll
                                        ? l10n.websitesSslProviderFilterAll
                                        : item,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            provider.setProviderFilter(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (provider.certificates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text(l10n.websitesSslListEmpty)),
                  )
                else
                  for (final section in provider.groupedCertificates.entries)
                    _CertificateGroupSection(
                      title: _localizedGroupTitle(context, section.key),
                      certificates: section.value,
                      onTapCertificate: (cert) => _openCertificateDetail(
                        context,
                        cert,
                      ),
                      onApplyCertificate: (cert) async {
                        await _confirmApplyCertificate(context, cert);
                      },
                      onUpdateCertificate: (cert) =>
                          _showUpdateDialog(context, cert),
                      onDeleteCertificate: (cert) => _confirmDeleteCertificate(
                        context,
                        cert,
                      ),
                      onOpenBoundWebsite: (cert) => _openBoundWebsite(
                        context,
                        cert,
                      ),
                      boundWebsiteCountOf: (cert) =>
                          provider.affectedWebsiteCount(cert),
                      boundWebsiteDomainsOf: (cert) =>
                          provider.affectedWebsiteDomains(cert),
                    ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: Text(initialWebsiteId == null
            ? l10n.websitesSslCreateAction
            : l10n.websitesSslApplyAction),
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
                  decoration: InputDecoration(
                      labelText: l10n.websitesSslAcmeAccountIdLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: domainController,
                  decoration:
                      InputDecoration(labelText: l10n.websitesSslPrimaryDomain),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: providerController,
                  decoration:
                      InputDecoration(labelText: l10n.websitesSslProviderLabel),
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
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.commonCancel)),
            FilledButton(
              onPressed: () async {
                final acmeId = int.tryParse(acmeController.text.trim()) ?? 0;
                final domain = domainController.text.trim();
                final providerName = providerController.text.trim();
                Navigator.of(ctx).pop();
                if (acmeId == 0 || domain.isEmpty || providerName.isEmpty) {
                  return;
                }
                await context
                    .read<WebsiteSslCenterProvider>()
                    .createCertificate(
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
                  decoration: InputDecoration(
                      labelText: l10n.websitesSslUploadTypeLabel),
                  items: [
                    DropdownMenuItem(
                        value: 'paste',
                        child: Text(l10n.websitesSslUploadTypePaste)),
                    DropdownMenuItem(
                        value: 'local',
                        child: Text(l10n.websitesSslUploadTypeLocal)),
                  ],
                  onChanged: (value) => setState(() => type = value ?? 'paste'),
                ),
                const SizedBox(height: 12),
                if (type == 'paste') ...[
                  TextField(
                    controller: certController,
                    maxLines: 3,
                    decoration: InputDecoration(
                        labelText: l10n.websitesSslCertificateLabel),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyController,
                    maxLines: 3,
                    decoration: InputDecoration(
                        labelText: l10n.websitesSslPrivateKeyLabel),
                  ),
                ] else ...[
                  TextField(
                    controller: certPathController,
                    decoration: InputDecoration(
                        labelText: l10n.websitesSslCertificatePathLabel),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyPathController,
                    decoration: InputDecoration(
                        labelText: l10n.websitesSslPrivateKeyPathLabel),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.commonCancel)),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await context
                    .read<WebsiteSslCenterProvider>()
                    .uploadCertificate(
                      WebsiteSSLUpload(
                        type: type,
                        certificate:
                            type == 'paste' ? certController.text.trim() : null,
                        privateKey:
                            type == 'paste' ? keyController.text.trim() : null,
                        certificatePath: type == 'local'
                            ? certPathController.text.trim()
                            : null,
                        privateKeyPath: type == 'local'
                            ? keyPathController.text.trim()
                            : null,
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

  void _openCertificateDetail(BuildContext context, WebsiteSSL cert) {
    final id = cert.id;
    if (id == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebsiteCertificateDetailPage(certificateId: id),
      ),
    );
  }

  Future<void> _confirmDeleteCertificate(
    BuildContext context,
    WebsiteSSL cert,
  ) async {
    final l10n = context.l10n;
    final certId = cert.id;
    if (certId == null) {
      return;
    }
    final provider = context.read<WebsiteSslCenterProvider>();

    final affectedCount = provider.affectedWebsiteCount(cert);
    final affectedDomains = provider.affectedWebsiteDomains(cert);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.websitesSslDeleteTitle),
            content: Text(
              '${l10n.websitesSslDeleteMessage(cert.primaryDomain ?? '-')}\n'
              '${l10n.websitesSslAffectedWebsitesCount(affectedCount)}\n'
              '${_affectedDomainsText(context, affectedDomains)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.commonDelete),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    await provider.deleteCertificate(certId);
  }

  Future<void> _confirmApplyCertificate(
    BuildContext context,
    WebsiteSSL cert,
  ) async {
    final l10n = context.l10n;
    final certId = cert.id;
    if (certId == null) {
      return;
    }
    final provider = context.read<WebsiteSslCenterProvider>();
    final affectedCount = provider.affectedWebsiteCount(cert);
    final affectedDomains = provider.affectedWebsiteDomains(cert);

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.websitesSslApplyAction),
            content: Text(
              '${l10n.websitesSslImpactHintApply}\n'
              '${l10n.websitesSslAffectedWebsitesCount(affectedCount)}\n'
              '${_affectedDomainsText(context, affectedDomains)}'
              '${provider.hasHighImpact(cert) ? '\n${l10n.websitesSslImpactWarningHigh}' : ''}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.commonConfirm),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }
    await provider.obtainCertificate(certId);
  }

  Future<void> _showUpdateDialog(BuildContext context, WebsiteSSL cert) async {
    final l10n = context.l10n;
    final certId = cert.id;
    if (certId == null) {
      return;
    }

    final primaryController =
        TextEditingController(text: cert.primaryDomain ?? '');
    final providerController = TextEditingController(text: cert.provider ?? '');
    final descriptionController =
        TextEditingController(text: cert.description ?? '');
    final domainsController = TextEditingController(
      text: (cert.domains ?? const <String>[]).skip(1).join(','),
    );
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
                  decoration:
                      InputDecoration(labelText: l10n.websitesSslPrimaryDomain),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: providerController,
                  decoration:
                      InputDecoration(labelText: l10n.websitesSslProviderLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: domainsController,
                  decoration: InputDecoration(
                    labelText: l10n.websitesSslOtherDomainsLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                      labelText: l10n.websitesSslDescriptionLabel),
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
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                final primary = primaryController.text.trim();
                final providerName = providerController.text.trim();
                if (primary.isEmpty || providerName.isEmpty) {
                  Navigator.of(ctx).pop();
                  return;
                }

                final centerProvider = context.read<WebsiteSslCenterProvider>();
                final affectedCount = centerProvider.affectedWebsiteCount(cert);
                final affectedDomains =
                    centerProvider.affectedWebsiteDomains(cert);
                final affectedDomainsText = affectedDomains.isEmpty
                    ? l10n.websitesSslNoAffectedWebsites
                    : l10n.websitesSslAffectedWebsitesDomains(
                        affectedDomains.join(', '),
                      );
                final confirmed = await showDialog<bool>(
                      context: ctx,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(l10n.websitesSslUpdateAction),
                        content: Text(
                          '${l10n.websitesSslAffectedWebsitesCount(affectedCount)}\n'
                          '$affectedDomainsText'
                          '${centerProvider.hasHighImpact(cert) ? '\n${l10n.websitesSslImpactWarningHigh}' : ''}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: Text(l10n.commonCancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: Text(l10n.commonSave),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (!confirmed) {
                  return;
                }

                if (!ctx.mounted) {
                  return;
                }
                Navigator.of(ctx).pop();
                await centerProvider.updateCertificate(
                  WebsiteSSLUpdate(
                    id: certId,
                    primaryDomain: primary,
                    provider: providerName,
                    autoRenew: autoRenew,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    otherDomains: domainsController.text.trim().isEmpty
                        ? null
                        : domainsController.text.trim(),
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
    domainsController.dispose();
  }

  String _affectedDomainsText(BuildContext context, List<String> domains) {
    final l10n = context.l10n;
    if (domains.isEmpty) {
      return l10n.websitesSslNoAffectedWebsites;
    }
    return l10n.websitesSslAffectedWebsitesDomains(domains.join(', '));
  }

  void _openBoundWebsite(BuildContext context, WebsiteSSL cert) {
    final websites = cert.websites ?? const <Website>[];
    if (websites.isEmpty) {
      return;
    }
    int? websiteId;
    String? displayName;
    for (final website in websites) {
      if (website.id == null) {
        continue;
      }
      websiteId = website.id;
      displayName = website.primaryDomain;
      break;
    }
    if (websiteId == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebsiteSiteSslPage(
          websiteId: websiteId!,
          displayName: displayName,
        ),
      ),
    );
  }

  String _localizedGroupTitle(BuildContext context, String rawTitle) {
    final l10n = context.l10n;
    switch (rawTitle) {
      case 'All certificates':
        return l10n.websitesSslGroupAll;
      case 'Expired':
        return l10n.websitesSslGroupExpired;
      case 'Within 7 days':
        return l10n.websitesSslGroupWithin7Days;
      case 'Within 30 days':
        return l10n.websitesSslGroupWithin30Days;
      case 'Healthy':
        return l10n.websitesSslGroupHealthy;
      default:
        return rawTitle;
    }
  }
}

class _CertificateGroupSection extends StatelessWidget {
  const _CertificateGroupSection({
    required this.title,
    required this.certificates,
    required this.onTapCertificate,
    required this.onApplyCertificate,
    required this.onUpdateCertificate,
    required this.onDeleteCertificate,
    required this.onOpenBoundWebsite,
    required this.boundWebsiteCountOf,
    required this.boundWebsiteDomainsOf,
  });

  final String title;
  final List<WebsiteSSL> certificates;
  final ValueChanged<WebsiteSSL> onTapCertificate;
  final ValueChanged<WebsiteSSL> onApplyCertificate;
  final ValueChanged<WebsiteSSL> onUpdateCertificate;
  final ValueChanged<WebsiteSSL> onDeleteCertificate;
  final ValueChanged<WebsiteSSL> onOpenBoundWebsite;
  final int Function(WebsiteSSL certificate) boundWebsiteCountOf;
  final List<String> Function(WebsiteSSL certificate) boundWebsiteDomainsOf;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          for (final cert in certificates)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: Row(
                    children: [
                      Expanded(child: Text(cert.primaryDomain ?? '-')),
                      SecurityStatusChip(
                        label: _localizedHealthLabel(
                          context,
                          resolveCertificateHealthStatus(cert.expireDate),
                        ),
                        color: _healthColor(
                          context,
                          resolveCertificateHealthStatus(cert.expireDate),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${l10n.websitesSslProviderLabel}: ${cert.provider ?? '-'}\n'
                    '${l10n.websitesSslExpireDate}: ${cert.expireDate ?? '-'}\n'
                    '${l10n.websitesSslAffectedWebsitesCount(boundWebsiteCountOf(cert))}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'detail') {
                        onTapCertificate(cert);
                        return;
                      }
                      if (value == 'apply') {
                        onApplyCertificate(cert);
                        return;
                      }
                      if (value == 'update') {
                        onUpdateCertificate(cert);
                        return;
                      }
                      if (value == 'delete') {
                        onDeleteCertificate(cert);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'detail',
                        child: Text(l10n.websitesSslInfoTitle),
                      ),
                      PopupMenuItem(
                        value: 'apply',
                        child: Text(l10n.websitesSslApplyAction),
                      ),
                      PopupMenuItem(
                        value: 'update',
                        child: Text(l10n.websitesSslUpdateAction),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.commonDelete),
                      ),
                    ],
                  ),
                  onTap: () => onTapCertificate(cert),
                ),
              ),
            ),
          if (certificates
              .any((certificate) => boundWebsiteCountOf(certificate) > 0))
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cert in certificates)
                  if (boundWebsiteCountOf(cert) > 0)
                    Tooltip(
                      message: boundWebsiteDomainsOf(cert).join(', '),
                      child: OutlinedButton.icon(
                        onPressed: () => onOpenBoundWebsite(cert),
                        icon: const Icon(Icons.open_in_new),
                        label: Text(
                          '${l10n.websitesSslOpenBoundSiteAction}: '
                          '${cert.primaryDomain ?? '-'} '
                          '(${boundWebsiteCountOf(cert)})',
                        ),
                      ),
                    ),
              ],
            ),
        ],
      ),
    );
  }

  Color _healthColor(BuildContext context, CertificateHealthStatus status) {
    switch (status) {
      case CertificateHealthStatus.healthy:
        return Theme.of(context).colorScheme.primary;
      case CertificateHealthStatus.expiringSoon:
        return Theme.of(context).colorScheme.tertiary;
      case CertificateHealthStatus.expired:
        return Theme.of(context).colorScheme.error;
      case CertificateHealthStatus.unknown:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  String _localizedHealthLabel(
    BuildContext context,
    CertificateHealthStatus status,
  ) {
    final l10n = context.l10n;
    switch (status) {
      case CertificateHealthStatus.healthy:
        return l10n.websitesSslHealthHealthy;
      case CertificateHealthStatus.expiringSoon:
        return l10n.websitesSslHealthExpiringSoon;
      case CertificateHealthStatus.expired:
        return l10n.websitesSslHealthExpired;
      case CertificateHealthStatus.unknown:
        return l10n.websitesSslHealthUnknown;
    }
  }
}

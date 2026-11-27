import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import '../../../data/models/ssl_models.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';
import 'package:onepanel_client/shared/security_gateway/utils/security_gateway_utils.dart';
import 'package:onepanel_client/shared/security_gateway/widgets/security_status_chip.dart';

import '../providers/website_ssl_center_provider.dart';
import '../widgets/website_async_state_view.dart';
import '../widgets/website_ssl_upload_dialog.dart';
import 'website_certificate_detail_page.dart';
import 'website_site_ssl_page.dart';
import 'website_ssl_accounts_page.dart';

class WebsiteSslCenterPage extends StatelessWidget {
  const WebsiteSslCenterPage({super.key, this.initialWebsiteId});

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.websitesSslPageTitle),
        actions: [
          IconButton(
            onPressed: () => context.read<WebsiteSslCenterProvider>().load(),
            icon: const Icon(Icons.refresh_outlined),
            tooltip: l10n.commonRefresh,
          ),
          IconButton(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add_outlined),
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
              padding: AppDesignTokens.cardPadding,
              children: [
                Card(
                  child: Padding(
                    padding: AppDesignTokens.cardPadding,
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
                              label: Text(
                                l10n.websitesSslFilterAllCount(
                                  provider.certificates.length,
                                ),
                              ),
                              selected:
                                  provider.expiryWindow ==
                                  CertificateExpiryWindow.all,
                              onSelected: (_) => provider.setExpiryWindow(
                                CertificateExpiryWindow.all,
                              ),
                            ),
                            ChoiceChip(
                              label: Text(
                                l10n.websitesSslFilterExpiredCount(
                                  provider.expiredCount,
                                ),
                              ),
                              selected:
                                  provider.expiryWindow ==
                                  CertificateExpiryWindow.expired,
                              onSelected: (_) => provider.setExpiryWindow(
                                CertificateExpiryWindow.expired,
                              ),
                            ),
                            ChoiceChip(
                              label: Text(
                                l10n.websitesSslFilterWithin7DaysCount(
                                  provider.within7DaysCount,
                                ),
                              ),
                              selected:
                                  provider.expiryWindow ==
                                  CertificateExpiryWindow.within7Days,
                              onSelected: (_) => provider.setExpiryWindow(
                                CertificateExpiryWindow.within7Days,
                              ),
                            ),
                            ChoiceChip(
                              label: Text(
                                l10n.websitesSslFilterWithin30DaysCount(
                                  provider.within30DaysCount,
                                ),
                              ),
                              selected:
                                  provider.expiryWindow ==
                                  CertificateExpiryWindow.within30Days,
                              onSelected: (_) => provider.setExpiryWindow(
                                CertificateExpiryWindow.within30Days,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ModuleSearchField(
                          onChanged: provider.setSearchQuery,
                          labelText: l10n.commonSearch,
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
                      onTapCertificate: (cert) =>
                          _openCertificateDetail(context, cert),
                      onApplyCertificate: (cert) async {
                        await _confirmApplyCertificate(context, cert);
                      },
                      onUpdateCertificate: (cert) =>
                          _showUpdateDialog(context, cert),
                      onDeleteCertificate: (cert) =>
                          _confirmDeleteCertificate(context, cert),
                      onOpenBoundWebsite: (cert) =>
                          _openBoundWebsite(context, cert),
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
        heroTag: 'website_ssl_center_create_fab',
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add_outlined),
        label: Text(
          initialWebsiteId == null
              ? l10n.websitesSslCreateAction
              : l10n.websitesSslApplyAction,
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final provider = context.read<WebsiteSslCenterProvider>();
    await showAdaptiveFormPanel<void>(
      context,
      builder: (_) => _CenterCertificateForm(provider: provider),
    );
  }

  Future<void> _showUploadDialog(BuildContext context) async {
    final provider = context.read<WebsiteSslCenterProvider>();
    await showAdaptiveFormPanel<bool>(
      context,
      builder: (_) =>
          WebsiteSslUploadDialog(onUpload: provider.uploadCertificate),
    );
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
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.websitesSslDeleteTitle,
      message:
          '${l10n.websitesSslDeleteMessage(cert.primaryDomain ?? '-')}\n'
          '${l10n.websitesSslAffectedWebsitesCount(affectedCount)}\n'
          '${_affectedDomainsText(context, affectedDomains)}',
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );
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

    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.websitesSslApplyAction,
      message:
          '${l10n.websitesSslImpactHintApply}\n'
          '${l10n.websitesSslAffectedWebsitesCount(affectedCount)}\n'
          '${_affectedDomainsText(context, affectedDomains)}'
          '${provider.hasHighImpact(cert) ? '\n${l10n.websitesSslImpactWarningHigh}' : ''}',
      confirmLabel: l10n.commonConfirm,
    );

    if (!confirmed) {
      return;
    }
    await provider.obtainCertificate(certId);
  }

  Future<void> _showUpdateDialog(BuildContext context, WebsiteSSL cert) async {
    if (cert.id == null) return;
    final provider = context.read<WebsiteSslCenterProvider>();
    await showAdaptiveFormPanel<void>(
      context,
      builder: (_) => _CenterCertificateForm(provider: provider, cert: cert),
    );
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
        builder: (_) =>
            WebsiteSiteSslPage(websiteId: websiteId!, displayName: displayName),
      ),
    );
  }

  // Provider returns hardcoded English group labels; map them to l10n here.
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

String _affectedDomainsText(BuildContext context, List<String> domains) {
  final l10n = context.l10n;
  if (domains.isEmpty) {
    return l10n.websitesSslNoAffectedWebsites;
  }
  return l10n.websitesSslAffectedWebsitesDomains(domains.join(', '));
}

class _CenterCertificateForm extends StatefulWidget {
  const _CenterCertificateForm({required this.provider, this.cert});

  final WebsiteSslCenterProvider provider;
  final WebsiteSSL? cert;

  @override
  State<_CenterCertificateForm> createState() => _CenterCertificateFormState();
}

class _CenterCertificateFormState extends State<_CenterCertificateForm> {
  final acmeController = TextEditingController();
  late final primaryController = TextEditingController(
    text: widget.cert?.primaryDomain ?? '',
  );
  late final providerController = TextEditingController(
    text: widget.cert?.provider ?? '',
  );
  late final descriptionController = TextEditingController(
    text: widget.cert?.description ?? '',
  );
  late final domainsController = TextEditingController(
    text: (widget.cert?.domains ?? const <String>[]).skip(1).join(','),
  );
  late bool autoRenew = widget.cert?.autoRenew ?? false;

  @override
  void dispose() {
    acmeController.dispose();
    primaryController.dispose();
    providerController.dispose();
    descriptionController.dispose();
    domainsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cert = widget.cert;
    final provider = widget.provider;
    final l10n = context.l10n;
    final primary = primaryController.text.trim();
    final providerName = providerController.text.trim();
    if (cert == null) {
      final acmeId = int.tryParse(acmeController.text.trim()) ?? 0;
      Navigator.of(context).pop();
      if (acmeId == 0 || primary.isEmpty || providerName.isEmpty) return;
      await provider.createCertificate(
        WebsiteSSLCreate(
          acmeAccountId: acmeId,
          primaryDomain: primary,
          provider: providerName,
          autoRenew: autoRenew,
        ),
      );
      return;
    }
    if (primary.isEmpty || providerName.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final affectedCount = provider.affectedWebsiteCount(cert);
    final affectedDomains = provider.affectedWebsiteDomains(cert);
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.websitesSslUpdateAction,
      message:
          '${l10n.websitesSslAffectedWebsitesCount(affectedCount)}\n'
          '${_affectedDomainsText(context, affectedDomains)}'
          '${provider.hasHighImpact(cert) ? '\n${l10n.websitesSslImpactWarningHigh}' : ''}',
      confirmLabel: l10n.commonSave,
    );
    if (!confirmed || !mounted) return;
    final description = descriptionController.text.trim();
    final otherDomains = domainsController.text.trim();
    final request = WebsiteSSLUpdate(
      id: cert.id!,
      primaryDomain: primary,
      provider: providerName,
      autoRenew: autoRenew,
      description: description.isEmpty ? null : description,
      otherDomains: otherDomains.isEmpty ? null : otherDomains,
    );
    Navigator.of(context).pop();
    await provider.updateCertificate(request);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = widget.cert != null;
    return AppFormPanel(
      title: isEdit
          ? l10n.websitesSslUpdateAction
          : l10n.websitesSslCreateAction,
      confirmLabel: isEdit ? l10n.commonSave : l10n.commonConfirm,
      onConfirm: _submit,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isEdit) ...[
            TextField(
              controller: acmeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.websitesSslAcmeAccountIdLabel,
              ),
            ),
            const SizedBox(height: 12),
          ],
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
          if (isEdit) ...[
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
                labelText: l10n.websitesSslDescriptionLabel,
              ),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.websitesSslAutoRenew),
            value: autoRenew,
            onChanged: (value) => setState(() => autoRenew = value),
          ),
        ],
      ),
    );
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
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
          if (certificates.any(
            (certificate) => boundWebsiteCountOf(certificate) > 0,
          ))
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

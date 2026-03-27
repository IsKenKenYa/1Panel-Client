import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/openresty/openresty_page.dart';
import 'package:onepanel_client/features/security_gateway/providers/security_gateway_center_provider.dart';
import 'package:onepanel_client/features/settings/panel_ssl/pages/panel_ssl_page.dart';
import 'package:onepanel_client/features/websites/pages/website_site_ssl_page.dart';
import 'package:onepanel_client/features/websites/pages/website_ssl_center_page.dart';
import 'package:onepanel_client/shared/security_gateway/widgets/risk_notice_banner.dart';
import 'package:provider/provider.dart';

class SecurityGatewayCenterPage extends StatelessWidget {
  const SecurityGatewayCenterPage({
    super.key,
    this.initialSection = SecurityGatewaySection.panelTls,
    this.initialWebsiteId,
    this.displayName,
    this.provider,
  });

  final SecurityGatewaySection initialSection;
  final int? initialWebsiteId;
  final String? displayName;
  final SecurityGatewayCenterProvider? provider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SecurityGatewayCenterProvider>(
      create: (_) => provider ??
          SecurityGatewayCenterProvider(
            initialWebsiteId: initialWebsiteId,
          )
        ..load(),
      child: _SecurityGatewayCenterBody(
        initialSection: initialSection,
        initialWebsiteId: initialWebsiteId,
        displayName: displayName,
      ),
    );
  }
}

class _SecurityGatewayCenterBody extends StatelessWidget {
  const _SecurityGatewayCenterBody({
    required this.initialSection,
    this.initialWebsiteId,
    this.displayName,
  });

  final SecurityGatewaySection initialSection;
  final int? initialWebsiteId;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<SecurityGatewayCenterProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Security & Gateway'),
            actions: [
              IconButton(
                onPressed: provider.load,
                icon: const Icon(Icons.refresh),
                tooltip: l10n.commonRefresh,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
            children: [
              if (provider.isLoading) const LinearProgressIndicator(),
              RiskNoticeBanner(
                  notices: provider.riskNotices,
                  title: 'Unified security summary'),
              const SizedBox(height: AppDesignTokens.spacingMd),
              _SectionCard(
                title: 'Security Summary',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricRow(
                        label: 'Entry Focus',
                        value: _entryLabel(initialSection)),
                    _MetricRow(
                        label: 'Panel TLS',
                        value: provider.panelTlsEnabled
                            ? 'Available'
                            : 'Unavailable'),
                    _MetricRow(
                      label: 'Website Expiring',
                      value:
                          '${provider.expiringCertificateCount} certificate(s)',
                    ),
                    _MetricRow(
                      label: 'OpenResty',
                      value: provider.openRestyRunning ? 'Running' : 'Inactive',
                    ),
                    _MetricRow(
                        label: 'Latest Apply',
                        value: provider.latestApplyResult),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              _SectionCard(
                title: 'Quick Actions',
                child: Wrap(
                  spacing: AppDesignTokens.spacingSm,
                  runSpacing: AppDesignTokens.spacingSm,
                  children: [
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PanelSslPage()),
                      ),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Panel TLS'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WebsiteSslCenterPage(
                              initialWebsiteId: initialWebsiteId),
                        ),
                      ),
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('Certificate Center'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const OpenRestyPage()),
                      ),
                      icon: const Icon(Icons.hub_outlined),
                      label: const Text('OpenResty HTTPS'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('security-gateway-rollback-action'),
                      onPressed: () async {
                        final success = await provider.rollbackLatest();
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Rolled back the latest local snapshot.'
                                  : 'No rollback snapshot available.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('Rollback Latest'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              _SectionCard(
                title: 'Panel TLS',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricRow(
                        label: 'Status',
                        value: provider.panelTlsEnabled
                            ? 'Loaded'
                            : 'Unavailable'),
                    _MetricRow(
                      label: 'Risk',
                      value: provider.riskNotices
                              .where((notice) => notice.title.contains('Panel'))
                              .isEmpty
                          ? 'No panel TLS risk detected'
                          : provider.riskNotices
                              .firstWhere(
                                  (notice) => notice.title.contains('Panel'))
                              .message,
                    ),
                    _MetricRow(
                      label: 'Recent',
                      value: provider.recentSnapshotSummary('panel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PanelSslPage()),
                      ),
                      child: const Text('Open Panel TLS details'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              _SectionCard(
                title: 'Website Certificates',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricRow(
                        label: 'Summary',
                        value:
                            '${provider.certificates.length} certificates loaded'),
                    _MetricRow(
                        label: 'Risk',
                        value:
                            '${provider.expiringCertificateCount} expiring soon'),
                    _MetricRow(
                      label: 'Recent',
                      value: provider.recentSnapshotSummary('website_https'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WebsiteSslCenterPage(
                              initialWebsiteId: initialWebsiteId),
                        ),
                      ),
                      child: const Text('Open certificate center'),
                    ),
                    if (initialWebsiteId != null)
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WebsiteSiteSslPage(
                              websiteId: initialWebsiteId!,
                              displayName: displayName,
                            ),
                          ),
                        ),
                        child: const Text('Open current website strategy'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              _SectionCard(
                title: 'OpenResty Gateway',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricRow(
                        label: 'Status',
                        value:
                            provider.openRestyRunning ? 'Running' : 'Inactive'),
                    _MetricRow(
                      label: 'HTTPS',
                      value: provider.openRestySnapshot.https['https'] == true
                          ? 'Enabled'
                          : 'Disabled',
                    ),
                    _MetricRow(
                      label: 'Recent',
                      value: provider.recentSnapshotSummary('openresty_'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const OpenRestyPage()),
                      ),
                      child: const Text('Open OpenResty console'),
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

  String _entryLabel(SecurityGatewaySection section) {
    switch (section) {
      case SecurityGatewaySection.panelTls:
        return 'Panel TLS';
      case SecurityGatewaySection.websiteCertificates:
        return 'Website Certificates';
      case SecurityGatewaySection.openresty:
        return 'OpenResty Gateway';
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: AppDesignTokens.spacingMd),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignTokens.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 136,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

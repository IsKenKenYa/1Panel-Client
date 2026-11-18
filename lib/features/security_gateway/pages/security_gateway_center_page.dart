import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/security_gateway/providers/security_gateway_center_provider.dart';
import 'package:onepanel_client/features/security_gateway/widgets/security_gateway_localizations.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/shared/security_gateway/widgets/risk_notice_banner.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(l10n.securityGatewayPageTitle),
            actions: [
              IconButton(
                onPressed: provider.load,
                icon: const Icon(Icons.refresh_outlined),
                tooltip: l10n.commonRefresh,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
            children: [
              if (provider.isLoading) const LinearProgressIndicator(),
              RiskNoticeBanner(
                  notices: localizeSecurityGatewayRiskNotices(
                      context, provider.riskNotices),
                  title: l10n.securityGatewayUnifiedSummaryTitle),
              const SizedBox(height: AppDesignTokens.spacingMd),
              SectionCard(
                title: l10n.securityGatewaySummarySection,
                padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricRow(
                        label: l10n.securityGatewayEntryFocusLabel,
                        value: _entryLabel(context, initialSection)),
                    _MetricRow(
                        label: l10n.securityGatewayPanelTlsSection,
                        value: provider.panelTlsEnabled
                            ? l10n.securityGatewayAvailable
                            : l10n.securityGatewayUnavailable),
                    _MetricRow(
                      label: l10n.securityGatewayWebsiteExpiringLabel,
                      value: l10n.securityGatewayCertificateCount(
                          provider.expiringCertificateCount),
                    ),
                    _MetricRow(
                      label: l10n.securityGatewayOpenRestyLabel,
                      value: provider.openRestyRunning
                          ? l10n.securityGatewayRunning
                          : l10n.securityGatewayInactive,
                    ),
                    _MetricRow(
                        label: l10n.securityGatewayLatestApplyLabel,
                        value: localizeSecurityGatewayLatestApply(
                            context, provider)),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              SectionCard(
                title: l10n.securityGatewayQuickActionsSection,
                padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
                child: Wrap(
                  spacing: AppDesignTokens.spacingSm,
                  runSpacing: AppDesignTokens.spacingSm,
                  children: [
                    FilledButton.icon(
                      onPressed: () => openRouteRespectingShell(
                        context,
                        AppRoutes.panelSsl,
                      ),
                      icon: const Icon(Icons.download_outlined),
                      label: Text(l10n.securityGatewayPanelTlsSection),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => openRouteRespectingShell(
                        context,
                        AppRoutes.websiteSslCenter,
                        arguments: {'websiteId': initialWebsiteId},
                      ),
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: Text(l10n.securityGatewayCertificateCenterAction),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => openRouteRespectingShell(
                        context,
                        AppRoutes.openrestyCenter,
                      ),
                      icon: const Icon(Icons.hub_outlined),
                      label: Text(l10n.securityGatewayOpenRestyHttpsAction),
                    ),
                    OutlinedButton.icon(
                      key: const Key('security-gateway-rollback-action'),
                      onPressed: () async {
                        final success = await provider.rollbackLatest();
                        if (!context.mounted) {
                          return;
                        }
                        success
                            ? SnackBarUtils.showSuccess(
                                context, l10n.securityGatewayRollbackSuccess)
                            : SnackBarUtils.showInfo(
                                context, l10n.securityGatewayRollbackEmpty);
                      },
                      icon: const Icon(Icons.history),
                      label: Text(l10n.securityGatewayRollbackLatestAction),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              SectionCard(
                title: l10n.securityGatewayPanelTlsSection,
                padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricRow(
                        label: l10n.securityGatewayStatusLabel,
                        value: provider.panelTlsEnabled
                            ? l10n.securityGatewayLoaded
                            : l10n.securityGatewayUnavailable),
                    _MetricRow(
                      label: l10n.securityGatewayRiskLabel,
                      value: () {
                        final localizedNotices =
                            localizeSecurityGatewayRiskNotices(
                                context, provider.riskNotices);
                        final tlsExpired = localizedNotices
                            .where((notice) =>
                                notice.title ==
                                l10n
                                    .securityGatewayRiskPanelTlsExpiredTitle)
                            .toList();
                        return tlsExpired.isEmpty
                            ? l10n.securityGatewayNoPanelTlsRisk
                            : tlsExpired.first.message;
                      }(),
                    ),
                    _MetricRow(
                      label: l10n.securityGatewayRecentLabel,
                      value: localizeSecurityGatewayRecentSummary(
                          context, provider, 'panel'),
                    ),
                    TextButton(
                      onPressed: () => openRouteRespectingShell(
                        context,
                        AppRoutes.panelSsl,
                      ),
                      child: Text(l10n.securityGatewayOpenPanelTlsAction),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              SectionCard(
                title: l10n.securityGatewayWebsiteCertsSection,
                padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricRow(
                        label: l10n.securityGatewaySummaryLabel,
                        value: l10n.securityGatewayCertsLoadedCount(
                            provider.certificates.length)),
                    _MetricRow(
                        label: l10n.securityGatewayRiskLabel,
                        value: l10n.securityGatewayExpiringSoonCount(
                            provider.expiringCertificateCount)),
                    _MetricRow(
                      label: l10n.securityGatewayRecentLabel,
                      value: localizeSecurityGatewayRecentSummary(
                          context, provider, 'website_https'),
                    ),
                    TextButton(
                      onPressed: () => openRouteRespectingShell(
                        context,
                        AppRoutes.websiteSslCenter,
                        arguments: {'websiteId': initialWebsiteId},
                      ),
                      child: Text(l10n.securityGatewayOpenCertCenterAction),
                    ),
                    if (initialWebsiteId != null)
                      TextButton(
                        onPressed: () => openRouteRespectingShell(
                          context,
                          AppRoutes.websiteSiteSsl,
                          arguments: {
                            'websiteId': initialWebsiteId,
                            'displayName': displayName,
                          },
                        ),
                        child: Text(
                            l10n.securityGatewayOpenWebsiteStrategyAction),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              SectionCard(
                title: l10n.securityGatewayOpenRestyGatewaySection,
                padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricRow(
                        label: l10n.securityGatewayStatusLabel,
                        value: provider.openRestyRunning
                            ? l10n.securityGatewayRunning
                            : l10n.securityGatewayInactive),
                    _MetricRow(
                      label: l10n.openrestyTabHttps,
                      value: provider.openRestySnapshot.https['https'] == true
                          ? l10n.securityGatewayEnabled
                          : l10n.securityGatewayDisabled,
                    ),
                    _MetricRow(
                      label: l10n.securityGatewayRecentLabel,
                      value: localizeSecurityGatewayRecentSummary(
                          context, provider, 'openresty_'),
                    ),
                    TextButton(
                      onPressed: () => openRouteRespectingShell(
                        context,
                        AppRoutes.openrestyCenter,
                      ),
                      child: Text(l10n.securityGatewayOpenOpenRestyAction),
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

  String _entryLabel(
      BuildContext context, SecurityGatewaySection section) {
    final l10n = context.l10n;
    switch (section) {
      case SecurityGatewaySection.panelTls:
        return l10n.securityGatewayEntryPanelTls;
      case SecurityGatewaySection.websiteCertificates:
        return l10n.securityGatewayEntryWebsiteCerts;
      case SecurityGatewaySection.openresty:
        return l10n.securityGatewayEntryOpenResty;
    }
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

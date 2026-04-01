import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  static const officialDomainName = 'onepanel.iskenkenya.com';
  static const repoSsh = 'git@github.com:IsKenKenYa/1Panel-Client.git';
  static const repoHttps = 'https://github.com/IsKenKenYa/1Panel-Client.git';
  static const issuesUrl = 'https://github.com/IsKenKenYa/1Panel-Client/issues';
  static const releasesUrl =
      'https://github.com/IsKenKenYa/1Panel-Client/releases';

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutPageTitle),
      ),
      body: FutureBuilder<PackageInfo>(
        future: _packageInfoFuture,
        builder: (context, snapshot) {
          final packageInfo = snapshot.data;
          return ListView(
            padding: AppDesignTokens.pagePadding,
            children: [
              _HeroCard(packageInfo: packageInfo),
              const SizedBox(height: AppDesignTokens.spacingLg),
              _SectionCard(
                title: l10n.aboutBuildSectionTitle,
                child: Column(
                  children: [
                    _InfoRow(
                      label: l10n.aboutVersionLabel,
                      value: packageInfo?.version ?? '-',
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      label: l10n.aboutBuildLabel,
                      value: packageInfo?.buildNumber ?? '-',
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      label: l10n.aboutPackageNameLabel,
                      value: packageInfo?.packageName ?? '-',
                    ),
                    const Divider(height: 24),
                    _LinkRow(
                      label: l10n.aboutOfficialDomainLabel,
                      value: AboutPage.officialDomainName,
                      openActionLabel: l10n.aboutLinkOpenAction,
                      onOpen: () => _openLink(
                          context, 'https://${AboutPage.officialDomainName}'),
                      onCopy: () =>
                          _copyText(context, AboutPage.officialDomainName),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingLg),
              _SectionCard(
                title: l10n.aboutProjectSectionTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.aboutProjectSummary),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    Text(l10n.aboutProjectFeatureList),
                    const SizedBox(height: AppDesignTokens.spacingMd),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () =>
                              _openLink(context, AboutPage.issuesUrl),
                          icon: const Icon(Icons.feedback_outlined),
                          label: Text(l10n.aboutFeedbackAction),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _openLink(context, AboutPage.releasesUrl),
                          icon: const Icon(Icons.open_in_new),
                          label: Text(l10n.aboutReleaseAction),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingLg),
              _SectionCard(
                title: l10n.aboutRepositorySectionTitle,
                child: Column(
                  children: [
                    _LinkRow(
                      label: l10n.aboutRepositoryHttpsLabel,
                      value: AboutPage.repoHttps,
                      onOpen: () => _openLink(context, AboutPage.repoHttps),
                    ),
                    const Divider(height: 24),
                    _LinkRow(
                      label: l10n.aboutRepositorySshLabel,
                      value: AboutPage.repoSsh,
                      onCopy: () => _copyText(context, AboutPage.repoSsh),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.aboutLinkOpenFailed)),
      );
    }
  }

  Future<void> _copyText(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.commonCopied)),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.packageInfo});

  final PackageInfo? packageInfo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/branding/app_icon_preview.png',
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: AppDesignTokens.spacingMd),
            Text(
              context.l10n.appName,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (packageInfo != null) ...[
              const SizedBox(height: AppDesignTokens.spacingSm),
              Text(
                '${packageInfo!.version} (${packageInfo!.buildNumber})',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: AppDesignTokens.spacingSm),
            Text(
              AboutPage.officialDomainName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppDesignTokens.spacingMd),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.value,
    this.onOpen,
    this.onCopy,
    this.openActionLabel,
  });

  final String label;
  final String value;
  final VoidCallback? onOpen;
  final VoidCallback? onCopy;
  final String? openActionLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppDesignTokens.spacingXs),
        SelectableText(value),
        const SizedBox(height: AppDesignTokens.spacingSm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (onOpen != null)
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new),
                label: Text(
                  openActionLabel ?? context.l10n.aboutRepositoryOpenAction,
                ),
              ),
            if (onCopy != null)
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_outlined),
                label: Text(context.l10n.commonCopy),
              ),
          ],
        ),
      ],
    );
  }
}

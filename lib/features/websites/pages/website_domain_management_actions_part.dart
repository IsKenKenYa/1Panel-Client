part of 'website_domain_management_page.dart';

extension _WebsiteDomainActions on _WebsiteDomainBody {
  Future<void> _showBatchDomainDialog(
    BuildContext context,
    WebsiteDomainProvider provider,
  ) async {
    final l10n = context.l10n;
    final domainsController = TextEditingController();
    final defaultPortController = TextEditingController(text: '80');
    var ssl = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(l10n.websitesDomainBatchAddTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.websitesDomainBatchAddHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: defaultPortController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.websitesDomainPortLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: domainsController,
                  minLines: 6,
                  maxLines: 10,
                  decoration: InputDecoration(
                    labelText: l10n.websitesDomainBatchInputLabel,
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
                  final defaultPort =
                      int.tryParse(defaultPortController.text.trim());
                  if (defaultPort == null ||
                      defaultPort < 1 ||
                      defaultPort > 65535) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(l10n.websitesDomainValidationPort)),
                    );
                    return;
                  }

                  final parseResult = _parseBatchDomains(
                    l10n: l10n,
                    input: domainsController.text,
                    currentDomains: provider.domains,
                    defaultPort: defaultPort,
                    ssl: ssl,
                  );
                  if (parseResult.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(parseResult.error!)),
                    );
                    return;
                  }
                  await provider.addDomainsBatch(parseResult.domains);
                  if (!context.mounted) {
                    return;
                  }
                  if (provider.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(provider.error!)),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();
                },
                child: Text(l10n.websitesDomainBatchAddAction),
              ),
            ],
          ),
        );
      },
    );

    domainsController.dispose();
    defaultPortController.dispose();
  }

  Future<void> _showDomainDialog(
    BuildContext context,
    WebsiteDomainProvider provider, {
    WebsiteDomain? existing,
  }) async {
    final l10n = context.l10n;
    final domainController =
        TextEditingController(text: existing?.domain ?? '');
    final portController =
        TextEditingController(text: '${existing?.port ?? 80}');
    var ssl = existing?.ssl ?? false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(
              existing == null
                  ? l10n.websitesDomainAddTitle
                  : l10n.websitesDomainEditTitle,
            ),
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
                  final domain = domainController.text.trim().toLowerCase();
                  final port = int.tryParse(portController.text.trim());
                  final validation = _validateDomainInput(
                    l10n: l10n,
                    currentId: existing?.id,
                    currentDomains: provider.domains,
                    domain: domain,
                    port: port,
                  );
                  if (validation != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(validation)),
                    );
                    return;
                  }
                  if (existing == null) {
                    await provider.addDomain(
                      domain: domain,
                      port: port!,
                      ssl: ssl,
                    );
                  } else {
                    await provider.updateDomain(
                      id: existing.id!,
                      domain: domain,
                      port: port,
                      ssl: ssl,
                    );
                  }
                  if (!context.mounted) {
                    return;
                  }
                  if (provider.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(provider.error!)),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();
                },
                child:
                    Text(existing == null ? l10n.commonAdd : l10n.commonSave),
              ),
            ],
          ),
        );
      },
    );

    domainController.dispose();
    portController.dispose();
  }

  String? _validateDomainInput({
    required AppLocalizations l10n,
    required int? currentId,
    required List<WebsiteDomain> currentDomains,
    required String domain,
    required int? port,
  }) {
    if (domain.isEmpty) {
      return l10n.websitesDomainValidationRequired;
    }
    if (port == null || port < 1 || port > 65535) {
      return l10n.websitesDomainValidationPort;
    }
    final duplicate = currentDomains.any(
      (item) =>
          item.id != currentId && item.domain?.trim().toLowerCase() == domain,
    );
    if (duplicate) {
      return l10n.websitesDomainValidationDuplicate;
    }
    return null;
  }

  ({String? error, List<Map<String, dynamic>> domains}) _parseBatchDomains({
    required AppLocalizations l10n,
    required String input,
    required List<WebsiteDomain> currentDomains,
    required int defaultPort,
    required bool ssl,
  }) {
    final seen = currentDomains
        .map((WebsiteDomain item) => item.domain?.trim().toLowerCase())
        .whereType<String>()
        .toSet();
    final parsed = <Map<String, dynamic>>[];
    final lines = input
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      return (
        error: l10n.websitesDomainBatchValidationEmpty,
        domains: const []
      );
    }

    for (final line in lines) {
      final normalized = line.toLowerCase();
      final segments = normalized.split(':');
      final domain = segments.first.trim();
      final port = segments.length > 1
          ? int.tryParse(segments.last.trim())
          : defaultPort;
      if (domain.isEmpty || port == null || port < 1 || port > 65535) {
        return (
          error: l10n.websitesDomainBatchValidationInvalid(line),
          domains: const []
        );
      }
      if (seen.contains(domain)) {
        return (
          error: l10n.websitesDomainValidationDuplicate,
          domains: const []
        );
      }
      seen.add(domain);
      parsed.add(<String, dynamic>{
        'domain': domain,
        'port': port,
        'ssl': ssl,
      });
    }

    return (error: null, domains: parsed);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WebsiteDomainProvider provider,
    WebsiteDomain domain,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.websitesDeleteTitle),
        content: Text(
          context.l10n.websitesDomainDeleteMessage(domain.domain ?? '-'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && domain.id != null) {
      await provider.deleteDomain(domain.id!);
      if (!context.mounted) {
        return;
      }
      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error!)),
        );
      }
    }
  }
}

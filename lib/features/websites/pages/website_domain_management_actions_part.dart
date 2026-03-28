part of 'website_domain_management_page.dart';

extension _WebsiteDomainActions on _WebsiteDomainBody {
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
                  Navigator.of(ctx).pop();
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
          item.id != currentId &&
          item.domain?.trim().toLowerCase() == domain,
    );
    if (duplicate) {
      return l10n.websitesDomainValidationDuplicate;
    }
    return null;
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
    }
  }
}

import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/data/models/website_models.dart';

class WebsiteLifecycleRuntimeCard extends StatelessWidget {
  const WebsiteLifecycleRuntimeCard({
    super.key,
    required this.runtimes,
    required this.value,
    required this.siteDir,
    required this.onRuntimeChanged,
    required this.onSiteDirChanged,
  });

  final List<RuntimeInfo> runtimes;
  final int? value;
  final String siteDir;
  final ValueChanged<int?> onRuntimeChanged;
  final ValueChanged<String> onSiteDirChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              initialValue: value,
              decoration: InputDecoration(labelText: l10n.websitesRuntimeLabel),
              items: [
                for (final runtime in runtimes)
                  DropdownMenuItem(
                    value: runtime.id,
                    child: Text(runtime.name ?? '${runtime.id}'),
                  ),
              ],
              onChanged: onRuntimeChanged,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: siteDir,
              decoration:
                  InputDecoration(labelText: l10n.websitesSiteDirLabel),
              onChanged: onSiteDirChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class WebsiteLifecycleProxyCard extends StatelessWidget {
  const WebsiteLifecycleProxyCard({
    super.key,
    required this.proxyType,
    required this.proxyAddress,
    required this.port,
    required this.onProxyTypeChanged,
    required this.onProxyAddressChanged,
    required this.onPortChanged,
  });

  final String proxyType;
  final String proxyAddress;
  final String port;
  final ValueChanged<String> onProxyTypeChanged;
  final ValueChanged<String> onProxyAddressChanged;
  final ValueChanged<String> onPortChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: proxyType,
              decoration:
                  InputDecoration(labelText: l10n.websitesProxyTypeLabel),
              items: const [
                DropdownMenuItem(value: 'tcp', child: Text('tcp')),
                DropdownMenuItem(value: 'http', child: Text('http')),
              ],
              onChanged: (value) {
                if (value != null) onProxyTypeChanged(value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: proxyAddress,
              decoration:
                  InputDecoration(labelText: l10n.websitesProxyAddressLabel),
              onChanged: onProxyAddressChanged,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: port,
              decoration:
                  InputDecoration(labelText: l10n.websitesDomainPortLabel),
              keyboardType: TextInputType.number,
              onChanged: onPortChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class WebsiteLifecycleParentCard extends StatelessWidget {
  const WebsiteLifecycleParentCard({
    super.key,
    required this.websites,
    required this.value,
    required this.onChanged,
  });

  final List<WebsiteInfo> websites;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<int>(
          initialValue: value,
          decoration:
              InputDecoration(labelText: l10n.websitesParentWebsiteLabel),
          items: [
            for (final website in websites)
              DropdownMenuItem(
                value: website.id,
                child: Text(website.displayDomain ?? '${website.id}'),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

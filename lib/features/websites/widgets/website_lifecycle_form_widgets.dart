import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/data/models/website_group_models.dart';
import 'package:onepanel_client/data/models/website_models.dart';

class WebsiteLifecycleTextFieldCard extends StatelessWidget {
  const WebsiteLifecycleTextFieldCard({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.maxLines = 1,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class WebsiteLifecycleTypeCard extends StatelessWidget {
  const WebsiteLifecycleTypeCard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          decoration:
              InputDecoration(labelText: l10n.websitesLifecycleTypeLabel),
          items: [
            DropdownMenuItem(
              value: 'runtime',
              child: Text(l10n.websitesLifecycleTypeRuntime),
            ),
            DropdownMenuItem(
              value: 'proxy',
              child: Text(l10n.websitesLifecycleTypeProxy),
            ),
            DropdownMenuItem(
              value: 'subsite',
              child: Text(l10n.websitesLifecycleTypeSubsite),
            ),
            DropdownMenuItem(
              value: 'static',
              child: Text(l10n.websitesLifecycleTypeStatic),
            ),
          ],
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}

class WebsiteLifecycleGroupCard extends StatelessWidget {
  const WebsiteLifecycleGroupCard({
    super.key,
    required this.groups,
    required this.value,
    required this.onChanged,
  });

  final List<WebsiteGroup> groups;
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
          decoration: InputDecoration(labelText: l10n.websitesGroupLabel),
          items: [
            for (final group in groups)
              DropdownMenuItem(
                value: group.id,
                child: Text(group.name ?? '${group.id}'),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

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

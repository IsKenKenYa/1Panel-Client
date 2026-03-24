import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

import '../providers/website_create_provider.dart';
import '../widgets/website_async_state_view.dart';

class WebsiteCreateFlowPage extends StatelessWidget {
  const WebsiteCreateFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebsiteCreateProvider()..load(),
      child: const _WebsiteCreateFlowBody(),
    );
  }
}

class _WebsiteCreateFlowBody extends StatelessWidget {
  const _WebsiteCreateFlowBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text('${l10n.websitesPageTitle} · ${l10n.commonCreate}')),
      body: Consumer<WebsiteCreateProvider>(
        builder: (context, provider, _) {
          return WebsiteAsyncStateView(
            isLoading: provider.isLoading,
            error: provider.error,
            onRetry: () => provider.load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.layers_outlined),
                    title: Text(l10n.websitesPageTitle),
                    subtitle: Text(provider.groups.isEmpty ? l10n.commonComingSoon : '${provider.groups.length} groups'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.commonComingSoon,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

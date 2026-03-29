import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

import '../providers/website_ssl_accounts_provider.dart';
import '../widgets/website_async_state_view.dart';

part 'website_ssl_accounts_actions_part.dart';

class WebsiteSslAccountsPage extends StatelessWidget {
  const WebsiteSslAccountsPage({
    super.key,
    this.provider,
  });

  final WebsiteSslAccountsProvider? provider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final activeProvider = provider ?? WebsiteSslAccountsProvider();
        activeProvider.load();
        return activeProvider;
      },
      child: const _WebsiteSslAccountsBody(),
    );
  }
}

class _WebsiteSslAccountsBody extends StatelessWidget {
  const _WebsiteSslAccountsBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sslSettingsTitle),
        actions: [
          IconButton(
            onPressed: () => context.read<WebsiteSslAccountsProvider>().load(),
            icon: const Icon(Icons.refresh),
            tooltip: l10n.commonRefresh,
          ),
        ],
      ),
      body: Consumer<WebsiteSslAccountsProvider>(
        builder: (context, provider, _) {
          return WebsiteAsyncStateView(
            isLoading: provider.isLoading,
            error: provider.error,
            onRetry: () => provider.load(),
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  if (provider.operationError != null)
                    _OperationErrorBanner(message: provider.operationError!),
                  TabBar(
                    tabs: [
                      Tab(text: l10n.websitesSslAccountsCaTab),
                      Tab(text: l10n.websitesSslAccountsAcmeTab),
                      Tab(text: l10n.websitesSslAccountsDnsTab),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _CertificateAuthorityTab(
                          provider: provider,
                          onCreate: () => _showCertificateAuthorityDialog(
                            context,
                            provider,
                          ),
                          onDelete: (item) =>
                              _confirmDeleteCertificateAuthority(
                            context,
                            provider,
                            item,
                          ),
                          onObtain: (item) => _showObtainDialog(
                            context,
                            provider,
                            item,
                          ),
                          onRenew: (item) => _renewCertificate(
                            context,
                            provider,
                            item,
                          ),
                          onDownload: (item) => _downloadCertificate(
                            context,
                            provider,
                            item,
                          ),
                        ),
                        _AcmeAccountTab(
                          provider: provider,
                          onCreate: () => _showAcmeDialog(context, provider),
                          onEdit: (item) => _showAcmeDialog(context, provider,
                              existing: item),
                          onDelete: (item) => _confirmDeleteAcme(
                            context,
                            provider,
                            item,
                          ),
                        ),
                        _DnsAccountTab(
                          provider: provider,
                          onCreate: () => _showDnsDialog(context, provider),
                          onEdit: (item) =>
                              _showDnsDialog(context, provider, existing: item),
                          onDelete: (item) => _confirmDeleteDns(
                            context,
                            provider,
                            item,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OperationErrorBanner extends StatelessWidget {
  const _OperationErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(message),
      leading: const Icon(Icons.warning_amber_outlined),
      actions: [
        TextButton(
          onPressed: () => ScaffoldMessenger.of(context).clearMaterialBanners(),
          child: Text(context.l10n.commonClose),
        ),
      ],
    );
  }
}

class _CertificateAuthorityTab extends StatelessWidget {
  const _CertificateAuthorityTab({
    required this.provider,
    required this.onCreate,
    required this.onDelete,
    required this.onObtain,
    required this.onRenew,
    required this.onDownload,
  });

  final WebsiteSslAccountsProvider provider;
  final VoidCallback onCreate;
  final ValueChanged<Map<String, dynamic>> onDelete;
  final ValueChanged<Map<String, dynamic>> onObtain;
  final ValueChanged<Map<String, dynamic>> onRenew;
  final ValueChanged<Map<String, dynamic>> onDownload;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: provider.isOperating ? null : onCreate,
            icon: const Icon(Icons.add),
            label: Text(l10n.websitesSslAccountsCreateCaAction),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: provider.certificateAuthorities.isEmpty
                ? Center(child: Text(l10n.websitesSslAccountsEmpty))
                : ListView.builder(
                    itemCount: provider.certificateAuthorities.length,
                    itemBuilder: (context, index) {
                      final item = provider.certificateAuthorities[index];
                      final id = provider.resolveAccountId(item);
                      final title = _readString(item, const ['name']);
                      final subtitle = _readString(
                        item,
                        const ['commonName', 'organization', 'country'],
                      );
                      return Card(
                        child: ListTile(
                          title: Text(title),
                          subtitle: Text(subtitle),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                onPressed: provider.isOperating || id == null
                                    ? null
                                    : () => onObtain(item),
                                icon: const Icon(Icons.vpn_key_outlined),
                                tooltip: l10n.websitesSslAccountsObtainAction,
                              ),
                              IconButton(
                                onPressed: provider.isOperating || id == null
                                    ? null
                                    : () => onRenew(item),
                                icon: const Icon(Icons.refresh),
                                tooltip: l10n.websitesSslAccountsRenewAction,
                              ),
                              IconButton(
                                onPressed: provider.isOperating || id == null
                                    ? null
                                    : () => onDownload(item),
                                icon: const Icon(Icons.download_outlined),
                                tooltip: l10n.websitesSslAccountsDownloadAction,
                              ),
                              IconButton(
                                onPressed: provider.isOperating || id == null
                                    ? null
                                    : () => onDelete(item),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: l10n.commonDelete,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AcmeAccountTab extends StatelessWidget {
  const _AcmeAccountTab({
    required this.provider,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final WebsiteSslAccountsProvider provider;
  final VoidCallback onCreate;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: provider.isOperating ? null : onCreate,
            icon: const Icon(Icons.add),
            label: Text(l10n.websitesSslAccountsCreateAcmeAction),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: provider.acmeAccounts.isEmpty
                ? Center(child: Text(l10n.websitesSslAccountsEmpty))
                : ListView.builder(
                    itemCount: provider.acmeAccounts.length,
                    itemBuilder: (context, index) {
                      final item = provider.acmeAccounts[index];
                      final id = provider.resolveAccountId(item);
                      final email = _readString(item, const ['email']);
                      final type = _readString(item, const ['type']);
                      final useProxy = _readBool(item, const ['useProxy']);
                      return Card(
                        child: ListTile(
                          title: Text(email),
                          subtitle: Text(
                            '$type · ${useProxy ? l10n.commonYes : l10n.commonNo}',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                onPressed: provider.isOperating || id == null
                                    ? null
                                    : () => onEdit(item),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: l10n.commonEdit,
                              ),
                              IconButton(
                                onPressed: provider.isOperating || id == null
                                    ? null
                                    : () => onDelete(item),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: l10n.commonDelete,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DnsAccountTab extends StatelessWidget {
  const _DnsAccountTab({
    required this.provider,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final WebsiteSslAccountsProvider provider;
  final VoidCallback onCreate;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: provider.isOperating ? null : onCreate,
            icon: const Icon(Icons.add),
            label: Text(l10n.websitesSslAccountsCreateDnsAction),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: provider.dnsAccounts.isEmpty
                ? Center(child: Text(l10n.websitesSslAccountsEmpty))
                : ListView.builder(
                    itemCount: provider.dnsAccounts.length,
                    itemBuilder: (context, index) {
                      final item = provider.dnsAccounts[index];
                      final id = provider.resolveAccountId(item);
                      final name = _readString(item, const ['name']);
                      final type = _readString(item, const ['type']);
                      final authorization = item['authorization'];
                      final authCount =
                          authorization is Map ? authorization.length : 0;
                      return Card(
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text('$type · $authCount'),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                onPressed: provider.isOperating || id == null
                                    ? null
                                    : () => onEdit(item),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: l10n.commonEdit,
                              ),
                              IconButton(
                                onPressed: provider.isOperating || id == null
                                    ? null
                                    : () => onDelete(item),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: l10n.commonDelete,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _readString(Map<String, dynamic> item, List<String> keys) {
  for (final key in keys) {
    final value = item[key];
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '-';
}

bool _readBool(Map<String, dynamic> item, List<String> keys) {
  for (final key in keys) {
    final value = item[key];
    if (value is bool) {
      return value;
    }
    if (value is String) {
      if (value.toLowerCase() == 'true') {
        return true;
      }
      if (value.toLowerCase() == 'false') {
        return false;
      }
    }
  }
  return false;
}

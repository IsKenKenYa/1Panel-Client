import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/mcp_models.dart';
import 'package:onepanel_client/features/ai/mcp_server_provider.dart';
import 'package:provider/provider.dart';

class AIMcpTabWidget extends StatefulWidget {
  const AIMcpTabWidget({super.key});

  @override
  State<AIMcpTabWidget> createState() => _AIMcpTabWidgetState();
}

class _AIMcpTabWidgetState extends State<AIMcpTabWidget> {
  final TextEditingController _searchController = TextEditingController();
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<McpServerProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<McpServerProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: provider.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: l10n.aiMcpSearchHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: provider.isLoading
                        ? null
                        : () {
                            provider.updateSearchQuery(
                                _searchController.text.trim());
                            provider.load();
                          },
                    icon: const Icon(Icons.search),
                  ),
                ),
                onSubmitted: (String value) {
                  provider.updateSearchQuery(value.trim());
                  provider.load();
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: provider.isMutating
                        ? null
                        : () => _showServerDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.aiMcpCreate),
                  ),
                  OutlinedButton.icon(
                    onPressed: provider.isMutating
                        ? null
                        : () => _showDomainDialog(context),
                    icon: const Icon(Icons.public_outlined),
                    label: Text(l10n.aiMcpBindDomain),
                  ),
                  OutlinedButton.icon(
                    onPressed: provider.isLoading ? null : provider.load,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.commonRefresh),
                  ),
                ],
              ),
              if (provider.error != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  provider.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.public_outlined),
                  title: Text(l10n.aiMcpBindingTitle),
                  subtitle: Text(
                    (provider.binding.domain ?? '').trim().isEmpty
                        ? l10n.commonEmpty
                        : '${provider.binding.domain}\n${provider.binding.connUrl ?? ''}'
                            .trim(),
                  ),
                  isThreeLine:
                      (provider.binding.domain ?? '').trim().isNotEmpty,
                ),
              ),
              const SizedBox(height: 12),
              if (provider.servers.isEmpty && !provider.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: Text(l10n.aiMcpNoServers)),
                )
              else
                ...provider.servers.map(
                  (McpServerDTO server) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                      title: Text(server.name ?? '-'),
                      subtitle: Text(_subtitle(context, provider, server)),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (String value) => _handleAction(
                          context,
                          provider,
                          server,
                          value,
                        ),
                        itemBuilder: (_) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'config',
                            child: Text(l10n.aiMcpConfigPreviewTitle),
                          ),
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text(l10n.aiMcpEdit),
                          ),
                          PopupMenuItem<String>(
                            value: 'start',
                            child: Text(l10n.commonStart),
                          ),
                          PopupMenuItem<String>(
                            value: 'stop',
                            child: Text(l10n.commonStop),
                          ),
                          PopupMenuItem<String>(
                            value: 'restart',
                            child: Text(l10n.commonRestart),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(l10n.commonDelete),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _subtitle(
    BuildContext context,
    McpServerProvider provider,
    McpServerDTO server,
  ) {
    final l10n = context.l10n;
    final lines = <String>[
      '${l10n.aiMcpStatusLabel}: ${server.status ?? '-'}',
      '${l10n.aiMcpPortLabel}: ${server.port?.toString() ?? '-'}',
      '${l10n.aiMcpTransportLabel}: ${server.outputTransport ?? '-'}',
      '${l10n.aiMcpExternalUrl}: ${provider.buildExternalUrl(server).isEmpty ? '-' : provider.buildExternalUrl(server)}',
    ];
    return lines.join('\n');
  }

  Future<void> _handleAction(
    BuildContext context,
    McpServerProvider provider,
    McpServerDTO server,
    String action,
  ) async {
    final l10n = context.l10n;
    if (action == 'config') {
      final preview = const JsonEncoder.withIndent('  ')
          .convert(provider.buildConfigPreview(server));
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text(l10n.aiMcpConfigPreviewTitle),
          content: SingleChildScrollView(child: SelectableText(preview)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.commonClose),
            ),
          ],
        ),
      );
      return;
    }
    if (action == 'edit') {
      await _showServerDialog(context, initialValue: server);
      return;
    }
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text(l10n.commonDelete),
          content: Text(l10n.aiMcpDeleteConfirm(server.name ?? '-')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.commonDelete),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await provider.deleteServer(server.id ?? 0);
      }
      return;
    }
    await provider.operateServer(
      id: server.id ?? 0,
      operate: action,
    );
  }

  Future<void> _showServerDialog(
    BuildContext context, {
    McpServerDTO? initialValue,
  }) async {
    final l10n = context.l10n;
    final formKey = GlobalKey<FormState>();
    final nameController =
        TextEditingController(text: initialValue?.name ?? '');
    final commandController =
        TextEditingController(text: initialValue?.command ?? '');
    final typeController =
        TextEditingController(text: initialValue?.type ?? 'stdio');
    final transportController = TextEditingController(
      text: initialValue?.outputTransport ?? 'streamable_http',
    );
    final portController = TextEditingController(
      text: initialValue?.port?.toString() ?? '8000',
    );
    final baseUrlController =
        TextEditingController(text: initialValue?.baseUrl ?? '');
    final hostIpController =
        TextEditingController(text: initialValue?.hostIP ?? '');
    final containerController =
        TextEditingController(text: initialValue?.containerName ?? '');
    final ssePathController =
        TextEditingController(text: initialValue?.ssePath ?? '');
    final streamablePathController = TextEditingController(
      text: initialValue?.streamableHttpPath ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            initialValue == null
                ? l10n.aiMcpDialogCreateTitle
                : l10n.aiMcpDialogEditTitle,
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _FormField(
                    controller: nameController,
                    label: l10n.commonName,
                    validator: (String? value) => (value ?? '').trim().isEmpty
                        ? l10n.aiMcpNameRequired
                        : null,
                  ),
                  _FormField(
                    controller: commandController,
                    label: l10n.aiMcpCommandLabel,
                    validator: (String? value) => (value ?? '').trim().isEmpty
                        ? l10n.aiMcpCommandRequired
                        : null,
                  ),
                  _FormField(
                    controller: typeController,
                    label: l10n.aiMcpTypeLabel,
                    validator: (String? value) => (value ?? '').trim().isEmpty
                        ? l10n.aiMcpTypeRequired
                        : null,
                  ),
                  _FormField(
                    controller: transportController,
                    label: l10n.aiMcpTransportLabel,
                    validator: (String? value) => (value ?? '').trim().isEmpty
                        ? l10n.aiMcpTransportRequired
                        : null,
                  ),
                  _FormField(
                    controller: portController,
                    label: l10n.aiMcpPortLabel,
                    keyboardType: TextInputType.number,
                    validator: (String? value) =>
                        int.tryParse((value ?? '').trim()) == null
                            ? l10n.aiMcpPortRequired
                            : null,
                  ),
                  _FormField(
                    controller: baseUrlController,
                    label: l10n.aiMcpBaseUrlLabel,
                  ),
                  _FormField(
                    controller: hostIpController,
                    label: l10n.aiMcpHostIpLabel,
                  ),
                  _FormField(
                    controller: containerController,
                    label: l10n.aiMcpContainerLabel,
                  ),
                  _FormField(
                    controller: ssePathController,
                    label: l10n.aiMcpSsePathLabel,
                  ),
                  _FormField(
                    controller: streamablePathController,
                    label: l10n.aiMcpStreamablePathLabel,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                final success =
                    await context.read<McpServerProvider>().saveServer(
                          id: initialValue?.id,
                          name: nameController.text.trim(),
                          command: commandController.text.trim(),
                          type: typeController.text.trim(),
                          outputTransport: transportController.text.trim(),
                          port: int.parse(portController.text.trim()),
                          baseUrl: baseUrlController.text,
                          hostIP: hostIpController.text,
                          containerName: containerController.text,
                          ssePath: ssePathController.text,
                          streamableHttpPath: streamablePathController.text,
                        );
                if (!dialogContext.mounted || !success) {
                  return;
                }
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n.commonSave),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDomainDialog(BuildContext context) async {
    final l10n = context.l10n;
    final provider = context.read<McpServerProvider>();
    final formKey = GlobalKey<FormState>();
    final domainController =
        TextEditingController(text: provider.binding.domain ?? '');
    final ipListController = TextEditingController(
      text: (provider.binding.allowIPs ?? const <String>[]).join('\n'),
    );
    final sslController = TextEditingController(
      text: provider.binding.sslID?.toString() ?? '',
    );
    final websiteController = TextEditingController(
      text: provider.binding.websiteID?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.aiMcpDomainDialogTitle),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _FormField(
                    controller: domainController,
                    label: l10n.websitesDomainLabel,
                    validator: (String? value) => (value ?? '').trim().isEmpty
                        ? l10n.aiMcpDomainRequired
                        : null,
                  ),
                  _FormField(
                    controller: ipListController,
                    label: l10n.aiIpAllowListLabel,
                    maxLines: 4,
                  ),
                  _FormField(
                    controller: sslController,
                    label: l10n.aiSslIdOptionalLabel,
                    keyboardType: TextInputType.number,
                  ),
                  _FormField(
                    controller: websiteController,
                    label: l10n.aiWebsiteIdOptionalLabel,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                final success = await context
                    .read<McpServerProvider>()
                    .saveDomainBinding(
                      domain: domainController.text.trim(),
                      ipList: ipListController.text.trim(),
                      sslId: int.tryParse(sslController.text.trim()),
                      websiteId: int.tryParse(websiteController.text.trim()),
                    );
                if (!dialogContext.mounted || !success) {
                  return;
                }
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n.commonSave),
            ),
          ],
        );
      },
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

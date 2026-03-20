import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/openresty_models.dart';
import '../../../data/models/website_models.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import '../providers/website_config_provider.dart';
import '../widgets/website_common_widgets.dart';

class WebsiteConfigPage extends StatelessWidget {
  final int websiteId;
  final String? displayName;

  const WebsiteConfigPage({super.key, required this.websiteId, this.displayName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebsiteConfigProvider(websiteId: websiteId)..loadAll(),
      child: _WebsiteConfigBody(title: displayName),
    );
  }
}

class _WebsiteConfigBody extends StatefulWidget {
  final String? title;

  const _WebsiteConfigBody({this.title});

  @override
  State<_WebsiteConfigBody> createState() => _WebsiteConfigBodyState();
}

class _WebsiteConfigBodyState extends State<_WebsiteConfigBody> {
  final TextEditingController _configController = TextEditingController();
  final TextEditingController _runtimeIdController = TextEditingController();

  @override
  void dispose() {
    _configController.dispose();
    _runtimeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<WebsiteConfigProvider>(
      builder: (context, provider, _) {
        final title = widget.title == null
            ? l10n.websitesConfigPageTitle
            : '${l10n.websitesConfigPageTitle} · ${widget.title}';

        if (provider.isLoading && provider.nginxConfigFile == null) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null && provider.nginxConfigFile == null) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: WebsiteErrorSection(
              message: provider.error!,
              onRetry: provider.loadAll,
            ),
          );
        }

        final configContent = provider.nginxConfigFile?.content ?? '';
        if (_configController.text.isEmpty || _configController.text == configContent) {
          _configController.text = configContent;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.loadAll,
                tooltip: l10n.commonRefresh,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ConfigEditorCard(
                controller: _configController,
                onReload: provider.loadConfigFile,
                onSave: () => provider.saveConfigFile(_configController.text),
              ),
              const SizedBox(height: 12),
              _ScopeCard(
                scope: provider.scope,
                response: provider.scopeResponse,
                onScopeChanged: (key) => provider.loadScope(key),
                onEdit: (params) => provider.updateScope(params),
              ),
              const SizedBox(height: 12),
              _PhpVersionCard(
                controller: _runtimeIdController,
                onUpdate: () async {
                  final runtimeId = int.tryParse(_runtimeIdController.text.trim());
                  await provider.updatePhpVersion(runtimeId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.commonSaveSuccess)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConfigEditorCard extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function() onReload;
  final Future<void> Function() onSave;

  const _ConfigEditorCard({
    required this.controller,
    required this.onReload,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.websitesConfigEditorTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: onReload,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.commonRefresh),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save),
                  label: Text(l10n.commonSave),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 12,
              maxLines: 18,
              decoration: InputDecoration(
                hintText: l10n.websitesConfigHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeCard extends StatelessWidget {
  final NginxKey scope;
  final WebsiteNginxScopeResponse? response;
  final ValueChanged<NginxKey> onScopeChanged;
  final Future<void> Function(List<WebsiteNginxParam> params) onEdit;

  const _ScopeCard({
    required this.scope,
    required this.response,
    required this.onScopeChanged,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final params = response?.params ?? const [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.websitesConfigScopeTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<NginxKey>(
              value: scope,
              decoration: InputDecoration(
                labelText: l10n.websitesConfigScopeLabel,
                border: const OutlineInputBorder(),
              ),
              items: NginxKey.values
                  .map((key) => DropdownMenuItem(value: key, child: Text(key.value)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onScopeChanged(value);
                }
              },
            ),
            const SizedBox(height: 12),
            if (params.isEmpty)
              Text(l10n.websitesConfigScopeEmpty)
            else
              Column(
                children: params.map((param) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(param.name ?? '-', style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: param.params.map((item) => Chip(label: Text(item))).toList(),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showEditDialog(context, param, params),
                          child: Text(l10n.commonEdit),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WebsiteNginxParam param, List<WebsiteNginxParam> allParams) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: param.params.join(','));
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.websitesConfigScopeEditTitle(param.name ?? '-')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.websitesConfigScopeValuesLabel,
            hintText: l10n.websitesConfigScopeValuesHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final values = controller.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              Navigator.of(ctx).pop();
              final updated = param.copyWith(params: values);
              final next = allParams.map((item) => item.name == updated.name ? updated : item).toList();
              await onEdit(next);
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}

class _PhpVersionCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onUpdate;

  const _PhpVersionCard({required this.controller, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.websitesPhpVersionTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.websitesPhpRuntimeIdLabel,
                hintText: l10n.websitesPhpRuntimeIdHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onUpdate,
              icon: const Icon(Icons.save),
              label: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}

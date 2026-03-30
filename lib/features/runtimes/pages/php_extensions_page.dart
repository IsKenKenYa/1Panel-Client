import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';
import 'package:onepanel_client/features/runtimes/providers/php_extensions_provider.dart';
import 'package:onepanel_client/features/runtimes/utils/runtime_l10n_helper.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

class PhpExtensionsPage extends StatefulWidget {
  const PhpExtensionsPage({
    super.key,
    required this.args,
  });

  final RuntimeManageArgs args;

  @override
  State<PhpExtensionsPage> createState() => _PhpExtensionsPageState();
}

class _PhpExtensionsPageState extends State<PhpExtensionsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<PhpExtensionsProvider>().initialize(widget.args);
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
    return Consumer<PhpExtensionsProvider>(
      builder: (context, provider, _) {
        final title = provider.runtimeName.trim().isEmpty
            ? l10n.operationsPhpExtensionsTitle
            : '${provider.runtimeName} · ${l10n.operationsPhpExtensionsTitle}';
        return ServerAwarePageScaffold(
          title: title,
          onServerChanged: () =>
              context.read<PhpExtensionsProvider>().initialize(widget.args),
          actions: <Widget>[
            IconButton(
              onPressed: provider.isLoading ? null : provider.load,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
            IconButton(
              onPressed: provider.isOperating ? null : () => _showRecordDialog(),
              icon: const Icon(Icons.add),
              tooltip: l10n.commonCreate,
            ),
          ],
          body: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: provider.updateKeyword,
                  decoration: InputDecoration(
                    hintText: l10n.commonSearch,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: AsyncStatePageBodyWidget(
                  isLoading: provider.isLoading,
                  isEmpty: provider.isEmpty,
                  errorMessage:
                      localizeRuntimeError(l10n, provider.errorMessage),
                  onRetry: provider.load,
                  emptyTitle: l10n.runtimeEmptyTitle,
                  emptyDescription: l10n.runtimeEmptyDescription,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: <Widget>[
                      for (final item in provider.filteredItems) ...<Widget>[
                        _buildItemCard(context, provider, item),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${l10n.operationsPhpExtensionsTitle} Records',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: provider.isOperating
                                ? null
                                : () => _showRecordDialog(),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.commonCreate),
                          ),
                        ],
                      ),
                      if (provider.extensionRecords.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            l10n.runtimeEmptyDescription,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      for (final record in provider.extensionRecords) ...<Widget>[
                        Card(
                          child: ListTile(
                            title: Text(record.name),
                            subtitle: Text(record.extensions),
                            trailing: Wrap(
                              spacing: 8,
                              children: <Widget>[
                                IconButton(
                                  onPressed: provider.isOperating
                                      ? null
                                      : () => _showRecordDialog(record: record),
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: l10n.commonEdit,
                                ),
                                IconButton(
                                  onPressed: provider.isOperating
                                      ? null
                                      : () => _deleteRecord(record),
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: l10n.commonDelete,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    PhpExtensionsProvider provider,
    PHPExtensionSupport item,
  ) {
    final l10n = context.l10n;
    final isInstalled = item.installed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if ((item.description ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(item.description!),
            ],
            if (item.versions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: item.versions
                    .map((version) => Chip(label: Text(version)))
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: provider.isOperating ? null : () => _toggle(item),
              child: Text(
                isInstalled ? l10n.appActionUninstall : l10n.appStoreInstall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(PHPExtensionSupport item) async {
    final l10n = context.l10n;
    final confirm = await ConfirmActionSheetWidget.show(
      context,
      title: item.installed ? l10n.appActionUninstall : l10n.appStoreInstall,
      message:
          '${item.installed ? l10n.appActionUninstall : l10n.appStoreInstall} ${item.name}?',
      confirmLabel:
          item.installed ? l10n.appActionUninstall : l10n.appStoreInstall,
      isDestructive: item.installed,
      confirmIcon:
          item.installed ? Icons.delete_outline : Icons.download_outlined,
    );
    if (!confirm || !mounted) {
      return;
    }
    final success =
        await context.read<PhpExtensionsProvider>().toggleExtension(item);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? l10n.commonSaveSuccess : l10n.commonSaveFailed),
      ),
    );
  }

  Future<void> _showRecordDialog({PHPExtensionRecord? record}) async {
    final l10n = context.l10n;
    final nameController = TextEditingController(text: record?.name ?? '');
    final extensionsController =
        TextEditingController(text: record?.extensions ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(record == null ? l10n.commonCreate : l10n.commonEdit),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                enabled: record == null,
                decoration: InputDecoration(labelText: l10n.commonName),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: extensionsController,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Extensions'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.commonConfirm),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<PhpExtensionsProvider>();
    final ok = record == null
        ? await provider.createExtensionRecord(
            nameController.text,
            extensionsController.text,
          )
        : await provider.updateExtensionRecord(
            record,
            extensionsController.text,
          );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.commonSaveSuccess : l10n.commonSaveFailed),
      ),
    );
  }

  Future<void> _deleteRecord(PHPExtensionRecord record) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.commonDelete,
      message: '${l10n.commonDelete} ${record.name}?',
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
      confirmIcon: Icons.delete_outline,
    );
    if (!confirmed || !mounted) {
      return;
    }

    final ok =
        await context.read<PhpExtensionsProvider>().deleteExtensionRecord(record);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.commonSaveSuccess : l10n.commonSaveFailed),
      ),
    );
  }
}

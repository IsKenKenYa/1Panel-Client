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
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: provider.filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = provider.filteredItems[index];
                      return _buildItemCard(context, provider, item);
                    },
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
      message: '${item.installed ? l10n.appActionUninstall : l10n.appStoreInstall} ${item.name}?',
      confirmLabel:
          item.installed ? l10n.appActionUninstall : l10n.appStoreInstall,
      isDestructive: item.installed,
      confirmIcon:
          item.installed ? Icons.delete_outline : Icons.download_outlined,
    );
    if (!confirm || !mounted) {
      return;
    }
    final success = await context.read<PhpExtensionsProvider>().toggleExtension(item);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? l10n.commonSaveSuccess : l10n.commonSaveFailed),
      ),
    );
  }
}

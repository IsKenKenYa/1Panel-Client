import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

import '../providers/website_template_provider.dart';

class WebsiteTemplateOutputsPage extends StatefulWidget {
  const WebsiteTemplateOutputsPage({super.key, this.templateId});

  final int? templateId;

  @override
  State<WebsiteTemplateOutputsPage> createState() =>
      _WebsiteTemplateOutputsPageState();
}

class _WebsiteTemplateOutputsPageState
    extends State<WebsiteTemplateOutputsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<WebsiteTemplateProvider>()
            .loadOutputs(templateID: widget.templateId);
      }
    });
  }

  Future<void> _delete(int id) async {
    final l10n = context.l10n;
    await showAppFormDialog(
      context,
      title: l10n.commonDelete,
      destructive: true,
      content: Text(l10n.websitesTemplateOutputDeleteConfirm),
      onConfirm: () async {
        final provider = context.read<WebsiteTemplateProvider>();
        final ok = await provider.deleteOutput(
          id,
          templateID: widget.templateId,
        );
        if (!mounted) return;
        if (!ok) {
          throw StateError(provider.operationError ?? '$id');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ServerAwarePageScaffold(
      title: l10n.websitesTemplateOutputsTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_outlined),
          tooltip: l10n.commonRefresh,
          onPressed: () => context
              .read<WebsiteTemplateProvider>()
              .loadOutputs(templateID: widget.templateId),
        ),
      ],
      body: Consumer<WebsiteTemplateProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.outputs.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.outputs.items.isEmpty) {
            return ModuleErrorStateWidget(
              message: provider.error!,
              onRetry: () => provider.loadOutputs(
                templateID: widget.templateId,
              ),
            );
          }
          final items = provider.outputs.items;
          if (items.isEmpty) {
            return Center(child: Text(l10n.websitesTemplateOutputEmpty));
          }
          return RefreshIndicator(
            onRefresh: () =>
                provider.loadOutputs(templateID: widget.templateId),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.templateName} · ${item.outputPath}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l10n.commonDelete,
                      onPressed: () => _delete(item.id),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

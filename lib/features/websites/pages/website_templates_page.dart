import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

import '../providers/website_template_provider.dart';

class WebsiteTemplatesPage extends StatefulWidget {
  const WebsiteTemplatesPage({super.key});

  @override
  State<WebsiteTemplatesPage> createState() => _WebsiteTemplatesPageState();
}

class _WebsiteTemplatesPageState extends State<WebsiteTemplatesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WebsiteTemplateProvider>().loadTemplates();
    });
  }

  Future<void> _openForm({int? templateId}) async {
    await openRouteRespectingShell(
      context,
      AppRoutes.websiteTemplateForm,
      arguments: <String, dynamic>{'templateId': templateId},
    );
    if (mounted) await context.read<WebsiteTemplateProvider>().loadTemplates();
  }

  Future<void> _delete(int id, String name) async {
    final l10n = context.l10n;
    await showAppFormDialog(
      context,
      title: l10n.commonDelete,
      destructive: true,
      content: Text(l10n.websitesTemplateDeleteConfirm),
      onConfirm: () async {
        final provider = context.read<WebsiteTemplateProvider>();
        final ok = await provider.deleteTemplate(id);
        if (!mounted) return;
        if (!ok) {
          throw StateError(provider.operationError ?? name);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ServerAwarePageScaffold(
      title: l10n.websitesTemplateTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.output_outlined),
          tooltip: l10n.websitesTemplateOutputsTitle,
          onPressed: () => openRouteRespectingShell(
            context,
            AppRoutes.websiteTemplateOutputs,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.commonRefresh,
          onPressed: () =>
              context.read<WebsiteTemplateProvider>().loadTemplates(),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'website_template_create_fab',
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text(l10n.websitesTemplateCreate),
      ),
      body: Consumer<WebsiteTemplateProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.templates.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.templates.items.isEmpty) {
            return ModuleErrorStateWidget(
              message: provider.error!,
              onRetry: () => provider.loadTemplates(),
            );
          }
          final items = provider.templates.items;
          if (items.isEmpty) {
            return Center(child: Text(l10n.websitesTemplateEmpty));
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadTemplates(),
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
                      '${item.type} · ${item.remark.isEmpty ? item.createdAt : item.remark}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow_outlined),
                          tooltip: l10n.websitesTemplateGenerate,
                          onPressed: () => openRouteRespectingShell(
                            context,
                            AppRoutes.websiteTemplateOutputCreate,
                            arguments: <String, dynamic>{
                              'templateId': item.id,
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: l10n.websitesTemplateEdit,
                          onPressed: () => _openForm(templateId: item.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.commonDelete,
                          onPressed: () => _delete(item.id, item.name),
                        ),
                      ],
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

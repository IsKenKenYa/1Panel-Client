import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/containers/dialogs/template_create_dialog.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';
import '../containers_provider.dart';

class TemplatesTab extends StatelessWidget {
  const TemplatesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    
    return Consumer<ContainersProvider>(
      builder: (context, provider, _) {
        final templates = provider.data.templates;
        if (provider.templatesState.isLoading && templates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.templatesState.error != null && templates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(provider.templatesState.error!),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: provider.loadTemplates,
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          );
        }

        if (templates.isEmpty) {
          return Center(child: Text(l10n.commonEmpty));
        }

        return RefreshIndicator(
          onRefresh: provider.loadTemplates,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final template = templates[index];
              return AppCard(
                title: template.name,
                child: ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(template.name),
                  subtitle: Text(template.description),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        showDialog(
                          context: context,
                          builder: (context) => TemplateCreateDialog(template: template),
                        );
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.commonDelete),
                            content: Text(l10n.commonDeleteTemplateConfirm),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.commonCancel),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(l10n.commonConfirm),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await provider.deleteTemplate([template.id]);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.commonEdit),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          l10n.commonDelete,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

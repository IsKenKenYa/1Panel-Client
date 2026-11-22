import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';
import 'package:onepanel_client/features/containers/dialogs/template_create_dialog.dart';
import 'package:onepanel_client/features/shell/widgets/shell_list_bottom_padding.dart';
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
          return ModuleErrorStateWidget(
            message: provider.templatesState.error,
            onRetry: provider.loadTemplates,
          );
        }

        if (templates.isEmpty) {
          return Center(child: Text(l10n.commonEmpty));
        }

        return PartialErrorToastListener(
          errorMessage: provider.templatesState.error,
          hasCachedData: templates.isNotEmpty,
          onRetry: provider.loadTemplates,
          child: RefreshIndicator(
          onRefresh: provider.loadTemplates,
          child: ListView.separated(
            padding: AppDesignTokens.cardPadding +
                shellListBottomPadding(context),
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
                          builder: (context) =>
                              TemplateCreateDialog(template: template),
                        );
                      } else if (value == 'delete') {
                        final confirm = await ConfirmActionSheetWidget.show(
                          context,
                          title: l10n.commonDelete,
                          message: l10n.commonDeleteTemplateConfirm,
                          confirmLabel: l10n.commonDelete,
                          isDestructive: true,
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
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        );
      },
    );
  }
}
